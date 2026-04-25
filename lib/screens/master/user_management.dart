import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

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
      final response = await _supabase
          .from('m_user')
          .select()
          .order('status', ascending: true)
          .order('created_at', ascending: false);
      setState(() => _users = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Inside UserManagementScreen, update the _showApprovalDialog function:
  void _showApprovalDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'worker';
    String? selectedDept = user['department'];
    String? selectedKitchen = user['kitchen_id'];
    bool isApproved = user['status'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Approve User: ${user['name']}"),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'worker', child: Text("WORKER")),
                  DropdownMenuItem(value: 'admin', child: Text("ADMIN")),
                ],
                onChanged: (v) => setModalState(() => selectedRole = v!),
                decoration: const InputDecoration(labelText: "Role"),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => selectedDept = v,
                decoration: const InputDecoration(
                  labelText: "Department (e.g. Electrical, Plumbing)",
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Approve Status"),
                value: isApproved,
                onChanged: (v) => setModalState(() => isApproved = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await Supabase.instance.client
                      .from('m_user')
                      .update({
                        'role': selectedRole,
                        'department': selectedDept,
                        'status': isApproved,
                      })
                      .eq('id', user['id']);
                  Navigator.pop(ctx);
                  _fetchUsers();
                },
                child: const Text("SAVE & APPROVE"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: Text(
          "User Approvals",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: golden))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isPending = user['status'] == false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isPending
                          ? Colors.orange.shade300
                          : Colors.grey.shade200,
                      width: isPending ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isPending
                          ? Colors.orange.shade50
                          : (user['role'] == 'admin'
                                ? Colors.red.shade50
                                : navy.withOpacity(0.05)),
                      child: Icon(
                        isPending ? Icons.pending_actions : Icons.person,
                        color: isPending
                            ? Colors.orange
                            : (user['role'] == 'admin' ? Colors.red : navy),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['name'] ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "NEW",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "AMP: ${user['amp_id']} • ${user['role'].toString().toUpperCase()}",
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    trailing: const Icon(Icons.edit_square, color: golden),
                    onTap: () => _showApprovalDialog(user),
                  ),
                );
              },
            ),
    );
  }
}
