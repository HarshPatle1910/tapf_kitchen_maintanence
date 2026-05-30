import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

import 'ticket_detail_screen.dart';
import '../core/services/notification_service.dart';

import '../widgets/ticket_card.dart';
import '../widgets/filter_bottom_sheet.dart';

// --- Screen Imports for Navigation ---
import 'reports/reports_screen.dart';
import 'master/user_management.dart';
import 'more_screen.dart';

// ============================================================================
// ROOT WRAPPER WITH BOTTOM NAVIGATION BAR
// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color navy = Color(0xFF26538D);
  final _supabase = Supabase.instance.client;
  int _selectedIndex = 0;

  bool _isLoadingAccess = true;
  List<String> _allowedReportCodes = [];

  @override
  void initState() {
    super.initState();
    NotificationService().initNotifications();
    _fetchUserReportAccess();
  }

  Future<void> _fetchUserReportAccess() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final res = await _supabase.from('user_report_access').select('report_code').eq('user_id', userId);
        if (mounted) {
          setState(() {
            _allowedReportCodes = List<String>.from(res.map((x) => x['report_code']));
            _isLoadingAccess = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAccess = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final bool isAdmin = authProv.activeRole == 'admin';

    // Show Reports Tab if Admin OR if they have access to at least 1 report
    final bool showReportsTab = isAdmin || _allowedReportCodes.isNotEmpty;

    // Dynamically build tabs based on permissions
    final List<Widget> pages = [
      const _HomeTicketView(),
      if (showReportsTab) ReportsScreen(allowedReportCodes: _allowedReportCodes, isAdmin: isAdmin),
      if (isAdmin) const UserManagementScreen(),
      const MoreScreen(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      if (showReportsTab) const BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Reports'),
      if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
      const BottomNavigationBarItem(icon: Icon(Icons.menu), activeIcon: Icon(Icons.menu_open), label: 'More'),
    ];

    // Ensure selectedIndex doesn't crash if permissions load and change tab count
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    if (_isLoadingAccess && !isAdmin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: navy)));
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: navy,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 0,
          items: navItems,
        ),
      ),
    );
  }
}

// ============================================================================
// THE ACTUAL TICKET DASHBOARD
// ============================================================================
class _HomeTicketView extends StatefulWidget {
  const _HomeTicketView();

  @override
  State<_HomeTicketView> createState() => _HomeTicketViewState();
}

