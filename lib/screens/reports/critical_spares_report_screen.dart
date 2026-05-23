import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class CriticalSparesReportScreen extends StatefulWidget {
  const CriticalSparesReportScreen({super.key});

  @override
  State<CriticalSparesReportScreen> createState() => _CriticalSparesReportScreenState();
}

class _CriticalSparesReportScreenState extends State<CriticalSparesReportScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  String? _getActiveKitchenId() {
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    String targetKitchenId = ticketProv.kitchenFilter;

    if (targetKitchenId == 'ALL' || targetKitchenId.isEmpty) {
      if (authProv.assignedKitchens.isNotEmpty) {
        return authProv.assignedKitchens.first['id'].toString();
      }
      return null;
    }
    return targetKitchenId;
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final targetKitchenId = _getActiveKitchenId();

    if (targetKitchenId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await _supabase
          .from('v_critical_spare_parts_report')
          .select()
          .eq('kitchen_id', targetKitchenId)
          .order('spare_type')
          .order('spare_name');

      if (mounted) {
        setState(() {
          _records = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showExportDialog() {
    int expMonth = DateTime.now().month;
    int expYear = DateTime.now().year;
    String format = 'docx';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Export MT-15 Report", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Timeframe", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                      value: expMonth,
                      items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i], style: GoogleFonts.inter(fontSize: 14)))),
                      onChanged: (v) => setDialogState(() => expMonth = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                      value: expYear,
                      items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: GoogleFonts.inter(fontSize: 14)))).toList(),
                      onChanged: (v) => setDialogState(() => expYear = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text("Format", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                      label: Text("Word (.docx)", style: GoogleFonts.inter(fontWeight: format == 'docx' ? FontWeight.bold : FontWeight.normal)),
                      selected: format == 'docx', selectedColor: primary.withOpacity(0.1), side: BorderSide.none,
                      onSelected: (v) => setDialogState(() => format = 'docx')
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                      label: Text("PDF", style: GoogleFonts.inter(fontWeight: format == 'pdf' ? FontWeight.bold : FontWeight.normal)),
                      selected: format == 'pdf', selectedColor: primary.withOpacity(0.1), side: BorderSide.none,
                      onSelected: (v) => setDialogState(() => format = 'pdf')
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.grey.shade600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExport(expMonth, expYear, format);
              },
              child: Text("GENERATE", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeExport(int month, int year, String format) async {
    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primary)));

    try {
      // Constructs the month string parameter e.g., "May_2026"
      final monthString = "${_months[month - 1]}_$year";

      final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/critical-spares/$monthString?kitchen_id=$targetKitchenId&format=$format');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download/Maintenance Reports')
            : Directory('${(await getApplicationDocumentsDirectory()).path}/Maintenance Reports');

        if (!await saveDir.exists()) await saveDir.create(recursive: true);

        final expectedFilename = 'MT15_Critical_Spares_${monthString}.$format';
        final file = File('${saveDir.path}/$expectedFilename');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context); // Close loading dialog
        OpenFilex.open(file.path);
      } else {
        throw Exception("Server returned ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
    }
  }

  IconData _getSpareIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'MECHANICAL': return Icons.settings;
      case 'ELECTRICAL': return Icons.electric_bolt;
      case 'CHEMICAL': return Icons.science;
      default: return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface, foregroundColor: primary, elevation: 0,
        title: Text("MT-15 Critical Spares", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        actions: [IconButton(icon: const Icon(Icons.download_outlined, color: primary), onPressed: _showExportDialog)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _records.isEmpty
          ? Center(child: Text("No critical spare parts found.", style: GoogleFonts.inter(color: Colors.grey)))
          : RefreshIndicator(
        color: primary,
        onRefresh: _fetchData,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final item = _records[i];
            final num onStock = item['on_stock'] ?? 0;
            final num maintainedStock = item['maintained_stock'] ?? 0;
            final bool isLowStock = onStock < maintainedStock;

            return Material(
              color: surface, borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: isLowStock ? Colors.red.shade200 : Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
                      child: Icon(_getSpareIcon(item['spare_type']), color: primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${item['spare_name']}", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text("Code: ${item['spare_code'] ?? 'N/A'}", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          Text("Type: ${item['spare_type'] ?? 'N/A'}", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    // Stock Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isLowStock ? Colors.red.shade100 : Colors.green.shade100)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("$onStock / $maintainedStock", style: GoogleFonts.inter(color: isLowStock ? Colors.red.shade700 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(item['uom'] ?? 'Nos', style: GoogleFonts.inter(color: isLowStock ? Colors.red.shade400 : Colors.green.shade600, fontSize: 10, fontWeight: FontWeight.w600)),
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
    );
  }
}