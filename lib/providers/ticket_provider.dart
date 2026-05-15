import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http; // <-- ADDED FOR NOTIFICATIONS

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
  String _kitchenFilter = 'ALL';

  String _zoneFilter = 'ALL';
  bool _assignedToMeFilter = false;

  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'DATE_DESC';

  // Global Stats
  int _total = 0;
  int _toDo = 0;
  int _inProgress = 0;
  int _completed = 0;
  int _verified = 0;

  List<String> _allowedKitchenIds = [];
  RealtimeChannel? _ticketChannel;

  List<Map<String, dynamic>> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get priorityFilter => _priorityFilter;
  String get kitchenFilter => _kitchenFilter;

  String get zoneFilter => _zoneFilter;
  bool get assignedToMeFilter => _assignedToMeFilter;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get sortBy => _sortBy;

  int get total => _total;
  int get toDo => _toDo;
  int get inProgress => _inProgress;
  int get completed => _completed;
  int get verified => _verified;

  // ============================================================================
  // NOTIFICATION TRIGGER LOGIC
  // ============================================================================
  String get _pythonApiBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (Platform.isAndroid) return 'http://192.168.2.143:8000/api'; // Matches your python server IP
    if (Platform.isIOS) return 'http://127.0.0.1:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  /// Call this right after you successfully Insert or Update a ticket in Supabase!
  Future<void> sendInstantNotification({
    required String action, // Must be: "RAISED", "ASSIGNED", or "COMPLETED"
    required String ticketId,
    required String ticketNo,
    required String kitchenId,
    String? assignedToId,
  }) async {
    try {
      final url = Uri.parse('$_pythonApiBaseUrl/notifications/trigger');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "action": action,
          "ticket_id": ticketId,
          "ticket_no": ticketNo,
          "kitchen_id": kitchenId,
          "assigned_to_id": assignedToId,
        }),
      );

      debugPrint('Notification Triggered: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint("Failed to trigger notification: $e");
    }
  }
  // ============================================================================

  Future<void> initialize(List<String> kitchenIds) async {
    if (kitchenIds.isEmpty) return;
    if (_allowedKitchenIds.length == kitchenIds.length && _allowedKitchenIds.every((id) => kitchenIds.contains(id))) {
      return;
    }
    _allowedKitchenIds = kitchenIds;
    _initRealtime();
    refreshTickets();
  }

  void _initRealtime() {
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
    String? kitchenId,
    String? zoneId,
    bool? assignedToMe,
    DateTime? start,
    DateTime? end,
    String? sort,
  }) {
    if (status != null) _statusFilter = status;
    if (priority != null) _priorityFilter = priority;
    if (kitchenId != null) _kitchenFilter = kitchenId;
    if (zoneId != null) _zoneFilter = zoneId;
    if (assignedToMe != null) _assignedToMeFilter = assignedToMe;
    if (start != null) _startDate = start;
    if (end != null) _endDate = end;
    if (sort != null) _sortBy = sort;

    if (start == null && end == null && sort == null && status == null && priority == null && kitchenId == null && zoneId == null && assignedToMe == null) {
      _startDate = null;
      _endDate = null;
    }

    refreshTickets();
  }

  Future<void> refreshTickets({bool isRealtime = false}) async {
    _offset = 0;
    if (_allowedKitchenIds.isNotEmpty) {
      await _fetchGlobalStats();
      await fetchTickets(forceRefresh: isRealtime);
    }
  }

  Future<void> _fetchGlobalStats() async {
    if (_allowedKitchenIds.isEmpty) return;
    try {
      var query = _supabase.from('tickets').select('status');

      if (_kitchenFilter == 'ALL') {
        query = query.inFilter('kitchen_id', _allowedKitchenIds);
      } else {
        query = query.eq('kitchen_id', _kitchenFilter);
      }

      if (_assignedToMeFilter) {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) query = query.eq('assigned_to_id', userId);
      }

      final statsData = await query;
      _total = statsData.length;
      _toDo = statsData.where((t) => t['status'] == 'RAISED').length;
      _inProgress = statsData.where((t) => t['status'] == 'IN_PROGRESS' || t['status'] == 'ASSIGNED').length;
      _completed = statsData.where((t) => t['status'] == 'COMPLETED').length;
      _verified = statsData.where((t) => t['status'] == 'VERIFIED').length;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  Future<void> fetchTickets({bool loadMore = false, bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    if (_allowedKitchenIds.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    if (loadMore) _offset += _limit;

    try {
      var query = _supabase.from('tickets').select('''
            *, 
            m_kitchen(name),
            raised_by:m_user!raised_by_id(name),
            assigned_to:m_user!assigned_to_id(name),
            ticket_equipments(m_equipment(name))
          ''');

      if (_kitchenFilter == 'ALL') {
        query = query.inFilter('kitchen_id', _allowedKitchenIds);
      } else {
        query = query.eq('kitchen_id', _kitchenFilter);
      }

      if (_zoneFilter != 'ALL') {
        final areas = await _supabase.from('m_area').select('id').eq('zone_id', _zoneFilter);
        final List<String> areaIds = areas.map((a) => a['id'].toString()).toList();

        if (areaIds.isEmpty) {
          _tickets.clear();
          _isLoading = false;
          notifyListeners();
          return;
        }
        query = query.inFilter('area_id', areaIds);
      }

      if (_assignedToMeFilter) {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) query = query.eq('assigned_to_id', userId);
      }

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

      if (_priorityFilter != 'ALL') {
        query = query.eq('priority', _priorityFilter);
      }

      if (_startDate != null) {
        query = query.gte('ticket_raised_time', _startDate!.toIso8601String());
      }
      if (_endDate != null) {
        final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        query = query.lte('ticket_raised_time', endOfDay.toIso8601String());
      }

      if (_searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$_searchQuery%,ticket_no.ilike.%$_searchQuery%');
      }

      final bool isAscending = _sortBy == 'DATE_ASC';
      final response = await query.order('ticket_raised_time', ascending: isAscending).range(_offset, _offset + _limit - 1);

      if (!loadMore) _tickets.clear();
      _tickets.addAll(List<Map<String, dynamic>>.from(response));

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