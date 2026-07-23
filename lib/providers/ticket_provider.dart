import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/constants/api_constants.dart';
import '../core/services/firebase_media_service.dart';

class TicketProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = false;
  int _offset = 0;
  final int _itemsPerPage = 10;
  int _currentPage = 1;

  // --- Filter & Sort States ---
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  String _priorityFilter = 'ALL';
  String _kitchenFilter = 'ALL';

  String _zoneFilter = 'ALL';
  bool _assignedToMeFilter = false;
  bool _raisedByMeFilter = false;

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
  bool get raisedByMeFilter => _raisedByMeFilter;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get sortBy => _sortBy;

  int get total => _total;
  int get toDo => _toDo;
  int get inProgress => _inProgress;
  int get completed => _completed;
  int get verified => _verified;
  
  int get currentPage => _currentPage;
  int get currentFilterTotal {
    if (_statusFilter == 'TO DO') return _toDo;
    if (_statusFilter == 'IN PROGRESS') return _inProgress;
    if (_statusFilter == 'COMPLETED') return _completed;
    if (_statusFilter == 'VERIFIED') return _verified;
    return _total;
  }
  int get totalPages => (currentFilterTotal / _itemsPerPage).ceil() == 0 ? 1 : (currentFilterTotal / _itemsPerPage).ceil();
  int get itemsPerPage => _itemsPerPage;

  // ============================================================================
  // NOTIFICATION TRIGGER LOGIC
  // ============================================================================

  Future<void> sendInstantNotification({
    required String action,
    required String ticketId,
    required String ticketNo,
    required String kitchenId,
    String? assignedToId,
    String? raisedById,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/notifications/trigger');
      final String apiKey = dotenv.env['NOTIFICATION_API_KEY'] ?? '';

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          "action": action,
          "ticket_id": ticketId,
          "ticket_no": ticketNo,
          "kitchen_id": kitchenId,
          "assigned_to_id": assignedToId,
          "raised_by_id": raisedById ?? _supabase.auth.currentUser?.id,
        }),
      );
      debugPrint('Notification Trigger [$action]: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint("Failed to trigger notification: $e");
    }
  }

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
    bool? raisedByMe,
    DateTime? start,
    DateTime? end,
    String? sort,
    bool clearDates = false,
  }) {
    if (status != null) _statusFilter = status;
    if (priority != null) _priorityFilter = priority;
    if (kitchenId != null) _kitchenFilter = kitchenId;
    if (zoneId != null) _zoneFilter = zoneId;
    if (assignedToMe != null) _assignedToMeFilter = assignedToMe;
    if (raisedByMe != null) _raisedByMeFilter = raisedByMe;
    if (sort != null) _sortBy = sort;

    if (clearDates) {
      _startDate = null;
      _endDate = null;
    } else {
      if (start != null) _startDate = start;
      if (end != null) _endDate = end;
    }

    refreshTickets();
  }

  Future<void> refreshTickets({bool isRealtime = false}) async {
    _offset = 0;
    _currentPage = 1;
    if (_allowedKitchenIds.isNotEmpty) {
      // Run both concurrently for faster UI updates
      await Future.wait([
        _fetchGlobalStats(),
        fetchTickets(forceRefresh: isRealtime),
      ]);
    }
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages) return;
    _currentPage = page;
    _offset = (_currentPage - 1) * _itemsPerPage;
    fetchTickets();
  }

  // UPDATED: Now respects all filters (Zone, Priority, Date, Search) for accurate tab counts
  Future<void> _fetchGlobalStats() async {
    if (_allowedKitchenIds.isEmpty) return;
    try {
      var query = _supabase.from('tickets').select('status');

      // 1. Kitchen Filter
      if (_kitchenFilter == 'ALL') {
        query = query.inFilter('kitchen_id', _allowedKitchenIds);
      } else {
        query = query.eq('kitchen_id', _kitchenFilter);
      }

      // 2. Zone Filter
      if (_zoneFilter != 'ALL') {
        final areas = await _supabase.from('m_area').select('id').eq('zone_id', _zoneFilter);
        final List<String> areaIds = areas.map((a) => a['id'].toString()).toList();

        if (areaIds.isEmpty) {
          _total = 0; _toDo = 0; _inProgress = 0; _completed = 0; _verified = 0;
          notifyListeners();
          return;
        }
        query = query.inFilter('area_id', areaIds);
      }

      // 3. User Filter
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        if (_assignedToMeFilter && _raisedByMeFilter) {
          query = query.or('assigned_to_id.eq.$userId,raised_by_id.eq.$userId');
        } else if (_assignedToMeFilter) {
          query = query.eq('assigned_to_id', userId);
        } else if (_raisedByMeFilter) {
          query = query.eq('raised_by_id', userId);
        }
      }

      // 4. Priority Filter
      if (_priorityFilter != 'ALL') {
        query = query.eq('priority', _priorityFilter);
      }

      // 5. Date Filters
      if (_startDate != null) {
        query = query.gte('ticket_raised_time', _startDate!.toIso8601String());
      }
      if (_endDate != null) {
        final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        query = query.lte('ticket_raised_time', endOfDay.toIso8601String());
      }

      // 6. Search Query
      if (_searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$_searchQuery%,ticket_no.ilike.%$_searchQuery%');
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

  Future uploadTicketMedia({
    required File file,
    required String ticketId,
    required String uploadStage,
    required String mediaType,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final mediaService = FirebaseMediaService();

    // 1. Upload to Firebase
    final uploadResult = await mediaService.compressAndUpload(
      file: file,
      ticketId: ticketId,
      uploadStage: uploadStage,
      mediaType: mediaType,
    );

    if (uploadResult != null) {
      // 2. Save reference to Supabase
      try {
        await _supabase.from('ticket_media').insert({
          'ticket_id': ticketId,
          'media_url': uploadResult['media_url'],
          'file_name': uploadResult['file_name'],
          'file_size': uploadResult['file_size'],
          'content_type': uploadResult['content_type'],
          'media_type': mediaType,
          'upload_stage': uploadStage,
          'uploaded_by': userId,
        });
        debugPrint("Media successfully saved to Supabase");
      } catch (e) {
        debugPrint("Failed to save media record to Supabase: \$e");
      }
    }
  }

  Future<void> fetchTickets({bool loadMore = false, bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    if (_allowedKitchenIds.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    if (loadMore) {
       // loadMore is no longer used for infinite scroll, but we keep the logic if needed
       _offset += _itemsPerPage;
       _currentPage++;
    }

    try {
      var query = _supabase.from('tickets').select('''
            *, 
            m_kitchen(name),
            raised_by:m_user!raised_by_id(name),
            assigned_to:m_user!assigned_to_id(name)
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

      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        if (_assignedToMeFilter && _raisedByMeFilter) {
          query = query.or('assigned_to_id.eq.$userId,raised_by_id.eq.$userId');
        } else if (_assignedToMeFilter) {
          query = query.eq('assigned_to_id', userId);
        } else if (_raisedByMeFilter) {
          query = query.eq('raised_by_id', userId);
        }
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
      final response = await query.order('ticket_raised_time', ascending: isAscending).range(_offset, _offset + _itemsPerPage - 1);

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