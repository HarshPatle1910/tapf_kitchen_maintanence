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

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchEquipment();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEquipment() async {
    setState(() => _isLoading = true);
    try {
      // 1. Start the query without the .order() modifier
      var query = _supabase
          .from('m_equipment')
          .select('*, m_kitchen(name)')
          .eq('is_active', true);

      // 2. Apply the Search Filter BEFORE ordering
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      // 3. Add the .order() modifier at the very end, right before awaiting it
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Modern light background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text("Equipment Registry", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search equipment by name...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF4F6F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Equipment List
          Expanded(
            child: _isLoading && _equipment.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _equipment.isEmpty
                ? const Center(child: Text("No equipment found.", style: TextStyle(color: Colors.grey)))
                : RefreshIndicator(
              onRefresh: _fetchEquipment,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _equipment.length,
                itemBuilder: (context, index) {
                  final item = _equipment[index];
                  return _EquipmentCard(
                    item: item,
                    onDelete: () => _deleteEquipment(item['id']),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4A56E2),
        foregroundColor: Colors.white,
        onPressed: () => _showAddEquipmentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Equipment", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _deleteEquipment(String id) async {
    // Soft delete to preserve ticket history
    await _supabase.from('m_equipment').update({'is_active': false}).eq('id', id);
    _fetchEquipment();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipment removed')));
    }
  }

  void _showAddEquipmentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    // Defaulting to a specific kitchen for this example
    String assignedKitchenId = "YOUR_KITCHEN_UUID_HERE";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Register Equipment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Equipment Name *", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                        controller: areaCtrl,
                        decoration: const InputDecoration(labelText: "Area (e.g. Bakery)", border: OutlineInputBorder())
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                        controller: modelCtrl,
                        decoration: const InputDecoration(labelText: "Model", border: OutlineInputBorder())
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: dateCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: "Date of Commission",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today)
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    // Format as YYYY-MM-DD
                    dateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  }
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                  controller: remarksCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Remarks", border: OutlineInputBorder())
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A56E2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    await _supabase.from('m_equipment').insert({
                      'name': nameCtrl.text,
                      'area': areaCtrl.text,
                      'model': modelCtrl.text,
                      'date_of_commision': dateCtrl.text, // Matching your SQL spelling
                      'remarks': remarksCtrl.text,
                      'kitchen_id': assignedKitchenId,
                    });

                    _fetchEquipment();
                  },
                  child: const Text("SAVE EQUIPMENT", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MODERN EQUIPMENT CARD WIDGET ---
class _EquipmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _EquipmentCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF4A56E2).withOpacity(0.1),
            child: const Icon(Icons.precision_manufacturing, color: Color(0xFF4A56E2)),
          ),
          title: Text(item['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(
              "${item['m_kitchen']?['name'] ?? 'Unassigned'} • ${item['area'] ?? 'No Area'}",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _InfoItem(title: "Model", value: item['model'] ?? 'N/A')),
                      Expanded(child: _InfoItem(title: "Commissioned", value: item['date_of_commision'] ?? 'N/A')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoItem(title: "Remarks", value: item['remarks'] ?? 'No remarks added.'),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text("Remove Equipment"),
                      onPressed: () {
                        // Confirm deletion dialog
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Confirm Removal"),
                            content: Text("Are you sure you want to remove ${item['name']}?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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

  const _InfoItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}