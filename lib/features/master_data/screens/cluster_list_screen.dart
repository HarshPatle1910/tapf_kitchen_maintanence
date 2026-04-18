import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClusterListScreen extends ConsumerWidget {
  const ClusterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clusters")),
      body: ListView.separated(
        itemCount: 5, // Replace with AsyncValue from clusterProvider
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.hub_outlined),
            title: Text("Cluster ${index + 1}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to Kitchens filtered by this Cluster
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClusterDialog(context),
        label: const Text("New Cluster"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddClusterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Cluster"),
        content: const TextField(
          decoration: InputDecoration(labelText: "Cluster Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {}, child: const Text("Save")),
        ],
      ),
    );
  }
}