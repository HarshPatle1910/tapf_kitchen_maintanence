

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          TextButton(
            onPressed: () {}, // Update notifications table where user_id = current [cite: 538]
            child: const Text("Mark All Read", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: 3,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            // Unread dot indicator [cite: 539]
            leading: CircleAvatar(
              backgroundColor: index == 0 ? Colors.blue : Colors.grey[200],
              radius: 6,
            ),
            title: const Text("Ticket Assigned to You"), // Notification title [cite: 369]
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("KMS-2026-0042: Refrigerator not cooling..."), // Body excerpt [cite: 539]
                const SizedBox(height: 4),
                Text("2 mins ago", style: TextStyle(fontSize: 12, color: Colors.grey[600])), // Relative timestamp [cite: 539]
              ],
            ),
            onTap: () {
              // Mark as read + Deep link to ticket [cite: 540]
            },
          );
        },
      ),
    );
  }
}