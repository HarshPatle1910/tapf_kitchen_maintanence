import 'package:flutter/material.dart';
import '../../navigation/widgets/sidebar_drawer.dart';
import 'create_ticket_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plant Maintenance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {}, // Deep link to Notification Screen [cite: 540]
          ),
        ],
      ),
      drawer: const SidebarDrawer(),
      body: Column(
        children: [
          // 1. Stats Row [cite: 506]
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("381", "Total", Colors.black),
                _buildStatItem("91", "To Do", Colors.black),
                _buildStatItem("0", "In Progress", Colors.black),
                _buildStatItem("290", "Completed", Colors.black),
              ],
            ),
          ),

          // 2. Search Bar [cite: 507]
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 3. Ticket List [cite: 509]
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 3, // Mock data for now
              itemBuilder: (context, index) {
                return const TicketCard(); // Placeholder for the cards in your screenshot
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A56E2),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RaiseTicketScreen()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

// Basic Ticket Card matching the screenshot UI
class TicketCard extends StatelessWidget {
  const TicketCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("# Completed", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              "Reception Area Ac Air Blow Is Very Less.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text("Arun Chachadi"),
              ],
            ),
            const Row(
              children: [
                Icon(Icons.settings, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text("AIR CONDITIONER | OVERALL"),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14)),
                    SizedBox(width: 8),
                    Text("null", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Text("#315 days", style: TextStyle(color: Colors.grey[600])),
              ],
            )
          ],
        ),
      ),
    );
  }
}