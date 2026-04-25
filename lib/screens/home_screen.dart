import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import 'authentication/login_screen.dart';
import 'master/equipment_master_screen.dart';
import 'master/user_management.dart';
import 'ticket_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<TicketProvider>().fetchTickets(loadMore: true);
      }
    });

    // Safely trigger initialization exactly ONCE when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context.read<TicketProvider>().initialize(authProvider.activeKitchenId);
    });
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
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.activeRole == 'admin';

    final bool hasActiveFilters =
        ticketProvider.priorityFilter != 'ALL' ||
        ticketProvider.startDate != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: navy,
          title: Text(
            "Maintenance Dashboard",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
        ),
        drawer: _buildSidebar(context, isAdmin, authProvider),
        body: Column(
          children: [
            // 1. NON-SCROLLABLE QUICK FILTERS ROW
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Total",
                      ticketProvider.total,
                      Colors.blueGrey,
                      'ALL',
                      ticketProvider,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildStatCard(
                      "To Do",
                      ticketProvider.toDo,
                      Colors.redAccent,
                      'TO DO',
                      ticketProvider,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildStatCard(
                      "WIP",
                      ticketProvider.inProgress,
                      Colors.orange,
                      'IN PROGRESS',
                      ticketProvider,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildStatCard(
                      "Done",
                      ticketProvider.completed,
                      Colors.green,
                      'COMPLETED',
                      ticketProvider,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildStatCard(
                      "Verified",
                      ticketProvider.verified,
                      Colors.teal,
                      'VERIFIED',
                      ticketProvider,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Sleek Search & Advanced Filter Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onSubmitted: (value) => context
                            .read<TicketProvider>()
                            .setSearchQuery(value),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: navy,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search title or ticket #...",
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<TicketProvider>()
                                        .setSearchQuery('');
                                    _searchFocusNode.unfocus();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: golden,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      _searchFocusNode.unfocus();
                      _showFilterBottomSheet(context, ticketProvider);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: hasActiveFilters ? navy : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasActiveFilters ? navy : Colors.grey.shade300,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.tune,
                        color: hasActiveFilters ? Colors.white : navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Ticket List
            Expanded(
              child: RefreshIndicator(
                color: golden,
                onRefresh: () => ticketProvider.refreshTickets(),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount:
                      ticketProvider.tickets.length +
                      (ticketProvider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == ticketProvider.tickets.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(color: golden),
                        ),
                      );
                    }
                    return _TicketCard(ticket: ticketProvider.tickets[index]);
                  },
                ),
              ),
            ),
          ],
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

  // UPDATED STAT CARD TO FIT PERFECTLY
  Widget _buildStatCard(
    String label,
    int count,
    Color baseColor,
    String targetStatus,
    TicketProvider provider,
  ) {
    final isSelected = provider.statusFilter == targetStatus;

    return InkWell(
      onTap: () => provider.setFilters(status: targetStatus),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? baseColor : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isSelected ? baseColor : navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isSelected ? baseColor : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, TicketProvider provider) {
    String tempPriority = provider.priorityFilter;
    String tempStatus = provider.statusFilter;
    String tempSort = provider.sortBy;
    DateTime? tempStart = provider.startDate;
    DateTime? tempEnd = provider.endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String dateText = "Select Date Range";
            if (tempStart != null && tempEnd != null) {
              dateText =
                  "${tempStart!.day}/${tempStart!.month}/${tempStart!.year}  -  ${tempEnd!.day}/${tempEnd!.month}/${tempEnd!.year}";
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sort & Filter",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempPriority = 'ALL';
                            tempStatus = 'ALL';
                            tempSort = 'DATE_DESC';
                            tempStart = null;
                            tempEnd = null;
                          });
                        },
                        child: Text(
                          "Reset All",
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  Text(
                    "Sort By",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        "Newest First",
                        tempSort == 'DATE_DESC',
                        () => setModalState(() => tempSort = 'DATE_DESC'),
                      ),
                      _buildChip(
                        "Oldest First",
                        tempSort == 'DATE_ASC',
                        () => setModalState(() => tempSort = 'DATE_ASC'),
                      ),
                      _buildChip(
                        "Highest Priority",
                        tempSort == 'PRIORITY_DESC',
                        () => setModalState(() => tempSort = 'PRIORITY_DESC'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Date Raised",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        initialDateRange: tempStart != null && tempEnd != null
                            ? DateTimeRange(start: tempStart!, end: tempEnd!)
                            : null,
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: navy,
                              onPrimary: Colors.white,
                              onSurface: navy,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null)
                        setModalState(() {
                          tempStart = picked.start;
                          tempEnd = picked.end;
                        });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateText,
                            style: GoogleFonts.inter(
                              color: tempStart == null
                                  ? Colors.grey.shade500
                                  : navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: navy,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Priority",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW']
                        .map(
                          (prio) => _buildChip(
                            prio,
                            tempPriority == prio,
                            () => setModalState(() => tempPriority = prio),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        provider.setFilters(
                          status: tempStatus,
                          priority: tempPriority,
                          start: tempStart,
                          end: tempEnd,
                          sort: tempSort,
                        );
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        "APPLY FILTERS",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? navy : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: golden.withOpacity(0.3),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: isSelected ? golden : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    bool isAdmin,
    AuthProvider authProv,
  ) {
    // Safely get the user's name or fallback to a default
    final String displayName =
        authProv.userName ?? (isAdmin ? "Administrator" : "Staff Member");
    // Format the role to look clean (e.g., "Role: ADMIN")
    final String displayRole =
        "Role: ${(authProv.activeRole ?? 'Worker').toUpperCase()}";
    // Get the first letter for the Avatar (Fallback to 'U' if name is empty)
    final String initials = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'U';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: navy),
            accountName: Text(
              displayName,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              displayRole,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
            ),
          ),

          if (isAdmin) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ADMIN CONTROLS",
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: navy),
              title: Text(
                'User Management',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: navy,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.build_circle_outlined, color: navy),
              title: Text(
                'Equipment Registry',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: navy,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EquipmentMasterScreen(),
                  ),
                );
              },
            ),
            const Divider(),
          ],

          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              await authProv.logout();
              // if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final priorityInfo = _getPriorityInfo(ticket['priority']);
    final raisedByName = ticket['raised_by']?['name'] ?? 'Unknown User';
    final assignedToName = ticket['assigned_to']?['name'] ?? 'Unassigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: priorityInfo.color, width: 5),
            ),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticket: ticket),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticket['ticket_no'] ?? '#---',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityInfo.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priorityInfo.label,
                          style: GoogleFonts.inter(
                            color: priorityInfo.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    ticket['title'] ?? 'No Title',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.kitchen,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ticket['m_kitchen']?['name'] ?? 'General',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "•  ${ticket['status']}",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getStatusColor(ticket['status']),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _UserDisplay(label: "Raised by", name: raisedByName),
                      _UserDisplay(
                        label: "Assigned to",
                        name: assignedToName,
                        isRight: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'RAISED':
        return Colors.redAccent;
      case 'ASSIGNED':
        return Colors.blueAccent;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'VERIFIED':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  _PriorityData _getPriorityInfo(String? priority) {
    switch (priority) {
      case 'CRITICAL':
        return _PriorityData(Colors.red.shade700, 'CRITICAL');
      case 'HIGH':
        return _PriorityData(Colors.orange.shade700, 'HIGH');
      case 'MEDIUM':
        return _PriorityData(Colors.blue.shade600, 'MEDIUM');
      case 'LOW':
        return _PriorityData(Colors.green.shade600, 'LOW');
      default:
        return _PriorityData(Colors.grey, 'NONE');
    }
  }
}

class _PriorityData {
  final Color color;
  final String label;
  _PriorityData(this.color, this.label);
}

class _UserDisplay extends StatelessWidget {
  final String label;
  final String name;
  final bool isRight;

  const _UserDisplay({
    required this.label,
    required this.name,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (!isRight)
              Icon(Icons.person, size: 14, color: Colors.grey.shade400),
            if (!isRight) const SizedBox(width: 4),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (isRight) const SizedBox(width: 4),
            if (isRight)
              Icon(Icons.engineering, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ],
    );
  }
}
