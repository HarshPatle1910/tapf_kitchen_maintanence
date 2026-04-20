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

  @override
  void initState() {
    super.initState();
    _fetchEquipment();
  }

  Future<void> _fetchEquipment() async {
    try {
      // Joins with m_kitchen to display the kitchen name
      final response = await _supabase
          .from('m_equipment')
          .select('*, m_kitchen(name)')
          .order('created_at', ascending: false);

      setState(() => _equipment = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching equipment: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Equipment Registry")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _equipment.length,
        itemBuilder: (context, index) {
          final item = _equipment[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.build)),
              title: Text(item['name'] ?? 'Unnamed Equipment'),
              subtitle: Text("Area: ${item['area']} | Kitchen: ${item['m_kitchen']?['name'] ?? 'Unassigned'}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteEquipment(item['id']),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEquipmentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteEquipment(String id) async {
    // In production, you might want to 'soft delete' (is_active = false)
    // so you don't break old tickets that reference this equipment ID.
    await _supabase.from('m_equipment').update({'is_active': false}).eq('id', id);
    _fetchEquipment();
  }

  void _showAddEquipmentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    // Defaulting to a specific kitchen for this example
    // In reality, you'd fetch the admin's assigned kitchen ID here.
    String assignedKitchenId = "YOUR_KITCHEN_UUID_HERE";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Register Equipment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Equipment Name (e.g., Oven #4)")),
            TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: "Area (e.g., Bakery, Prep)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              await _supabase.from('m_equipment').insert({
                'name': nameCtrl.text,
                'area': areaCtrl.text,
                'kitchen_id': assignedKitchenId,
              });

              _fetchEquipment();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}