import 'package:flutter/material.dart';

import '../../master_data/screens/cluster_list_screen.dart';
import '../../master_data/screens/equipment_list_screen.dart';
import '../../master_data/screens/kitchen_list_screen.dart';
import '../../master_data/screens/user_management_screen.dart';
import '../../tickets/screens/assigned_work_screen.dart';
import '../../tickets/screens/notification_screen.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, fetch these from your Riverpod authProvider [cite: 416]
    const String userRole = 'admin'; // Change to 'worker' to test visibility
    const String userName = "Arun Chachadi";
    const String employeeId = "EMP-2026-001";

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF4A56E2)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF4A56E2)),
            ),
            accountName: const Text(userName), // [cite: 557]
            accountEmail: const Text("ID: $employeeId"), // [cite: 557]
          ),

          // Basic Navigation
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home Dashboard'),
            onTap: () => Navigator.pop(context),
          ),

          ListTile(
            leading: const Icon(Icons.assignment_ind),
            title: const Text('My Assigned Work'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignedWorkScreen()));
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            },
          ),

          // Admin-Only Master Data Sections
          if (userRole == 'admin') ...[
            const Divider(),

            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
              child: Text("ADMIN - MASTER DATA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ListTile(
              leading: const Icon(Icons.hub),
              title: const Text('Cluster Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ClusterListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.kitchen),
              title: const Text('Kitchen Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KitchenListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest),
              title: const Text('Equipment Registry'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipmentListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()));
              },
            ),
          ],

          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Add logout confirmation dialog [cite: 559]
              _showLogoutDialog(context);
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                // Clear JWT and FCM tokens here
                Navigator.pop(context);
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}