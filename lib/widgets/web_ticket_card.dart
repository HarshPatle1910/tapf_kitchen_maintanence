import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/ticket_detail_screen.dart';

class WebTicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  static const Color navy = Color(0xFF26538D);

  const WebTicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final priorityInfo = _getPriorityInfo(ticket['priority']);
    final raisedByName = ticket['raised_by']?['name'] ?? 'Unknown User';
    final assignedToName = ticket['assigned_to']?['name'] ?? 'Unassigned';

    // Calculate time ago based on ticket_raised_time
    String timeAgo = '';
    if (ticket['ticket_raised_time'] != null) {
      final raisedTime = DateTime.parse(ticket['ticket_raised_time']);
      final diff = DateTime.now().difference(raisedTime);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays} days ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours} hours ago';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes} min ago';
      } else {
        timeAgo = 'Just now';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: priorityInfo.color, width: 4),
            ),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticket: ticket),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Column 1: Info (Ticket No, Priority, Title, Location)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ticket['ticket_no'] ?? '#---',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              priorityInfo.label,
                              style: GoogleFonts.inter(
                                color: priorityInfo.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket['title'] ?? 'No Title',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.business, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              ticket['m_kitchen']?['name'] ?? 'General',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Column 2: Raised By
                  Expanded(
                    flex: 2,
                    child: _UserColumn(label: "Raised by", name: raisedByName),
                  ),

                  // Column 3: Assigned To
                  Expanded(
                    flex: 2,
                    child: _UserColumn(label: "Assigned to", name: assignedToName),
                  ),

                  // Column 4: Status and Time Ago
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(ticket['status']).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            ticket['status'] ?? 'UNKNOWN',
                            style: GoogleFonts.inter(
                              color: _getStatusColor(ticket['status']),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'RAISED': return Colors.redAccent;
      case 'ASSIGNED': return Colors.blueAccent;
      case 'IN_PROGRESS': return Colors.orange;
      case 'COMPLETED': return Colors.green;
      case 'VERIFIED': return Colors.teal;
      default: return Colors.grey;
    }
  }

  _PriorityData _getPriorityInfo(String? priority) {
    switch (priority) {
      case 'CRITICAL': return _PriorityData(Colors.red.shade700, 'CRITICAL');
      case 'HIGH': return _PriorityData(Colors.orange.shade700, 'HIGH');
      case 'MEDIUM': return _PriorityData(Colors.blue.shade600, 'MEDIUM');
      case 'LOW': return _PriorityData(Colors.green.shade600, 'LOW');
      default: return _PriorityData(Colors.grey, 'NONE');
    }
  }
}

class _PriorityData {
  final Color color;
  final String label;
  _PriorityData(this.color, this.label);
}

class _UserColumn extends StatelessWidget {
  final String label;
  final String name;

  const _UserColumn({required this.label, required this.name});

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Text(
                _getInitials(name),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
