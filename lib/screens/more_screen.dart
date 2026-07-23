// ignore_for_file: unused_element, unused_field, unused_local_variable
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';

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

  Future<void> _showUserDetails(BuildContext context, AuthProvider authProv) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Show a small loading indicator dialog while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: primary)),
    );

    try {
      final res = await _supabase.from('m_user').select().eq('id', userId).maybeSingle();

      // Pop loading dialog
      if (mounted) Navigator.pop(context);

      if (res != null && mounted) {
        _buildUserDetailsSheet(context, res);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load details: $e")));
      }
    }
  }

  void _buildUserDetailsSheet(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final initials = (user['name']?.toString().isNotEmpty ?? false) ? user['name'].toString().trim()[0].toUpperCase() : 'U';

        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),

              CircleAvatar(
                radius: 40,
                backgroundColor: primary.withOpacity(0.1),
                child: Text(initials, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: primary)),
              ),
              const SizedBox(height: 16),
              Text(user['name'] ?? 'Unknown User', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),

              const SizedBox(height: 24),
              _buildDetailRow(Icons.badge_outlined, "Employee ID", user['amp_id'] ?? 'N/A'),
              _buildDetailRow(Icons.work_outline, "Department", user['department'] ?? 'N/A'),
              _buildDetailRow(Icons.admin_panel_settings_outlined, "Role", (user['role'] ?? 'Worker').toString().toUpperCase()),
              _buildDetailRow(Icons.phone_outlined, "Mobile No.", user['mobile_no'] ?? 'N/A'),
              _buildDetailRow(Icons.home_outlined, "Address", user['address'] ?? 'N/A'),
            ],
          ),
        );
      },
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
            decoration: BoxDecoration(color: primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              ],
            ),
          )
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
            Text("Sign Out", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          ],
        ),
        content: Text("Are you sure you want to sign out of your account?", style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await authProv.logout();
            },
            child: Text("SIGN OUT", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
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
    final String initials = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'U';
    // final bool isAdmin = authProv.activeRole == 'admin';

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
                          child: Text(initials, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: primary)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                                child: Text("Role: $displayRole", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: primary)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.info_outline, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // if (isAdmin) ...[
              //   // --- Section: Configuration ---
              //   _buildSectionTitle("Facility Configuration"),
              //   _buildMenuCard([
              //     // _MenuItem(Icons.kitchen_outlined, "Kitchen Master", const KitchenMasterScreen(), context),
              //     _MenuItem(Icons.place_outlined, "Area Master", const AreaMasterScreen(), context),
              //     _MenuItem(Icons.layers_outlined, "Zone Master", const ZoneMasterScreen(), context),
              //   ]),
              //   const SizedBox(height: 24),
              //
              //   // --- Section: Assets & Inventory ---
              //   _buildSectionTitle("Assets & Inventory"),
              //   _buildMenuCard([
              //     _MenuItem(Icons.precision_manufacturing_outlined, "Equipment Registry", const EquipmentMasterScreen(), context),
              //     _MenuItem(Icons.build_circle_outlined, "Spares Master", const SparesMasterScreen(), context),
              //     _MenuItem(Icons.handyman_outlined, "Tools Master", const ToolsMasterScreen(), context),
              //     _MenuItem(Icons.local_shipping_outlined, "Vendor Directory", const VendorMasterScreen(), context),
              //   ]),
              //   const SizedBox(height: 32),
              // ],

              // --- Logout Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text("Sign Out", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
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

  // Widget _buildSectionTitle(String title) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 12, left: 4),
  //     child: Text(
  //       title.toUpperCase(),
  //       style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0, color: Colors.grey.shade500),
  //     ),
  //   );
  // }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(item.icon, color: primary, size: 20),
                ),
                title: Text(item.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF0F172A))),
                trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16),
                onTap: () => Navigator.push(item.context, MaterialPageRoute(builder: (_) => item.screen)),
              ),
              if (!isLast) Divider(height: 1, indent: 64, color: Colors.grey.shade100),
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