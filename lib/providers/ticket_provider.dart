import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 20;

  List<Map<String, dynamic>> get tickets => _tickets;
  bool get isLoading => _isLoading;

  // Computed Stats for the Dashboard
  int get total => _tickets.length;
  int get toDo => _tickets.where((t) => t['status'] == 'RAISED').length;
  int get inProgress => _tickets.where((t) => t['status'] == 'IN_PROGRESS' || t['status'] == 'ASSIGNED').length;
  int get completed => _tickets.where((t) => t['status'] == 'COMPLETED' || t['status'] == 'VERIFIED').length;

  TicketProvider() {
    _initRealtime();
    refreshTickets();
  }

  // Listen for live updates from Supabase
  void _initRealtime() {
    _supabase.channel('public:tickets').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tickets',
      callback: (payload) {
        // If a ticket changes in the database, refresh the list automatically
        refreshTickets();
      },
    ).subscribe();
  }

  Future<void> refreshTickets() async {
    _offset = 0;
    _tickets.clear();
    await fetchTickets();
  }

  Future<void> fetchTickets({bool loadMore = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    if (loadMore) _offset += _limit;

    try {
      // FIX: Removed assigned_to_id(name) and raised_by_id(name)
      // so the raw String UUIDs are preserved for the Dropdowns!
      final response = await _supabase
          .from('tickets')
          .select('''
            *, 
            m_kitchen(name),
            issue_categories(name)
          ''')
          .order('ticket_raised_time', ascending: false)
          .range(_offset, _offset + _limit - 1);

      if (loadMore) {
        _tickets.addAll(List<Map<String, dynamic>>.from(response));
      } else {
        _tickets = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      debugPrint("Error fetching tickets: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}