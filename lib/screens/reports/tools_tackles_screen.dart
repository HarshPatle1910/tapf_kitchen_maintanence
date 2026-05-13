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
  // Unified Minimalistic Color Palette
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _tools = [];
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  // Search State
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch master tools and history logs concurrently
      final toolsFuture = _supabase.from('m_tools').select('id, tool_name').eq('status', true).order('tool_name');
      final logsFuture = _supabase.from('v_tools_tackles_report').select().order('taken_time', ascending: false);

      final results = await Future.wait([toolsFuture, logsFuture]);

      if (mounted) {
        setState(() {
          _tools = List<Map<String, dynamic>>.from(results[0]);
          _logs = List<Map<String, dynamic>>.from(results[1]);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
    String exportMode = 'daily';
    DateTime selectedDate = DateTime.now();
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    String format = 'docx';

    final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    InputDecoration _minimalDialogDecor(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        filled: true, fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary)),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Export Tools Report", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Report Type", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text("Daily", style: GoogleFonts.inter(fontWeight: exportMode == 'daily' ? FontWeight.w600 : FontWeight.normal)),
                      selected: exportMode == 'daily', selectedColor: primary.withOpacity(0.1), backgroundColor: surface, side: BorderSide.none, showCheckmark: false,
                      onSelected: (v) => setDialogState(() => exportMode = 'daily'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text("Monthly", style: GoogleFonts.inter(fontWeight: exportMode == 'monthly' ? FontWeight.w600 : FontWeight.normal)),
                      selected: exportMode == 'monthly', selectedColor: primary.withOpacity(0.1), backgroundColor: surface, side: BorderSide.none, showCheckmark: false,
                      onSelected: (v) => setDialogState(() => exportMode = 'monthly'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (exportMode == 'daily') ...[
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now(),
                        builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primary)), child: child!),
                      );
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _minimalDialogDecor("Select Date"),
                      child: Text("${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}", style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF0F172A), fontSize: 14)),
                    ),
                  )
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: _minimalDialogDecor("Month"), value: selectedMonth, borderRadius: BorderRadius.circular(16), dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i], style: GoogleFonts.inter(fontSize: 14)))),
                          onChanged: (v) => setDialogState(() => selectedMonth = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: _minimalDialogDecor("Year"), value: selectedYear, borderRadius: BorderRadius.circular(16), dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: GoogleFonts.inter(fontSize: 14)))).toList(),
                          onChanged: (v) => setDialogState(() => selectedYear = v!),
                        ),
                      ),
                    ],
                  )
                ],

                const SizedBox(height: 16),
                Text("Format", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                        label: Text("Word (.docx)", style: GoogleFonts.inter(fontWeight: format == 'docx' ? FontWeight.bold : FontWeight.normal)),
                        selected: format == 'docx', selectedColor: primary.withOpacity(0.1), backgroundColor: surface, side: BorderSide.none, showCheckmark: false,
                        onSelected: (v) => setDialogState(() => format = 'docx')
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                        label: Text("PDF (.pdf)", style: GoogleFonts.inter(fontWeight: format == 'pdf' ? FontWeight.bold : FontWeight.normal)),
                        selected: format == 'pdf', selectedColor: primary.withOpacity(0.1), backgroundColor: surface, side: BorderSide.none, showCheckmark: false,
                        onSelected: (v) => setDialogState(() => format = 'pdf')
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.grey.shade600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExport(exportMode, selectedDate, selectedMonth, selectedYear, format);
              },
              child: Text("GENERATE", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _executeExport(String mode, DateTime date, int month, int year, String format) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primary)));

    try {
      Uri url;
      String expectedFilename;

      if (mode == 'daily') {
        final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        url = Uri.parse('$_pythonApiBaseUrl/reports/tools/$dateStr?format=$format');
        expectedFilename = 'Daily_Tools_Report_$dateStr.$format';
      } else {
        final monthStr = "$year-${month.toString().padLeft(2, '0')}";
        url = Uri.parse('$_pythonApiBaseUrl/reports/tools/monthly/$monthStr?format=$format');
        expectedFilename = 'Monthly_Tools_Report_$monthStr.$format';
      }

      final response = await http.get(url);

      if (response.statusCode == 200) {
        Directory? saveDir;
        if (Platform.isAndroid) saveDir = Directory('/storage/emulated/0/Download/Tools Reports');
        else saveDir = Directory('${(await getApplicationDocumentsDirectory()).path}/Tools Reports');
        if (!await saveDir.exists()) await saveDir.create(recursive: true);

        final file = File('${saveDir.path}/$expectedFilename');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context);
        OpenFilex.open(file.path);
      } else throw Exception("Server returned ${response.statusCode}");
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
    }
  }

  // --- HISTORY BOTTOM SHEET ---
  void _showToolHistory(String toolName, List<Map<String, dynamic>> history) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          return DraggableScrollableSheet(
              expand: false, initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9,
              builder: (_, controller) {
                return Column(
                  children: [
                    Container(margin: const EdgeInsets.symmetric(vertical: 12), height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.history, color: primary, size: 20)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Usage History", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                Text(toolName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text("${history.length} Logs", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
                          )
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey.shade100, thickness: 1),

                    Expanded(
                      child: history.isEmpty
                          ? Center(child: Text("No usage history found.", style: GoogleFonts.inter(color: Colors.grey)))
                          : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.all(20),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          final h = history[i];
                          final bool isRet = h['return_time'] != null;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(radius: 12, backgroundColor: surface, child: const Icon(Icons.person_outline, size: 14, color: primary)),
                                        const SizedBox(width: 8),
                                        Text(h['employee_name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), fontSize: 14)),
                                      ],
                                    ),
                                    if (h['ticket_no'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                                        child: Text(h['ticket_no'], style: GoogleFonts.inter(fontSize: 10, color: primary, fontWeight: FontWeight.bold)),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.login, size: 14, color: Colors.grey.shade400),
                                    const SizedBox(width: 6),
                                    Text("${h['taken_date']}  ${h['taken_hour']}", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 24),
                                    Icon(Icons.logout, size: 14, color: isRet ? Colors.grey.shade400 : Colors.orange.shade400),
                                    const SizedBox(width: 6),
                                    Text(
                                        isRet ? "${h['return_hour']}" : "Pending Return",
                                        style: GoogleFonts.inter(fontSize: 13, color: isRet ? Colors.grey.shade600 : Colors.orange.shade700, fontWeight: isRet ? FontWeight.w500 : FontWeight.bold)
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  ],
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter master tools based on search query
    final filteredTools = _tools.where((t) {
      final toolName = (t['tool_name'] ?? '').toString().toLowerCase();
      return toolName.contains(_searchQuery.toLowerCase());
    }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background, foregroundColor: primary, elevation: 0,
          title: Text("Tools Master List", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          actions: [
            IconButton(icon: const Icon(Icons.download_outlined, color: primary), tooltip: "Export Report", onPressed: _showExportDialog)
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primary))
            : Column(
          children: [
            // Minimal Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search Tool Name...",
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      FocusScope.of(context).unfocus();
                    },
                  )
                      : null,
                  filled: true, fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),

            Expanded(
              child: filteredTools.isEmpty
                  ? Center(child: Text("No tools found in master list.", style: GoogleFonts.inter(color: Colors.grey)))
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTools.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final tool = filteredTools[i];
                  final toolName = tool['tool_name'] ?? 'Unknown';

                  // Cross-reference logs to find current status
                  final toolHistory = _logs.where((l) => l['tool_name'] == toolName).toList();
                  final bool isAvailable = toolHistory.isEmpty || toolHistory.first['return_time'] != null;
                  final String currentHolder = !isAvailable ? toolHistory.first['employee_name'] ?? 'Unknown' : '';

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _showToolHistory(toolName, toolHistory);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
                              child: const Icon(Icons.handyman_outlined, color: primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(toolName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), fontSize: 15)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: isAvailable ? Colors.green : Colors.orange),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                          isAvailable ? "Available" : "In use by $currentHolder",
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.grey.shade600, fontSize: 13)
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}