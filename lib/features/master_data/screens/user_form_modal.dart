import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UserFormModal extends StatefulWidget {
  const UserFormModal({super.key});

  @override
  State<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<UserFormModal> {
  String selectedRole = 'worker'; // Default role [cite: 25]
  List<String> selectedKitchens = []; // For user_kitchens mapping [cite: 450]

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Create New Staff Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(decoration: const InputDecoration(labelText: "Full Name *", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: "Employee ID *", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: "Phone Number *", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: "Role *", border: OutlineInputBorder()),
            items: ['admin', 'worker'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
            onChanged: (val) => setState(() => selectedRole = val!),
          ),
          const SizedBox(height: 12),
          // In a real app, this would be a multi-select chip for assigned kitchens [cite: 532]
          const ListTile(
            title: Text("Assign Kitchens"),
            trailing: Icon(Icons.add_link),
            subtitle: Text("Selected: Main Kitchen, Bakery"),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            onPressed: () {
              // Trigger the 'create-worker' Edge Function
            },
            child: const Text("CREATE ACCOUNT"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}