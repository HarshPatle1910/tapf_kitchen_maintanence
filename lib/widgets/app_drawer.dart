import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

// Import your screens here (Adjust paths based on your actual structure)
import '../screens/master/area_screen.dart';
import '../screens/master/kitchen_screen.dart';
import '../screens/master/spares/spare_screen.dart';
import '../screens/master/vendor_screen.dart';
import '../screens/master/zone_screen.dart';
import '../screens/master/equipment_master_screen.dart';
import '../screens/master/tools_screen.dart';
import '../screens/master/user_management.dart';
import '../screens/reports/reports_screen.dart';

class AppDrawer extends StatelessWidget {
  final AuthProvider authProv;
  final TicketProvider ticketProv;
  final bool isAdmin;
  final Function(String) onKitchenChanged;

  static const Color navy = Color(0xFF26538D);

  const AppDrawer({
    super.key,
    required this.authProv,
    required this.ticketProv,
    required this.isAdmin,
    required this.onKitchenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String displayName = authProv.userName ?? (isAdmin ? "Administrator" : "Staff Member");
    final String displayRole = "Role: ${(authProv.activeRole ?? 'Worker').toUpperCase()}";
    final String initials = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'U';

    String validDropdownValue = ticketProv.kitchenFilter;
    if (!authProv.assignedKitchens.any((k) => k['id'].toString() == validDropdownValue) &&
        authProv.assignedKitchens.isNotEmpty) {
      validDropdownValue = authProv.assignedKitchens.first['id'].toString();
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Scrollable Area
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: navy),
                  accountName: Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                  accountEmail: Text(displayRole, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500)),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(initials, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: navy)),
                  ),
                ),

                if (authProv.assignedKitchens.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ACTIVE KITCHEN", style: GoogleFonts.inter(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: validDropdownValue,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: navy),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 4,
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: InputBorder.none),
                            items: authProv.assignedKitchens.map((k) => DropdownMenuItem(
                              value: k['id'].toString(),
                              child: Text(k['name'].toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                            )).toList(),
                            onChanged: (val) {
                              ticketProv.setFilters(kitchenId: val!, zoneId: 'ALL');
                              onKitchenChanged(val);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                ],

                if (isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("ADMIN CONTROLS", style: GoogleFonts.inter(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(context, Icons.analytics_outlined, 'Report Center', const ReportsScreen()),
                  _buildNavItem(context, Icons.people_outline, 'User Management', const UserManagementScreen()),
                  _buildNavItem(context, Icons.build_circle_outlined, 'Equipment Registry', const EquipmentMasterScreen()),
                  _buildNavItem(context, Icons.pan_tool, 'Spares', const SparesMasterScreen()),
                  _buildNavItem(context, Icons.handyman_outlined, 'Tools', const ToolsMasterScreen()),
                  _buildNavItem(context, Icons.place, 'Area', const AreaMasterScreen()),
                  _buildNavItem(context, Icons.person_pin_circle, 'Vendors', const VendorMasterScreen()),
                  _buildNavItem(context, Icons.directions_boat, 'Zone', const ZoneMasterScreen()),
                  _buildNavItem(context, Icons.kitchen, 'Kitchen', const KitchenMasterScreen()),

                ],
              ],
            ),
          ),

          // Pinned Footer
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async => await authProv.logout(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: navy),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}