import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kitchen_maintanence/screens/reports/complaint_report_screen.dart';
import 'package:kitchen_maintanence/screens/reports/master_equipment_report_screen.dart';
import 'package:kitchen_maintanence/screens/reports/pm_checklist_screen.dart';
import 'package:kitchen_maintanence/screens/reports/pm_schedule_screen.dart';
import 'package:kitchen_maintanence/screens/reports/testing_equipment_screen.dart';
import 'package:kitchen_maintanence/screens/reports/tools_tackles_screen.dart';
import 'breakdown_report_screen.dart';
import 'dg_log_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String code,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Minimalistic Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Icon(icon, color: primary, size: 24),
                ),
                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              code,
                              style: GoogleFonts.inter(
                                color: primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade300,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: primary,
        title: Text(
          "Report Center",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildReportCard(
            title: "Equipment Master",
            code: "MNT-02",
            desc:
                "Complete master list of all kitchen machinery and equipment.",
            icon: Icons.precision_manufacturing_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EquipmentReportScreen()),
            ),
          ),
          _buildReportCard(
            title: "Testing Equipments",
            code: "MT-03",
            desc: "Master list of testing, measuring, and calibration tools.",
            icon: Icons.speed_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TestingEquipmentScreen()),
            ),
          ),
          _buildReportCard(
            title: "Preventive Maintenance Schedule",
            code: "MT-05",
            desc: "Plan and achieve the machines",
            icon: Icons.speed_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PMScheduleScreen()),
            ),
          ),
          _buildReportCard(
            title: "PM Checklist",
            code: "MT-06",
            desc: "Scheduled preventive maintenance checklists and activities.",
            icon: Icons.fact_check_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PMChecklistScreen()),
            ),
          ),
          _buildReportCard(
            title: "Breakdown Intimation",
            code: "MT-07",
            desc:
                "Register and track sudden machinery breakdowns and resolutions.",
            icon: Icons.warning_amber_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BreakdownReportScreen()),
            ),
          ),
          _buildReportCard(
            title: "Tools & Tackles",
            code: "MT-08",
            desc: "Daily log of tools taken and returned by technicians.",
            icon: Icons.handyman_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ToolsTacklesScreen()),
            ),
          ),
          _buildReportCard(
            title: "DG SET Report",
            code: "MT-14",
            desc: "DG SET: 250 KVA (Rated Voltage: 415 V) (Rated Current: 347 A)",
            icon: Icons.handyman_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DGLogListScreen()),
            ),
          ),
          _buildReportCard(
            title: "Complaint Register",
            code: "MT-16",
            desc: "Log and monitor ongoing maintenance complaints.",
            icon: Icons.assignment_late_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComplaintReportScreen()),
            ),
          ),

          const SizedBox(height: 32), // Bottom padding
        ],
      ),
    );
  }
}
