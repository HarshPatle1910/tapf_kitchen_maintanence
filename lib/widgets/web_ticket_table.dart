import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/ticket_detail_screen.dart';

class WebTicketTable extends StatelessWidget {
  final List<Map<String, dynamic>> tickets;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  static const Color navy = Color(0xFF26538D);

  const WebTicketTable({
    super.key,
    required this.tickets,
    this.isLoading = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed Header
          _buildHeaderRow(),
          const Divider(height: 1, thickness: 1),
          
          // Scrollable List
          if (tickets.isEmpty && !isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text("No tickets found.")),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: tickets.length + (onLoadMore != null ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, thickness: 1),
                itemBuilder: (context, index) {
                  if (index == tickets.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : onLoadMore,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            side: const BorderSide(color: navy),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                                  "Show More",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                                ),
                        ),
                      ),
                    );
                  }
                  final ticket = tickets[index];
                  return _ExpandableTableRow(ticket: ticket);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Ticket #', flex: 1),
          _buildHeaderCell('Title', flex: 2),
          _buildHeaderCell('Priority', flex: 1),
          _buildHeaderCell('Raised By', flex: 1),
          _buildHeaderCell('Assigned To', flex: 1),
          _buildHeaderCell('Status', flex: 1),
          _buildHeaderCell('Time Ago', flex: 1),
          _buildHeaderCell('', flex: 0, width: 40), // For Action
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1, double? width}) {
    final textWidget = Text(
      title,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: navy,
      ),
    );
    
    if (width != null) {
      return SizedBox(width: width, child: textWidget);
    }
    
    return Expanded(
      flex: flex,
      child: textWidget,
    );
  }
}

class _ExpandableTableRow extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const _ExpandableTableRow({required this.ticket});

  @override
  State<_ExpandableTableRow> createState() => _ExpandableTableRowState();
}

class _ExpandableTableRowState extends State<_ExpandableTableRow> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final priorityInfo = _getPriorityInfo(ticket['priority']);
    final raisedByName = ticket['raised_by']?['name'] ?? 'Unknown';
    final assignedToName = ticket['assigned_to']?['name'] ?? 'Unassigned';

    String timeAgo = '';
    if (ticket['ticket_raised_time'] != null) {
      final raisedTime = DateTime.parse(ticket['ticket_raised_time']);
      final diff = DateTime.now().difference(raisedTime);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}m ago';
      } else {
        timeAgo = 'Now';
      }
    }

    return InkWell(
      onTap: _toggleExpand,
      hoverColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: priorityInfo.color, width: 4),
          ),
        ),
        child: Row(
          crossAxisAlignment: _isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            _buildDataCell(ticket['ticket_no'] ?? '#---', flex: 1, isBold: true),
            _buildDataCell(ticket['title'] ?? 'No Title', flex: 2),
            _buildPriorityCell(priorityInfo, flex: 1),
            _buildUserCell(raisedByName, flex: 1),
            _buildUserCell(assignedToName, flex: 1),
            _buildStatusCell(ticket['status'], flex: 1),
            _buildDataCell(timeAgo, flex: 1, color: Colors.grey.shade600),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketDetailScreen(ticket: ticket),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1, bool isBold = false, Color? color}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black87,
          ),
          maxLines: _isExpanded ? null : 1,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildPriorityCell(_PriorityData priorityInfo, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: priorityInfo.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                priorityInfo.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: priorityInfo.color,
                ),
                maxLines: _isExpanded ? null : 1,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserCell(String name, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                _getInitials(name),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: _isExpanded ? null : 1,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(String? status, {int flex = 1}) {
    final color = _getStatusColor(status);
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status ?? 'UNKNOWN',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
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
