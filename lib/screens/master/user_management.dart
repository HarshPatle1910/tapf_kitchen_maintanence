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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Management")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: user['role'] == 'admin' ? Colors.red[100] : Colors.blue[100],
              child: Icon(Icons.person, color: user['role'] == 'admin' ? Colors.red : Colors.blue),
            ),
            title: Text(user['name'] ?? 'Unknown'),
            subtitle: Text("ID: ${user['employee_id']} | Role: ${user['role'].toString().toUpperCase()}"),
            trailing: Switch(
              value: user['status'] ?? true, // active/inactive toggle
              onChanged: (val) async {
                // Toggle user active status
                await _supabase.from('m_user').update({'status': val}).eq('id', user['id']);
                _fetchUsers();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text("Add Staff"),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final empIdCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'worker';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Create Staff Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: empIdCtrl, decoration: const InputDecoration(labelText: "Employee ID", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder())),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                // Call the Edge Function to create Auth user + hash password
                await _supabase.functions.invoke('create-worker', body: {
                  'name': nameCtrl.text,
                  'employee_id': empIdCtrl.text,
                  'phone_number': phoneCtrl.text,
                  'role': role,
                  'password': 'defaultPassword123!', // Admin forces a password change later, or sends OTP
                });

                _fetchUsers();
              },
              child: const Text("CREATE ACCOUNT"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}