import 'package:flutter/material.dart';

class KitchenListScreen extends StatelessWidget {
  const KitchenListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kitchen Management")),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: const Text("Central Kitchen HQ"),
              subtitle: const Text("123 Business Road, Hyderabad"),
              trailing: Switch(
                value: true,
                onChanged: (val) {}, // Updates m_kitchen.status
              ),
              onLongPress: () {
                // Edit kitchen details
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Open full-screen modal to add kitchen
        child: const Icon(Icons.add_business),
      ),
    );
  }
}