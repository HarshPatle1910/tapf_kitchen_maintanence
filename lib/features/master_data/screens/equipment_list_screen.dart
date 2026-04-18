
import 'package:flutter/material.dart';

class EquipmentListScreen extends StatelessWidget {
  const EquipmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Equipment Registry")),
      body: Column(
        children: [
          // Filter by Kitchen dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Filter by Kitchen"),
              items: const [DropdownMenuItem(value: "1", child: Text("Main Kitchen"))],
              onChanged: (val) {},
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.settings)),
                  title: const Text("Industrial Oven #4"),
                  subtitle: const Text("Area: Bakery Section"),
                  trailing: const Icon(Icons.edit_outlined),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Add Equipment logic
        child: const Icon(Icons.build_circle),
      ),
    );
  }
}