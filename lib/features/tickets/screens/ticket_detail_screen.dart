import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("KMS-2026-0042"), // Auto-generated ID [cite: 214]
          bottom: const TabBar(
            tabs: [
              Tab(text: "Details"),
              Tab(text: "Media"),
              Tab(text: "Comments"),
            ],
            labelColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(),
            _buildMediaTab(),
            _buildCommentsTab(),
          ],
        ),
        bottomNavigationBar: _buildActionFAB(context), // Role-aware button [cite: 523]
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Status: IN PROGRESS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        const SizedBox(height: 8),
        const Text("Reception Area Ac Air Blow Is Very Less.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        const ListTile(leading: Icon(Icons.location_on), title: Text("Main Kitchen")),
        const ListTile(leading: Icon(Icons.build), title: Text("AC Unit #4")),
        const ListTile(leading: Icon(Icons.priority_high), title: Text("Priority: HIGH")), // Usage Guidance [cite: 162]
      ],
    );
  }

  Widget _buildMediaTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: 2,
      itemBuilder: (context, index) => Container(color: Colors.grey[300], child: const Icon(Icons.image)),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(child: ListView(children: const [ListTile(title: Text("Parts ordered."), subtitle: Text("Admin | 10:00 AM"))])),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Expanded(child: TextField(decoration: InputDecoration(hintText: "Add comment..."))),
              IconButton(icon: const Icon(Icons.send), onPressed: () {}), // Comments are immutable [cite: 173]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionFAB(BuildContext context) {
    // Workers see "START WORK" or "MARK COMPLETE" [cite: 184, 523]
    // Admins see "VERIFY" or "CLOSE" [cite: 188, 523]
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        onPressed: () {},
        child: const Text("MARK COMPLETE"),
      ),
    );
  }
}