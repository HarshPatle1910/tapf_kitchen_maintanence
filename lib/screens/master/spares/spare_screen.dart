import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/auth_provider.dart';
import '../../../providers/ticket_provider.dart';
import 'spare_inventory_screen.dart';

class SparesMasterScreen extends StatefulWidget {
  const SparesMasterScreen({super.key});

  @override
  State<SparesMasterScreen> createState() => _SparesMasterScreenState();
}

class _SparesMasterScreenState extends State<SparesMasterScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _spares = [];
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  String _typeFilter = 'ALL';
  String _statusFilter = 'ALL';
  bool _criticalOnlyFilter = false;

  // EXPANDED SPARE TYPES
  final List<String> _spareTypes = [
    'MECHANICAL', 'ELECTRICAL', 'CHEMICAL', 'OTHER'
  ];

  // UNIT OF MEASUREMENTS
  final List<String> _uomList = [
    'Nos', 'Kg', 'Ltr', 'Mtr', 'Box', 'Pkt', 'Roll', 'Set'
  ];

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

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final activeKitchenId = _getActiveKitchenId();
      if (activeKitchenId == null) {
        if (mounted) setState(() => _spares = []);
        return;
      }

      final vResp = await _supabase
          .from('m_vendor')
          .select('id, name')
          .eq('kitchen_id', activeKitchenId)
          .eq('status', true);

      final sResp = await _supabase
          .from('m_spares')
          .select('*, m_vendor(name), spare_tracker(current_qty)')
          .eq('kitchen_id', activeKitchenId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _vendors = List<Map<String, dynamic>>.from(vResp);
          for (var v in _vendors) {
            v['display_name'] = v['name'];
          }
          _spares = List<Map<String, dynamic>>.from(sResp);
        });
      }
    } catch (e) {
      debugPrint("Error fetching spares: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredSpares {
    var list = List<Map<String, dynamic>>.from(_spares);

    if (_searchQuery.isNotEmpty) {
      list = list.where((s) =>
      s['spare_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s['spare_code']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    if (_typeFilter != 'ALL') {
      list = list.where((s) => s['spare_type'] == _typeFilter).toList();
    }

    if (_statusFilter == 'ACTIVE') {
      list = list.where((s) => s['status'] == true).toList();
    } else if (_statusFilter == 'INACTIVE') {
      list = list.where((s) => s['status'] == false).toList();
    }

    if (_criticalOnlyFilter) {
      list = list.where((s) => s['is_critical'] == true).toList();
    }

    return list;
  }

  void _showFilterBottomSheet() {
    String tempType = _typeFilter;
    String tempStatus = _statusFilter;
    bool tempCritical = _criticalOnlyFilter;

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
                      Text("Filter Spares", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                      TextButton(
                        onPressed: () => setModalState(() {
                          tempType = 'ALL';
                          tempStatus = 'ALL';
                          tempCritical = false;
                        }),
                        child: Text("Reset All", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

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

                  Text("Spare Type", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['ALL', ..._spareTypes].map((type) =>
                        _buildChip(type, tempType == type, () => setModalState(() => tempType = type))
                    ).toList(),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.2))),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text("Critical Spares Only", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.red.shade700)),
                      activeColor: Colors.redAccent,
                      value: tempCritical,
                      onChanged: (val) => setModalState(() => tempCritical = val),
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () {
                        setState(() {
                          _typeFilter = tempType;
                          _statusFilter = tempStatus;
                          _criticalOnlyFilter = tempCritical;
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

  void _showSparesForm({Map<String, dynamic>? existingSpare}) {
    final nameController = TextEditingController(text: existingSpare?['spare_name'] ?? '');
    final codeController = TextEditingController(text: existingSpare?['spare_code'] ?? '');
    final descController = TextEditingController(text: existingSpare?['spare_description'] ?? '');

    String? selectedVendorId = existingSpare?['vendor_id']?.toString();
    final vendorCtrl = TextEditingController(text: existingSpare?['m_vendor']?['name'] ?? '');
    final vendorFocus = FocusNode();

    String spareType = existingSpare?['spare_type'] ?? 'MECHANICAL';
    String spareUOM = existingSpare?['uom'] ?? 'Nos';
    bool isCritical = existingSpare?['is_critical'] ?? false;

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final targetKitchenId = existingSpare?['kitchen_id']?.toString() ?? _getActiveKitchenId();

    if (targetKitchenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active kitchen selected.'), backgroundColor: Colors.red));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                    Text(existingSpare == null ? "Add New Spare Part" : "Edit Spare Part", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(flex: 2, child: _buildInputField(ctrl: nameController, label: "Spare Name *", icon: Icons.build, isRequired: true)),
                        const SizedBox(width: 12),
                        Expanded(flex: 1, child: _buildInputField(ctrl: codeController, label: "Code", icon: Icons.qr_code, textCapitalization: TextCapitalization.characters)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _spareTypes.contains(spareType) ? spareType : 'OTHER',
                            dropdownColor: Colors.white, // FIX: White background for list
                            borderRadius: BorderRadius.circular(16), // FIX: Rounded list edges
                            decoration: InputDecoration(
                              labelText: "Category *",
                              labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                              prefixIcon: const Icon(Icons.category_outlined, color: Colors.grey),
                              filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden, width: 2)),
                            ),
                            items: _spareTypes.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.inter(fontSize: 13)))).toList(),
                            onChanged: (val) => setModalState(() => spareType = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _uomList.contains(spareUOM) ? spareUOM : 'Nos',
                            dropdownColor: Colors.white, // FIX: White background for list
                            borderRadius: BorderRadius.circular(16), // FIX: Rounded list edges
                            decoration: InputDecoration(
                              labelText: "UOM *",
                              labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                              filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden, width: 2)),
                            ),
                            items: _uomList.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (val) => setModalState(() => spareUOM = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildSleekAutocomplete(
                      hint: "Search Preferred Vendor (Optional)",
                      icon: Icons.business,
                      controller: vendorCtrl,
                      focusNode: vendorFocus,
                      options: _vendors,
                      onSelected: (val) { setModalState(() => selectedVendorId = val['id'].toString()); },
                      onCleared: () { setModalState(() => selectedVendorId = null); },
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(ctrl: descController, label: "Description", icon: Icons.notes, maxLines: 2),
                    const SizedBox(height: 12),

                    if (existingSpare != null) ...[
                      Container(
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.2))),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          title: Text("Critical Spare", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.red.shade700)),
                          subtitle: Text("Requires priority restocking", style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade400)),
                          activeColor: Colors.redAccent,
                          value: isCritical,
                          onChanged: (val) => setModalState(() => isCritical = val),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: isSaving
                            ? null
                            : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => isSaving = true);

                          final payload = {
                            'spare_name': nameController.text.trim(),
                            'spare_code': codeController.text.trim().isEmpty ? null : codeController.text.trim().toUpperCase(),
                            'spare_description': descController.text.trim(),
                            'spare_type': spareType,
                            'uom': spareUOM,
                            'vendor_id': selectedVendorId,
                            'is_critical': isCritical,
                            'kitchen_id': targetKitchenId,
                          };

                          try {
                            if (existingSpare == null) {
                              await _supabase.from('m_spares').insert(payload).select();
                            } else {
                              await _supabase.from('m_spares').update(payload).eq('id', existingSpare['id']).select();
                            }
                            if (mounted) {
                              Navigator.pop(ctx);
                              _fetchData();
                            }
                          } catch (e) {
                            debugPrint("Insert Error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                            setModalState(() => isSaving = false);
                          }
                        },
                        child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text("SAVE SPARE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
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
  }

  // --- REUSABLE BUILDERS ---
  Future<void> _toggleStatus(String id, bool currentStatus) async {
    try {
      await _supabase.from('m_spares').update({'status': !currentStatus}).eq('id', id);
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildInputField({required TextEditingController ctrl, required String label, required IconData icon, bool isRequired = false, int maxLines = 1, TextCapitalization textCapitalization = TextCapitalization.words}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, textCapitalization: textCapitalization,
      validator: isRequired ? (val) => val == null || val.trim().isEmpty ? 'Required' : null : null,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden, width: 2)),
      ),
    );
  }

  Widget _buildSleekAutocomplete({required String hint, required IconData icon, required TextEditingController controller, required FocusNode focusNode, required List<Map<String, dynamic>> options, required Function(Map<String, dynamic>) onSelected, VoidCallback? onCleared}) {
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: controller, focusNode: focusNode,
      optionsBuilder: (val) {
        if (val.text.isEmpty) return options;
        return options.where((opt) => opt['display_name'].toString().toLowerCase().contains(val.text.toLowerCase()));
      },
      displayStringForOption: (opt) => opt['display_name'].toString(),
      onSelected: (sel) { onSelected(sel); focusNode.unfocus(); },
      fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
        controller: ctrl, focusNode: fNode,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: navy),
        decoration: InputDecoration(
          labelText: hint, labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden, width: 2)),
          suffixIcon: ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16, color: Colors.grey), onPressed: () { ctrl.clear(); if (onCleared != null) onCleared(); }) : null,
        ),
      ),
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4.0, borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 48),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListView.separated(
              padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (ctx, idx) => ListTile(title: Text(opts.elementAt(idx)['display_name'], style: GoogleFonts.inter(fontSize: 13, color: navy, fontWeight: FontWeight.w500)), onTap: () => onSel(opts.elementAt(idx))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? navy : Colors.grey.shade700)),
      selected: isSelected, onSelected: (_) => onTap(),
      selectedColor: navy.withOpacity(0.08), backgroundColor: Colors.white, showCheckmark: false,
      side: BorderSide(color: isSelected ? navy : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // FIX: Fully rounded chips
    );
  }

  Widget _buildStatCard(String label, int count, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count.toString(), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: baseColor)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: baseColor.withOpacity(0.8), fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'MECHANICAL': return Colors.blue;
      case 'ELECTRICAL': return Colors.amber.shade700;
      case 'PLUMBING': return Colors.cyan;
      case 'HVAC': return Colors.deepPurple;
      case 'HARDWARE': return Colors.brown;
      case 'CHEMICAL': return Colors.teal;
      case 'CONSUMABLES': return Colors.pink;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = _spares.length;
    int criticalItems = _spares.where((s) => s['is_critical'] == true).length;
    int mechanicalItems = _spares.where((s) => s['spare_type'] == 'MECHANICAL').length;

    final displayList = _filteredSpares;
    final bool hasActiveFilters = _typeFilter != 'ALL' || _statusFilter != 'ALL' || _criticalOnlyFilter;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background, elevation: 0, foregroundColor: navy,
          title: Text("Spares Master", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: golden))
            : CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: background, elevation: 0, floating: true, snap: true, automaticallyImplyLeading: false, toolbarHeight: 5,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(160),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(child: _buildStatCard("Total Spares", totalItems, navy)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard("Mechanical", mechanicalItems, Colors.blue)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard("Critical", criticalItems, Colors.red)),
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
                                  hintText: "Search spares or code...", hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 20), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); _searchFocusNode.unfocus(); }) : null,
                                  filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40.0), child: Center(child: Text("No items match your filters.", style: GoogleFonts.inter(color: Colors.grey)))))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final spare = displayList[i];
                      final typeColor = _getTypeColor(spare['spare_type'] ?? 'OTHER');
                      final bool isActive = spare['status'] == true;
                      final String uom = spare['uom'] ?? 'Nos';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey.shade100)
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: spare['is_critical'] == true ? Colors.red : typeColor, width: 5))
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(spare['spare_name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? navy : Colors.grey)),
                                          ),
                                          if (spare['is_critical'] == true)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.warning_rounded, color: Colors.red, size: 12),
                                                  const SizedBox(width: 4),
                                                  Text("CRITICAL", style: GoogleFonts.inter(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                            child: Text(spare['spare_type'] ?? 'OTHER', style: GoogleFonts.inter(color: typeColor, fontSize: 10, fontWeight: FontWeight.w800)),
                                          ),
                                          const SizedBox(width: 12),
                                          if (spare['spare_code'] != null && spare['spare_code'].toString().isNotEmpty)
                                            Text("CODE: ${spare['spare_code']}", style: GoogleFonts.inter(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text("Measured In: $uom", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Divider(height: 1, color: Colors.grey.shade100),

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Switch.adaptive(value: isActive, activeColor: golden, onChanged: (val) => _toggleStatus(spare['id'], isActive)),
                                          Text(isActive ? "Active" : "Inactive", style: GoogleFonts.inter(fontSize: 12, color: isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      // FIX: Disable Buttons if Inactive
                                      Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: isActive ? () {
                                              Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => SpareInventoryScreen(spare: spare),
                                              ));
                                            } : null,
                                            icon: Icon(Icons.inventory_2_outlined, size: 18, color: isActive ? golden : Colors.grey.shade400),
                                            label: Text("Stock", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isActive ? golden : Colors.grey.shade400)),
                                          ),
                                          TextButton.icon(
                                            onPressed: isActive ? () => _showSparesForm(existingSpare: spare) : null,
                                            icon: Icon(Icons.edit_outlined, size: 18, color: isActive ? navy : Colors.grey.shade400),
                                            label: Text("Edit", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isActive ? navy : Colors.grey.shade400)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: golden, foregroundColor: navy,
          onPressed: _showSparesForm,
          icon: const Icon(Icons.add), label: Text("Add Spare", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}