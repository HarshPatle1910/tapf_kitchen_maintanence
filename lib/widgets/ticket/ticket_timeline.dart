import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketTimeline extends StatelessWidget {
  final Map<String, dynamic> ticket;
  static const Color navy = Color(0xFF26538D);

  const TicketTimeline({super.key, required this.ticket});

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      DateTime d = DateTime.parse(isoString).toUtc().add(const Duration(hours: 5, minutes: 30));
      final int hour12 = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      final String amPm = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} $hour12:${d.minute.toString().padLeft(2, '0')} $amPm';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildTimeRow(String label, String timeStr, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(_formatDate(timeStr), style: GoogleFonts.inter(fontSize: 12, color: navy, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final startTime = ticket['repair_start_time'];
    final compTime = ticket['ticket_completion_time'];
    final verifierId = ticket['verified_by_id'];

    if (startTime == null && compTime == null && verifierId == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Activity Timeline", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy, fontSize: 13)),
          const SizedBox(height: 12),

          if (startTime != null) _buildTimeRow("Work Started", startTime, Icons.play_circle_fill, Colors.blue),
          if (startTime != null && compTime != null) const SizedBox(height: 8),

          if (compTime != null) _buildTimeRow("Work Completed", compTime, Icons.check_circle, Colors.green),
          if (compTime != null && verifierId != null) const SizedBox(height: 8),

          if (verifierId != null) _buildTimeRow("Verified & Closed", ticket['updated_at'], Icons.verified, Colors.teal),
        ],
      ),
    );
  }
}