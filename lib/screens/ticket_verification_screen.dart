import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import 'package:go_router/go_router.dart';
import '../core/routes/app_routes.dart';
import 'video_player_screen.dart';

class TicketVerificationScreen extends StatefulWidget {
  const TicketVerificationScreen({super.key});

  @override
  State<TicketVerificationScreen> createState() =>
      _TicketVerificationScreenState();
}

class _TicketVerificationScreenState extends State<TicketVerificationScreen>
    with TickerProviderStateMixin {
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
  List<Map<String, dynamic>> _zonePendingTickets = [];
  List<Map<String, dynamic>> _allocatedZones = [];
  String _selectedZoneFilter = 'ALL';

  bool _isAdmin = false;
  String? _currentUserId;
  String? _selectedKitchenId;

  bool get _canAccessZoneSignOff => _allocatedZones.isNotEmpty || _isAdmin;

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

    _fetchAllTickets();
  }

  void _updateTabController() {
    if (_canAccessZoneSignOff) {
      if (_tabController == null || _tabController!.length != 2) {
        _tabController?.dispose();
        _tabController = TabController(length: 2, vsync: this);
        _tabController!.addListener(() {
          if (mounted) setState(() {});
        });
      }
    } else {
      _tabController?.dispose();
      _tabController = null;
    }
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
            _zonePendingTickets = [];
            _allocatedZones = [];
            _isLoading = false;
          });
          _updateTabController();
        }
        return;
      }

      // Step 1: Fetch active zones for this kitchen and determine allocated zones
      final zonesRes = await _supabase
          .from('m_zone')
          .select('id, name, zone_leader')
          .eq('kitchen_id', _selectedKitchenId!)
          .eq('status', true)
          .order('name');
      final allKitchenZones = List<Map<String, dynamic>>.from(zonesRes);

      List<Map<String, dynamic>> userZones = allKitchenZones
          .where((z) => z['zone_leader']?.toString() == userId)
          .toList();

      // If user is an Admin and has no specific zone leader assignment,
      // fallback to all active zones in the kitchen so admin can sign off for any zone
      if (_isAdmin && userZones.isEmpty) {
        userZones = allKitchenZones;
      }

      // Step 2: Query tickets raised by current user with status COMPLETED for SELECTED KITCHEN only
      final raiserRes = await _supabase
          .from('tickets')
          .select('''
            *,
            m_kitchen(name),
            m_area(id, area_name, zone_id, m_zone(id, name)),
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

      // Step 3: Fetch completed tickets for allocated zones
      List<Map<String, dynamic>> pendingZone = [];
      if (userZones.isNotEmpty) {
        final zoneIds = userZones.map((z) => z['id'].toString()).toList();
        final areasRes = await _supabase
            .from('m_area')
            .select('id, area_name, zone_id')
            .inFilter('zone_id', zoneIds)
            .eq('status', true);
        final areaIds = List<Map<String, dynamic>>.from(areasRes)
            .map((a) => a['id'].toString())
            .toList();

        if (areaIds.isNotEmpty) {
          final zoneTicketsRes = await _supabase
              .from('tickets')
              .select('''
                *,
                m_kitchen(name),
                m_area(id, area_name, zone_id, m_zone(id, name)),
                raised_by:m_user!raised_by_id(name),
                assigned_to:m_user!assigned_to_id(name)
              ''')
              .eq('kitchen_id', _selectedKitchenId!)
              .eq('status', 'COMPLETED')
              .inFilter('area_id', areaIds)
              .order('ticket_completion_time', ascending: false);

          final allZoneCompleted =
              List<Map<String, dynamic>>.from(zoneTicketsRes);

          // Pending Zone Sign-Off: admin_verified is false or null
          pendingZone = allZoneCompleted.where((t) {
            return t['admin_verified'] != true;
          }).toList();
        }
      }

      // Fetch completion proof media for all pending tickets
      final allUniqueTicketIds = <String>{
        ...pendingRaiser.map((t) => t['id']?.toString() ?? ''),
        ...pendingZone.map((t) => t['id']?.toString() ?? ''),
      }..remove('');

      if (allUniqueTicketIds.isNotEmpty) {
        try {
          final mediaRes = await _supabase
              .from('ticket_media')
              .select('id, ticket_id, media_url, media_type, upload_stage')
              .inFilter('ticket_id', allUniqueTicketIds.toList());

          final Map<String, List<Map<String, dynamic>>> mediaByTicket = {};
          for (var m in mediaRes) {
            final tId = m['ticket_id']?.toString();
            if (tId != null) {
              mediaByTicket.putIfAbsent(tId, () => []).add(Map<String, dynamic>.from(m));
            }
          }

          for (var t in pendingRaiser) {
            t['ticket_media'] = mediaByTicket[t['id'].toString()] ?? [];
          }
          for (var t in pendingZone) {
            t['ticket_media'] = mediaByTicket[t['id'].toString()] ?? [];
          }
        } catch (mediaErr) {
          debugPrint("Error fetching ticket_media: $mediaErr");
        }
      }

      if (mounted) {
        setState(() {
          _allocatedZones = userZones;
          _raiserPendingTickets = pendingRaiser;
          _zonePendingTickets = pendingZone;
          _isLoading = false;
        });
        _updateTabController();
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
    required bool isVerifyingAsZoneLeader,
  }) async {
    final ticketId = ticket['id'];
    final nowISO = _getCurrentIST();
    final updates = <String, dynamic>{'updated_at': nowISO};

    bool currentAdminVerified = ticket['admin_verified'] ?? false;
    bool currentRaiserVerified = ticket['raiser_verified'] ?? false;

    if (isVerifyingAsZoneLeader) {
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
                  : isVerifyingAsZoneLeader
                      ? "Zone sign-off recorded for #${ticket['ticket_no']}!"
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
    required bool isVerifyingAsZoneLeader,
  }) {
    final otherVerified = isVerifyingAsZoneLeader
        ? (ticket['raiser_verified'] ?? false)
        : (ticket['admin_verified'] ?? false);
    final otherRoleLabel =
        isVerifyingAsZoneLeader ? "Ticket Raiser" : "Zone In-Charge";

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
                      color: (isVerifyingAsZoneLeader ? adminColor : raiserColor)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isVerifyingAsZoneLeader
                          ? Icons.layers_outlined
                          : Icons.verified_user_rounded,
                      color: isVerifyingAsZoneLeader ? adminColor : raiserColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVerifyingAsZoneLeader
                              ? "Zone Verification Sign-Off"
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
                        backgroundColor: isVerifyingAsZoneLeader
                            ? adminColor
                            : const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        isVerifyingAsZoneLeader
                            ? "Confirm Zone Sign-Off"
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
                          isVerifyingAsZoneLeader: isVerifyingAsZoneLeader,
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
      final zone = (t['m_area']?['m_zone']?['name'] ?? '').toString().toLowerCase();
      final area = (t['m_area']?['area_name'] ?? '').toString().toLowerCase();
      return title.contains(q) ||
          ticketNo.contains(q) ||
          kitchen.contains(q) ||
          assigned.contains(q) ||
          zone.contains(q) ||
          area.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _filterZoneList(List<Map<String, dynamic>> list) {
    var filtered = _filterList(list);
    if (_selectedZoneFilter != 'ALL') {
      filtered = filtered.where((t) {
        final zoneId = t['m_area']?['m_zone']?['id']?.toString() ??
            t['m_area']?['zone_id']?.toString();
        return zoneId == _selectedZoneFilter;
      }).toList();
    }
    return filtered;
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
    final isWeb = MediaQuery.of(context).size.width > 800;
    final int totalPending =
        _raiserPendingTickets.length + _zonePendingTickets.length;

    if (isWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildWebAppBar(
          context,
          authProv,
          isSingleKitchen,
          activeKitchenName,
          totalPending,
        ),
        body: _buildWebBody(),
      );
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
              _canAccessZoneSignOff
                  ? "Raiser & Zone Sign-Off Center"
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
        bottom: _canAccessZoneSignOff && _tabController != null
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
                            const Text("Zone Sign-Off"),
                            if (_zonePendingTickets.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _buildCountBadge(
                                _zonePendingTickets.length,
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
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            menuMaxHeight: 400,
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
                  hintText: "Search by title, #ID, area, or technician...",
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
                : _canAccessZoneSignOff && _tabController != null
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

                          // TAB 2 (Zone Leader / Admin): Zone Sign-Off
                          Column(
                            children: [
                              if (_allocatedZones.length > 1)
                                _buildZoneFilterChips(),
                              Expanded(
                                child: _buildTicketList(
                                  tickets: _filterZoneList(_zonePendingTickets),
                                  isRaiserContext: false,
                                  emptyTitle: "No Pending Zone Sign-Offs",
                                  emptyMessage: _selectedZoneFilter == 'ALL'
                                      ? "All completed tickets in your allocated zones have received zone sign-off."
                                      : "No pending sign-offs in the selected zone.",
                                ),
                              ),
                            ],
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

  // ==========================================
  // WEB DESKTOP LAYOUT (width > 800)
  // ==========================================

  PreferredSizeWidget _buildWebAppBar(
    BuildContext context,
    AuthProvider authProv,
    bool isSingleKitchen,
    String activeKitchenName,
    int totalPending,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(75),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 75,
        leadingWidth: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 16, color: navy),
                    const SizedBox(width: 4),
                    Text(
                      "Back",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Image.asset(
              "assets/icon/akshaya_patra_logo.png",
              height: 40,
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
                    "SELECTED KITCHEN",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isSingleKitchen)
                    Text(
                      activeKitchenName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF94A3B8),
                          width: 1.2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          menuMaxHeight: 400,
                          value: _selectedKitchenId,
                          isDense: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: navy,
                            size: 18,
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: navy,
                          ),
                          items: authProv.assignedKitchens.map((k) {
                            return DropdownMenuItem<String>(
                              value: k['id'].toString(),
                              child: Text(
                                k['name'] ?? 'Unknown Kitchen',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null && val != _selectedKitchenId) {
                              setState(() => _selectedKitchenId = val);
                              context.read<TicketProvider>().setFilters(kitchenId: val);
                              _fetchAllTickets();
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Stat Cards Row
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildWebStatCard(
                        label: "Total Pending",
                        count: totalPending,
                        color: navy,
                        isSelected: false,
                        onTap: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildWebStatCard(
                        label: "Raised by Me",
                        count: _raiserPendingTickets.length,
                        color: raiserColor,
                        isSelected: _tabController == null || _tabController!.index == 0,
                        onTap: () {
                          if (_tabController != null && _tabController!.index != 0) {
                            _tabController!.animateTo(0);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    if (_canAccessZoneSignOff) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWebStatCard(
                          label: "Zone Sign-Off",
                          count: _zonePendingTickets.length,
                          color: adminColor,
                          isSelected: _tabController != null && _tabController!.index == 1,
                          onTap: () {
                            if (_tabController != null && _tabController!.index != 1) {
                              _tabController!.animateTo(1);
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),
            // Refresh button
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(navy),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: navy, size: 24),
              tooltip: "Refresh Tickets",
              onPressed: _isLoading ? null : _fetchAllTickets,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildWebStatCard({
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
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
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isSelected ? color : navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebBody() {
    final isZoneTab = _canAccessZoneSignOff && (_tabController?.index ?? 0) == 1;
    final activeTickets = isZoneTab
        ? _filterZoneList(_zonePendingTickets)
        : _filterList(_raiserPendingTickets);

    return Column(
      children: [
        // Web Control Bar (Search + Tab Pills + Zone Chips)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Search Box
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                        },
                        decoration: InputDecoration(
                          hintText: "Search by ticket #, title, technician, zone, area...",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: navy,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Tab Switcher Pills
                  if (_canAccessZoneSignOff && _tabController != null)
                    _buildWebTabPills(),
                ],
              ),

              // Zone Filter Chips if on Zone tab and multiple zones
              if (isZoneTab && _allocatedZones.length > 1) ...[
                const SizedBox(height: 10),
                _buildZoneFilterChips(),
              ],
            ],
          ),
        ),

        // Main Table Area
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: navy))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: activeTickets.isEmpty
                      ? _buildWebEmptyState(isZoneTab)
                      : _buildWebVerificationTable(
                          context,
                          activeTickets,
                          isZoneTab,
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildWebTabPills() {
    final activeIndex = _tabController?.index ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWebPillButton(
            title: "Raised by Me",
            count: _raiserPendingTickets.length,
            isSelected: activeIndex == 0,
            color: raiserColor,
            onTap: () {
              if (_tabController != null && _tabController!.index != 0) {
                _tabController!.animateTo(0);
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 4),
          _buildWebPillButton(
            title: "Zone Sign-Off",
            count: _zonePendingTickets.length,
            isSelected: activeIndex == 1,
            color: adminColor,
            onTap: () {
              if (_tabController != null && _tabController!.index != 1) {
                _tabController!.animateTo(1);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebPillButton({
    required String title,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWebEmptyState(bool isZoneTab) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 48,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isZoneTab
                  ? "No Pending Zone Sign-Offs"
                  : "No Pending Raiser Verifications",
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isZoneTab
                  ? (_selectedZoneFilter == 'ALL'
                      ? "All completed tickets in your allocated zones have received zone sign-off."
                      : "No pending sign-offs in the selected zone.")
                  : "None of your raised tickets in this kitchen require verification.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _fetchAllTickets,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Refresh List"),
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                side: const BorderSide(color: navy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebVerificationTable(
    BuildContext context,
    List<Map<String, dynamic>> tickets,
    bool isZoneTab,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed Header
          _buildWebTableHeader(),
          const Divider(height: 1, thickness: 1),

          // Rows
          Expanded(
            child: ListView.separated(
              itemCount: tickets.length,
              separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _WebVerificationTableRow(
                  key: ValueKey(ticket['id'] ?? ticket['ticket_no'] ?? index),
                  ticket: ticket,
                  index: index,
                  isZoneTab: isZoneTab,
                  onVerify: () => _confirmVerificationDialog(
                    ticket: ticket,
                    isVerifyingAsZoneLeader: isZoneTab,
                  ),
                  onOpenImage: (url) => _openImageViewer(context, url),
                  getCompletionImageUrl: _getCompletionImageUrl,
                  formatDate: _formatDate,
                  getPriorityColor: _getPriorityColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _buildWebHeaderCell('Ticket #', flex: 2),
          _buildWebHeaderCell('Title & Description', flex: 4),
          _buildWebHeaderCell('Zone & Area', flex: 3),
          _buildWebHeaderCell('Priority', flex: 2),
          _buildWebHeaderCell('Assigned Tech', flex: 3),
          _buildWebHeaderCell('Proof Media', flex: 2),
          _buildWebHeaderCell('Resolution Info', flex: 3),
          _buildWebHeaderCell('Audit Status', flex: 3),
          _buildWebHeaderCell('Action', flex: 3),
        ],
      ),
    );
  }

  Widget _buildWebHeaderCell(String title, {int flex = 1, double? width}) {
    final textWidget = Text(
      title,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: navy,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: textWidget);
    }
    return Expanded(flex: flex, child: textWidget);
  }

  // --- Zone Filter Chips for Zone Sign-Off Tab ---
  Widget _buildZoneFilterChips() {
    return Container(
      height: 38,
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: _selectedZoneFilter == 'ALL',
              label: Text(
                "All Allocated Zones (${_zonePendingTickets.length})",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: _selectedZoneFilter == 'ALL'
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: _selectedZoneFilter == 'ALL'
                      ? Colors.white
                      : Colors.grey.shade700,
                ),
              ),
              backgroundColor: Colors.white,
              selectedColor: adminColor,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedZoneFilter == 'ALL'
                      ? adminColor
                      : Colors.grey.shade300,
                ),
              ),
              onSelected: (_) {
                setState(() => _selectedZoneFilter = 'ALL');
              },
            ),
          ),
          ..._allocatedZones.map((z) {
            final zoneId = z['id'].toString();
            final zoneName = z['name'] ?? 'Zone';
            final count = _zonePendingTickets.where((t) {
              final tZoneId = t['m_area']?['m_zone']?['id']?.toString() ??
                  t['m_area']?['zone_id']?.toString();
              return tZoneId == zoneId;
            }).length;
            final isSelected = _selectedZoneFilter == zoneId;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  "$zoneName ($count)",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                backgroundColor: Colors.white,
                selectedColor: adminColor,
                checkmarkColor: Colors.white,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? adminColor : Colors.grey.shade300,
                  ),
                ),
                onSelected: (_) {
                  setState(() => _selectedZoneFilter = zoneId);
                },
              ),
            );
          }),
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
              : _buildZoneCard(ticket);
        },
      ),
    );
  }

  String? _getCompletionImageUrl(Map<String, dynamic> ticket) {
    final mediaList = ticket['ticket_media'] as List<dynamic>?;
    if (mediaList != null && mediaList.isNotEmpty) {
      for (var m in mediaList) {
        if (m is Map<String, dynamic>) {
          final stage = (m['upload_stage'] ?? '').toString().toUpperCase();
          final url = m['media_url']?.toString();
          if (stage == 'COMPLETED' && url != null && url.isNotEmpty) {
            if (!url.startsWith('http')) {
              return _supabase.storage.from('ticket-media').getPublicUrl(url);
            }
            return url;
          }
        }
      }
      for (var m in mediaList) {
        if (m is Map<String, dynamic>) {
          final url = m['media_url']?.toString();
          if (url != null && url.isNotEmpty) {
            if (!url.startsWith('http')) {
              return _supabase.storage.from('ticket-media').getPublicUrl(url);
            }
            return url;
          }
        }
      }
    }
    return null;
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    final lower = imageUrl.toLowerCase();
    final isVideo = lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm') ||
        lower.contains('.mkv') ||
        lower.contains('.avi');

    if (isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            videoUrl: imageUrl,
            title: "Verification Video",
            subtitle: "Completion Proof",
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Failed to load image",
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. RAISER CARD: Distinct Purple / Violet Theme ---
  Widget _buildRaiserCard(Map<String, dynamic> ticket) {
    final priorityColor = _getPriorityColor(ticket['priority']);
    final adminVerified = ticket['admin_verified'] == true;
    final areaName = ticket['m_area']?['area_name'];
    final zoneName = ticket['m_area']?['m_zone']?['name'];

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
          final ticketId =
              (ticket['id'] ?? ticket['ticket_no'] ?? '').toString();
          context
              .push(AppRoutes.ticketDetailPath(ticketId), extra: ticket)
              .then((_) => _fetchAllTickets());
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

              // Meta details (Kitchen & Zone/Area)
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
                  if (zoneName != null || areaName != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        [?zoneName, ?areaName].join(" • "),
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
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
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
                  const SizedBox(width: 8),
                  Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    "Completed: ${_formatDate(ticket['ticket_completion_time'])}",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Completion Proof Image Preview (Mobile)
              Builder(
                builder: (context) {
                  final completionUrl = _getCompletionImageUrl(ticket);
                  if (completionUrl == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _openImageViewer(context, completionUrl),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                completionUrl,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 54,
                                  height: 54,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image,
                                      size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Completion Proof Photo",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: navy,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Tap to view full resolution photo",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.zoom_in_rounded,
                                size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

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

              // Zone verification status indicator
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
                          ? "Zone In-Charge has verified this ticket"
                          : "Pending Zone In-Charge verification",
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
                    isVerifyingAsZoneLeader: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. ZONE CARD: Distinct Amber / Gold Theme with Zone Prominence ---
  Widget _buildZoneCard(Map<String, dynamic> ticket) {
    final priorityColor = _getPriorityColor(ticket['priority']);
    final raiserVerified = ticket['raiser_verified'] == true;
    final areaName = ticket['m_area']?['area_name'];
    final zoneName = ticket['m_area']?['m_zone']?['name'];

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
          final ticketId =
              (ticket['id'] ?? ticket['ticket_no'] ?? '').toString();
          context
              .push(AppRoutes.ticketDetailPath(ticketId), extra: ticket)
              .then((_) => _fetchAllTickets());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Ticket Number, Zone Badge & Priority Badge
              Row(
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
                  if (zoneName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.layers_outlined,
                              size: 12, color: Colors.orange.shade800),
                          const SizedBox(width: 4),
                          Text(
                            zoneName,
                            style: GoogleFonts.inter(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
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

              // Info Row: Area, Raiser, Technician
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (areaName != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            areaName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade700,
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

              // Completion Proof Image Preview (Mobile)
              Builder(
                builder: (context) {
                  final completionUrl = _getCompletionImageUrl(ticket);
                  if (completionUrl == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _openImageViewer(context, completionUrl),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                completionUrl,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 54,
                                  height: 54,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image,
                                      size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Completion Proof Photo",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: navy,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Tap to view full resolution photo",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.zoom_in_rounded,
                                size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

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
                    "Approve & Zone Sign-Off",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onPressed: () => _confirmVerificationDialog(
                    ticket: ticket,
                    isVerifyingAsZoneLeader: true,
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

class _WebVerificationTableRow extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final int index;
  final bool isZoneTab;
  final VoidCallback onVerify;
  final Function(String) onOpenImage;
  final String? Function(Map<String, dynamic>) getCompletionImageUrl;
  final String Function(String?) formatDate;
  final Color Function(String?) getPriorityColor;

  const _WebVerificationTableRow({
    super.key,
    required this.ticket,
    required this.index,
    required this.isZoneTab,
    required this.onVerify,
    required this.onOpenImage,
    required this.getCompletionImageUrl,
    required this.formatDate,
    required this.getPriorityColor,
  });

  @override
  State<_WebVerificationTableRow> createState() =>
      _WebVerificationTableRowState();
}

class _WebVerificationTableRowState extends State<_WebVerificationTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final ticketId = (ticket['id'] ?? ticket['ticket_no'] ?? '').toString();
    final priorityColor = widget.getPriorityColor(ticket['priority']);
    final raiserVerified = ticket['is_verified_by_raiser'] == true;
    final adminVerified = ticket['is_verified_by_admin'] == true;
    final completionUrl = widget.getCompletionImageUrl(ticket);
    final techName = ticket['assigned_to']?['name'] ?? 'Technician';
    final completedTime = widget.formatDate(ticket['ticket_completion_time']);
    final zoneName = ticket['m_area']?['m_zone']?['name'] ?? 'Unknown Zone';
    final areaName = ticket['m_area']?['area_name'] ?? 'General Area';
    final assetName = ticket['m_asset']?['name'];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          context.push(
            AppRoutes.ticketDetailPath(ticketId),
            extra: ticket,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFF1F5F9)
                : (widget.index.isEven ? Colors.white : const Color(0xFFFAFAFA)),
            border: Border(
              left: BorderSide(
                color: priorityColor,
                width: 4,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Ticket #
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26538D).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "#${ticket['ticket_no'] ?? ticket['id'] ?? '---'}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF26538D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // 2. Title & Description
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ticket['title'] ?? 'No Title',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (assetName != null &&
                          assetName.toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.precision_manufacturing_outlined,
                                size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                assetName.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Zone & Area
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          zoneName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        areaName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Priority
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ticket['priority'] ?? 'MEDIUM',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: priorityColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Assigned Tech
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.handyman_outlined,
                              size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              techName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        completedTime,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Proof Media (Completion Image Thumbnail)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: completionUrl != null
                      ? Tooltip(
                          message: "Click to preview completion photo",
                          child: InkWell(
                            onTap: () => widget.onOpenImage(completionUrl),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      completionUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image,
                                            size: 16, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.zoom_in,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.no_photography_outlined,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                ),
              ),

              // 7. Resolution Info
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: (ticket['action_taken'] != null &&
                          ticket['action_taken']
                              .toString()
                              .trim()
                              .isNotEmpty)
                      ? Tooltip(
                          message: ticket['action_taken'].toString(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticket['action_taken'].toString(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : Text(
                          "No remarks",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
              ),

              // 8. Audit Status
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: raiserVerified
                              ? Colors.green.shade50
                              : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              raiserVerified
                                  ? Icons.check_circle_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 11,
                              color: raiserVerified
                                  ? Colors.green.shade700
                                  : Colors.purple.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              raiserVerified
                                  ? "Raiser Verified"
                                  : "Awaiting Raiser",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: raiserVerified
                                    ? Colors.green.shade700
                                    : Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: adminVerified
                              ? Colors.green.shade50
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              adminVerified
                                  ? Icons.verified_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 11,
                              color: adminVerified
                                  ? Colors.green.shade700
                                  : Colors.amber.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              adminVerified
                                  ? "Zone Approved"
                                  : "Awaiting Zone",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: adminVerified
                                    ? Colors.green.shade700
                                    : Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 9. Actions
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isZoneTab
                              ? const Color(0xFFD97706)
                              : const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(
                          widget.isZoneTab
                              ? Icons.verified_outlined
                              : Icons.check_circle_outline,
                          size: 14,
                        ),
                        label: Text(
                          widget.isZoneTab ? "Sign-Off" : "Verify",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: widget.onVerify,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: Color(0xFF26538D),
                      ),
                      tooltip: "View Ticket Details",
                      onPressed: () {
                        context.push(
                          AppRoutes.ticketDetailPath(ticketId),
                          extra: ticket,
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

