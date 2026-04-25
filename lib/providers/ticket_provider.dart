import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 20;

  // --- Filter & Sort States ---
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  String _priorityFilter = 'ALL';
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'DATE_DESC';

  // Global Stats
  int _total = 0;
  int _toDo = 0;
  int _inProgress = 0;
  int _completed = 0;
  int _verified = 0;

  // Current active kitchen context
  String? _currentKitchenId;
  RealtimeChannel? _ticketChannel;

  List<Map<String, dynamic>> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get priorityFilter => _priorityFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get sortBy => _sortBy;

  int get total => _total;
  int get toDo => _toDo;
  int get inProgress => _inProgress;
  int get completed => _completed;
  int get verified => _verified;

  // Initialize and attach to a specific kitchen
  Future<void> initialize(String? kitchenId) async {
    String? targetKitchen = kitchenId;

    // SMART FALLBACK: If user has no kitchen assigned yet, grab the default one
    if (targetKitchen == null) {
      try {
        final fallback = await _supabase
            .from('m_kitchen')
            .select('id')
            .limit(1)
            .maybeSingle();
        if (fallback != null) {
          targetKitchen = fallback['id'];
        }
      } catch (e) {
        debugPrint("Kitchen Fallback Error: $e");
      }
    }

    if (targetKitchen == null || targetKitchen == _currentKitchenId) return;

    _currentKitchenId = targetKitchen;
    _initRealtime();
    refreshTickets();
  }

  void _initRealtime() {
    // Clean up old channel if switching kitchens
    _ticketChannel?.unsubscribe();

    _ticketChannel = _supabase
        .channel('public_tickets_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets',
          callback: (payload) {
            debugPrint("Realtime DB Change Detected: Refreshing tickets...");
            refreshTickets(isRealtime: true);
          },
        );
    _ticketChannel?.subscribe();
  }

  @override
  void dispose() {
    _ticketChannel?.unsubscribe();
    super.dispose();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    refreshTickets();
  }

  void setFilters({
    String? status,
    String? priority,
    DateTime? start,
    DateTime? end,
    String? sort,
  }) {
    if (status != null) _statusFilter = status;
    if (priority != null) _priorityFilter = priority;
    if (start != null) _startDate = start;
    if (end != null) _endDate = end;
    if (sort != null) _sortBy = sort;

    if (start == null &&
        end == null &&
        sort == null &&
        status == null &&
        priority == null) {
      _startDate = null;
      _endDate = null;
    }

    refreshTickets();
  }

  void clearDateFilter() {
    _startDate = null;
    _endDate = null;
    refreshTickets();
  }

  Future<void> refreshTickets({bool isRealtime = false}) async {
    _offset = 0;
    if (_currentKitchenId != null) {
      await _fetchGlobalStats();
      await fetchTickets(forceRefresh: isRealtime);
    }
  }

  Future<void> _fetchGlobalStats() async {
    if (_currentKitchenId == null) return;

    try {
      // Strictly isolate stats to the active kitchen
      final statsData = await _supabase
          .from('tickets')
          .select('status')
          .eq('kitchen_id', _currentKitchenId!);

      _total = statsData.length;
      _toDo = statsData.where((t) => t['status'] == 'RAISED').length;
      _inProgress = statsData
          .where(
            (t) => t['status'] == 'IN_PROGRESS' || t['status'] == 'ASSIGNED',
          )
          .length;
      _completed = statsData.where((t) => t['status'] == 'COMPLETED').length;
      _verified = statsData.where((t) => t['status'] == 'VERIFIED').length;

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  Future<void> fetchTickets({
    bool loadMore = false,
    bool forceRefresh = false,
  }) async {
    // Prevent overlapping queries unless forced by Realtime
    if (_isLoading && !forceRefresh) return;
    if (_currentKitchenId == null) return;

    _isLoading = true;
    notifyListeners();

    if (loadMore) _offset += _limit;

    try {
      // 0. Base Query with Relational Joins and Strict Kitchen Isolation
      var query = _supabase
          .from('tickets')
          .select('''
            *, 
            m_kitchen(name),
            raised_by:m_user!raised_by_id(name),
            assigned_to:m_user!assigned_to_id(name)
          ''')
          .eq('kitchen_id', _currentKitchenId!);

      // 1. Status Filter
      if (_statusFilter != 'ALL') {
        if (_statusFilter == 'TO DO') {
          query = query.eq('status', 'RAISED');
        } else if (_statusFilter == 'IN PROGRESS') {
          query = query.inFilter('status', ['IN_PROGRESS', 'ASSIGNED']);
        } else if (_statusFilter == 'COMPLETED') {
          query = query.eq('status', 'COMPLETED');
        } else if (_statusFilter == 'VERIFIED') {
          query = query.eq('status', 'VERIFIED');
        } else {
          query = query.eq('status', _statusFilter);
        }
      }

      // 2. Priority Filter
      if (_priorityFilter != 'ALL') {
        query = query.eq('priority', _priorityFilter);
      }

      // 3. Custom Date Range Filter
      if (_startDate != null) {
        query = query.gte('ticket_raised_time', _startDate!.toIso8601String());
      }
      if (_endDate != null) {
        final endOfDay = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        query = query.lte('ticket_raised_time', endOfDay.toIso8601String());
      }

      // 4. Search Filter
      if (_searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$_searchQuery%,ticket_no.ilike.%$_searchQuery%',
        );
      }

      // 5. Database Sorting Execution
      final bool isAscending = _sortBy == 'DATE_ASC';
      final response = await query
          .order('ticket_raised_time', ascending: isAscending)
          .range(_offset, _offset + _limit - 1);

      if (!loadMore) {
        _tickets.clear();
      }

      _tickets.addAll(List<Map<String, dynamic>>.from(response));

      // 6. Local Sorting Override for Priority
      if (_sortBy == 'PRIORITY_DESC') {
        _tickets.sort((a, b) {
          const pWeights = {'CRITICAL': 4, 'HIGH': 3, 'MEDIUM': 2, 'LOW': 1};
          final valA = pWeights[a['priority']] ?? 0;
          final valB = pWeights[b['priority']] ?? 0;
          return valB.compareTo(valA);
        });
      }
    } catch (e) {
      debugPrint("Error fetching tickets: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
