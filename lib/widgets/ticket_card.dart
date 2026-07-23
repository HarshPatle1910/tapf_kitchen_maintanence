import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/ticket_detail_screen.dart'; // Adjust path if needed

class TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  static const Color navy = Color(0xFF26538D);

  const TicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final priorityInfo = _getPriorityInfo(ticket['priority']);
    final raisedByName = ticket['raised_by']?['name'] ?? 'Unknown User';
    final assignedToName = ticket['assigned_to']?['name'] ?? 'Unassigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: priorityInfo.color, width: 5),
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticket['ticket_no'] ?? '#---',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityInfo.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priorityInfo.label,
                          style: GoogleFonts.inter(
                            color: priorityInfo.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    ticket['title'] ?? 'No Title',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.kitchen, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ticket['m_kitchen']?['name'] ?? 'General',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "•  ${ticket['status']}",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getStatusColor(ticket['status']),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _UserDisplay(label: "Raised by", name: raisedByName)),
                      const SizedBox(width: 16),
                      Expanded(child: _UserDisplay(label: "Assigned to", name: assignedToName, isRight: true)),
                    ],
                  ),
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

class _UserDisplay extends StatelessWidget {
  final String label;
  final String name;
  final bool isRight;

  const _UserDisplay({required this.label, required this.name, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isRight) Icon(Icons.person, size: 14, color: Colors.grey.shade400),
            if (!isRight) const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isRight) const SizedBox(width: 4),
            if (isRight) Icon(Icons.engineering, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ],
    );
  }
}