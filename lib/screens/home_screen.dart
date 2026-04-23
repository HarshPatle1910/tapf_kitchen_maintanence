import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Only Riverpod now!
import '../main.dart'; // Access to your global providers
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import 'login_screen.dart';
import 'master/equipment_master_screen.dart';
import 'ticket_detail_screen.dart';
import 'master/user_management.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // FIX: Replaced context.read with ref.read
        ref.read(ticketControllerProvider).fetchTickets(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Properly watch both providers using Riverpod
    final ticketProvider = ref.watch(ticketControllerProvider);
    final authProvider = ref.watch(authControllerProvider);
    final isAdmin = authProvider.isAdmin; // Extracted from watched provider

    final bool hasActiveFilters =
        ticketProvider.priorityFilter != 'ALL' ||
            ticketProvider.startDate != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        centerTitle: false,
      ),
      drawer: _buildSidebar(context, isAdmin),
      body: Column(
        children: [
          // 1. Clickable Stats Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(child: _buildStatCard("Total", ticketProvider.total, Colors.blueGrey, 'ALL', ticketProvider)),
                const SizedBox(width: 4),
                Expanded(child: _buildStatCard("To Do", ticketProvider.toDo, Colors.redAccent, 'TO DO', ticketProvider)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard("In Progress", ticketProvider.inProgress, Colors.orange, 'IN PROGRESS', ticketProvider)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard("Completed", ticketProvider.completed, Colors.green, 'COMPLETED', ticketProvider)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard("Verified", ticketProvider.verified, Colors.teal, 'VERIFIED', ticketProvider)),
              ],
            ),
          ),

          // 2. Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    // FIX: Replaced context.read with ref.read
                    onSubmitted: (value) =>
                        ref.read(ticketControllerProvider).setSearchQuery(value),
                    decoration: InputDecoration(
                      hintText: "Search title or ticket #...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // FIX: Replaced context.read with ref.read
                          ref.read(ticketControllerProvider).setSearchQuery('');
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _showFilterBottomSheet(context, ticketProvider),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? const Color(0xFF4A56E2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.tune,
                      color: hasActiveFilters ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Ticket List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ticketProvider.refreshTickets(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount:
                ticketProvider.tickets.length +
                    (ticketProvider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == ticketProvider.tickets.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
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
        backgroundColor: const Color(0xFF4A56E2),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TicketDetailScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          "Raise Issue",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      int count,
      Color baseColor,
      String targetStatus,
      TicketProvider provider,
      ) {
    final isSelected = provider.statusFilter == targetStatus;

    return InkWell(
      onTap: () {
        provider.setFilters(status: targetStatus);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? baseColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: baseColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? baseColor : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sort & Filter",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                        child: const Text("Reset All"),
                      ),
                    ],
                  ),
                  const Divider(),

                  const Text(
                    "Sort By",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text("Newest First"),
                        selected: tempSort == 'DATE_DESC',
                        onSelected: (val) =>
                            setModalState(() => tempSort = 'DATE_DESC'),
                      ),
                      ChoiceChip(
                        label: const Text("Oldest First"),
                        selected: tempSort == 'DATE_ASC',
                        onSelected: (val) =>
                            setModalState(() => tempSort = 'DATE_ASC'),
                      ),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Priority "),
                            Icon(Icons.arrow_downward, size: 14),
                          ],
                        ),
                        selected: tempSort == 'PRIORITY_DESC',
                        onSelected: (val) =>
                            setModalState(() => tempSort = 'PRIORITY_DESC'),
                        selectedColor: Colors.red.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Date Raised",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        initialDateRange: tempStart != null && tempEnd != null
                            ? DateTimeRange(start: tempStart!, end: tempEnd!)
                            : null,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF4A56E2),
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempStart = picked.start;
                          tempEnd = picked.end;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateText,
                            style: TextStyle(
                              color: tempStart == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Color(0xFF4A56E2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Priority",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW']
                        .map(
                          (prio) => ChoiceChip(
                        label: Text(prio),
                        selected: tempPriority == prio,
                        onSelected: (val) =>
                            setModalState(() => tempPriority = prio),
                      ),
                    )
                        .toList(),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A56E2),
                        foregroundColor: Colors.white,
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
                      child: const Text(
                        "APPLY",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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

  Widget _buildSidebar(BuildContext context, bool isAdmin) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF4A56E2)),
            accountName: Text(
              isAdmin ? "Administrator" : "Staff Member",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(isAdmin ? "Full Access" : "Worker Portal"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF4A56E2)),
            ),
          ),

          if (isAdmin) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ADMIN CONTROLS",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('User Management'),
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
              leading: const Icon(Icons.build_circle_outlined),
              title: const Text('Equipment Registry'),
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
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // FIX: Replaced context.read with ref.read
              await ref.read(authControllerProvider).logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: priorityInfo.color, width: 6),
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                          style: TextStyle(
                            color: priorityInfo.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    ticket['title'] ?? 'No Title',
                    style: const TextStyle(
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
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ticket['m_kitchen']?['name'] ?? 'General',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "•  ${ticket['status']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _getStatusColor(ticket['status']),
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
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
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (!isRight)
              const Icon(Icons.person, size: 14, color: Colors.black54),
            if (!isRight) const SizedBox(width: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isRight) const SizedBox(width: 4),
            if (isRight)
              const Icon(Icons.engineering, size: 14, color: Colors.black54),
          ],
        ),
      ],
    );
  }
}