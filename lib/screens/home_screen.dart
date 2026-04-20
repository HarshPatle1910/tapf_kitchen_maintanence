import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import 'login_screen.dart';
import 'ticket_detail_screen.dart'; // We will build this next

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Infinite Scroll Logic
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<TicketProvider>().fetchTickets(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A56E2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Stats Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatText("Total", ticketProvider.total),
                _StatText("To Do", ticketProvider.toDo),
                _StatText("In Progress", ticketProvider.inProgress),
                _StatText("Completed", ticketProvider.completed),
              ],
            ),
          ),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search tickets...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 3. Ticket List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ticketProvider.refreshTickets(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ticketProvider.tickets.length + (ticketProvider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the bottom if fetching more
                  if (index == ticketProvider.tickets.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final ticket = ticketProvider.tickets[index];
                  return _TicketCard(ticket: ticket);
                },
              ),
            ),
          ),
        ],
      ),
      // Floating Action Button to Raise a Ticket
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A56E2),
        foregroundColor: Colors.white,
        onPressed: () {
          // Open Detail Screen in "Raise New" mode (ticket is null)
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketDetailScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget for the Stats numbers
class _StatText extends StatelessWidget {
  final String label;
  final int count;
  const _StatText(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
            count.toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A56E2))
        ),
        Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)
        ),
      ],
    );
  }
}

// Widget for the Ticket List Items
class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          ticket['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Status: ${ticket['status']}", style: TextStyle(color: _getStatusColor(ticket['status']), fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text("Kitchen: ${ticket['m_kitchen']?['name'] ?? 'N/A'}"),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Open Detail Screen in "Edit" mode
          Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)));
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'RAISED': return Colors.red;
      case 'IN_PROGRESS': return Colors.orange;
      case 'COMPLETED': return Colors.green;
      default: return Colors.grey;
    }
  }
}