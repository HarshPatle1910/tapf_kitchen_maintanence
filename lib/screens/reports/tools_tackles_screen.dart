import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ToolsTacklesScreen extends StatefulWidget {
  const ToolsTacklesScreen({super.key});

  @override
  State<ToolsTacklesScreen> createState() => _ToolsTacklesScreenState();
}

class _ToolsTacklesScreenState extends State<ToolsTacklesScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await _supabase
          .from('v_tools_tackles_report')
          .select()
          .order('taken_time', ascending: false);

      if (mounted) {
        setState(() {
          _records = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- EXPORT LOGIC ---
  String get _pythonApiBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (Platform.isAndroid) return 'http://192.168.0.45:8000/api';
    if (Platform.isIOS) return 'http://127.0.0.1:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  void _showExportDialog() {
    String exportMode = 'daily'; // 'daily' or 'monthly'
    DateTime selectedDate = DateTime.now();
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    String format = 'docx'; // NEW: Default to Word

    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Export Tools Report", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text("Daily", style: GoogleFonts.inter(fontSize: 13)),
                        value: 'daily',
                        groupValue: exportMode,
                        onChanged: (v) => setDialogState(() => exportMode = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text("Monthly", style: GoogleFonts.inter(fontSize: 13)),
                        value: 'monthly',
                        groupValue: exportMode,
                        onChanged: (v) => setDialogState(() => exportMode = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (exportMode == 'daily') ...[
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now());
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Select Date",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                      ),
                    ),
                  )
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(labelText: "Month", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          value: selectedMonth,
                          items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))),
                          onChanged: (v) => setDialogState(() => selectedMonth = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(labelText: "Year", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          value: selectedYear,
                          items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                          onChanged: (v) => setDialogState(() => selectedYear = v!),
                        ),
                      ),
                    ],
                  )
                ],

                // NEW: Format Selection
                const SizedBox(height: 16),
                Text("Format:", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChoiceChip(label: const Text("Word (.docx)"), selected: format == 'docx', onSelected: (v) => setDialogState(() => format = 'docx')),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text("PDF (.pdf)"), selected: format == 'pdf', onSelected: (v) => setDialogState(() => format = 'pdf')),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: golden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExport(exportMode, selectedDate, selectedMonth, selectedYear, format); // Passed format
              },
              child: const Text("GENERATE"),
            )
          ],
        ),
      ),
    );
  }

  // UPDATED: Now receives the format argument
  Future<void> _executeExport(String mode, DateTime date, int month, int year, String format) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: golden)));

    try {
      Uri url;
      String expectedFilename;

      if (mode == 'daily') {
        final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        url = Uri.parse('$_pythonApiBaseUrl/reports/tools/$dateStr?format=$format'); // Attached format
        expectedFilename = 'Daily_Tools_Report_$dateStr.$format';
      } else {
        final monthStr = "$year-${month.toString().padLeft(2, '0')}";
        url = Uri.parse('$_pythonApiBaseUrl/reports/tools/monthly/$monthStr?format=$format'); // Attached format
        expectedFilename = 'Monthly_Tools_Report_$monthStr.$format';
      }

      final response = await http.get(url);

      if (response.statusCode == 200) {
        Directory? saveDir;
        if (Platform.isAndroid) {
          saveDir = Directory('/storage/emulated/0/Download/Tools Reports');
        } else {
          saveDir = Directory('${(await getApplicationDocumentsDirectory()).path}/Tools Reports');
        }
        if (!await saveDir.exists()) await saveDir.create(recursive: true);

        final file = File('${saveDir.path}/$expectedFilename');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context);
        OpenFilex.open(file.path);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Export Failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter records based on search query (Tool name, Employee name, or Ticket No)
    final filteredRecords = _records.where((r) {
      final toolName = (r['tool_name'] ?? '').toString().toLowerCase();
      final empName = (r['employee_name'] ?? '').toString().toLowerCase();
      final ticketNo = (r['ticket_no'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return toolName.contains(q) || empName.contains(q) || ticketNo.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        title: Text("Tools & Tackles Record", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: navy),
            tooltip: "Export Report",
            onPressed: _showExportDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: golden))
          : Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search by Tool, Employee, or Ticket...",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden)),
              ),
            ),
          ),
          Expanded(
            child: filteredRecords.isEmpty
                ? Center(child: Text("No records found.", style: GoogleFonts.inter(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRecords.length,
              itemBuilder: (ctx, i) {
                final item = filteredRecords[i];
                final bool isReturned = item['return_time'] != null;

                return Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isReturned ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isReturned ? Icons.check_circle : Icons.handyman,
                            color: isReturned ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['tool_name'] ?? 'Unknown Tool', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: navy, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text("By: ${item['employee_name'] ?? 'Unknown'}", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
                              const SizedBox(height: 8),

                              // Time Row
                              Row(
                                children: [
                                  Icon(Icons.login, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text("${item['taken_date']} ${item['taken_hour']}", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.logout, size: 14, color: isReturned ? Colors.grey.shade500 : Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(isReturned ? item['return_hour'] : "Pending", style: GoogleFonts.inter(color: isReturned ? Colors.grey.shade600 : Colors.orange, fontSize: 12, fontWeight: isReturned ? FontWeight.normal : FontWeight.bold)),
                                ],
                              ),

                              // Ticket ID Tag
                              if (item['ticket_no'] != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: navy.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                                  child: Text("Ticket: ${item['ticket_no']}", style: GoogleFonts.inter(color: navy, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}