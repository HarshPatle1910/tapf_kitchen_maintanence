import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await _supabase.from('m_user').select().order('created_at');
      setState(() => _users = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text("User Management", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: user['role'] == 'admin' ? Colors.red.shade50 : const Color(0xFF4A56E2).withOpacity(0.1),
                child: Icon(Icons.person, color: user['role'] == 'admin' ? Colors.red : const Color(0xFF4A56E2)),
              ),
              title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("ID: ${user['employee_id']} • ${user['role'].toString().toUpperCase()}"),
              trailing: Switch(
                activeColor: const Color(0xFF4A56E2),
                value: user['status'] ?? true,
                onChanged: (val) async {
                  await _supabase.from('m_user').update({'status': val}).eq('id', user['id']);
                  _fetchUsers();
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4A56E2),
        foregroundColor: Colors.white,
        onPressed: () => _showAddUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text("Add Staff", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final empIdCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'worker';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              const Text("Create Staff Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: empIdCtrl,
                decoration: const InputDecoration(labelText: "Employee ID", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'worker', child: Text("WORKER")),
                  DropdownMenuItem(value: 'admin', child: Text("ADMIN")),
                ],
                onChanged: (val) => role = val!,
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

                    try {
                      // Pass the exact same secret key defined in the AuthProvider
                      await _supabase.functions.invoke('create-worker', body: {
                        'name': nameCtrl.text,
                        'employee_id': empIdCtrl.text,
                        'phone_number': phoneCtrl.text,
                        'role': role,
                        'password': 'SETUP_KEY_2026!@#',
                      });

                      if(mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User added successfully. They can now setup their password.')));
                      }
                    } catch (e) {
                      if (mounted) {
                        String errorMsg = 'Error creating account';
                        if (e.toString().contains('already been registered')) {
                          errorMsg = 'An account with this Employee ID already exists!';
                        } else {
                          errorMsg = e.toString();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
                      }
                    }

                    _fetchUsers();
                  },
                  child: const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
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