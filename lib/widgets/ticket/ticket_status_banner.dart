import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketStatusBanner extends StatelessWidget {
  final String currentStatus;
  final String? raisedTime;

  const TicketStatusBanner({
    super.key,
    required this.currentStatus,
    this.raisedTime,
  });

  Color _getStatusColor() {
    switch (currentStatus.toUpperCase()) {
      case 'VERIFIED':
        return const Color(0xFFD97706); // Amber/Golden
      case 'COMPLETED':
        return const Color(0xFF059669); // Emerald Green
      case 'IN_PROGRESS':
        return const Color(0xFF2563EB); // Royal Blue
      case 'ASSIGNED':
        return const Color(0xFFD97706); // Amber
      case 'RAISED':
      default:
        return const Color(0xFFDC2626); // Crimson Red
    }
  }

  String _getPillText() {
    switch (currentStatus.toUpperCase()) {
      case 'VERIFIED':
        return 'Resolved';
      case 'COMPLETED':
        return 'Pending Audit';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'ASSIGNED':
        return 'Assigned';
      case 'RAISED':
      default:
        return 'Open';
    }
  }

  Color _getPillBgColor() {
    switch (currentStatus.toUpperCase()) {
      case 'VERIFIED':
      case 'COMPLETED':
        return const Color(0xFFECFDF5); // Light Green
      case 'IN_PROGRESS':
        return const Color(0xFFEFF6FF); // Light Blue
      case 'ASSIGNED':
        return const Color(0xFFFEF3C7); // Light Amber
      case 'RAISED':
      default:
        return const Color(0xFFFEF2F2); // Light Red
    }
  }

  Color _getPillTextColor() {
    switch (currentStatus.toUpperCase()) {
      case 'VERIFIED':
      case 'COMPLETED':
        return const Color(0xFF059669);
      case 'IN_PROGRESS':
        return const Color(0xFF2563EB);
      case 'ASSIGNED':
        return const Color(0xFFD97706);
      case 'RAISED':
      default:
        return const Color(0xFFDC2626);
    }
  }

  IconData _getStatusIcon() {
    switch (currentStatus.toUpperCase()) {
      case 'VERIFIED':
        return Icons.verified_outlined;
      case 'COMPLETED':
        return Icons.check_circle_outline_rounded;
      case 'IN_PROGRESS':
        return Icons.play_circle_outline_rounded;
      case 'ASSIGNED':
        return Icons.person_pin_circle_outlined;
      case 'RAISED':
      default:
        return Icons.report_problem_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final pillText = _getPillText();
    final pillBg = _getPillBgColor();
    final pillColor = _getPillTextColor();
    final statusIcon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: const Color(0xFFD97706), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CURRENT STATUS",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            currentStatus,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: statusColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pillText,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: pillColor,
                  ),
                ),
              ),
            ],
          ),
          if (raisedTime != null && raisedTime!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF94A3B8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Raised On:",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    raisedTime!,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}