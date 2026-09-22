import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import 'ticket_detail_screen.dart';

class TicketVerificationScreen extends StatefulWidget {
  const TicketVerificationScreen({super.key});

  @override
  State<TicketVerificationScreen> createState() =>
      _TicketVerificationScreenState();
}

class _TicketVerificationScreenState extends State<TicketVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const Color navy = Color(0xFF26538D);
  static const Color raiserColor = Color(0xFF6366F1); // Indigo / Purple
  static const Color adminColor = Color(0xFFD97706); // Amber / Gold
  static const Color background = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;
  TabController? _tabController;

  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _raiserPendingTickets = [];
  List<Map<String, dynamic>> _adminPendingTickets = [];

  bool _isAdmin = false;
  String? _currentUserId;
  String? _selectedKitchenId;

  @override
  void initState() {
    super.initState();
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    _isAdmin = authProv.isAdmin;
    _currentUserId = authProv.currentUserId;

    // Resolve selected kitchen from TicketProvider, fallback to first assigned kitchen
    final currentKitchenId = ticketProv.kitchenFilter;
    if (currentKitchenId == 'ALL' ||
        !authProv.assignedKitchens.any(
          (k) => k['id'].toString() == currentKitchenId,
        )) {
      _selectedKitchenId = authProv.assignedKitchens.isNotEmpty
          ? authProv.assignedKitchens.first['id'].toString()
          : null;
    } else {
      _selectedKitchenId = currentKitchenId;
    }

    if (_isAdmin) {
      _tabController = TabController(length: 2, vsync: this);
    }

    _fetchAllTickets();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getCurrentIST() {
    final nowUtc = DateTime.now().toUtc();
    final ist = nowUtc.add(const Duration(hours: 5, minutes: 30));
    return ist.toIso8601String();
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _fetchAllTickets() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProv = context.read<AuthProvider>();
      final userId = authProv.currentUserId;

      if (userId == null || _selectedKitchenId == null) {
        if (mounted) {
          setState(() {
            _raiserPendingTickets = [];
            _adminPendingTickets = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Query 1: Tickets raised by current user with status COMPLETED for SELECTED KITCHEN only
      final raiserRes = await _supabase
          .from('tickets')
          .select('''
            *,
            m_kitchen(name),
            raised_by:m_user!raised_by_id(name),
            assigned_to:m_user!assigned_to_id(name)
          ''')
          .eq('kitchen_id', _selectedKitchenId!)
          .eq('raised_by_id', userId)
          .eq('status', 'COMPLETED')
          .order('ticket_completion_time', ascending: false);

      final allRaiserCompleted =
          List<Map<String, dynamic>>.from(raiserRes);

      // Pending Raiser verification: raiser_verified is false or null
      final pendingRaiser = allRaiserCompleted.where((t) {
        return t['raiser_verified'] != true;
      }).toList();

      // Query 2: If admin, fetch completed tickets for SELECTED KITCHEN only
      List<Map<String, dynamic>> pendingAdmin = [];
      if (_isAdmin) {
        final adminRes = await _supabase
            .from('tickets')
            .select('''
              *,
              m_kitchen(name),
              raised_by:m_user!raised_by_id(name),
              assigned_to:m_user!assigned_to_id(name)
            ''')
            .eq('kitchen_id', _selectedKitchenId!)
            .eq('status', 'COMPLETED')
            .order('ticket_completion_time', ascending: false);

        final allAdminCompleted =
            List<Map<String, dynamic>>.from(adminRes);

        // Pending Admin verification: admin_verified is false or null
        pendingAdmin = allAdminCompleted.where((t) {
          return t['admin_verified'] != true;
        }).toList();
      }

      if (mounted) {
        setState(() {
          _raiserPendingTickets = pendingRaiser;
          _adminPendingTickets = pendingAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading verification tickets: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load tickets: $e"),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  // --- Perform Verification ---
  Future<void> _verifyTicket({
    required Map<String, dynamic> ticket,
    required bool isVerifyingAsAdmin,
  }) async {
    final ticketId = ticket['id'];
    final nowISO = _getCurrentIST();
    final updates = <String, dynamic>{'updated_at': nowISO};

    bool currentAdminVerified = ticket['admin_verified'] ?? false;
    bool currentRaiserVerified = ticket['raiser_verified'] ?? false;

    if (isVerifyingAsAdmin) {
      updates['admin_verified'] = true;
      updates['admin_verified_at'] = nowISO;
      currentAdminVerified = true;
    } else {
      updates['raiser_verified'] = true;
      updates['raiser_verified_at'] = nowISO;
      currentRaiserVerified = true;
    }

    // Both verified -> Transition to VERIFIED
    bool fullyVerified = currentAdminVerified && currentRaiserVerified;
    if (fullyVerified) {
      updates['status'] = 'VERIFIED';
      updates['verified_by_id'] = _currentUserId;
    }

    try {
      await _supabase.from('tickets').update(updates).eq('id', ticketId);

      // Return any tools if fully verified
      if (fullyVerified) {
        await _supabase
            .from('ticket_tools')
            .update({'return_time': nowISO, 'is_vacant': true})
            .eq('ticket_id', ticketId)
            .isFilter('return_time', null);

        // Trigger notification
        if (mounted) {
          context.read<TicketProvider>().sendInstantNotification(
                action: 'VERIFIED',
                ticketId: ticketId,
                ticketNo: ticket['ticket_no'] ?? 'UNKNOWN',
                kitchenId: ticket['kitchen_id'],
                assignedToId: ticket['assigned_to_id'],
                raisedById: ticket['raised_by_id'],
                telegramMessageId: ticket['telegram_message_id'],
              );
        }
      }

      if (mounted) {
        context.read<TicketProvider>().refreshTickets();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fullyVerified
                  ? "Ticket #${ticket['ticket_no']} is now FULLY VERIFIED and closed!"
                  : isVerifyingAsAdmin
                      ? "Admin sign-off recorded for #${ticket['ticket_no']}!"
                      : "Raiser verification recorded for #${ticket['ticket_no']}!",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchAllTickets();
      }
    } catch (e) {
      debugPrint("Error verifying ticket: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to verify ticket: $e"),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  // --- Show Confirmation Bottom Sheet ---
  void _confirmVerificationDialog({
    required Map<String, dynamic> ticket,
    required bool isVerifyingAsAdmin,
  }) {
    final otherVerified = isVerifyingAsAdmin
        ? (ticket['raiser_verified'] ?? false)
        : (ticket['admin_verified'] ?? false);
    final otherRoleLabel = isVerifyingAsAdmin ? "Ticket Raiser" : "Facility Admin";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isVerifyingAsAdmin ? adminColor : raiserColor)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isVerifyingAsAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.verified_user_rounded,
                      color: isVerifyingAsAdmin ? adminColor : raiserColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVerifyingAsAdmin
                              ? "Admin Verification Sign-Off"
                              : "Raiser Work Confirmation",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "Ticket ${ticket['ticket_no'] ?? '#---'}",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              Text(
                ticket['title'] ?? 'Untitled Ticket',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              if (ticket['action_taken'] != null &&
                  ticket['action_taken'].toString().trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Action Taken by Technician:",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket['action_taken'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notice about overall status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: otherVerified
                      ? Colors.green.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: otherVerified
                        ? Colors.green.shade200
                        : Colors.amber.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      otherVerified
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      size: 18,
                      color: otherVerified
                          ? Colors.green.shade700
                          : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        otherVerified
                            ? "The $otherRoleLabel has already verified. Confirming now will close this ticket as fully VERIFIED."
                            : "Awaiting $otherRoleLabel verification. After both parties verify, the ticket will be closed.",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: otherVerified
                              ? Colors.green.shade900
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isVerifyingAsAdmin ? adminColor : const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        isVerifyingAsAdmin
                            ? "Confirm Admin Sign-Off"
                            : "Confirm & Verify",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _verifyTicket(
                          ticket: ticket,
                          isVerifyingAsAdmin: isVerifyingAsAdmin,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Filtering Helper ---
  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((t) {
      final title = (t['title'] ?? '').toString().toLowerCase();
      final ticketNo = (t['ticket_no'] ?? '').toString().toLowerCase();
      final kitchen = (t['m_kitchen']?['name'] ?? '').toString().toLowerCase();
      final assigned = (t['assigned_to']?['name'] ?? '').toString().toLowerCase();
      return title.contains(q) ||
          ticketNo.contains(q) ||
          kitchen.contains(q) ||
          assigned.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final assignedKitchens = authProv.assignedKitchens;
    final bool isSingleKitchen = assignedKitchens.length <= 1;

    String activeKitchenName = 'No Facility Assigned';
    if (_selectedKitchenId != null) {
      final match = assignedKitchens.firstWhere(
        (k) => k['id'].toString() == _selectedKitchenId,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty && match['name'] != null) {
        activeKitchenName = match['name'];
      }
    } else if (assignedKitchens.isNotEmpty) {
      activeKitchenName = assignedKitchens.first['name'] ?? 'Facility';
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ticket Verification",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
            Text(
              _isAdmin
                  ? "Raiser & Admin Sign-Off Center"
                  : "Confirm resolution of your raised tickets",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: navy),
            tooltip: "Refresh Tickets",
            onPressed: _fetchAllTickets,
          ),
        ],
        bottom: _isAdmin && _tabController != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: navy,
                    indicatorWeight: 3,
                    labelColor: navy,
                    unselectedLabelColor: Colors.grey.shade500,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Raised by Me"),
                            if (_raiserPendingTickets.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _buildCountBadge(
                                _raiserPendingTickets.length,
                                raiserColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Admin Sign-Off"),
                            if (_adminPendingTickets.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _buildCountBadge(
                                _adminPendingTickets.length,
                                adminColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // 1. Kitchen Selector Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: navy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.kitchen_rounded, size: 18, color: navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "SELECTED KITCHEN",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      if (isSingleKitchen)
                        Text(
                          activeKitchenName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedKitchenId,
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
                            items: assignedKitchens.map((k) {
                              return DropdownMenuItem<String>(
                                value: k['id'].toString(),
                                child: Text(
                                  k['name'] ?? 'Unknown Kitchen',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null && val != _selectedKitchenId) {
                                setState(() => _selectedKitchenId = val);
                                context
                                    .read<TicketProvider>()
                                    .setFilters(kitchenId: val);
                                _fetchAllTickets();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search by title, #ID, or technician...",
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 3. Tab Views / Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: navy))
                : _isAdmin && _tabController != null
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          // TAB 1: Raiser Pending Tickets
                          _buildTicketList(
                            tickets: _filterList(_raiserPendingTickets),
                            isRaiserContext: true,
                            emptyTitle: "No Pending Raiser Verifications",
                            emptyMessage:
                                "None of your raised tickets in this kitchen require verification.",
                          ),

                          // TAB 2 (Admin Only): Admin Sign-Off
                          _buildTicketList(
                            tickets: _filterList(_adminPendingTickets),
                            isRaiserContext: false,
                            emptyTitle: "No Pending Admin Sign-Offs",
                            emptyMessage:
                                "All completed tickets in this kitchen have been verified by an admin.",
                          ),
                        ],
                      )
                    : _buildTicketList(
                        tickets: _filterList(_raiserPendingTickets),
                        isRaiserContext: true,
                        emptyTitle: "No Pending Verifications",
                        emptyMessage:
                            "None of your raised tickets in this kitchen require verification.",
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // --- List Builder ---
  Widget _buildTicketList({
    required List<Map<String, dynamic>> tickets,
    required bool isRaiserContext,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchAllTickets,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: isRaiserContext ? raiserColor : adminColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    emptyTitle,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllTickets,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tickets.length,
        itemBuilder: (ctx, index) {
          final ticket = tickets[index];
          return isRaiserContext
              ? _buildRaiserCard(ticket)
              : _buildAdminCard(ticket);
        },
      ),
    );
  }

  // --- 1. RAISER CARD: Distinct Purple / Violet Theme ---
  Widget _buildRaiserCard(Map<String, dynamic> ticket) {
    final priorityColor = _getPriorityColor(ticket['priority']);
    final adminVerified = ticket['admin_verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: raiserColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: raiserColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticket: ticket),
            ),
          ).then((_) => _fetchAllTickets());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Ticket Number & Priority Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: navy.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ticket['ticket_no'] ?? '#---',
                            style: GoogleFonts.inter(
                              color: navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (ticket['priority'] ?? 'MEDIUM').toString().toUpperCase(),
                      style: GoogleFonts.inter(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                ticket['title'] ?? 'Untitled Ticket',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              // Meta details
              Row(
                children: [
                  Icon(Icons.kitchen_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      ticket['m_kitchen']?['name'] ?? 'Facility',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.handyman_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Solved by: ${ticket['assigned_to']?['name'] ?? 'Technician'}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Completed: ${_formatDate(ticket['ticket_completion_time'])}",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Taken Summary Box
              if (ticket['action_taken'] != null &&
                  ticket['action_taken'].toString().trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Technician Resolution:",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticket['action_taken'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Admin verification status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: adminVerified
                      ? Colors.green.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      adminVerified
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      size: 14,
                      color: adminVerified
                          ? Colors.green.shade700
                          : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      adminVerified
                          ? "Admin has verified this ticket"
                          : "Pending Admin verification",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: adminVerified
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A), // Emerald Green
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    "Confirm & Verify My Ticket",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onPressed: () => _confirmVerificationDialog(
                    ticket: ticket,
                    isVerifyingAsAdmin: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. ADMIN CARD: Distinct Amber / Gold Theme ---
  Widget _buildAdminCard(Map<String, dynamic> ticket) {
    final priorityColor = _getPriorityColor(ticket['priority']);
    final raiserVerified = ticket['raiser_verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: adminColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: adminColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticket: ticket),
            ),
          ).then((_) => _fetchAllTickets());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Ticket Number & Priority Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: adminColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ticket['ticket_no'] ?? '#---',
                            style: GoogleFonts.inter(
                              color: adminColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (ticket['priority'] ?? 'MEDIUM').toString().toUpperCase(),
                      style: GoogleFonts.inter(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                ticket['title'] ?? 'Untitled Ticket',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Info Row: Kitchen, Raiser, Technician
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.kitchen_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          ticket['m_kitchen']?['name'] ?? 'Facility',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          "Raised: ${ticket['raised_by']?['name'] ?? 'User'}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.handyman_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          "Tech: ${ticket['assigned_to']?['name'] ?? 'Unassigned'}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          "Completed: ${_formatDate(ticket['ticket_completion_time'])}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cause and Action Taken summary
              if ((ticket['cause_of_issue'] != null &&
                      ticket['cause_of_issue'].toString().trim().isNotEmpty) ||
                  (ticket['action_taken'] != null &&
                      ticket['action_taken'].toString().trim().isNotEmpty)) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket['cause_of_issue'] != null &&
                          ticket['cause_of_issue'].toString().trim().isNotEmpty) ...[
                        Text(
                          "Cause: ${ticket['cause_of_issue']}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (ticket['action_taken'] != null &&
                          ticket['action_taken'].toString().trim().isNotEmpty)
                        Text(
                          "Action: ${ticket['action_taken']}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Raiser status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: raiserVerified
                      ? Colors.green.shade50
                      : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      raiserVerified
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      size: 14,
                      color: raiserVerified
                          ? Colors.green.shade700
                          : Colors.purple.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      raiserVerified
                          ? "Raiser has confirmed the resolution"
                          : "Awaiting Raiser confirmation",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: raiserVerified
                            ? Colors.green.shade800
                            : Colors.purple.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: adminColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: Text(
                    "Approve & Admin Sign-Off",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onPressed: () => _confirmVerificationDialog(
                    ticket: ticket,
                    isVerifyingAsAdmin: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade800;
      case 'MEDIUM':
        return Colors.blue.shade700;
      case 'LOW':
        return Colors.green.shade700;
      default:
        return Colors.blueGrey;
    }
  }
}
