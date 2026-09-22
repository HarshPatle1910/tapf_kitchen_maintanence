import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class EquipmentMasterScreen extends StatefulWidget {
  const EquipmentMasterScreen({super.key});

  @override
  State<EquipmentMasterScreen> createState() => _EquipmentMasterScreenState();
}

class _EquipmentMasterScreenState extends State<EquipmentMasterScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipment = [];
  List<Map<String, dynamic>> _allAreas = [];
  List<Map<String, dynamic>> _activeZones = [];
  bool _isLoading = true;

  // Search, Filter & Sort State
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // 'ALL', 'ACTIVE', 'INACTIVE'
  String _zoneFilter = 'ALL';   // 'ALL' or zone_id
  String _sortBy = 'NAME_ASC';  // 'NAME_ASC', 'NAME_DESC', 'NEWEST'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchZones();
      _fetchAreas();
      _fetchEquipment();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getActiveKitchenId() {
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    String activeId = ticketProv.kitchenFilter;

    if (authProv.assignedKitchens.isNotEmpty) {
      if (!authProv.assignedKitchens.any((k) => k['id'].toString() == activeId)) {
        activeId = authProv.assignedKitchens.first['id'].toString();
      }
    } else {
      activeId = '';
    }
    return activeId;
  }

  Future<void> _fetchZones() async {
    try {
      final kitchenId = _getActiveKitchenId();
      if (kitchenId.isEmpty) return;

      final response = await _supabase
          .from('m_zone')
          .select('id, name, kitchen_id')
          .eq('kitchen_id', kitchenId)
          .eq('status', true)
          .order('name');

      if (mounted) {
        setState(() {
          _activeZones = List<Map<String, dynamic>>.from(response);
          for (var z in _activeZones) {
            z['display_name'] = z['name'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching zones: $e");
    }
  }

  Future<void> _fetchAreas() async {
    try {
      final kitchenId = _getActiveKitchenId();
      if (kitchenId.isEmpty) return;

      final response = await _supabase
          .from('m_area')
          .select('id, area_name, zone_id, m_zone!inner(kitchen_id)')
          .eq('status', true)
          .eq('m_zone.kitchen_id', kitchenId);

      if (mounted) {
        setState(() {
          _allAreas = List<Map<String, dynamic>>.from(response);
          for (var a in _allAreas) {
            a['display_name'] = a['area_name'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching areas: $e");
    }
  }

  Future<void> _fetchEquipment() async {
    setState(() => _isLoading = true);
    try {
      final kitchenId = _getActiveKitchenId();
      if (kitchenId.isEmpty) throw Exception("No Active Kitchen");

      final response = await _supabase
          .from('m_equipment')
          .select('*, m_area!inner(id, area_name, zone_id, m_zone!inner(id, name, kitchen_id))')
          .eq('m_area.m_zone.kitchen_id', kitchenId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() => _equipment = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint("Error fetching equipment: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredEquipment {
    var list = List<Map<String, dynamic>>.from(_equipment);

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final code = (item['equipment_code'] ?? '').toString().toLowerCase();
        final model = (item['model'] ?? '').toString().toLowerCase();
        final areaName = (item['m_area']?['area_name'] ?? '').toString().toLowerCase();
        final zoneName = (item['m_area']?['m_zone']?['name'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q) || model.contains(q) || areaName.contains(q) || zoneName.contains(q);
      }).toList();
    }

    // Status filter: ALL, ACTIVE, INACTIVE
    if (_statusFilter == 'ACTIVE') {
      list = list.where((item) => item['status'] == true).toList();
    } else if (_statusFilter == 'INACTIVE') {
      list = list.where((item) => item['status'] == false).toList();
    }

    // Zone filter
    if (_zoneFilter != 'ALL') {
      list = list.where((item) {
        final zoneId = item['m_area']?['zone_id']?.toString() ??
            item['m_area']?['m_zone']?['id']?.toString();
        return zoneId == _zoneFilter;
      }).toList();
    }

    // Sort order: NAME_ASC, NAME_DESC, NEWEST
    if (_sortBy == 'NAME_ASC') {
      list.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
    } else if (_sortBy == 'NAME_DESC') {
      list.sort((a, b) => (b['name'] ?? '').toString().toLowerCase().compareTo((a['name'] ?? '').toString().toLowerCase()));
    } else if (_sortBy == 'NEWEST') {
      list.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
    }

    return list;
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _searchFocusNode.unfocus();
  }

  Future<void> _showAddEquipmentDialog({Map<String, dynamic>? existingEquipment}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return _EquipmentFormBottomSheet(allAreas: _allAreas, existingEquipment: existingEquipment);
      },
    );

    if (result == true) {
      _fetchEquipment();
    }
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    try {
      await _supabase.from('m_equipment').update({'status': !currentStatus}).eq('id', id);
      _fetchEquipment();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus ? 'Equipment marked as active' : 'Equipment marked as inactive',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: navy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFilterBottomSheet() {
    String tempStatus = _statusFilter;
    String tempZone = _zoneFilter;
    String tempSort = _sortBy;

    final zoneFilterCtrl = TextEditingController();
    final zoneFilterFocusNode = FocusNode();

    if (tempZone != 'ALL') {
      final match = _activeZones.firstWhere(
        (z) => z['id'].toString() == tempZone,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        zoneFilterCtrl.text = match['display_name'] ?? match['name'] ?? '';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Sort & Filter", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempStatus = 'ALL';
                                  tempZone = 'ALL';
                                  tempSort = 'NAME_ASC';
                                  zoneFilterCtrl.clear();
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
                            _buildChip("Name (A-Z)", tempSort == 'NAME_ASC', () => setModalState(() => tempSort = 'NAME_ASC')),
                            _buildChip("Name (Z-A)", tempSort == 'NAME_DESC', () => setModalState(() => tempSort = 'NAME_DESC')),
                            _buildChip("Newest First", tempSort == 'NEWEST', () => setModalState(() => tempSort = 'NEWEST')),
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
                        const SizedBox(height: 24),

                        Text("Filter by Zone", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        _buildSleekAutocomplete(
                          hint: "Search Zone (Clear for All)",
                          icon: Icons.layers_outlined,
                          controller: zoneFilterCtrl,
                          focusNode: zoneFilterFocusNode,
                          options: _activeZones,
                          isDisabled: false,
                          onSelected: (val) {
                            setModalState(() {
                              tempZone = val['id'].toString();
                            });
                          },
                          onCleared: () {
                            setModalState(() {
                              tempZone = 'ALL';
                            });
                          },
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() {
                                _statusFilter = tempStatus;
                                _zoneFilter = tempZone;
                                _sortBy = tempSort;
                              });
                              Navigator.pop(ctx);
                            },
                            child: Text("APPLY FILTERS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      zoneFilterCtrl.dispose();
      zoneFilterFocusNode.dispose();
    });
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? navy : Colors.grey.shade700,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: navy.withValues(alpha: 0.08),
      backgroundColor: Colors.white,
      showCheckmark: false,
      side: BorderSide(color: isSelected ? navy : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildStatCard(String label, int count, Color baseColor, String targetStatus) {
    final isSelected = _statusFilter == targetStatus;

    return InkWell(
      onTap: () => setState(() => _statusFilter = isSelected && targetStatus != 'ALL' ? 'ALL' : targetStatus),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? baseColor : Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count.toString(), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? baseColor : navy)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: isSelected ? baseColor : Colors.grey.shade600, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterBadge({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: navy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: navy.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: navy, fontWeight: FontWeight.w600)),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.close, size: 14, color: navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleekAutocomplete({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<Map<String, dynamic>> options,
    required bool isDisabled,
    required Function(Map<String, dynamic>) onSelected,
    VoidCallback? onCleared,
  }) {
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (val) {
        if (val.text.isEmpty) return options;
        return options.where((opt) => (opt['display_name'] ?? opt['name'] ?? '').toString().toLowerCase().contains(val.text.toLowerCase()));
      },
      displayStringForOption: (opt) => (opt['display_name'] ?? opt['name'] ?? '').toString(),
      onSelected: (sel) {
        onSelected(sel);
        focusNode.unfocus();
      },
      fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
        controller: ctrl,
        focusNode: fNode,
        enabled: !isDisabled,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDisabled ? Colors.grey.shade700 : navy),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: isDisabled ? Colors.grey.shade100 : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
          suffixIcon: ctrl.text.isNotEmpty && !isDisabled
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                  onPressed: () {
                    ctrl.clear();
                    if (onCleared != null) onCleared();
                  },
                )
              : null,
        ),
        onTap: () {
          if (!isDisabled && ctrl.text.isEmpty) {
            // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
            ctrl.notifyListeners();
          }
        },
      ),
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 48),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: opts.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (ctx, idx) => ListTile(
                dense: true,
                title: Text(
                  (opts.elementAt(idx)['display_name'] ?? opts.elementAt(idx)['name'] ?? '').toString(),
                  style: GoogleFonts.inter(fontSize: 13, color: navy, fontWeight: FontWeight.w500),
                ),
                onTap: () => onSel(opts.elementAt(idx)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _equipment.length;
    final int activeCount = _equipment.where((e) => e['status'] == true).length;
    final int inactiveCount = totalCount - activeCount;

    final displayList = _filteredEquipment;
    final bool hasActiveFilters = _statusFilter != 'ALL' || _zoneFilter != 'ALL' || _sortBy != 'NAME_ASC';

    String? selectedZoneName;
    if (_zoneFilter != 'ALL') {
      final match = _activeZones.firstWhere(
        (z) => z['id'].toString() == _zoneFilter,
        orElse: () => <String, dynamic>{},
      );
      selectedZoneName = match['name'] ?? match['display_name'];
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: navy,
          title: Text(
            "Equipment Registry",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Stats Row: Total, Active, Inactive
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Total", totalCount, Colors.blueGrey, 'ALL')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard("Active", activeCount, Colors.green, 'ACTIVE')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard("Inactive", inactiveCount, Colors.redAccent, 'INACTIVE')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Search Bar + Filter Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _searchFocusNode.hasFocus ? navy.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8, offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                            decoration: InputDecoration(
                              hintText: "Search name, code, model...",
                              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                              prefixIcon: Icon(Icons.search, color: _searchFocusNode.hasFocus ? navy : Colors.grey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(icon: const Icon(Icons.cancel, color: Colors.grey, size: 20), onPressed: _clearSearch)
                                  : null,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          _searchFocusNode.unfocus();
                          _showFilterBottomSheet();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: hasActiveFilters ? navy : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: hasActiveFilters ? navy : Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(Icons.tune_rounded, color: hasActiveFilters ? Colors.white : navy, size: 22),
                              if (hasActiveFilters)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
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
                    ],
                  ),

                  // 3. Active Filters Chips (if any active filter)
                  if (hasActiveFilters) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_zoneFilter != 'ALL') ...[
                            _buildActiveFilterBadge(
                              label: "Zone: ${selectedZoneName ?? 'Filtered'}",
                              onRemove: () => setState(() => _zoneFilter = 'ALL'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_statusFilter != 'ALL') ...[
                            _buildActiveFilterBadge(
                              label: "Status: ${_statusFilter == 'ACTIVE' ? 'Active' : 'Inactive'}",
                              onRemove: () => setState(() => _statusFilter = 'ALL'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_sortBy != 'NAME_ASC') ...[
                            _buildActiveFilterBadge(
                              label: "Sort: ${_sortBy == 'NAME_DESC' ? 'Z-A' : 'Newest'}",
                              onRemove: () => setState(() => _sortBy = 'NAME_ASC'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _statusFilter = 'ALL';
                                _zoneFilter = 'ALL';
                                _sortBy = 'NAME_ASC';
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: Colors.red.shade700,
                            ),
                            child: Text("Clear all", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. Equipment List
            Expanded(
              child: _isLoading && _equipment.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: golden))
                  : displayList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.precision_manufacturing_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                _equipment.isEmpty
                                    ? "No equipment found in this Kitchen"
                                    : "No equipment matches your filters",
                                style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              if (_equipment.isNotEmpty && hasActiveFilters) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(foregroundColor: navy, side: const BorderSide(color: navy)),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _statusFilter = 'ALL';
                                      _zoneFilter = 'ALL';
                                      _sortBy = 'NAME_ASC';
                                    });
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: Text("Reset Filters", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: navy,
                          onRefresh: () async {
                            await _fetchZones();
                            await _fetchAreas();
                            await _fetchEquipment();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final item = displayList[index];
                              return _EquipmentCard(
                                item: item,
                                onEdit: () => _showAddEquipmentDialog(existingEquipment: item),
                                onToggleStatus: (id, currentStatus) => _toggleStatus(id, currentStatus),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: golden, foregroundColor: navy, elevation: 2,
          onPressed: () {
            _searchFocusNode.unfocus();
            _showAddEquipmentDialog();
          },
          icon: const Icon(Icons.add_rounded),
          label: Text("Add Equipment", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

// =====================================================================
// DEDICATED STATEFUL BOTTOM SHEET (Fixes the FocusNode/Overlay Crash)
// =====================================================================
class _EquipmentFormBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> allAreas;
  final Map<String, dynamic>? existingEquipment;

  const _EquipmentFormBottomSheet({required this.allAreas, this.existingEquipment});

  @override
  State<_EquipmentFormBottomSheet> createState() => _EquipmentFormBottomSheetState();
}

class _EquipmentFormBottomSheetState extends State<_EquipmentFormBottomSheet> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  final _supabase = Supabase.instance.client;

  final formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController codeCtrl;
  late TextEditingController modelCtrl;
  late TextEditingController remarksCtrl;
  late TextEditingController areaCtrl;
  late FocusNode areaFocusNode;

  String? selectedAreaId;
  DateTime? commissionedDate;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final eq = widget.existingEquipment;
    nameCtrl = TextEditingController(text: eq?['name']);
    codeCtrl = TextEditingController(text: eq?['equipment_code']);
    modelCtrl = TextEditingController(text: eq?['model']);
    remarksCtrl = TextEditingController(text: eq?['remarks']);
    selectedAreaId = eq?['area_id']?.toString();
    
    if (eq != null && eq['m_area'] != null) {
      areaCtrl = TextEditingController(text: eq['m_area']['area_name']);
    } else {
      areaCtrl = TextEditingController();
    }
    if (eq != null && eq['date_of_commision'] != null) {
      commissionedDate = DateTime.tryParse(eq['date_of_commision']);
    }
    areaFocusNode = FocusNode();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    modelCtrl.dispose();
    remarksCtrl.dispose();
    areaCtrl.dispose();
    areaFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveEquipment() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    if (selectedAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please select an Area from the list.', style: GoogleFonts.inter()),
              backgroundColor: Colors.red
          )
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => isSaving = true);

    try {
      final data = {
        'name': nameCtrl.text,
        'area_id': selectedAreaId,
        'equipment_code': codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
        'model': modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
        'date_of_commision': commissionedDate?.toIso8601String().split('T')[0],
        'remarks': remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim(),
      };
      if (widget.existingEquipment != null) {
        await _supabase.from('m_equipment').update(data).eq('id', widget.existingEquipment!['id']);
      } else {
        await _supabase.from('m_equipment').insert(data);
      }

      if (mounted) {
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('Equipment saved successfully!', style: GoogleFonts.inter()),
                backgroundColor: Colors.green
            )
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('Error saving data: $e', style: GoogleFonts.inter()),
                backgroundColor: Colors.red
            )
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 12
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                Text(widget.existingEquipment != null ? "Edit Equipment" : "Register Equipment", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                const SizedBox(height: 24),

                _buildInputField(
                  ctrl: nameCtrl, label: "Equipment Name *", icon: Icons.precision_manufacturing, isRequired: true,
                ),
                const SizedBox(height: 16),

                _buildSleekAutocomplete(
                  hint: "Search Area *",
                  icon: Icons.place_outlined,
                  controller: areaCtrl,
                  focusNode: areaFocusNode,
                  options: widget.allAreas,
                  isDisabled: false,
                  onSelected: (val) {
                    setState(() {
                      selectedAreaId = val['id'].toString();
                    });
                  },
                  onCleared: () {
                    setState(() {
                      selectedAreaId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(ctrl: codeCtrl, label: "Eq. Code", icon: Icons.qr_code_2_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(ctrl: modelCtrl, label: "Model No.", icon: Icons.tag),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final picked = await showDatePicker(
                      context: context, initialDate: commissionedDate ?? DateTime.now(),
                      firstDate: DateTime(2000), lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: navy, onPrimary: Colors.white, onSurface: navy)),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => commissionedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    isEmpty: commissionedDate == null,
                    decoration: InputDecoration(
                      labelText: "Commissioned Date",
                      labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                      filled: true, fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Text(
                      commissionedDate == null ? "" : "${commissionedDate!.year}-${commissionedDate!.month.toString().padLeft(2, '0')}-${commissionedDate!.day.toString().padLeft(2, '0')}",
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: navy), maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildInputField(ctrl: remarksCtrl, label: "Remarks", icon: Icons.notes_rounded, maxLines: 2),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: isSaving ? null : _saveEquipment,
                    child: isSaving ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text("SAVE EQUIPMENT", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleekAutocomplete({
    required String hint, required IconData icon, required TextEditingController controller,
    required FocusNode focusNode, required List<Map<String, dynamic>> options,
    required bool isDisabled, required Function(Map<String, dynamic>) onSelected, VoidCallback? onCleared,
  }) {
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: controller, focusNode: focusNode,
      optionsBuilder: (val) {
        if (val.text.isEmpty) return options;
        return options.where((opt) => opt['display_name'].toString().toLowerCase().contains(val.text.toLowerCase()));
      },
      displayStringForOption: (opt) => opt['display_name'].toString(),
      onSelected: (sel) { onSelected(sel); focusNode.unfocus(); },
      fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
        controller: ctrl, focusNode: fNode, enabled: !isDisabled,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDisabled ? Colors.grey.shade700 : navy),
        decoration: InputDecoration(
          labelText: hint, labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          filled: true, fillColor: isDisabled ? Colors.grey.shade100 : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
          suffixIcon: ctrl.text.isNotEmpty && !isDisabled ? IconButton(icon: const Icon(Icons.clear, size: 16, color: Colors.grey), onPressed: () { ctrl.clear(); if (onCleared != null) onCleared(); }) : null,
        ),
      ),
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4.0, borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 48),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: ListView.separated(
              padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (ctx, idx) => ListTile(
                dense: true,
                title: Text(opts.elementAt(idx)['display_name'], style: GoogleFonts.inter(fontSize: 13, color: navy, fontWeight: FontWeight.w500)),
                onTap: () => onSel(opts.elementAt(idx)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController ctrl, required String label, required IconData icon, bool isRequired = false, int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy, fontSize: 14),
      validator: isRequired ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// =====================================================================
// EQUIPMENT CARD
// =====================================================================
class _EquipmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final Function(String id, bool currentStatus) onToggleStatus;
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  const _EquipmentCard({
    required this.item,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = item['status'] == true;
    final areaName = item['m_area'] != null ? (item['m_area']['area_name'] ?? 'No Area Assigned') : 'No Area Assigned';
    final zoneName = item['m_area'] != null && item['m_area']['m_zone'] != null
        ? (item['m_area']['m_zone']['name'] ?? '')
        : '';
    final String? eqCode = item['equipment_code'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          iconColor: navy,
          collapsedIconColor: Colors.grey,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? navy.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.precision_manufacturing_rounded, color: isActive ? navy : Colors.grey),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item['name'] ?? 'Unnamed',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? navy : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? "Active" : "Inactive",
                  style: GoogleFonts.inter(
                    color: isActive ? Colors.green : Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                if (eqCode != null && eqCode.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: navy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      eqCode,
                      style: GoogleFonts.inter(color: navy, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (zoneName.isNotEmpty) ...[
                  Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      zoneName,
                      style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text("•", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ),
                ],
                Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    areaName,
                    style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _InfoItem(title: "Model No.", value: item['model'] ?? 'N/A', icon: Icons.tag)),
                      Expanded(child: _InfoItem(title: "Commissioned", value: item['date_of_commision'] ?? 'N/A', icon: Icons.calendar_today)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoItem(
                    title: "Remarks",
                    value: item['remarks'] != null && item['remarks'].toString().isNotEmpty
                        ? item['remarks']
                        : 'No remarks added.',
                    icon: Icons.notes,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            isActive ? "Active" : "Inactive",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.green : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Switch.adaptive(
                            value: isActive,
                            activeColor: golden,
                            onChanged: (val) => onToggleStatus(item['id'].toString(), isActive),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: navy),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text("Edit Equipment", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        onPressed: onEdit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title; final String value; final IconData icon;
  const _InfoItem({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400), const SizedBox(width: 8),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600))
                ]
            )
        ),
      ],
    );
  }
}