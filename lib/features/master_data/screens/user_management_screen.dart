import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_form_modal.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Employee ID or Name",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: 5, // Replace with your usersProvider stream
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: const Text("K Mohan Krishna"), // m_user.name [cite: 239]
            subtitle: const Text("ID: EMP102 | Role: Worker"),
                trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to detail to edit or deactivate [cite: 533]
            },
          ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserModal(context),
        label: const Text("Add Staff"),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddUserModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const UserFormModal(),
    );
  }
}