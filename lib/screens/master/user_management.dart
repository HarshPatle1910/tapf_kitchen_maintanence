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
      // Order by status ascending (false first, so pending users show at the top)
      final response = await _supabase.from('m_user').select().order('status', ascending: true).order('created_at', ascending: false);
      setState(() => _users = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _showApprovalDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'worker';
    bool isApproved = user['status'] ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Manage: ${user['name']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("AMP ID: ${user['amp_id']}  |  Phone: ${user['mobile_no']}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: "Assign Role", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'worker', child: Text("WORKER")),
                        DropdownMenuItem(value: 'admin', child: Text("ADMIN")),
                      ],
                      onChanged: (val) => setModalState(() => selectedRole = val!),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text("Account Approved", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Allow this user to access the app"),
                      activeColor: const Color(0xFF4A56E2),
                      value: isApproved,
                      onChanged: (val) => setModalState(() => isApproved = val),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A56E2), foregroundColor: Colors.white),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);
                          await _supabase.from('m_user').update({
                            'role': selectedRole,
                            'status': isApproved,
                          }).eq('id', user['id']);
                          _fetchUsers();
                        },
                        child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text("User Approvals & Management", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isPending = user['status'] == false;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isPending ? Colors.orange.shade300 : Colors.transparent, width: isPending ? 2 : 0)
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isPending ? Colors.orange.shade50 : (user['role'] == 'admin' ? Colors.red.shade50 : const Color(0xFF4A56E2).withOpacity(0.1)),
                child: Icon(
                    isPending ? Icons.pending_actions : Icons.person,
                    color: isPending ? Colors.orange : (user['role'] == 'admin' ? Colors.red : const Color(0xFF4A56E2))
                ),
              ),
              title: Row(
                children: [
                  Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                      child: const Text("NEW", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
              subtitle: Text("AMP: ${user['amp_id']} • ${user['role'].toString().toUpperCase()}"),
              trailing: const Icon(Icons.edit_square, color: Colors.grey),
              onTap: () => _showApprovalDialog(user),
            ),
          );
        },
      ),
    );
  }
}