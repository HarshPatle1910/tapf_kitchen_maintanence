import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketTimeline extends StatelessWidget {
  final Map<String, dynamic> ticket;
  static const Color navy = Color(0xFF1E293B);

  const TicketTimeline({super.key, required this.ticket});

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      DateTime d = DateTime.parse(isoString).toUtc().add(const Duration(hours: 5, minutes: 30));
      final int hour12 = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      final String amPm = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  $hour12:${d.minute.toString().padLeft(2, '0')} $amPm';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String? _calculateDuration() {
    try {
      final raisedStr = ticket['ticket_raised_time'] ?? ticket['created_at'];
      final startStr = ticket['repair_start_time'] ?? ticket['assigned_to_time'] ?? raisedStr;
      final endStr = ticket['verified_by_id'] != null
          ? (ticket['admin_verified_at'] ?? ticket['raiser_verified_at'] ?? ticket['updated_at'] ?? ticket['ticket_completion_time'])
          : ticket['ticket_completion_time'];

      if (startStr == null || endStr == null) return null;

      final startDt = DateTime.parse(startStr);
      final endDt = DateTime.parse(endStr);
      final diff = endDt.difference(startDt);

      if (diff.isNegative || diff.inMinutes <= 0) return null;

      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return 'Total duration: ${hours}h ${minutes}m';
      } else {
        return 'Total duration: ${minutes}m';
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedTime = ticket['assigned_to_time'];
    final startTime = ticket['repair_start_time'];
    final compTime = ticket['ticket_completion_time'];
    final adminVerifiedTime = ticket['admin_verified_at'];
    final raiserVerifiedTime = ticket['raiser_verified_at'];
    final verifierId = ticket['verified_by_id'];

    if (assignedTime == null &&
        startTime == null &&
        compTime == null &&
        adminVerifiedTime == null &&
        raiserVerifiedTime == null &&
        verifierId == null) {
      return const SizedBox.shrink();
    }

    String? assignedWorkerName;
    if (ticket['assigned_to'] != null) {
      if (ticket['assigned_to'] is Map) {
        assignedWorkerName = ticket['assigned_to']['name']?.toString();
      } else if (ticket['assigned_to'] is String) {
        assignedWorkerName = ticket['assigned_to'].toString();
      }
    }

    final List<Map<String, dynamic>> steps = [];

    if (assignedTime != null) {
      steps.add({
        'title': 'Worker Assigned',
        'time': assignedTime,
        'icon': Icons.engineering_rounded,
        'color': const Color(0xFFD97706),
        'subtitle': assignedWorkerName != null ? 'Worker: $assignedWorkerName' : null,
        'isDone': true,
      });
    }

    if (startTime != null) {
      steps.add({
        'title': 'Work Started',
        'time': startTime,
        'icon': Icons.play_arrow_rounded,
        'color': const Color(0xFF2563EB),
        'isDone': true,
      });
    }

    if (compTime != null) {
      steps.add({
        'title': 'Work Completed',
        'time': compTime,
        'icon': Icons.check_rounded,
        'color': const Color(0xFF10B981),
        'isDone': true,
      });
    }

    if (adminVerifiedTime != null) {
      steps.add({
        'title': 'Admin Verified',
        'time': adminVerifiedTime,
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFFF59E0B),
        'isDone': true,
      });
    }

    if (raiserVerifiedTime != null) {
      steps.add({
        'title': 'Raiser Verified',
        'time': raiserVerifiedTime,
        'icon': Icons.person_rounded,
        'color': const Color(0xFF7C3AED),
        'isDone': true,
      });
    }

    if (verifierId != null) {
      steps.add({
        'title': 'Verified & Closed',
        'time': ticket['updated_at'] ?? compTime,
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF0D9488),
        'isDone': true,
        'isFinal': true,
      });
    }

    final durationString = _calculateDuration();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF475569),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Activity Timeline",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (durationString != null) ...[
                const SizedBox(width: 8),
                Text(
                  durationString,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final bool isLast = index == steps.length - 1;
            final Color stepColor = step['color'] as Color;
            final bool isFinalStep = step['isFinal'] == true;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left timeline node & connecting line
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: stepColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: stepColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: const Color(0xFFCBD5E1),
                              margin: const EdgeInsets.symmetric(vertical: 2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Middle title & subtitle
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            step['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (step['subtitle'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              step['subtitle'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Right timestamp pill
                  Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFinalStep ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isFinalStep ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        _formatDate(step['time'] as String?),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isFinalStep ? const Color(0xFF047857) : const Color(0xFF334155),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}