// ignore_for_file: unused_element, unused_field, unused_local_variable
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

import 'ticket_detail_screen.dart';
import '../core/services/notification_service.dart';

import '../widgets/ticket_card.dart';
import '../widgets/web_ticket_card.dart';
import '../widgets/web_ticket_table.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/responsive_sidebar.dart';

// --- Screen Imports for Navigation ---
// import 'reports/reports_screen.dart';
import 'master/user_management.dart';
import 'more_screen.dart';
import 'ticket_verification_screen.dart';

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
  String? _lastCheckedKitchenId;
  bool _isSidebarFixed = true;

  // Master list to ensure we don't show the tab for deprecated/invalid codes
  final List<String> _validReportCodes = [
    "MNT-02",
    "MT-03",
    "MT-15",
    "MT-05",
    "MT-06",
    "MT-07",
    "MT-16",
    "MT-10",
    "MT-11",
    "MT-13",
    "MT-14",
    "MT-08",
  ];

  @override
  void initState() {
    super.initState();
    NotificationService().initNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketProv = context.read<TicketProvider>();
      final authProv = context.read<AuthProvider>();
      _resolveKitchenAndFetch(ticketProv, authProv);
    });
  }

  // Resolves the currently active kitchen and triggers a fetch if it changed
  void _resolveKitchenAndFetch(
    TicketProvider ticketProv,
    AuthProvider authProv,
  ) {
    String currentKitchenId = ticketProv.kitchenFilter;

    // Resolve 'ALL' or missing to the first actual assigned kitchen
    if (currentKitchenId == 'ALL' ||
        !authProv.assignedKitchens.any(
          (k) => k['id'].toString() == currentKitchenId,
        )) {
      if (authProv.assignedKitchens.isNotEmpty) {
        currentKitchenId = authProv.assignedKitchens.first['id'].toString();
      } else {
        if (mounted && _isLoadingAccess) {
          setState(() => _isLoadingAccess = false);
        }
        return;
      }
    }

    if (currentKitchenId.isNotEmpty &&
        currentKitchenId != _lastCheckedKitchenId) {
      _checkAndFetchPermissions(currentKitchenId);
    }
  }

  // Fetches permissions for the specific kitchen
  Future<void> _checkAndFetchPermissions(String kitchenId) async {
    _lastCheckedKitchenId = kitchenId;

    Future.microtask(() {
      if (mounted) setState(() => _isLoadingAccess = true);
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final res = await _supabase
            .from('user_report_access')
            .select('report_code')
            .eq('user_id', userId)
            .eq('kitchen_id', kitchenId);

        if (mounted) {
          setState(() {
            _allowedReportCodes = List<String>.from(
              res.map((x) => x['report_code']),
            );
            _isLoadingAccess = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAccess = false;
          _allowedReportCodes = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final ticketProv = context.watch<TicketProvider>();

    // Check if the kitchen was changed from the Ticket Dashboard dropdown
    _resolveKitchenAndFetch(ticketProv, authProv);

    final isWeb = MediaQuery.of(context).size.width > 800;
    final bool isAdmin = authProv.activeRole == 'admin';
    final bool hasValidReports = _allowedReportCodes.any(
      (code) => _validReportCodes.contains(code),
    );

    // Show Reports Tab if Admin OR if they have access to at least 1 valid report in current kitchen
    final bool showReportsTab = isAdmin || hasValidReports;

    final List<Widget> pages = [
      const _HomeTicketView(),
      // if (showReportsTab)
      //   ReportsScreen(
      //     allowedReportCodes: _allowedReportCodes,
      //     isAdmin: isAdmin,
      //   ),
      if (isAdmin) const UserManagementScreen(),
      const MoreScreen(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      // if (showReportsTab)
      //   const BottomNavigationBarItem(
      //     icon: Icon(Icons.analytics_outlined),
      //     activeIcon: Icon(Icons.analytics),
      //     label: 'Reports',
      //   ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Users',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu),
        activeIcon: Icon(Icons.menu_open),
        label: 'More',
      ),
    ];

    // Safety fallback: If tab disappears while user is on it, return them to Home
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    Widget bodyContent = IndexedStack(index: _selectedIndex, children: pages);

    if (isWeb) {
      final List<SidebarItem> sidebarItems = [
        SidebarItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
        // if (showReportsTab) SidebarItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Reports'),
        if (isAdmin) SidebarItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Users'),
        SidebarItem(icon: Icons.menu, activeIcon: Icons.menu_open, label: 'More'),
      ];

      return Scaffold(
        body: Row(
          children: [
            ResponsiveSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
              isFixed: _isSidebarFixed,
              onToggleFixed: () => setState(() => _isSidebarFixed = !_isSidebarFixed),
              items: sidebarItems,
            ),
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    return Scaffold(
      body: bodyContent,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: navy,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
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
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    // _scrollController listener removed to disable infinite scroll

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = context.read<AuthProvider>();
      if (authProv.assignedKitchens.isNotEmpty) {
        final ticketProv = context.read<TicketProvider>();
        if (ticketProv.kitchenFilter == 'ALL') {
          ticketProv.setFilters(
            kitchenId: authProv.assignedKitchens.first['id'].toString(),
          );
        }
        final List<String> kIds = authProv.assignedKitchens
            .map((k) => k['id'].toString())
            .toList();
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
      if (targetKitchenId == 'ALL' ||
          !authProv.assignedKitchens.any(
            (k) => k['id'].toString() == targetKitchenId,
          )) {
        if (authProv.assignedKitchens.isNotEmpty) {
          targetKitchenId = authProv.assignedKitchens.first['id'].toString();
        } else {
          return;
        }
      }

      final res = await supabase
          .from('m_zone')
          .select('id, name')
          .eq('kitchen_id', targetKitchenId)
          .eq('status', true);
      if (mounted) {
        setState(() {
          _kitchenZones = List<Map<String, dynamic>>.from(res)
              .map(
                (z) => {
                  'id': z['id'],
                  'name': z['name'],
                  'display_name': z['name'],
                },
              )
              .toList();
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
    final isWeb = MediaQuery.of(context).size.width > 800;

    String? validDropdownValue = ticketProvider.kitchenFilter;
    if (validDropdownValue == 'ALL' ||
        !authProv.assignedKitchens.any(
          (k) => k['id'].toString() == validDropdownValue,
        )) {
      validDropdownValue = authProv.assignedKitchens.isNotEmpty
          ? authProv.assignedKitchens.first['id'].toString()
          : null;
    }

    final bool hasActiveFilters =
        ticketProvider.priorityFilter != 'ALL' ||
        ticketProvider.startDate != null ||
        ticketProvider.zoneFilter != 'ALL' ||
        ticketProvider.areaFilter != 'ALL' ||
        ticketProvider.assignedToMeFilter ||
        ticketProvider.raisedByMeFilter;
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
              Image.asset(
                "assets/icon/akshaya_patra_logo.png",
                height: 42,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Selected Kitchen",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (isSingleKitchen)
                      Text(
                        authProv.assignedKitchens.isNotEmpty
                            ? authProv.assignedKitchens.first['name'] ??
                                  'Unknown Kitchen'
                            : 'No Kitchens',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: navy,
                          letterSpacing: -0.2,
                        ),
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
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            value: validDropdownValue,
                            isDense: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: navy,
                              size: 20,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: navy,
                            ),
                            items: authProv.assignedKitchens
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k['id'].toString(),
                                    child: Text(
                                      k['name'] ?? 'Unknown',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
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
              if (isWeb) ...[
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _buildSearchSortFilterRow(context, ticketProvider, authProv, hasActiveFilters),
                  ),
                ),
              ]
            ],
          ),
          actions: [
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.verified_outlined, color: navy, size: 24),
                  if (ticketProvider.completed > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          ticketProvider.completed > 9
                              ? "9+"
                              : ticketProvider.completed.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: "Ticket Verification",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TicketVerificationScreen(),
                  ),
                ).then((_) => ticketProvider.refreshTickets());
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? double.infinity : 1200),
            child: RefreshIndicator(
              color: golden,
              backgroundColor: Colors.white,
              onRefresh: () => ticketProvider.refreshTickets(),
          child: isWeb ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: WebTicketTable(
              tickets: ticketProvider.tickets,
              isLoading: ticketProvider.isLoading,
              onLoadMore: ticketProvider.tickets.length < ticketProvider.currentFilterTotal 
                  ? () => ticketProvider.fetchMoreTickets() 
                  : null,
            ),
          ) : CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 4,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(165),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                            width: double.infinity,
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
                          child: _buildSearchSortFilterRow(
                            context,
                            ticketProvider,
                            authProv,
                            hasActiveFilters,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ticket = ticketProvider.tickets[index];
                      return isWeb ? WebTicketCard(ticket: ticket) : TicketCard(ticket: ticket);
                    },
                    childCount: ticketProvider.tickets.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80, top: 16),
                  child: _buildPagination(ticketProvider),
                ),
              ),
            ],
          ),
          ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: golden,
          foregroundColor: navy,
          elevation: 4,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TicketDetailScreen()),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            "Raise Issue",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSortFilterRow(
    BuildContext context,
    TicketProvider ticketProvider,
    AuthProvider authProv,
    bool hasActiveFilters,
  ) {
    final bool isSortActive = ticketProvider.sortBy != 'DATE_DESC';
    final bool isSearchActive =
        _isSearchExpanded || _searchController.text.isNotEmpty;

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: isSearchActive
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: _buildCollapsedActionRow(
        context: context,
        ticketProvider: ticketProvider,
        authProv: authProv,
        hasActiveFilters: hasActiveFilters,
        isSortActive: isSortActive,
      ),
      secondChild: _buildExpandedSearchRow(
        context: context,
        ticketProvider: ticketProvider,
        authProv: authProv,
        hasActiveFilters: hasActiveFilters,
        isSortActive: isSortActive,
      ),
    );
  }

  Widget _buildCollapsedActionRow({
    required BuildContext context,
    required TicketProvider ticketProvider,
    required AuthProvider authProv,
    required bool hasActiveFilters,
    required bool isSortActive,
  }) {
    return Row(
      children: [
        // 1. Search Button (expands on tap)
        Expanded(
          child: _buildActionButton(
            icon: Icons.search,
            label: "Search",
            isActive: false,
            onTap: () {
              setState(() => _isSearchExpanded = true);
              Future.delayed(const Duration(milliseconds: 150), () {
                if (mounted) _searchFocusNode.requestFocus();
              });
            },
          ),
        ),
        const SizedBox(width: 8),

        // 2. Sort By Button
        Expanded(
          child: _buildActionButton(
            icon: Icons.swap_vert_rounded,
            label: isSortActive ? _getSortShortLabel(ticketProvider.sortBy) : "Sort",
            isActive: isSortActive,
            showDot: isSortActive,
            onTap: () => _showSortBottomSheet(context, ticketProvider),
          ),
        ),
        const SizedBox(width: 8),

        // 3. Filter Button
        Expanded(
          child: _buildActionButton(
            icon: Icons.tune,
            label: "Filter",
            isActive: hasActiveFilters,
            showDot: hasActiveFilters,
            onTap: () {
              _searchFocusNode.unfocus();
              showFilterBottomSheet(
                context: context,
                provider: ticketProvider,
                authProv: authProv,
                kitchenZones: _kitchenZones,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSearchRow({
    required BuildContext context,
    required TicketProvider ticketProvider,
    required AuthProvider authProv,
    required bool hasActiveFilters,
    required bool isSortActive,
  }) {
    final bool isWeb = MediaQuery.of(context).size.width > 800;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                ticketProvider.setSearchQuery(value);
              },
              onSubmitted: (value) {
                if (isWeb) ticketProvider.setSearchQuery(value);
              },
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: navy,
              ),
              decoration: InputDecoration(
                hintText: "Search title or ticket #...",
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: navy, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                  tooltip: "Close search",
                  onPressed: () {
                    _searchController.clear();
                    ticketProvider.setSearchQuery('');
                    _searchFocusNode.unfocus();
                    setState(() => _isSearchExpanded = false);
                  },
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: golden, width: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildCompactIconButton(
          icon: Icons.swap_vert_rounded,
          tooltip: "Sort (${_getSortShortLabel(ticketProvider.sortBy)})",
          isActive: isSortActive,
          onTap: () => _showSortBottomSheet(context, ticketProvider),
        ),
        const SizedBox(width: 8),
        _buildCompactIconButton(
          icon: Icons.tune,
          tooltip: "Filter",
          isActive: hasActiveFilters,
          onTap: () {
            _searchFocusNode.unfocus();
            showFilterBottomSheet(
              context: context,
              provider: ticketProvider,
              authProv: authProv,
              kitchenZones: _kitchenZones,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    bool showDot = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? navy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? navy : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : navy,
              size: 19,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : navy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showDot) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: golden,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isActive ? navy : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? navy : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : navy,
                size: 20,
              ),
              if (isActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: golden,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet(
    BuildContext context,
    TicketProvider ticketProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentSort = ticketProvider.sortBy;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.swap_vert_rounded, color: navy, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      "Sort Tickets",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSortOptionTile(
                  title: "Newest First (Default)",
                  subtitle: "Most recently raised tickets first",
                  isSelected: currentSort == 'DATE_DESC',
                  onTap: () {
                    ticketProvider.setFilters(sort: 'DATE_DESC');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _buildSortOptionTile(
                  title: "Oldest First",
                  subtitle: "Tickets raised longest ago first",
                  isSelected: currentSort == 'DATE_ASC',
                  onTap: () {
                    ticketProvider.setFilters(sort: 'DATE_ASC');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _buildSortOptionTile(
                  title: "Highest Priority First",
                  subtitle: "Critical & High priority tickets first",
                  isSelected: currentSort == 'PRIORITY_DESC',
                  onTap: () {
                    ticketProvider.setFilters(sort: 'PRIORITY_DESC');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? navy.withOpacity(0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? navy : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? navy : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: navy, size: 20)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  String _getSortShortLabel(String sort) {
    switch (sort) {
      case 'DATE_ASC':
        return "Oldest";
      case 'PRIORITY_DESC':
        return "Priority";
      case 'DATE_DESC':
      default:
        return "Sort";
    }
  }

  Widget _buildPagination(TicketProvider ticketProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: ticketProvider.currentPage > 1
              ? () => ticketProvider.goToPage(ticketProvider.currentPage - 1)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          'Page ${ticketProvider.currentPage} of ${ticketProvider.totalPages}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: navy,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: ticketProvider.currentPage < ticketProvider.totalPages
              ? () => ticketProvider.goToPage(ticketProvider.currentPage + 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color color,
    String targetStatus,
    TicketProvider provider,
  ) {
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
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? color : navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: isSelected ? color : Colors.grey.shade500,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