class _HomeTicketViewState extends State<_HomeTicketView> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _kitchenZones = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<TicketProvider>().fetchTickets(loadMore: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = context.read<AuthProvider>();
      if (authProv.assignedKitchens.isNotEmpty) {
        final ticketProv = context.read<TicketProvider>();
        if (ticketProv.kitchenFilter == 'ALL') {
          ticketProv.setFilters(kitchenId: authProv.assignedKitchens.first['id'].toString());
        }
        final List<String> kIds = authProv.assignedKitchens.map((k) => k['id'].toString()).toList();
        ticketProv.initialize(kIds);
        _fetchKitchenZones();
      }
    });
  }

  Future<void> _fetchKitchenZones() async {
    try {
      final ticketProv = context.read<TicketProvider>();
      final authProv = context.read<AuthProvider>();
      final supabase = Supabase.instance.client;

      String targetKitchenId = ticketProv.kitchenFilter;
      if (targetKitchenId == 'ALL' || !authProv.assignedKitchens.any((k) => k['id'].toString() == targetKitchenId)) {
        if (authProv.assignedKitchens.isNotEmpty) {
          targetKitchenId = authProv.assignedKitchens.first['id'].toString();
        } else {
          return;
        }
      }

      final res = await supabase.from('m_zone').select('id, name').eq('kitchen_id', targetKitchenId).eq('status', true);
      if (mounted) {
        setState(() {
          _kitchenZones = List<Map<String, dynamic>>.from(res).map((z) => {'id': z['id'], 'name': z['name'], 'display_name': z['name']}).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching zones: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final authProv = context.watch<AuthProvider>();

    String? validDropdownValue = ticketProvider.kitchenFilter;
    if (validDropdownValue == 'ALL' || !authProv.assignedKitchens.any((k) => k['id'].toString() == validDropdownValue)) {
      validDropdownValue = authProv.assignedKitchens.isNotEmpty ? authProv.assignedKitchens.first['id'].toString() : null;
    }

    final bool hasActiveFilters = ticketProvider.priorityFilter != 'ALL' || ticketProvider.startDate != null || ticketProvider.zoneFilter != 'ALL' || ticketProvider.assignedToMeFilter || ticketProvider.raisedByMeFilter;
    final bool isSingleKitchen = authProv.assignedKitchens.length <= 1;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 75,
          title: Row(
            children: [
              Container(
                width: 45, height: 45,
                decoration: BoxDecoration(color: navy.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Image.asset("assets/icon/app_logo.png", fit: BoxFit.cover,),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Selected Kitchen", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    if (isSingleKitchen)
                      Text(
                        authProv.assignedKitchens.isNotEmpty ? authProv.assignedKitchens.first['name'] ?? 'Unknown Kitchen' : 'No Kitchens',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: navy, letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                            value: validDropdownValue,
                            isDense: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: navy, size: 20),
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: navy),
                            items: authProv.assignedKitchens.map((k) =>
                                DropdownMenuItem(value: k['id'].toString(), child: Text(k['name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.w700)))
                            ).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ticketProvider.setFilters(kitchenId: val);
                                _fetchKitchenZones();
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          color: golden,
          backgroundColor: Colors.white,
          onRefresh: () => ticketProvider.refreshTickets(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent, elevation: 0, floating: true, snap: true, automaticallyImplyLeading: false, toolbarHeight: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(170),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16), width: double.infinity,
                          child: Row(
                            children: [
                              Expanded(child: _buildStatCard("Total", ticketProvider.total, Colors.blueGrey, 'ALL', ticketProvider)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildStatCard("To Do", ticketProvider.toDo, Colors.redAccent, 'TO DO', ticketProvider)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildStatCard("WIP", ticketProvider.inProgress, Colors.orange, 'IN PROGRESS', ticketProvider)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildStatCard("Done", ticketProvider.completed, Colors.green, 'COMPLETED', ticketProvider)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildStatCard("Verified", ticketProvider.verified, Colors.teal, 'VERIFIED', ticketProvider)),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: RawAutocomplete<Map<String, dynamic>>(
                                    textEditingController: _searchController, focusNode: _searchFocusNode,
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                                      final query = textEditingValue.text.toLowerCase();
                                      return ticketProvider.tickets.where((ticket) {
                                        final title = (ticket['title'] ?? '').toLowerCase();
                                        final no = (ticket['ticket_no'] ?? '').toLowerCase();
                                        return title.contains(query) || no.contains(query);
                                      });
                                    },
                                    displayStringForOption: (option) => option['ticket_no'] ?? '',
                                    onSelected: (selection) {
                                      _searchController.clear(); _searchFocusNode.unfocus();
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: selection)));
                                    },
                                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                                      return TextField(
                                        controller: textEditingController, focusNode: focusNode,
                                        onSubmitted: (value) { onFieldSubmitted(); context.read<TicketProvider>().setSearchQuery(value); },
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                                        decoration: InputDecoration(
                                          hintText: "Search title or ticket #...", hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                          suffixIcon: textEditingController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 20), onPressed: () {
                                            textEditingController.clear(); context.read<TicketProvider>().setSearchQuery(''); focusNode.unfocus();
                                          }) : null,
                                          filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                                        ),
                                      );
                                    },
                                    optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Map<String, dynamic>> onSelected, Iterable<Map<String, dynamic>> options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4.0, borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            width: MediaQuery.of(context).size.width - 86,
                                            constraints: const BoxConstraints(maxHeight: 250),
                                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                            child: ListView.separated(
                                              padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
                                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                                              itemBuilder: (BuildContext context, int index) {
                                                final option = options.elementAt(index);
                                                return ListTile(
                                                  title: Text(option['title'] ?? 'No Title', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: navy), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  subtitle: Text(option['ticket_no'] ?? '#---', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                                  trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                                  onTap: () => onSelected(option),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Filter Trigger
                              InkWell(
                                onTap: () {
                                  _searchFocusNode.unfocus();
                                  showFilterBottomSheet(
                                      context: context,
                                      provider: ticketProvider,
                                      authProv: authProv,
                                      kitchenZones: _kitchenZones
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: hasActiveFilters ? navy : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: hasActiveFilters ? navy : Colors.transparent),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Icon(Icons.tune, color: hasActiveFilters ? Colors.white : navy),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      if (index == ticketProvider.tickets.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: golden)),
                        );
                      }
                      return TicketCard(ticket: ticketProvider.tickets[index]); // Injected modular card
                    },
                    childCount: ticketProvider.tickets.length + (ticketProvider.isLoading ? 1 : 0),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: golden,
          foregroundColor: navy,
          elevation: 4,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketDetailScreen())),
          icon: const Icon(Icons.add_rounded),
          label: Text("Raise Issue", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, String targetStatus, TicketProvider provider) {
    final bool isSelected = provider.statusFilter == targetStatus;
    return InkWell(
      onTap: () {
        if (isSelected) {
          provider.setFilters(status: 'ALL');
        } else {
          provider.setFilters(status: targetStatus);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
          boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count.toString(), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? color : navy)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 9, color: isSelected ? color : Colors.grey.shade500, fontWeight: FontWeight.w800, letterSpacing: 0), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}