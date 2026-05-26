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

// ============================================================================
// 1. DASHBOARD LIST SCREEN
// ============================================================================
class ElectricalLogListScreen extends StatefulWidget {
  const ElectricalLogListScreen({super.key});

  @override
  State<ElectricalLogListScreen> createState() => _ElectricalLogListScreenState();
}

class _ElectricalLogListScreenState extends State<ElectricalLogListScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    // Clamp to minimum constraints (May 2025)
    if (_selectedYear < 2025) _selectedYear = 2025;
    if (_selectedYear == 2025 && _selectedMonth < 5) _selectedMonth = 5;

    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  String? _getActiveKitchenId() {
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    String targetKitchenId = ticketProv.kitchenFilter;
    if (targetKitchenId == 'ALL' || targetKitchenId.isEmpty) {
      if (authProv.assignedKitchens.isNotEmpty) return authProv.assignedKitchens.first['id'].toString();
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
      final startDate = DateTime(_selectedYear, _selectedMonth, 1).toIso8601String().split('T')[0];
      final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0).toIso8601String().split('T')[0];

      final res = await _supabase
          .from('daily_electrical_log')
          .select('id, log_date, verified_by, daily_kwh_consumption')
          .eq('kitchen_id', targetKitchenId)
          .gte('log_date', startDate)
          .lte('log_date', endDate);

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

  List<DateTime> _getDatesForMonth() {
    final now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);

    int targetDays = (_selectedYear == now.year && _selectedMonth == now.month) ? now.day : daysInMonth;

    List<DateTime> validDates = [];
    for (int i = 1; i <= targetDays; i++) {
      DateTime dt = DateTime(_selectedYear, _selectedMonth, i);
      // Hard clamp: Do not show dates before May 1, 2025
      if (dt.isBefore(DateTime(2026, 5, 1))) continue;
      validDates.add(dt);
    }
    return validDates;
  }

  // Generate Year Items dynamically (From 2025 to Current Year)
  List<DropdownMenuItem<int>> _getYearItems() {
    int currentYear = DateTime.now().year;
    List<int> years = List.generate((currentYear - 2025) + 1, (i) => 2025 + i);
    return years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))))).toList();
  }

  // Generate Month Items dynamically (Enforce May 2025 start, and cap at Current Month)
  List<DropdownMenuItem<int>> _getMonthItems() {
    int startMonth = (_selectedYear == 2025) ? 5 : 1; // May is month 5
    int endMonth = (_selectedYear == DateTime.now().year) ? DateTime.now().month : 12;

    List<DropdownMenuItem<int>> items = [];
    for (int m = startMonth; m <= endMonth; m++) {
      items.add(DropdownMenuItem(value: m, child: Text(_months[m - 1], style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)))));
    }
    return items;
  }

  void _onYearChanged(int? newYear) {
    if (newYear == null) return;
    setState(() {
      _selectedYear = newYear;
      // Re-clamp month if out of bounds for the newly selected year
      if (_selectedYear == 2025 && _selectedMonth < 5) _selectedMonth = 5;
      if (_selectedYear == DateTime.now().year && _selectedMonth > DateTime.now().month) _selectedMonth = DateTime.now().month;
    });
    _fetchData();
  }

  void _showExportFormatDialog() {
    String format = 'xlsx';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Export Monthly Log", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: primary.withOpacity(0.1))),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Generating report for ${_months[_selectedMonth - 1]} $_selectedYear.", style: GoogleFonts.inter(fontSize: 13, color: primary, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("Select Format", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(label: Text("Excel (.xlsx)", style: GoogleFonts.inter(fontWeight: format == 'xlsx' ? FontWeight.bold : FontWeight.normal)), selected: format == 'xlsx', selectedColor: primary.withOpacity(0.1), side: BorderSide(color: format == 'xlsx' ? primary : Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), onSelected: (v) => setDialogState(() => format = 'xlsx')),
                  const SizedBox(width: 10),
                  ChoiceChip(label: Text("PDF", style: GoogleFonts.inter(fontWeight: format == 'pdf' ? FontWeight.bold : FontWeight.normal)), selected: format == 'pdf', selectedColor: primary.withOpacity(0.1), side: BorderSide(color: format == 'pdf' ? primary : Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), onSelected: (v) => setDialogState(() => format = 'pdf')),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), elevation: 0),
              onPressed: () { Navigator.pop(ctx); _executeExport(format); },
              child: Text("DOWNLOAD", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeExport(String format) async {
    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId == null) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primary)));

    try {
      final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/electrical-log/monthly?kitchen_id=$targetKitchenId&month=$_selectedMonth&year=$_selectedYear&format=$format');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid ? Directory('/storage/emulated/0/Download/Maintenance Reports') : Directory('${(await getApplicationDocumentsDirectory()).path}/Maintenance Reports');
        if (!await saveDir.exists()) await saveDir.create(recursive: true);
        final file = File('${saveDir.path}/MT10_Electrical_Log_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.$format');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) Navigator.pop(context);
        OpenFilex.open(file.path);
      } else { throw Exception("Server returned ${response.statusCode}"); }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetKitchenId = _getActiveKitchenId();
    final dates = _getDatesForMonth();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface, foregroundColor: primary, elevation: 0,
        title: Text("MT-10 Electrical Log", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        actions: [IconButton(icon: const Icon(Icons.download_outlined, color: primary), onPressed: _showExportFormatDialog)],
      ),
      body: Column(
        children: [
          // ROUNDED FILTERS
          Container(
            color: surface, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    borderRadius: BorderRadius.circular(24), dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    value: _selectedMonth,
                    icon: const Icon(Icons.arrow_drop_down, color: primary),
                    items: _getMonthItems(),
                    onChanged: (v) { setState(() => _selectedMonth = v!); _fetchData(); },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    borderRadius: BorderRadius.circular(24), dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    value: _selectedYear,
                    icon: const Icon(Icons.arrow_drop_down, color: primary),
                    items: _getYearItems(),
                    onChanged: _onYearChanged,
                  ),
                ),
              ],
            ),
          ),
          // DATE LIST
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: primary)) : RefreshIndicator(
              color: primary, onRefresh: _fetchData,
              child: ListView.separated(
                padding: const EdgeInsets.all(16), itemCount: dates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final targetDate = dates[dates.length - 1 - i]; // Newest first
                  final dateStr = targetDate.toIso8601String().split('T')[0];
                  final existingRecord = _records.cast<Map<String, dynamic>?>().firstWhere((r) => r?['log_date'] == dateStr, orElse: () => null);

                  final bool hasData = existingRecord != null;
                  final bool isVerified = existingRecord != null && existingRecord['verified_by'] != null;

                  return Material(
                    color: surface, borderRadius: BorderRadius.circular(16), elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        if (targetKitchenId == null) return;
                        final result = await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ElectricalLogFormScreen(date: targetDate, kitchenId: targetKitchenId, existingLogId: existingRecord?['id'])
                        ));
                        if (result == true) _fetchData();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: isVerified ? Colors.green.shade50 : (hasData ? Colors.orange.shade50 : const Color(0xFFF8FAFC)), borderRadius: BorderRadius.circular(12), border: Border.all(color: isVerified ? Colors.green.shade100 : (hasData ? Colors.orange.shade100 : Colors.grey.shade100))),
                              child: Icon(isVerified ? Icons.verified : Icons.electric_meter, color: isVerified ? Colors.green : (hasData ? Colors.orange : primary), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${targetDate.day.toString().padLeft(2,'0')} ${_months[targetDate.month - 1]} ${targetDate.year}", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: isVerified ? Colors.green.shade50 : (hasData ? Colors.orange.shade50 : Colors.grey.shade100), borderRadius: BorderRadius.circular(6)),
                                        child: Text(isVerified ? "Verified & Locked" : (hasData ? "Draft Saved" : "No Entry"), style: GoogleFonts.inter(color: isVerified ? Colors.green.shade700 : (hasData ? Colors.orange.shade800 : Colors.grey.shade600), fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
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
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. ENTRY FORM SCREEN (WITH DAILY EXPORT)
// ============================================================================
class ElectricalLogFormScreen extends StatefulWidget {
  final DateTime date;
  final String kitchenId;
  final String? existingLogId;

  const ElectricalLogFormScreen({super.key, required this.date, required this.kitchenId, this.existingLogId});

  @override
  State<ElectricalLogFormScreen> createState() => _ElectricalLogFormScreenState();
}

class _ElectricalLogFormScreenState extends State<ElectricalLogFormScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _isVerified = false;
  bool _isReadOnly = false;

  String? _dailyLogId;
  String _kwhOpening = "0.0";
  String _kvahOpening = "0.0";

  final _kwhClosingCtrl = TextEditingController();
  final _kvahClosingCtrl = TextEditingController();

  final List<String> _timeSlots = ['06:00:00', '10:00:00', '14:00:00', '18:00:00', '22:00:00'];
  final Map<String, Map<String, TextEditingController>> _slotCtrls = {};

  @override
  void initState() {
    super.initState();
    for (var time in _timeSlots) {
      _slotCtrls[time] = {
        'ht_voltage': TextEditingController(), 'tap_no': TextEditingController(),
        'lt_voltage': TextEditingController(), 'lt_amps': TextEditingController(),
        'frequency': TextEditingController(), 'power_factor': TextEditingController(), 'remarks': TextEditingController(),
      };
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  @override
  void dispose() {
    _kwhClosingCtrl.dispose(); _kvahClosingCtrl.dispose();
    for (var slot in _slotCtrls.values) { for (var ctrl in slot.values) { ctrl.dispose(); } }
    super.dispose();
  }

  Future<void> _initData() async {
    _dailyLogId = widget.existingLogId;

    if (_dailyLogId != null) {
      try {
        final masterRes = await _supabase.from('daily_electrical_log').select().eq('id', _dailyLogId!).single();
        _isVerified = masterRes['verified_by'] != null;
        _isReadOnly = _isVerified;

        _kwhOpening = masterRes['kwh_opening']?.toString() ?? "0.0";
        _kvahOpening = masterRes['kvah_opening']?.toString() ?? "0.0";
        _kwhClosingCtrl.text = masterRes['kwh_closing']?.toString() ?? "";
        _kvahClosingCtrl.text = masterRes['kvah_closing']?.toString() ?? "";

        final readingsRes = await _supabase.from('electrical_log_reading').select().eq('daily_log_id', _dailyLogId!);
        final List<dynamic> readings = readingsRes;

        for (var row in readings) {
          final time = row['reading_time'].toString();
          if (_slotCtrls.containsKey(time)) {
            _slotCtrls[time]!['ht_voltage']!.text = row['ht_voltage']?.toString() ?? '';
            _slotCtrls[time]!['tap_no']!.text = row['tap_no']?.toString() ?? '';
            _slotCtrls[time]!['lt_voltage']!.text = row['lt_voltage']?.toString() ?? '';
            _slotCtrls[time]!['lt_amps']!.text = row['lt_amps']?.toString() ?? '';
            _slotCtrls[time]!['frequency']!.text = row['frequency']?.toString() ?? '';
            _slotCtrls[time]!['power_factor']!.text = row['power_factor']?.toString() ?? '';
            _slotCtrls[time]!['remarks']!.text = row['remarks']?.toString() ?? '';
          }
        }
      } catch (e) { debugPrint("Error loading log: $e"); }
    } else {
      try {
        final prevRes = await _supabase.from('daily_electrical_log').select('kwh_closing, kvah_closing').eq('kitchen_id', widget.kitchenId).lt('log_date', widget.date.toIso8601String().split('T')[0]).order('log_date', ascending: false).limit(1);
        if (prevRes.isNotEmpty) {
          _kwhOpening = prevRes.first['kwh_closing']?.toString() ?? "0.0";
          _kvahOpening = prevRes.first['kvah_closing']?.toString() ?? "0.0";
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final masterData = {
        'kitchen_id': widget.kitchenId,
        'log_date': widget.date.toIso8601String().split('T')[0],
        'kwh_closing': double.tryParse(_kwhClosingCtrl.text) ?? 0,
        'kvah_closing': double.tryParse(_kvahClosingCtrl.text) ?? 0,
        'prepared_by': currentUserId,
        if (_isVerified) 'verified_by': currentUserId,
      };

      final upsertRes = await _supabase.from('daily_electrical_log').upsert(masterData, onConflict: 'kitchen_id, log_date').select('id').single();
      final activeLogId = upsertRes['id'];

      List<Map<String, dynamic>> readingsToInsert = [];
      for (var time in _timeSlots) {
        final ctrls = _slotCtrls[time]!;
        if (ctrls['ht_voltage']!.text.isNotEmpty || ctrls['lt_voltage']!.text.isNotEmpty || ctrls['lt_amps']!.text.isNotEmpty) {
          readingsToInsert.add({
            'daily_log_id': activeLogId,
            'reading_time': time,
            'ht_voltage': double.tryParse(ctrls['ht_voltage']!.text),
            'tap_no': ctrls['tap_no']!.text,
            'lt_voltage': double.tryParse(ctrls['lt_voltage']!.text),
            'lt_amps': double.tryParse(ctrls['lt_amps']!.text),
            'frequency': double.tryParse(ctrls['frequency']!.text),
            'power_factor': double.tryParse(ctrls['power_factor']!.text),
            'remarks': ctrls['remarks']!.text,
            'logged_by': currentUserId,
          });
        }
      }

      await _supabase.from('electrical_log_reading').delete().eq('daily_log_id', activeLogId);
      if (readingsToInsert.isNotEmpty) {
        await _supabase.from('electrical_log_reading').insert(readingsToInsert);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isVerified ? "Log Verified & Locked!" : "Draft Saved!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- DAILY EXPORT FEATURE ---
  void _showDailyExportFormatDialog() {
    String format = 'xlsx';
    final dateStr = widget.date.toIso8601String().split('T')[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Export Daily Log", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Exporting report for $dateStr.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              Text("Select Format", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(label: Text("Excel", style: GoogleFonts.inter(fontWeight: format == 'xlsx' ? FontWeight.bold : FontWeight.normal)), selected: format == 'xlsx', selectedColor: primary.withOpacity(0.1), side: BorderSide(color: format == 'xlsx' ? primary : Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), onSelected: (v) => setDialogState(() => format = 'xlsx')),
                  const SizedBox(width: 10),
                  ChoiceChip(label: Text("PDF", style: GoogleFonts.inter(fontWeight: format == 'pdf' ? FontWeight.bold : FontWeight.normal)), selected: format == 'pdf', selectedColor: primary.withOpacity(0.1), side: BorderSide(color: format == 'pdf' ? primary : Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), onSelected: (v) => setDialogState(() => format = 'pdf')),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), elevation: 0),
              onPressed: () { Navigator.pop(ctx); _executeDailyExport(dateStr, format); },
              child: Text("DOWNLOAD", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeDailyExport(String dateStr, String format) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primary)));
    try {
      final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/electrical-log/daily?kitchen_id=${widget.kitchenId}&date=$dateStr&format=$format');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid ? Directory('/storage/emulated/0/Download/Maintenance Reports') : Directory('${(await getApplicationDocumentsDirectory()).path}/Maintenance Reports');
        if (!await saveDir.exists()) await saveDir.create(recursive: true);
        final file = File('${saveDir.path}/MT10_Electrical_Daily_$dateStr.$format');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) Navigator.pop(context);
        OpenFilex.open(file.path);
      } else { throw Exception("Server returned ${response.statusCode}"); }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
    }
  }

  InputDecoration _decor(String label, {String? suffix}) {
    return InputDecoration(
      labelText: label, suffixText: suffix,
      labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
      filled: true, fillColor: _isReadOnly ? Colors.grey.shade50 : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary)),
    );
  }

  Widget _buildMetricRow(String l1, TextEditingController c1, String l2, TextEditingController c2, {String? s1, String? s2, bool isNumeric = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: TextField(controller: c1, enabled: !_isReadOnly, keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: _decor(l1, suffix: s1))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: c2, enabled: !_isReadOnly, keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: _decor(l2, suffix: s2))),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(String time) {
    final ctrls = _slotCtrls[time]!;
    final hour = int.parse(time.substring(0, 2));
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final uiTime = "${formattedHour.toString().padLeft(2,'0')}:${time.substring(3,5)} $ampm";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: surface, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: primary, iconColor: primary,
          title: Text("Reading at $uiTime", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), fontSize: 15)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0).copyWith(top: 0),
              child: Column(
                children: [
                  _buildMetricRow("HT Voltage", ctrls['ht_voltage']!, "Tap No", ctrls['tap_no']!, s1: "kV", isNumeric: false),
                  _buildMetricRow("LT Voltage", ctrls['lt_voltage']!, "LT Amps", ctrls['lt_amps']!, s1: "V", s2: "A"),
                  _buildMetricRow("Frequency", ctrls['frequency']!, "Power Factor", ctrls['power_factor']!, s1: "Hz"),
                  TextField(controller: ctrls['remarks']!, enabled: !_isReadOnly, maxLines: 2, decoration: _decor("Remarks / Observations")),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primary)));
    final dateStr = "${widget.date.day.toString().padLeft(2,'0')}/${widget.date.month.toString().padLeft(2,'0')}/${widget.date.year}";

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: surface, foregroundColor: primary, elevation: 0,
          title: Text(_isReadOnly ? "View Verified Log" : "Edit Log - $dateStr", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5, fontSize: 18)),
          actions: [
            // Daily Export Button (Visible only if a record exists)
            if (_dailyLogId != null)
              IconButton(icon: const Icon(Icons.download_rounded, color: primary), onPressed: _showDailyExportFormatDialog),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isReadOnly)
                Container(
                  width: double.infinity, margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text("This electrical log is verified and permanently locked.", style: GoogleFonts.inter(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 13))),
                    ],
                  ),
                ),

              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: surface, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, color: primary, size: 20),
                        const SizedBox(width: 8),
                        Text("Daily Meter Consumption", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Text("KWH Opening: $_kwhOpening", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500))),
                        Expanded(child: Text("KVAH Opening: $_kvahOpening", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMetricRow("Closing KWH", _kwhClosingCtrl, "Closing KVAH", _kvahClosingCtrl),
                  ],
                ),
              ),

              Text("Hourly Readings", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary, fontSize: 16)),
              const SizedBox(height: 12),

              ..._timeSlots.map((t) => _buildTimeSlotCard(t)),

              if (!_isReadOnly)
                Container(
                  margin: const EdgeInsets.only(bottom: 16, top: 16),
                  decoration: BoxDecoration(
                      color: _isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isVerified ? Colors.green.shade300 : Colors.orange.shade300)
                  ),
                  child: CheckboxListTile(
                    title: Text("Verify and Lock this Log", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _isVerified ? Colors.green.shade800 : Colors.orange.shade900)),
                    subtitle: Text("Once verified, these readings cannot be edited.", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
                    value: _isVerified,
                    activeColor: Colors.green.shade700,
                    checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      FocusScope.of(context).unfocus();
                      setState(() => _isVerified = val ?? false);
                    },
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
        bottomNavigationBar: _isReadOnly
            ? null
            : SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _isVerified ? Colors.green.shade600 : primary,
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: _isSaving ? null : _saveRecord,
              child: _isSaving
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isVerified ? "Confirm & Lock Log" : "Save Draft", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}