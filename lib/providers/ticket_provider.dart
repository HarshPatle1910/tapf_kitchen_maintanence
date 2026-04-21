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
  String _sortBy = 'DATE_DESC'; // DATE_DESC, DATE_ASC, PRIORITY_DESC

  // Global Stats
  int _total = 0;
  int _toDo = 0;
  int _inProgress = 0;
  int _completed = 0;

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

  TicketProvider() {
    _initRealtime();
    refreshTickets();
  }

  void _initRealtime() {
    _supabase.channel('public:tickets').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tickets',
      callback: (payload) => refreshTickets(),
    ).subscribe();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    refreshTickets();
  }

  // Updated to accept dates and sorting
  void setFilters({String? status, String? priority, DateTime? start, DateTime? end, String? sort}) {
    if (status != null) _statusFilter = status;
    if (priority != null) _priorityFilter = priority;
    if (start != null) _startDate = start;
    if (end != null) _endDate = end;
    if (sort != null) _sortBy = sort;

    // If the user cleared the dates from the UI
    if (start == null && end == null && sort == null && status == null && priority == null) {
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

  Future<void> refreshTickets() async {
    _offset = 0;
    _tickets.clear();
    await _fetchGlobalStats();
    await fetchTickets();
  }

  Future<void> _fetchGlobalStats() async {
    try {
      final statsData = await _supabase.from('tickets').select('status');
      _total = statsData.length;
      _toDo = statsData.where((t) => t['status'] == 'RAISED').length;
      _inProgress = statsData.where((t) => t['status'] == 'IN_PROGRESS' || t['status'] == 'ASSIGNED').length;
      _completed = statsData.where((t) => t['status'] == 'COMPLETED' || t['status'] == 'VERIFIED').length;
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  Future<void> fetchTickets({bool loadMore = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    if (loadMore) _offset += _limit;

    try {
      var query = _supabase
          .from('tickets')
          .select('''
            *, 
            m_kitchen(name),
            issue_categories(name),
            raised_by:m_user!raised_by_id(name),
            assigned_to:m_user!assigned_to_id(name)
          ''');

      // 1. Status Filter
      if (_statusFilter != 'ALL') {
        if (_statusFilter == 'TO DO') {
          query = query.eq('status', 'RAISED');
        } else if (_statusFilter == 'IN PROGRESS') {
          query = query.inFilter('status', ['IN_PROGRESS', 'ASSIGNED']);
        } else if (_statusFilter == 'COMPLETED') {
          query = query.inFilter('status', ['COMPLETED', 'VERIFIED']);
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
        // Include the entire end day (up to 23:59:59)
        final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        query = query.lte('ticket_raised_time', endOfDay.toIso8601String());
      }

      // 4. Search Filter
      if (_searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$_searchQuery%,ticket_no.ilike.%$_searchQuery%');
      }

      // 5. Database Sorting (Date based)
      final bool isAscending = _sortBy == 'DATE_ASC';
      final response = await query
          .order('ticket_raised_time', ascending: isAscending)
          .range(_offset, _offset + _limit - 1);

      if (loadMore) {
        _tickets.addAll(List<Map<String, dynamic>>.from(response));
      } else {
        _tickets = List<Map<String, dynamic>>.from(response);
      }

      // 6. Local Sorting for Priority (CRITICAL -> LOW)
      if (_sortBy == 'PRIORITY_DESC') {
        _tickets.sort((a, b) {
          const pWeights = {'CRITICAL': 4, 'HIGH': 3, 'MEDIUM': 2, 'LOW': 1};
          final valA = pWeights[a['priority']] ?? 0;
          final valB = pWeights[b['priority']] ?? 0;
          return valB.compareTo(valA); // Descending
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