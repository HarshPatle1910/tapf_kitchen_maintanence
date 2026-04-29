import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';

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
  List<Map<String, dynamic>> _kitchens = [];
  bool _isLoading = true;

  // Search & Filter States
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, ACTIVE, INACTIVE
  String _kitchenFilter = 'ALL';
  String _sortBy = 'NEWEST'; // NEWEST, NAME_ASC, NAME_DESC

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch all active kitchens available to the user
      final kitchenResponse = await _supabase
          .from('m_kitchen')
          .select('id, name')
          .eq('status', true)
          .order('name');

      // 2. Fetch all zones and join with kitchen table to get the kitchen name
      final zoneResponse = await _supabase
          .from('m_zone')
          .select('*, m_kitchen(name)')
          .order('created_at');

      if (mounted) {
        setState(() {
          _kitchens = List<Map<String, dynamic>>.from(kitchenResponse);
          _zones = List<Map<String, dynamic>>.from(zoneResponse);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FILTER & SORT LOGIC ---
  List<Map<String, dynamic>> get _filteredZones {
    var list = List<Map<String, dynamic>>.from(_zones);

    // 1. Search Filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((z) => z['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // 2. Status Filter
    if (_statusFilter == 'ACTIVE') {
      list = list.where((z) => z['status'] == true).toList();
    } else if (_statusFilter == 'INACTIVE') {
      list = list.where((z) => z['status'] == false).toList();
    }

    // 3. Kitchen Filter (Only applied if they have multiple kitchens)
    if (_kitchens.length > 1 && _kitchenFilter != 'ALL') {
      list = list.where((z) => z['kitchen_id'].toString() == _kitchenFilter).toList();
    }

    // 4. Sorting
    if (_sortBy == 'NAME_ASC') {
      list.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    } else if (_sortBy == 'NAME_DESC') {
      list.sort((a, b) => b['name'].toString().compareTo(a['name'].toString()));
    } else {
      list.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
    }

    return list;
  }

  // --- BOTTOM SHEETS ---
  void _showFilterBottomSheet() {
    String tempStatus = _statusFilter;
    String tempKitchen = _kitchenFilter;
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
                            tempKitchen = 'ALL';
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

                  // SMART UI: Only show kitchen filter if there are multiple kitchens
                  if (_kitchens.length > 1) ...[
                    const SizedBox(height: 24),
                    Text("Filter by Kitchen", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tempKitchen,
                      decoration: InputDecoration(
                        filled: true, fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.kitchen_outlined, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                      ),
                      items: [
                        DropdownMenuItem(value: 'ALL', child: Text("All Kitchens", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy))),
                        ..._kitchens.map((k) => DropdownMenuItem(value: k['id'].toString(), child: Text(k['name'].toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy))))
                      ],
                      onChanged: (val) => setModalState(() => tempKitchen = val!),
                    ),
                    const SizedBox(height: 40),
                  ] else ...[
                    const SizedBox(height: 32),
                  ],

                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      onPressed: () {
                        setState(() {
                          _statusFilter = tempStatus;
                          _kitchenFilter = tempKitchen;
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

  void _showZoneForm({Map<String, dynamic>? existingZone}) {
    final nameController = TextEditingController(text: existingZone?['name'] ?? '');

    String? selectedKitchenId = existingZone?['kitchen_id'] ?? context.read<AuthProvider>().activeKitchenId;

    // SMART LOGIC: If they only have 1 kitchen, auto-select it.
    // Otherwise, ensure the default exists in the dropdown list.
    if (_kitchens.length == 1) {
      selectedKitchenId = _kitchens.first['id'].toString();
    } else if (selectedKitchenId != null && !_kitchens.any((k) => k['id'].toString() == selectedKitchenId)) {
      selectedKitchenId = null;
    }

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  Text(existingZone == null ? "Add New Zone" : "Edit Zone", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                  const SizedBox(height: 24),

                  // SMART UI: Only show kitchen selection if they have more than 1 kitchen
                  if (_kitchens.length > 1) ...[
                    DropdownButtonFormField<String>(
                      value: selectedKitchenId,
                      validator: (val) => val == null ? 'Please select a Kitchen' : null,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "Select Kitchen *",
                        labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                        prefixIcon: const Icon(Icons.kitchen_outlined, color: Colors.grey),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                      ),
                      items: _kitchens.map((k) => DropdownMenuItem(value: k['id'].toString(), child: Text(k['name'].toString()))).toList(),
                      onChanged: (val) => setModalState(() => selectedKitchenId = val),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: nameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Zone Name is required' : null,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
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
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      onPressed: isSaving ? null : () async {
                        // If they only have 1 kitchen, we ensure selectedKitchenId isn't null before submitting
                        if (_kitchens.length == 1 && selectedKitchenId == null) {
                          selectedKitchenId = _kitchens.first['id'].toString();
                        }

                        if (!formKey.currentState!.validate() || selectedKitchenId == null) {
                          if (selectedKitchenId == null && _kitchens.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No Kitchens available to link.', style: GoogleFonts.inter()), backgroundColor: Colors.red));
                          }
                          return;
                        }

                        setModalState(() => isSaving = true);
                        try {
                          if (existingZone == null) {
                            await _supabase.from('m_zone').insert({
                              'name': nameController.text.trim(),
                              'kitchen_id': selectedKitchenId
                            });
                          } else {
                            await _supabase.from('m_zone').update({
                              'name': nameController.text.trim(),
                              'kitchen_id': selectedKitchenId
                            }).eq('id', existingZone['id']);
                          }
                          if (mounted) {
                            Navigator.pop(ctx);
                            _fetchData();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Zone saved successfully!', style: GoogleFonts.inter()), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red));
                          setModalState(() => isSaving = false);
                        }
                      },
                      child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text("SAVE ZONE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    try {
      await _supabase.from('m_zone').update({'status': !currentStatus}).eq('id', id);
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // --- UI WIDGETS ---
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
    // Calculate Stats
    final int totalCount = _zones.length;
    final int activeCount = _zones.where((z) => z['status'] == true).length;
    final int inactiveCount = totalCount - activeCount;

    final displayList = _filteredZones;
    final bool hasActiveFilters = _statusFilter != 'ALL' || _kitchenFilter != 'ALL' || _sortBy != 'NEWEST';

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
              // Floating Search & Stats Bar
              SliverAppBar(
                backgroundColor: background,
                elevation: 0,
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(160),
                  child: Column(
                    children: [
                      // 1. STATS ROW
                      Container(
                        color: background,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        width: double.infinity,
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

                      // 2. SEARCH & FILTER ROW
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                                  decoration: InputDecoration(
                                    hintText: "Search zones...",
                                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                        _searchFocusNode.unfocus();
                                      },
                                    )
                                        : null,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden, width: 2)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                _searchFocusNode.unfocus();
                                _showFilterBottomSheet();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: hasActiveFilters ? navy : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: hasActiveFilters ? navy : Colors.white),
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

              // LIST OF ZONES
              if (displayList.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(child: Text("No zones match your filters.", style: GoogleFonts.inter(color: Colors.grey))),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final zone = displayList[i];
                        final bool isActive = zone['status'] == true;
                        final kitchenName = zone['m_kitchen']?['name'] ?? 'Unknown Kitchen';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.grey.shade100)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: Text(zone['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: isActive ? navy : Colors.grey)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Row(
                                children: [
                                  Icon(Icons.kitchen_outlined, size: 14, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(kitchenName, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500))),

                                  // SMART UI: If they only have 1 kitchen, no need to show the Kitchen name on every card.
                                  // We just show the Active/Inactive badge aligned to the left.
                                  if (_kitchens.length > 1)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text(isActive ? "Active" : "Inactive", style: GoogleFonts.inter(color: isActive ? Colors.green : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch.adaptive(
                                  value: isActive,
                                  activeColor: golden,
                                  onChanged: (val) => _toggleStatus(zone['id'], isActive),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: navy),
                                  onPressed: () => _showZoneForm(existingZone: zone),
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
            if (_kitchens.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You must create a Kitchen first!', style: GoogleFonts.inter()), backgroundColor: Colors.orange));
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