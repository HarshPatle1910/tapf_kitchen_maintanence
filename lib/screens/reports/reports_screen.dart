import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kitchen_maintanence/screens/master/equipment_master_screen.dart';
import 'package:kitchen_maintanence/screens/reports/complaint_report_screen.dart';
import 'package:kitchen_maintanence/screens/reports/master_equipment_report_screen.dart';

// Import the new dedicated report screen
import 'breakdown_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const Color navy = Color(0xFF26538D);
  static const Color background = Color(0xFFF8F9FA);

  Widget _buildReportCard({required String title, required String desc, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: navy)),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background, elevation: 0, foregroundColor: navy,
        title: Text("Report Center", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          Text("Available Reports", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade500, letterSpacing: 1.2)),
          const SizedBox(height: 16),

          _buildReportCard(
            title: "Breakdown Intimation",
            desc: "Generate detailed DOCX/PDF reports for individual breakdown tickets.",
            icon: Icons.description_outlined,
            color: Colors.blue,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BreakdownReportScreen()));
            },
          ),

          const SizedBox(height: 16),
          _buildReportCard(
            title: "Complaint Register",
            desc: "Excel/PDF export of all logged complaints.",
            icon: Icons.table_view_outlined,
            color: Colors.green,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintReportScreen()));
            },
          ),

          const SizedBox(height: 16),
          _buildReportCard(
            title: "Equipment Master",
            desc: "Excel export of the full equipment registry.",
            icon: Icons.build_circle_outlined,
            color: Colors.orange,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipmentReportScreen()));
            },
          ),
        ],
      ),
    );
  }
}