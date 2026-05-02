import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
  List<Map<String, dynamic>> _allKitchens = []; // To store kitchen names
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final adminKitchenIds = context.read<AuthProvider>().activeKitchenIds;

      // 1. Fetch all kitchens to map IDs to Names
      final kRes = await _supabase.from('m_kitchen').select('id, name');
      _allKitchens = List<Map<String, dynamic>>.from(kRes);

      // 2. Fetch users and their requested kitchens
      final response = await _supabase
          .from('m_user')
          .select('*, user_kitchens(kitchen_id, m_kitchen(name))')
          .order('status', ascending: true)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> filteredList = [];

      for (var u in response) {
        final uKitchens = (u['user_kitchens'] as List).map((k) => k['kitchen_id'].toString()).toList();

        // SMART VISIBILITY: Only show user if they requested a kitchen this Admin manages
        // (Or if the admin is a super-admin with no restrictions)
        bool hasOverlap = uKitchens.any((k) => adminKitchenIds.contains(k));

        if (hasOverlap || adminKitchenIds.isEmpty) {
          filteredList.add(u);
        }
      }

      if (mounted) {
        setState(() => _users = filteredList);
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showApprovalDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'worker';
    String? selectedDept = user['department'];
    bool isApproved = user['status'] ?? false;

    // Extract user's originally requested kitchens
    final requestedKIds = (user['user_kitchens'] as List).map((k) => k['kitchen_id'].toString()).toList();
    final requestedKitchenNames = (user['user_kitchens'] as List).map((k) => k['m_kitchen']['name'].toString()).join(", ");

    // Determine which kitchens this admin has the power to assign
    final adminKitchenIds = context.read<AuthProvider>().activeKitchenIds;
    List<Map<String, dynamic>> allowedKitchens = adminKitchenIds.isEmpty
        ? _allKitchens // Super admin sees all
        : _allKitchens.where((k) => adminKitchenIds.contains(k['id'].toString())).toList();

    // Pre-select the kitchens the user requested, ONLY IF the admin has power over them
    List<String> finalizedKitchenIds = allowedKitchens
        .map((k) => k['id'].toString())
        .where((id) => requestedKIds.contains(id))
        .toList();

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              Text("Review Access: ${user['name']}", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
              const SizedBox(height: 4),
              Text("Originally Requested: $requestedKitchenNames", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),

              // ==========================================
              // FIX: Styled Role Dropdown
              // ==========================================
              Text("Assign Role *", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedRole,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: navy),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                  items: [
                    DropdownMenuItem(value: 'worker', child: Text("WORKER", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy))),
                    DropdownMenuItem(value: 'admin', child: Text("ADMIN", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy))),
                  ],
                  onChanged: (v) => setModalState(() => selectedRole = v!),
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // FIX: Styled Department TextField
              // ==========================================
              Text("Department", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: TextField(
                  controller: TextEditingController(text: selectedDept)..selection = TextSelection.collapsed(offset: selectedDept?.length ?? 0),
                  onChanged: (v) => selectedDept = v,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: "e.g. Electrical",
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // THE POWER TO ALLOCATE: Admin selects final kitchens
              Text("Allocate to Kitchens *", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy, fontSize: 14)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: allowedKitchens.map((k) {
                  final isSelected = finalizedKitchenIds.contains(k['id'].toString());
                  return FilterChip(
                    label: Text(k['name'], style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? navy : Colors.grey.shade700)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setModalState(() {
                        if (selected) {
                          finalizedKitchenIds.add(k['id'].toString());
                        } else {
                          finalizedKitchenIds.remove(k['id'].toString());
                        }
                      });
                    },
                    selectedColor: navy.withOpacity(0.08),
                    backgroundColor: Colors.white,
                    checkmarkColor: navy,
                    side: BorderSide(color: isSelected ? navy : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: SwitchListTile(
                  title: Text("Approve Account", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy)),
                  subtitle: Text("Grant access to the app", style: GoogleFonts.inter(fontSize: 12)),
                  value: isApproved, activeColor: Colors.green,
                  onChanged: (v) => setModalState(() => isApproved = v),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isSaving ? null : () async {
                    if (finalizedKitchenIds.isEmpty && isApproved) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You must allocate at least one kitchen to approve them.', style: GoogleFonts.inter()), backgroundColor: Colors.red));
                      return;
                    }

                    setModalState(() => isSaving = true);
                    try {
                      // 1. Update Core User Details
                      await _supabase.from('m_user').update({
                        'role': selectedRole,
                        'department': selectedDept,
                        'status': isApproved,
                      }).eq('id', user['id']);

                      // 2. Overwrite Kitchen Allocations
                      // First, delete old allocations
                      await _supabase.from('user_kitchens').delete().eq('user_id', user['id']);

                      // Then, insert the newly finalized ones
                      if (finalizedKitchenIds.isNotEmpty) {
                        final inserts = finalizedKitchenIds.map((kId) => {
                          'user_id': user['id'],
                          'kitchen_id': kId
                        }).toList();
                        await _supabase.from('user_kitchens').insert(inserts);
                      }

                      if (mounted) {
                        Navigator.pop(ctx);
                        _fetchData();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User approved and allocated successfully.', style: GoogleFonts.inter()), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red));
                      setModalState(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("SAVE & APPROVE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
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
        elevation: 0, backgroundColor: Colors.white, foregroundColor: navy,
        title: Text("User Approvals", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: golden))
          : _users.isEmpty
          ? Center(child: Text("No pending users found in your scope.", style: GoogleFonts.inter(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isPending = user['status'] == false;
          final kNames = (user['user_kitchens'] as List).map((k) => k['m_kitchen']['name'].toString()).join(", ");

          return Card(
            margin: const EdgeInsets.only(bottom: 12), elevation: 0, color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isPending ? Colors.orange.shade300 : Colors.grey.shade200, width: isPending ? 2 : 1)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isPending ? Colors.orange.shade50 : (user['role'] == 'admin' ? Colors.red.shade50 : navy.withOpacity(0.05)),
                child: Icon(isPending ? Icons.pending_actions : Icons.person, color: isPending ? Colors.orange : (user['role'] == 'admin' ? Colors.red : navy)),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(user['name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy))),
                  if (isPending)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: Text("NEW", style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AMP: ${user['amp_id']} • ${user['role'].toString().toUpperCase()}", style: GoogleFonts.inter(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("Requested: ${kNames.isEmpty ? 'None' : kNames}", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
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