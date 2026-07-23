// ignore_for_file: unused_element, unused_field, unused_local_variable
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class ZoneMasterScreen extends StatefulWidget {
  const ZoneMasterScreen({super.key});

  @override
  State<ZoneMasterScreen> createState() => _ZoneMasterScreenState();
}

class _ZoneMasterScreenState extends State<ZoneMasterScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _kitchenUsers = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  String _sortBy = 'NEWEST';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String? _getActiveKitchenId() {
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    String activeKitchenId = ticketProv.kitchenFilter;

    if (activeKitchenId == 'ALL' || !authProv.assignedKitchens.any((k) => k['id'].toString() == activeKitchenId)) {
      if (authProv.assignedKitchens.isNotEmpty) {
        return authProv.assignedKitchens.first['id'].toString();
      }
      return null;
    }
    return activeKitchenId;
  }

  String _getActiveKitchenName(String? kitchenId) {
    if (kitchenId == null) return 'Unknown Kitchen';
    final authProv = context.read<AuthProvider>();

    int index = authProv.assignedKitchens.indexWhere((k) => k['id'].toString() == kitchenId);
    if (index != -1) {
      return authProv.assignedKitchens[index]['name']?.toString() ?? 'Unknown Kitchen';
    }
    return 'Unknown Kitchen';
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final activeKitchenId = _getActiveKitchenId();

      if (activeKitchenId == null) {
        if (mounted) {
          setState(() {
            _zones = [];
            _kitchenUsers = [];
          });
        }
        return;
      }

      final responses = await Future.wait([
        _supabase.from('m_zone').select('*, m_kitchen(name)').eq('kitchen_id', activeKitchenId).order('created_at'),
        _supabase.from('m_user').select('id, name, user_kitchens(kitchen_id)').eq('status', true),
      ]);

      if (mounted) {
        setState(() {
          _zones = List<Map<String, dynamic>>.from(responses[0]);

          final allUsers = List<Map<String, dynamic>>.from(responses[1]);
          _kitchenUsers = allUsers.where((u) {
            final userKitchens = u['user_kitchens'] as List<dynamic>? ?? [];
            return userKitchens.any((uk) => uk['kitchen_id'].toString() == activeKitchenId);
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredZones {
    var list = List<Map<String, dynamic>>.from(_zones);

    if (_searchQuery.isNotEmpty) {
      list = list.where((z) => z['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_statusFilter == 'ACTIVE') {
      list = list.where((z) => z['status'] == true).toList();
    } else if (_statusFilter == 'INACTIVE') {
      list = list.where((z) => z['status'] == false).toList();
    }

    if (_sortBy == 'NAME_ASC') {
      list.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    } else if (_sortBy == 'NAME_DESC') {
      list.sort((a, b) => b['name'].toString().compareTo(a['name'].toString()));
    } else {
      list.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
    }

    return list;
  }

  void _showFilterBottomSheet() {
    String tempStatus = _statusFilter;
    String tempSort = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Sort & Filter", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempStatus = 'ALL';
                            tempSort = 'NEWEST';
                          });
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text("Reset All", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  Text("Sort By", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _buildChip("Newest First", tempSort == 'NEWEST', () => setModalState(() => tempSort = 'NEWEST')),
                      _buildChip("Name (A-Z)", tempSort == 'NAME_ASC', () => setModalState(() => tempSort = 'NAME_ASC')),
                      _buildChip("Name (Z-A)", tempSort == 'NAME_DESC', () => setModalState(() => tempSort = 'NAME_DESC')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text("Status", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _buildChip("All", tempStatus == 'ALL', () => setModalState(() => tempStatus = 'ALL')),
                      _buildChip("Active", tempStatus == 'ACTIVE', () => setModalState(() => tempStatus = 'ACTIVE')),
                      _buildChip("Inactive", tempStatus == 'INACTIVE', () => setModalState(() => tempStatus = 'INACTIVE')),
                    ],
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      onPressed: () {
                        setState(() {
                          _statusFilter = tempStatus;
                          _sortBy = tempSort;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text("APPLY FILTERS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
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

  Future<void> _showZoneForm({Map<String, dynamic>? existingZone}) async {
    final targetKitchenId = existingZone?['kitchen_id']?.toString() ?? _getActiveKitchenId();

    if (targetKitchenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active kitchen selected.'), backgroundColor: Colors.red));
      return;
    }

    final targetKitchenName = existingZone != null
        ? (existingZone['m_kitchen']?['name'] ?? 'Unknown Kitchen')
        : _getActiveKitchenName(targetKitchenId);

    // Launch proper Stateful Widget Bottom Sheet
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ZoneFormBottomSheet(
        existingZone: existingZone,
        kitchenUsers: _kitchenUsers,
        targetKitchenId: targetKitchenId,
        targetKitchenName: targetKitchenName,
      ),
    );

    if (result == true) {
      _fetchData();
    }
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _supabase.from('m_zone').update({'status': !currentStatus}).eq('id', id);
      _fetchData();
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? navy : Colors.grey.shade700)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: navy.withOpacity(0.08),
      backgroundColor: Colors.white,
      showCheckmark: false,
      side: BorderSide(color: isSelected ? navy : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildStatCard(String label, int count, Color baseColor, String targetStatus) {
    final isSelected = _statusFilter == targetStatus;

    return InkWell(
      onTap: () => setState(() => _statusFilter = targetStatus),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? baseColor : Colors.transparent, width: 1.5),
          boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count.toString(), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? baseColor : navy)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: isSelected ? baseColor : Colors.grey.shade500, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _zones.length;
    final int activeCount = _zones.where((z) => z['status'] == true).length;
    final int inactiveCount = totalCount - activeCount;

    final displayList = _filteredZones;
    final bool hasActiveFilters = _statusFilter != 'ALL' || _sortBy != 'NEWEST';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background, elevation: 0, foregroundColor: navy,
          title: Text("Zone Registry", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: golden))
            : RefreshIndicator(
          color: golden, backgroundColor: Colors.white,
          onRefresh: _fetchData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: background, elevation: 0, floating: true, snap: true, automaticallyImplyLeading: false, toolbarHeight: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(160),
                  child: Column(
                    children: [
                      Container(
                        color: background, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard("Total", totalCount, Colors.blueGrey, 'ALL')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard("Active", activeCount, Colors.green, 'ACTIVE')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard("Inactive", inactiveCount, Colors.redAccent, 'INACTIVE')),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                                child: TextField(
                                  controller: _searchController, focusNode: _searchFocusNode, onChanged: (value) => setState(() => _searchQuery = value),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                                  decoration: InputDecoration(
                                    hintText: "Search zones...", hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                    suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 20), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); _searchFocusNode.unfocus(); }) : null,
                                    filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden, width: 2)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () { _searchFocusNode.unfocus(); _showFilterBottomSheet(); },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: hasActiveFilters ? navy : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hasActiveFilters ? navy : Colors.white),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
              if (displayList.isEmpty)
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40.0), child: Center(child: Text("No zones match your filters.", style: GoogleFonts.inter(color: Colors.grey)))))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final zone = displayList[i];
                        final bool isActive = zone['status'] == true;

                        // Look up the leader name matching the UUID
                        final String? leaderId = zone['zone_leader'];
                        String? leaderName;
                        if (leaderId != null) {
                          final match = _kitchenUsers.where((u) => u['id'] == leaderId).toList();
                          if (match.isNotEmpty) leaderName = match.first['name'];
                        }

                        final String? chatId = zone['telegram_chat_id'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                              border: Border.all(color: Colors.grey.shade100)
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(zone['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: isActive ? navy : Colors.grey)),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                            child: Text(isActive ? "Active" : "Inactive", style: GoogleFonts.inter(color: isActive ? Colors.green : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        ],
                                      ),
                                    ),
                                    IconButton(icon: const Icon(Icons.edit_outlined, color: navy), onPressed: () => _showZoneForm(existingZone: zone)),
                                  ],
                                ),
                                if ((leaderName != null && leaderName.isNotEmpty) || (chatId != null && chatId.isNotEmpty))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Divider(color: Colors.grey.shade100, height: 1),
                                  ),
                                if ((leaderName != null && leaderName.isNotEmpty) || (chatId != null && chatId.isNotEmpty))
                                  Row(
                                    children: [
                                      if (leaderName != null && leaderName.isNotEmpty) ...[
                                        Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(leaderName, style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                      ],
                                      if (chatId != null && chatId.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Icon(Icons.telegram, size: 14, color: Colors.blue.shade400),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(chatId, style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                      ]
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: displayList.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: navy, foregroundColor: Colors.white, elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () {
            FocusScope.of(context).unfocus();
            if (_getActiveKitchenId() == null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You must have an active Kitchen first!', style: GoogleFonts.inter()), backgroundColor: Colors.orange));
            } else {
              _showZoneForm();
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: Text("Add Zone", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// =====================================================================
// DEDICATED STATEFUL BOTTOM SHEET (Fixes the FocusNode/Overlay Crash)
// =====================================================================
class _ZoneFormBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? existingZone;
  final List<Map<String, dynamic>> kitchenUsers;
  final String targetKitchenId;
  final String targetKitchenName;

  const _ZoneFormBottomSheet({
    this.existingZone,
    required this.kitchenUsers,
    required this.targetKitchenId,
    required this.targetKitchenName,
  });

  @override
  State<_ZoneFormBottomSheet> createState() => _ZoneFormBottomSheetState();
}

class _ZoneFormBottomSheetState extends State<_ZoneFormBottomSheet> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  final _supabase = Supabase.instance.client;
  final formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController leaderController;
  late TextEditingController telegramController;
  late FocusNode leaderFocusNode;

  String? selectedLeaderId;
  bool isSaving = false;
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.existingZone?['name'] ?? '');

    // Reverse-lookup the user's name based on the stored UUID
    selectedLeaderId = widget.existingZone?['zone_leader'];
    String initialLeaderName = '';
    if (selectedLeaderId != null) {
      final match = widget.kitchenUsers.where((u) => u['id'] == selectedLeaderId).toList();
      if (match.isNotEmpty) {
        initialLeaderName = match.first['name'];
      }
    }

    leaderController = TextEditingController(text: initialLeaderName);
    telegramController = TextEditingController(text: widget.existingZone?['telegram_chat_id'] ?? '');
    leaderFocusNode = FocusNode();
    isActive = widget.existingZone?['status'] ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    leaderController.dispose();
    telegramController.dispose();
    leaderFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveZone() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final Map<String, dynamic> payload = {
        'name': nameController.text.trim(),
        'kitchen_id': widget.targetKitchenId,
        'zone_leader': selectedLeaderId, // Saving UUID, not name
        'telegram_chat_id': telegramController.text.trim().isEmpty ? null : telegramController.text.trim(),
        'status': isActive,
      };

      if (widget.existingZone == null) {
        await _supabase.from('m_zone').insert(payload);
      } else {
        await _supabase.from('m_zone').update(payload).eq('id', widget.existingZone!['id']);
      }

      if (mounted) {
        navigator.pop(true); // Return true to trigger refresh
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Zone saved successfully!', style: GoogleFonts.inter()), backgroundColor: Colors.green));
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red));
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                Text(widget.existingZone == null ? "Add New Zone" : "Edit Zone", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                const SizedBox(height: 24),

                TextFormField(
                  controller: TextEditingController(text: widget.targetKitchenName),
                  readOnly: true,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Target Kitchen",
                    labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: Icon(Icons.kitchen_outlined, color: Colors.grey.shade400, size: 20),
                    filled: true, fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: nameController,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Zone Name is required' : null,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "Zone Name *",
                    labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: const Icon(Icons.layers_outlined, color: Colors.grey),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Zone Leader Autocomplete with active X button
                RawAutocomplete<Map<String, dynamic>>(
                  textEditingController: leaderController,
                  focusNode: leaderFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return widget.kitchenUsers;
                    }
                    return widget.kitchenUsers.where((user) => user['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (option) => option['name'],
                  onSelected: (option) {
                    setState(() {
                      selectedLeaderId = option['id'];
                    });
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: textEditingController,
                      builder: (context, value, child) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                          textCapitalization: TextCapitalization.words,
                          onChanged: (val) {
                            if (selectedLeaderId != null) {
                              setState(() => selectedLeaderId = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: "Zone Leader",
                            labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                            prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                            filled: true, fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                            suffixIcon: value.text.isNotEmpty
                                ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                onPressed: () {
                                  textEditingController.clear();
                                  setState(() => selectedLeaderId = null);
                                }
                            )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                  optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Map<String, dynamic>> onSelected, Iterable<Map<String, dynamic>> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 48),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: ListView.separated(
                            padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
                            separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title: Text(option['name'], style: GoogleFonts.inter(fontSize: 14, color: navy, fontWeight: FontWeight.w600)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: telegramController,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                  decoration: InputDecoration(
                    labelText: "Telegram Chat ID",
                    labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: const Icon(Icons.telegram, color: Colors.grey),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                  ),
                ),

                // Status Toggle (Only visible if Editing)
                if (widget.existingZone != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Zone Status", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy, fontSize: 14)),
                      subtitle: Text(isActive ? "Active" : "Inactive", style: GoogleFonts.inter(color: isActive ? Colors.green : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                      value: isActive,
                      activeColor: golden,
                      onChanged: (val) => setState(() => isActive = val),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                    onPressed: isSaving ? null : _saveZone,
                    child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text("SAVE ZONE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}