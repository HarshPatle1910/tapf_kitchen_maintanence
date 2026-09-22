// ignore_for_file: unused_element, unused_field, unused_local_variable
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import 'master/area_screen.dart';
import 'master/equipment_master_screen.dart';
import 'master/spares/spare_screen.dart';
import 'master/tools_screen.dart';
import 'master/vendor_screen.dart';
import 'master/zone_screen.dart';

// // --- Master Screen Imports ---
// import 'master/area_screen.dart';
// import 'master/kitchen_screen.dart';
// import 'master/spares/spare_screen.dart';
// import 'master/vendor_screen.dart';
// import 'master/zone_screen.dart';
// import 'master/equipment_master_screen.dart';
// import 'master/tools_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  final _supabase = Supabase.instance.client;

  Future<void> _showUserDetails(
    BuildContext context,
    AuthProvider authProv,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Show a small loading indicator dialog while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: primary)),
    );

    try {
      final res = await _supabase
          .from('m_user')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Pop loading dialog
      if (mounted) Navigator.pop(context);

      if (res != null && mounted) {
        _buildUserDetailsSheet(context, res, authProv);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load details: $e")));
      }
    }
  }

  void _buildUserDetailsSheet(
    BuildContext context,
    Map<String, dynamic> initialUser,
    AuthProvider authProv,
  ) {
    final Map<String, dynamic> user = Map<String, dynamic>.from(initialUser);
    final nameController = TextEditingController(text: user['name'] ?? '');
    final deptController = TextEditingController(text: user['department'] ?? '');
    final addressController = TextEditingController(text: user['address'] ?? '');
    bool isEditing = false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final initials = (user['name']?.toString().isNotEmpty ?? false)
                ? user['name'].toString().trim()[0].toUpperCase()
                : 'U';

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? "Edit Profile" : "My Profile",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (!isEditing)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: primary),
                              tooltip: "Edit Profile",
                              onPressed: () {
                                nameController.text = user['name'] ?? '';
                                deptController.text = user['department'] ?? '';
                                addressController.text = user['address'] ?? '';
                                setModalState(() => isEditing = true);
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.grey),
                              tooltip: "Cancel",
                              onPressed: isSaving
                                  ? null
                                  : () => setModalState(() => isEditing = false),
                            ),
                        ],
                      ),
                      const Divider(height: 20),

                      if (!isEditing) ...[
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: primary.withOpacity(0.1),
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user['name'] ?? 'Unknown User',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (user['role'] ?? 'Worker').toString().toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          Icons.badge_outlined,
                          "Employee ID",
                          user['amp_id'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          Icons.work_outline,
                          "Department",
                          (user['department'] != null && user['department'].toString().trim().isNotEmpty)
                              ? user['department']
                              : 'Not set',
                        ),
                        _buildDetailRow(
                          Icons.home_outlined,
                          "Address",
                          (user['address'] != null && user['address'].toString().trim().isNotEmpty)
                              ? user['address']
                              : 'Not set',
                        ),
                        _buildDetailRow(
                          Icons.phone_outlined,
                          "Mobile No.",
                          user['mobile_no'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          Icons.admin_panel_settings_outlined,
                          "Role",
                          (user['role'] ?? 'Worker').toString().toUpperCase(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(
                              "Edit Profile",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: () {
                              nameController.text = user['name'] ?? '';
                              deptController.text = user['department'] ?? '';
                              addressController.text = user['address'] ?? '';
                              setModalState(() => isEditing = true);
                            },
                          ),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Update your name, department, and address below.",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildEditTextField(
                          controller: nameController,
                          label: "Full Name *",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildEditTextField(
                          controller: deptController,
                          label: "Department",
                          hint: "e.g. Electrical, Mechanical, Kitchen",
                          icon: Icons.work_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildEditTextField(
                          controller: addressController,
                          label: "Address",
                          hint: "Enter your address",
                          icon: Icons.home_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.grey.shade500),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Employee ID, Mobile No. and Role are managed by administrators.",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () => setModalState(() => isEditing = false),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final newName = nameController.text.trim();
                                        final newDept = deptController.text.trim();
                                        final newAddress = addressController.text.trim();

                                        if (newName.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Name cannot be empty",
                                                style: GoogleFonts.inter(),
                                              ),
                                              backgroundColor: Colors.red.shade600,
                                            ),
                                          );
                                          return;
                                        }

                                        setModalState(() => isSaving = true);

                                        try {
                                          final ok = await authProv.updateProfile(
                                            name: newName,
                                            department: newDept,
                                            address: newAddress,
                                          );

                                          if (!ok) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    authProv.errorMessage ?? "Failed to update profile",
                                                    style: GoogleFonts.inter(),
                                                  ),
                                                  backgroundColor: Colors.red.shade600,
                                                ),
                                              );
                                            }
                                            setModalState(() => isSaving = false);
                                            return;
                                          }

                                          // Update local state
                                          user['name'] = newName;
                                          user['department'] = newDept;
                                          user['address'] = newAddress;

                                          setModalState(() {
                                            isSaving = false;
                                            isEditing = false;
                                          });

                                          if (mounted) setState(() {});

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Profile updated successfully!",
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                backgroundColor: const Color(0xFF16A34A),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setModalState(() => isSaving = false);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Error: $e"),
                                                backgroundColor: Colors.red.shade600,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                child: isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Save Changes",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40.0 : 0),
          child: Icon(icon, color: primary, size: 20),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider authProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              "Sign Out",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to sign out of your account?",
          style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await authProv.logout();
            },
            child: Text(
              "SIGN OUT",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final String displayName = authProv.userName ?? "User";
    final String displayRole = (authProv.activeRole ?? 'Worker').toUpperCase();
    final String initials = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'U';
    final bool isAdmin = authProv.activeRole == 'admin';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Profile Header ---
              Material(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showUserDetails(context, authProv),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: primary.withOpacity(0.1),
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Role: $displayRole",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: primary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              if (isAdmin) ...[
                // --- Section: Configuration ---
                _buildSectionTitle("Facility Configuration"),
                _buildMenuCard([
                  // _MenuItem(Icons.kitchen_outlined, "Kitchen Master", const KitchenMasterScreen(), context),
                  _MenuItem(
                    Icons.place_outlined,
                    "Area Master",
                    const AreaMasterScreen(),
                    context,
                  ),
                  _MenuItem(
                    Icons.layers_outlined,
                    "Zone Master",
                    const ZoneMasterScreen(),
                    context,
                  ),
                ]),
                const SizedBox(height: 24),

                // --- Section: Assets & Inventory ---
                _buildSectionTitle("Assets & Inventory"),
                _buildMenuCard([
                  _MenuItem(
                    Icons.precision_manufacturing_outlined,
                    "Equipment Registry",
                    const EquipmentMasterScreen(),
                    context,
                  ),
                  _MenuItem(
                    Icons.build_circle_outlined,
                    "Spares Master",
                    const SparesMasterScreen(),
                    context,
                  ),
                  _MenuItem(
                    Icons.handyman_outlined,
                    "Tools Master",
                    const ToolsMasterScreen(),
                    context,
                  ),
                  _MenuItem(
                    Icons.local_shipping_outlined,
                    "Vendor Directory",
                    const VendorMasterScreen(),
                    context,
                  ),
                ]),
                const SizedBox(height: 32),
              ],

              // --- Logout Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    "Sign Out",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () => _confirmSignOut(context, authProv),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.0,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
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
      child: Column(
        children: items.asMap().entries.map((entry) {
          final int index = entry.key;
          final _MenuItem item = entry.value;
          final bool isLast = index == items.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: primary, size: 20),
                ),
                title: Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade300,
                  size: 16,
                ),
                onTap: () => Navigator.push(
                  item.context,
                  MaterialPageRoute(builder: (_) => item.screen),
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 64, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Widget screen;
  final BuildContext context;

  _MenuItem(this.icon, this.title, this.screen, this.context);
}
