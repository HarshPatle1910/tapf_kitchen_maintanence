import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

class EquipmentReportScreen extends StatefulWidget {
  const EquipmentReportScreen({super.key});

  @override
  State<EquipmentReportScreen> createState() => _EquipmentReportScreenState();
}

class _EquipmentReportScreenState extends State<EquipmentReportScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  String get _pythonApiBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (Platform.isAndroid) return 'http://192.168.0.45:8000/api';
    if (Platform.isIOS) return 'http://127.0.0.1:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

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

    final url = Uri.parse('$_pythonApiBaseUrl/reports/equipment?month=$_selectedMonth&year=$_selectedYear&format=$_selectedFormat');

    // Creating a local filename that matches the server's clean naming scheme
    final monthAbbr = _months[_selectedMonth! - 1].substring(0, 3);
    final String finalFileName = 'Equipment_Master_${monthAbbr}_$_selectedYear.$_selectedFormat';

    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: golden)),
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
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process report: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Export is ready as long as a month and year are selected
    final bool isReadyToExport = _selectedMonth != null && _selectedYear != null;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: navy,
        title: Text("Equipment Master", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INPUT SECTION (DROPDOWNS)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select Timeframe", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // MONTH DROPDOWN
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedMonth,
                              isExpanded: true,
                              hint: Text("Month", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                              icon: const Icon(Icons.keyboard_arrow_down, color: navy),
                              items: List.generate(_months.length, (index) {
                                return DropdownMenuItem(
                                  value: index + 1,
                                  child: Text(_months[index], style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy, fontSize: 14)),
                                );
                              }),
                              onChanged: (val) => setState(() => _selectedMonth = val),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // YEAR DROPDOWN
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              isExpanded: true,
                              hint: Text("Year", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                              icon: const Icon(Icons.keyboard_arrow_down, color: navy),
                              items: _years.map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy, fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedYear = val),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. EXPORT SETTINGS SECTION
            Text("Export Settings", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade500, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFormat = 'xlsx'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedFormat == 'xlsx' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedFormat == 'xlsx' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.table_chart, size: 18, color: _selectedFormat == 'xlsx' ? Colors.green.shade700 : Colors.grey), const SizedBox(width: 8),
                            Text("Excel (.xlsx)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _selectedFormat == 'xlsx' ? navy : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFormat = 'pdf'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedFormat == 'pdf' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedFormat == 'pdf' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf, size: 18, color: _selectedFormat == 'pdf' ? Colors.red.shade700 : Colors.grey), const SizedBox(width: 8),
                            Text("PDF (.pdf)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _selectedFormat == 'pdf' ? navy : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: !isReadyToExport ? null : SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100, foregroundColor: navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0
                    ),
                    onPressed: () => _processReport("preview"),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text("PREVIEW", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: golden, foregroundColor: navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0
                    ),
                    onPressed: () => _processReport("share"),
                    icon: const Icon(Icons.share),
                    label: Text("SHARE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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