import 'package:flutter/material.dart';

class AssignedWorkScreen extends StatelessWidget {
  const AssignedWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Assignments"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Active"), // ASSIGNED & IN_PROGRESS
              Tab(text: "Completed"), // Waiting for Admin verification
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTicketList(isActive: true),
            _buildTicketList(isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList({required bool isActive}) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 2, // Filtered by assigned_to_id == current_user_id
      itemBuilder: (context, index) {
        return Card(
          // Priority color bar on left as per §11.5
          child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.red, width: 6)), // Critical/High color
            ),
            child: ListTile(
              title: const Text("KMS-2026-0081", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Exhaust Fan making noise | Ventilation"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to TicketDetailScreen
              },
            ),
          ),
        );
      },
    );
  }
}