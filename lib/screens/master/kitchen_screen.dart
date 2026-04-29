import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class KitchenMasterScreen extends StatefulWidget {
  const KitchenMasterScreen({super.key});

  @override
  State<KitchenMasterScreen> createState() => _KitchenMasterScreenState();
}

class _KitchenMasterScreenState extends State<KitchenMasterScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _kitchens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKitchens();
  }

  Future<void> _fetchKitchens() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('m_kitchen').select().order('created_at');
      setState(() => _kitchens = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showKitchenForm({Map<String, dynamic>? existingKitchen}) {
    final nameController = TextEditingController(text: existingKitchen?['name'] ?? '');
    final addressController = TextEditingController(text: existingKitchen?['address'] ?? '');
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
                  Text(existingKitchen == null ? "Add New Kitchen" : "Edit Kitchen", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: nameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Kitchen Name is required' : null,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                    decoration: InputDecoration(labelText: "Kitchen Name *", prefixIcon: const Icon(Icons.business_outlined, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: addressController,
                    maxLines: 2,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                    decoration: InputDecoration(labelText: "Address", prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: isSaving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModalState(() => isSaving = true);
                        try {
                          if (existingKitchen == null) {
                            await _supabase.from('m_kitchen').insert({'name': nameController.text.trim(), 'address': addressController.text.trim()});
                          } else {
                            await _supabase.from('m_kitchen').update({'name': nameController.text.trim(), 'address': addressController.text.trim()}).eq('id', existingKitchen['id']);
                          }
                          if (mounted) {
                            Navigator.pop(ctx);
                            _fetchKitchens();
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          setModalState(() => isSaving = false);
                        }
                      },
                      child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text("SAVE KITCHEN", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
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
      await _supabase.from('m_kitchen').update({'status': !currentStatus}).eq('id', id);
      _fetchKitchens();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background, elevation: 0, foregroundColor: navy,
        title: Text("Kitchen Registry", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: golden))
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _kitchens.length,
        itemBuilder: (ctx, i) {
          final kitchen = _kitchens[i];
          final bool isActive = kitchen['status'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(kitchen['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: isActive ? navy : Colors.grey)),
              subtitle: Text(isActive ? "Active" : "Inactive", style: GoogleFonts.inter(color: isActive ? Colors.green : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(value: isActive, activeColor: golden, onChanged: (val) => _toggleStatus(kitchen['id'], isActive)),
                  IconButton(icon: const Icon(Icons.edit_outlined, color: navy), onPressed: () => _showKitchenForm(existingKitchen: kitchen)),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: navy, foregroundColor: Colors.white,
        onPressed: () => _showKitchenForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text("Add Kitchen", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
    );
  }
}