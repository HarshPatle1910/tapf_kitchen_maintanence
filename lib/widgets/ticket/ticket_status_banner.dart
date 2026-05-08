import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketStatusBanner extends StatelessWidget {
  final String currentStatus;

  const TicketStatusBanner({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade300, width: 2)
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Current Status", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(currentStatus, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.orange.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}