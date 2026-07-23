import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class EquipmentReportScreen extends StatefulWidget {
  const EquipmentReportScreen({super.key});

  @override
  State<EquipmentReportScreen> createState() => _EquipmentReportScreenState();
}

class _EquipmentReportScreenState extends State<EquipmentReportScreen> {
  // Unified Minimalistic Color Palette
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);

  String _selectedFormat = 'xlsx';

  // Monthly State Variables
  int? _selectedMonth;
  int? _selectedYear;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Generates a list of years from 2020 up to the current year + 1
  final List<int> _years = List.generate(
      (DateTime.now().year - 2020) + 1,
          (index) => 2020 + index
  );

  @override
  void initState() {
    super.initState();
    // Default to the current month and year
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
  }

  Future<void> _processReport(String action) async {
    if (_selectedMonth == null || _selectedYear == null) return;

    // 1. SILENTLY FETCH THE TARGET KITCHEN FROM THE HOME SCREEN STATE
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    String targetKitchenId = ticketProv.kitchenFilter;

    // If 'ALL' is selected on the dashboard, default to their first assigned kitchen
    if (targetKitchenId == 'ALL' || targetKitchenId.isEmpty) {
      if (authProv.assignedKitchens.isNotEmpty) {
        targetKitchenId = authProv.assignedKitchens.first['id'].toString();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active kitchen available!'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // Append kitchen_id to the Railway API call
    final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/equipment_master?kitchen_id=$targetKitchenId&month=$_selectedMonth&year=$_selectedYear&format=$_selectedFormat');

    // Creating a local filename that matches the server's clean naming scheme
    final monthAbbr = _months[_selectedMonth! - 1].substring(0, 3);
    final String finalFileName = 'Equipment_Master_${monthAbbr}_$_selectedYear.$_selectedFormat';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: primary)),
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        File? file;

        try {
          Directory? saveDir;
          if (Platform.isAndroid) {
            saveDir = Directory('/storage/emulated/0/Download/Equipment Master Reports');
          } else {
            final docDir = await getApplicationDocumentsDirectory();
            saveDir = Directory('${docDir.path}/Equipment Master Reports');
          }

          if (!await saveDir.exists()) {
            await saveDir.create(recursive: true);
          }

          file = File('${saveDir.path}/$finalFileName');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted && action == 'preview') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to Downloads/Equipment Master Reports/'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          final tempDir = await getTemporaryDirectory();
          file = File('${tempDir.path}/$finalFileName');
          await file.writeAsBytes(response.bodyBytes);
        }

        if (mounted) Navigator.pop(context);

        if (action == 'share') {
          await Share.shareXFiles([XFile(file.path)], text: 'Attached is the Equipment Master Report for $monthAbbr $_selectedYear.');
        } else if (action == 'preview') {
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file. Viewer app missing?'), backgroundColor: Colors.orange));
          }
        }
      } else if (response.statusCode == 404) {
        throw Exception("No equipment found for this kitchen in the selected timeframe.");
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process report: $e'), backgroundColor: Colors.red));
    }
  }

  // Helper for minimal dropdowns matching the new UI
  InputDecoration _minimalDecor() {
    return InputDecoration(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Export is ready as long as a month and year are selected
    final bool isReadyToExport = _selectedMonth != null && _selectedYear != null;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background, elevation: 0, foregroundColor: primary,
        title: Text("Equipment Master", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Generate Report", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text("Select the timeframe and format for your equipment master list export.", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 32),

            // 1. INPUT SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TIMEFRAME DROPDOWNS
                  Text("Timeframe", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: primary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // MONTH DROPDOWN
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          decoration: _minimalDecor(),
                          initialValue: _selectedMonth,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(16),
                          dropdownColor: Colors.white,
                          hint: Text("Month", style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14)),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          items: List.generate(_months.length, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(_months[index], style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: primary, fontSize: 14)),
                            );
                          }),
                          onChanged: (val) => setState(() => _selectedMonth = val),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // YEAR DROPDOWN
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          decoration: _minimalDecor(),
                          initialValue: _selectedYear,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(16),
                          dropdownColor: Colors.white,
                          hint: Text("Year", style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14)),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          items: _years.map((year) {
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: primary, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedYear = val),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. EXPORT SETTINGS SECTION
            Text("FORMAT", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey.shade400, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            Row(
              children: [
                ChoiceChip(
                  label: Text("Excel (.xlsx)", style: GoogleFonts.inter(fontWeight: _selectedFormat == 'xlsx' ? FontWeight.w600 : FontWeight.normal)),
                  selected: _selectedFormat == 'xlsx',
                  selectedColor: primary.withValues(alpha: 0.1),
                  backgroundColor: surface,
                  side: BorderSide.none,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onSelected: (v) => setState(() => _selectedFormat = 'xlsx'),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text("PDF (.pdf)", style: GoogleFonts.inter(fontWeight: _selectedFormat == 'pdf' ? FontWeight.w600 : FontWeight.normal)),
                  selected: _selectedFormat == 'pdf',
                  selectedColor: primary.withValues(alpha: 0.1),
                  backgroundColor: surface,
                  side: BorderSide.none,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onSelected: (v) => setState(() => _selectedFormat = 'pdf'),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: !isReadyToExport ? null : SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: surface,
                      foregroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => _processReport("preview"),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: Text("PREVIEW", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => _processReport("share"),
                    icon: const Icon(Icons.share_outlined, size: 20),
                    label: Text("SHARE", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}