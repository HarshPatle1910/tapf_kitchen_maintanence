import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Screen Imports ---
import 'package:kitchen_maintanence/screens/reports/complaint_report_screen.dart';
import 'package:kitchen_maintanence/screens/reports/master_equipment_report_screen.dart';
import 'package:kitchen_maintanence/screens/reports/pm_checklist_screen.dart';
import 'package:kitchen_maintanence/screens/reports/pm_schedule_screen.dart';
import 'package:kitchen_maintanence/screens/reports/ro_checklist_screen.dart';
import 'package:kitchen_maintanence/screens/reports/testing_equipment_screen.dart';
import 'package:kitchen_maintanence/screens/reports/tools_tackles_screen.dart';
import 'boiler_log_screen.dart';
import 'breakdown_report_screen.dart';
import 'critical_spares_report_screen.dart';
import 'dg_log_screen.dart';
import 'electrical_log_screen.dart';

// --- Data Models ---
class _ReportData {
  final String code;
  final String title;
  final Widget screen;

  _ReportData({required this.code, required this.title, required this.screen});
}

class _CategoryData {
  final String title;
  final IconData icon;
  final List<_ReportData> reports;

  _CategoryData({
    required this.title,
    required this.icon,
    required this.reports,
  });
}

class ReportsScreen extends StatefulWidget {
  final List<String> allowedReportCodes;
  final bool isAdmin;

  const ReportsScreen({
    super.key,
    required this.allowedReportCodes,
    required this.isAdmin,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // --- Master Configuration of Categories and Reports ---
  final List<_CategoryData> _allCategories = [
    _CategoryData(
      title: "Master Reports",
      icon: Icons.folder_special_outlined,
      reports: [
        _ReportData(
          code: "MNT-02",
          title: "Equipment Master",
          screen: const EquipmentReportScreen(),
        ),
        _ReportData(
          code: "MT-03",
          title: "Testing Equipment",
          screen: const TestingEquipmentScreen(),
        ),
        _ReportData(
          code: "MT-15",
          title: "Critical Spare Parts",
          screen: const CriticalSparesReportScreen(),
        ),
      ],
    ),
    _CategoryData(
      title: "Preventive Maintenance",
      icon: Icons.build_circle_outlined,
      reports: [
        _ReportData(
          code: "MT-05",
          title: "PM Schedule",
          screen: const PMScheduleScreen(),
        ),
        _ReportData(
          code: "MT-06",
          title: "PM Checklist",
          screen: const PMChecklistScreen(),
        ),
      ],
    ),
    _CategoryData(
      title: "Breakdown & Complaints",
      icon: Icons.assignment_late_outlined,
      reports: [
        _ReportData(
          code: "MT-07",
          title: "Breakdown Intimation",
          screen: const BreakdownReportScreen(),
        ),
        _ReportData(
          code: "MT-16",
          title: "Complaint Register",
          screen: const ComplaintReportScreen(),
        ),
      ],
    ),
    _CategoryData(
      title: "Daily Log Reports",
      icon: Icons.analytics_outlined,
      reports: [
        _ReportData(
          code: "MT-10",
          title: "Electrical Log",
          screen: const ElectricalLogListScreen(),
        ),
        _ReportData(
          code: "MT-11",
          title: "Boiler Log Sheet",
          screen: const BoilerLogListScreen(),
        ),
        _ReportData(
          code: "MT-13",
          title: "RO Plant Checklist",
          screen: const ROChecklistListScreen(),
        ),
        _ReportData(
          code: "MT-14",
          title: "DG Set Report",
          screen: const DGLogListScreen(),
        ),
      ],
    ),
    _CategoryData(
      title: "Asset Management",
      icon: Icons.inventory_2_outlined,
      reports: [
        _ReportData(
          code: "MT-08",
          title: "Tools & Tackles",
          screen: const ToolsTacklesScreen(),
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Refresh Logic ---
  Future<void> _handleRefresh() async {
    // Provides a visual refresh indicator delay and rebuilds the UI
    // If you add a callback from HomeScreen to re-fetch access data, you can call it here.
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {});
  }

  // --- Filter Logic ---
  List<_CategoryData> get _filteredCategories {
    // 1. First, strictly filter out reports the user doesn't have access to
    final authorizedCategories = _allCategories
        .map((cat) {
          final authorizedReports = cat.reports.where((report) {
            return widget.isAdmin ||
                widget.allowedReportCodes.contains(report.code);
          }).toList();
          return _CategoryData(
            title: cat.title,
            icon: cat.icon,
            reports: authorizedReports,
          );
        })
        .where((cat) => cat.reports.isNotEmpty)
        .toList();

    // 2. Then apply the search query
    if (_searchQuery.isEmpty) return authorizedCategories;

    return authorizedCategories
        .map((cat) {
          final filteredReports = cat.reports.where((report) {
            final matchesTitle = report.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final matchesCode = report.code.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            return matchesTitle || matchesCode;
          }).toList();

          return _CategoryData(
            title: cat.title,
            icon: cat.icon,
            reports: filteredReports,
          );
        })
        .where((cat) => cat.reports.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              color: background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reports Center",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SEARCH BAR ---
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search by report name or code...",
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- CATEGORIES LIST (ACCORDION) ---
            Expanded(
              child: RefreshIndicator(
                color: primary,
                backgroundColor: Colors.white,
                onRefresh: _handleRefresh,
                child: categories.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works when empty
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.15,
                        ),
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              "No reports accessible",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even if not full
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final initiallyExpanded =
                              _searchQuery.isNotEmpty || categories.length == 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: initiallyExpanded,
                                  iconColor: primary,
                                  collapsedIconColor: Colors.grey.shade400,
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          category.icon,
                                          color: primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          category.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "${category.reports.length}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                  children: category.reports
                                      .map((report) => _buildReportTile(report))
                                      .toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTile(_ReportData report) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => report.screen),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: primary.withOpacity(0.1)),
              ),
              child: Text(
                report.code,
                style: GoogleFonts.inter(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                report.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade300,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
