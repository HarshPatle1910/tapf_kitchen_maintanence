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
  static const Color background = Color(0xFFF8F9FA);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _allKitchens = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // Standard static list of assignable reports
  final List<Map<String, String>> _availableReports = [
    {"code": "MT-02", "name": "Equipment Master"},
    {"code": "MT-03", "name": "Testing Equipment"},
    {"code": "MT-15", "name": "Critical Spare Parts"},
    {"code": "MT-05", "name": "PM Schedule"},
    {"code": "MT-06", "name": "PM Checklist"},
    {"code": "MT-07", "name": "Breakdown Intimation"},
    {"code": "MT-16", "name": "Complaint Register"},
    {"code": "MT-10", "name": "Electrical Log"},
    {"code": "MT-11", "name": "Boiler Log Sheet"},
    {"code": "MT-13", "name": "RO Plant Checklist"},
    {"code": "MT-14", "name": "DG Set Report"},
    {"code": "MT-08", "name": "Tools & Tackles"},
  ];

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
      final adminKitchenIds = context.read<AuthProvider>().activeKitchenIds;

      final kitchensRes = await _supabase.from('m_kitchen').select('id, name');
      _allKitchens = List<Map<String, dynamic>>.from(kitchensRes);

      final userRes = await _supabase
          .from('m_user')
          .select('*, user_kitchens(kitchen_id)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> allUsers =
          List<Map<String, dynamic>>.from(userRes);

      final filteredUsers = allUsers.where((u) {
        if (u['status'] == false) return true; // Show all unapproved
        final userKs = u['user_kitchens'] as List<dynamic>? ?? [];
        if (userKs.isEmpty) return true; // Show users with no kitchens
        return userKs.any(
          (uk) => adminKitchenIds.contains(uk['kitchen_id'].toString()),
        );
      }).toList();

      setState(() => _users = filteredUsers);
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showApprovalDialog(Map<String, dynamic> user) {
    bool isApproved = user['status'] ?? false;
    String selectedRole = user['role'] ?? 'worker';

    final existingUserKitchens = user['user_kitchens'] as List<dynamic>? ?? [];
    List<String> assignedKitchenIds = existingUserKitchens
        .map((k) => k['kitchen_id'].toString())
        .toList();

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  "Manage User",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: navy.withOpacity(0.1),
                        child: Text(
                          user['name'].toString().toUpperCase()[0],
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: navy,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'],
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "AMP: ${user['amp_id']} | Mobile: ${user['mobile_no']}",
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Account Status",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: golden,
                  title: Text(
                    isApproved ? "Approved / Active" : "Pending Approval",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isApproved ? Colors.green : Colors.red,
                    ),
                  ),
                  value: isApproved,
                  onChanged: (val) => setModalState(() => isApproved = val),
                ),
                const Divider(height: 32),
                Text(
                  "Role Assignment",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        activeColor: navy,
                        title: Text(
                          "Worker",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        value: 'worker',
                        groupValue: selectedRole,
                        onChanged: (v) =>
                            setModalState(() => selectedRole = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        activeColor: navy,
                        title: Text(
                          "Admin",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        value: 'admin',
                        groupValue: selectedRole,
                        onChanged: (v) =>
                            setModalState(() => selectedRole = v!),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  "Kitchen Assignment",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _allKitchens.length,
                    itemBuilder: (context, i) {
                      final k = _allKitchens[i];
                      final kId = k['id'].toString();
                      final isSelected = assignedKitchenIds.contains(kId);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: navy,
                        title: Text(
                          k['name'],
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        value: isSelected,
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              assignedKitchenIds.add(kId);
                            } else {
                              assignedKitchenIds.remove(kId);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            try {
                              await _supabase
                                  .from('m_user')
                                  .update({
                                    'status': isApproved,
                                    'role': selectedRole,
                                  })
                                  .eq('id', user['id']);
                              await _supabase
                                  .from('user_kitchens')
                                  .delete()
                                  .eq('user_id', user['id']);
                              if (assignedKitchenIds.isNotEmpty) {
                                final inserts = assignedKitchenIds
                                    .map(
                                      (kId) => {
                                        'user_id': user['id'],
                                        'kitchen_id': kId,
                                      },
                                    )
                                    .toList();
                                await _supabase
                                    .from('user_kitchens')
                                    .insert(inserts);
                              }
                              if (mounted) {
                                Navigator.pop(ctx);
                                _fetchData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'User updated successfully!',
                                      style: GoogleFonts.inter(),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error: $e',
                                    style: GoogleFonts.inter(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setModalState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "SAVE USER",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UPDATED: Kitchen-Specific Report Access Manager Dialog ---
  Future<void> _showReportAccessDialog(Map<String, dynamic> user) async {
    final userId = user['id'];

    // Find all kitchens assigned to this specific user
    final existingUserKitchens = user['user_kitchens'] as List<dynamic>? ?? [];
    List<Map<String, dynamic>> userAssignedKitchens = [];

    for (var uk in existingUserKitchens) {
      final kMatch = _allKitchens.firstWhere(
        (k) => k['id'] == uk['kitchen_id'],
        orElse: () => {},
      );
      if (kMatch.isNotEmpty) {
        userAssignedKitchens.add(kMatch);
      }
    }

    if (userAssignedKitchens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User must be assigned to at least one kitchen first."),
        ),
      );
      return;
    }

    String? selectedKitchenId = userAssignedKitchens.first['id'].toString();
    List<String> assignedReportsForSelectedKitchen = [];
    bool isSaving = false;
    bool isLoadingPermissions = false;

    // Fetch Initial Permissions BEFORE opening Bottom Sheet to prevent UI lockup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: navy)),
    );

    try {
      final res = await _supabase
          .from('user_report_access')
          .select('report_code')
          .eq('user_id', userId)
          .eq('kitchen_id', selectedKitchenId!);

      assignedReportsForSelectedKitchen = List<String>.from(
        res.map((x) => x['report_code']),
      );
      if (mounted) Navigator.pop(context); // Close loading dialog
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load initial access: $e")),
      );
      return;
    }

    if (!mounted) return;

    // Helper to fetch permissions when switching kitchens in dropdown
    Future<void> fetchPermissionsForKitchen(
      String kitchenId,
      StateSetter setModalState,
    ) async {
      setModalState(() => isLoadingPermissions = true);
      try {
        final res = await _supabase
            .from('user_report_access')
            .select('report_code')
            .eq('user_id', userId)
            .eq('kitchen_id', kitchenId);

        setModalState(() {
          assignedReportsForSelectedKitchen = List<String>.from(
            res.map((x) => x['report_code']),
          );
          isLoadingPermissions = false;
        });
      } catch (e) {
        setModalState(() => isLoadingPermissions = false);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to load access: $e")));
      }
    }

    // Launch Bottom Sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  "Report Permissions",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                Text(
                  "Manage permissions per kitchen for ${user['name']}",
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // KITCHEN SELECTOR
                Text(
                  "Target Kitchen",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),

                // Show Dropdown only if multiple kitchens. Else, show static text.
                if (userAssignedKitchens.length == 1)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      userAssignedKitchens.first['name'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedKitchenId,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: navy,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: navy,
                        ),
                        items: userAssignedKitchens
                            .map(
                              (k) => DropdownMenuItem(
                                value: k['id'].toString(),
                                child: Text(k['name']),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null && val != selectedKitchenId) {
                            setModalState(() {
                              selectedKitchenId = val;
                              assignedReportsForSelectedKitchen.clear();
                            });
                            fetchPermissionsForKitchen(val, setModalState);
                          }
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoadingPermissions
                          ? null
                          : () {
                              setModalState(() {
                                assignedReportsForSelectedKitchen =
                                    _availableReports
                                        .map((r) => r['code']!)
                                        .toList();
                              });
                            },
                      child: Text(
                        "Select All",
                        style: GoogleFonts.inter(
                          color: navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: isLoadingPermissions
                          ? null
                          : () => setModalState(
                              () => assignedReportsForSelectedKitchen.clear(),
                            ),
                      child: Text(
                        "Clear",
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),

                Expanded(
                  child: isLoadingPermissions
                      ? const Center(
                          child: CircularProgressIndicator(color: golden),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _availableReports.length,
                          itemBuilder: (context, i) {
                            final r = _availableReports[i];
                            final isSelected = assignedReportsForSelectedKitchen
                                .contains(r['code']);
                            return CheckboxListTile(
                              activeColor: navy,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "${r['code']} - ${r['name']}",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              value: isSelected,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true)
                                    assignedReportsForSelectedKitchen.add(
                                      r['code']!,
                                    );
                                  else
                                    assignedReportsForSelectedKitchen.remove(
                                      r['code']!,
                                    );
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isSaving || isLoadingPermissions
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            try {
                              // Delete existing rules for this user ONLY IN THE SELECTED KITCHEN
                              await _supabase
                                  .from('user_report_access')
                                  .delete()
                                  .eq('user_id', userId)
                                  .eq('kitchen_id', selectedKitchenId!);

                              // Insert new rules
                              if (assignedReportsForSelectedKitchen
                                  .isNotEmpty) {
                                final payload =
                                    assignedReportsForSelectedKitchen
                                        .map(
                                          (code) => {
                                            'user_id': userId,
                                            'report_code': code,
                                            'kitchen_id': selectedKitchenId,
                                          },
                                        )
                                        .toList();
                                await _supabase
                                    .from('user_report_access')
                                    .insert(payload);
                              }

                              if (mounted) {
                                Navigator.pop(ctx);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Access saved for selected kitchen.',
                                      style: GoogleFonts.inter(),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error: $e',
                                    style: GoogleFonts.inter(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setModalState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "SAVE KITCHEN ACCESS",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      final nameMatches = u['name'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final phoneMatches = u['mobile_no'].toString().contains(_searchQuery);
      return nameMatches || phoneMatches;
    }).toList();

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          foregroundColor: navy,
          title: Text(
            "User Directory",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search name or phone...",
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: golden, width: 2),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: golden),
                    )
                  : filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        "No users found.",
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      color: golden,
                      backgroundColor: Colors.white,
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, i) {
                          final user = filteredUsers[i];
                          final isApproved = user['status'] ?? false;
                          final userKitchens =
                              user['user_kitchens'] as List<dynamic>? ?? [];
                          final kNames = userKitchens
                              .map((uk) {
                                final matched = _allKitchens.firstWhere(
                                  (k) => k['id'] == uk['kitchen_id'],
                                  orElse: () => {},
                                );
                                return matched['name'] ?? 'Unknown';
                              })
                              .join(", ");

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: isApproved
                                    ? navy.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                child: Text(
                                  user['name'].toString().toUpperCase()[0],
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: isApproved ? navy : Colors.orange,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['name'],
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isApproved)
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
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "AMP: ${user['amp_id']} • ${user['role'].toString().toUpperCase()}",
                                      style: GoogleFonts.inter(
                                        color: Colors.grey.shade800,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Assigned: ${kNames.isEmpty ? 'None' : kNames}",
                                      style: GoogleFonts.inter(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // IconButton(
                                  //   icon: const Icon(
                                  //     Icons.analytics_outlined,
                                  //     color: navy,
                                  //   ),
                                  //   tooltip: "Report Access",
                                  //   onPressed: () =>
                                  //       _showReportAccessDialog(user),
                                  // ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_square,
                                      color: golden,
                                    ),
                                    tooltip: "Edit User",
                                    onPressed: () {
                                      _searchFocusNode.unfocus();
                                      _showApprovalDialog(user);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
