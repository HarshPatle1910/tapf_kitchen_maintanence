import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EquipmentMasterScreen extends StatefulWidget {
  const EquipmentMasterScreen({super.key});

  @override
  State<EquipmentMasterScreen> createState() => _EquipmentMasterScreenState();
}

class _EquipmentMasterScreenState extends State<EquipmentMasterScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipment = [];
  bool _isLoading = true;

  // Search state & Focus
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  final Color _primaryColor = const Color(0xFF4A56E2);

  @override
  void initState() {
    super.initState();
    _fetchEquipment();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchEquipment() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('m_equipment')
          .select('*, m_kitchen(name)')
          .eq('is_active', true);

      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);
      setState(() => _equipment = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching equipment: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _fetchEquipment();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
    _searchFocusNode.unfocus(); // Drops the keyboard
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard when tapping anywhere outside the search bar
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // Softer, premium background
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: const Text("Equipment Registry", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // Floating Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _searchFocusNode.hasFocus
                          ? _primaryColor.withOpacity(0.15)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Search equipment...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: _searchFocusNode.hasFocus ? _primaryColor : Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.grey),
                      onPressed: _clearSearch, // The "Cut" button
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            // Equipment List
            Expanded(
              child: _isLoading && _equipment.isEmpty
                  ? Center(child: CircularProgressIndicator(color: _primaryColor))
                  : _equipment.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.precision_manufacturing_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text("No equipment found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
                  : RefreshIndicator(
                color: _primaryColor,
                onRefresh: _fetchEquipment,
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
                  itemCount: _equipment.length,
                  itemBuilder: (context, index) {
                    final item = _equipment[index];
                    return _EquipmentCard(
                      item: item,
                      primaryColor: _primaryColor,
                      onDelete: () => _deleteEquipment(item['id']),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: () {
            _searchFocusNode.unfocus();
            _showAddEquipmentDialog(context);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text("Add Equipment", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Future<void> _deleteEquipment(String id) async {
    await _supabase.from('m_equipment').update({'is_active': false}).eq('id', id);
    _fetchEquipment();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Equipment removed from registry'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          )
      );
    }
  }

  void _showAddEquipmentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    String assignedKitchenId = "YOUR_KITCHEN_UUID_HERE";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 12,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const Text("Register New Equipment", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 24),

              _buildInputField(ctrl: nameCtrl, label: "Equipment Name *", icon: Icons.precision_manufacturing, isRequired: true),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildInputField(ctrl: areaCtrl, label: "Area (e.g. Bakery)", icon: Icons.place_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField(ctrl: modelCtrl, label: "Model No.", icon: Icons.tag)),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: dateCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date of Commission",
                  prefixIcon: const Icon(Icons.calendar_today_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor)),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(primary: _primaryColor),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    dateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  }
                },
              ),
              const SizedBox(height: 16),

              _buildInputField(ctrl: remarksCtrl, label: "Remarks", icon: Icons.notes_rounded, maxLines: 2),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => _isLoading = true);

                    try {
                      final kitchenResp = await _supabase.from('m_kitchen').select('id').limit(1).single();

                      await _supabase.from('m_equipment').insert({
                        'name': nameCtrl.text,
                        'area': areaCtrl.text,
                        'model': modelCtrl.text,
                        'date_of_commision': dateCtrl.text.isEmpty ? null : dateCtrl.text,
                        'remarks': remarksCtrl.text,
                        'kitchen_id': kitchenResp['id'],
                      });

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        _fetchEquipment();
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Equipment saved successfully!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green.shade700,
                            )
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving data: $e'), backgroundColor: Colors.red)
                        );
                      }
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text("SAVE EQUIPMENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for cleaner text fields in the bottom sheet
  Widget _buildInputField({required TextEditingController ctrl, required String label, required IconData icon, bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: isRequired ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
      ),
    );
  }
}

// --- REDESIGNED EQUIPMENT CARD ---
class _EquipmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color primaryColor;
  final VoidCallback onDelete;

  const _EquipmentCard({required this.item, required this.primaryColor, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          iconColor: primaryColor,
          collapsedIconColor: Colors.grey,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Icon(Icons.precision_manufacturing_rounded, color: primaryColor),
          ),
          title: Text(item['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Icon(Icons.kitchen, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                // Wrapped in Flexible to prevent overflow
                // Flexible(
                //   child: Text(
                //     "${item['m_kitchen']?['name'] ?? 'Unassigned'}",
                //     style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                //     overflow: TextOverflow.ellipsis, // Adds '...' if too long
                //   ),
                // ),
                // const Text(" • ", style: TextStyle(color: Colors.grey)),
                // Wrapped in Flexible to prevent overflow
                Flexible(
                  child: Text(
                    "${item['area'] ?? 'No Area'}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    overflow: TextOverflow.ellipsis, // Adds '...' if too long
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))
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
                  const SizedBox(height: 20),
                  _InfoItem(title: "Remarks", value: item['remarks'] != null && item['remarks'].toString().isNotEmpty ? item['remarks'] : 'No remarks added.', icon: Icons.notes),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text("Remove Equipment", style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text("Confirm Removal", style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Text("Are you sure you want to remove '${item['name']}' from the registry?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  onDelete();
                                },
                                child: const Text("Remove"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoItem({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}