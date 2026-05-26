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
class ROChecklistListScreen extends StatefulWidget {
  const ROChecklistListScreen({super.key});

  @override
  State<ROChecklistListScreen> createState() => _ROChecklistListScreenState();
}

class _ROChecklistListScreenState extends State<ROChecklistListScreen> {
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
    if (_selectedYear < 2026) _selectedYear = 2026;
    if (_selectedYear == 2026 && _selectedMonth < 5) _selectedMonth = 5;

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
          .from('daily_ro_checklist_log')
          .select('id, log_date, verified_by')
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
      if (dt.isBefore(DateTime(2026, 5, 1))) continue;
      validDates.add(dt);
    }
    return validDates;
  }

  List<DropdownMenuItem<int>> _getYearItems() {
    int currentYear = DateTime.now().year;
    List<int> years = List.generate((currentYear - 2026) + 1, (i) => 2026 + i);
    return years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))))).toList();
  }

  List<DropdownMenuItem<int>> _getMonthItems() {
    int startMonth = (_selectedYear == 2026) ? 5 : 1;
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
      if (_selectedYear == 2026 && _selectedMonth < 5) _selectedMonth = 5;
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
          title: Text("Export Monthly Report", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
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
      final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/ro-checklist/monthly?kitchen_id=$targetKitchenId&month=$_selectedMonth&year=$_selectedYear&format=$format');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid ? Directory('/storage/emulated/0/Download/Maintenance Reports') : Directory('${(await getApplicationDocumentsDirectory()).path}/Maintenance Reports');
        if (!await saveDir.exists()) await saveDir.create(recursive: true);
        final file = File('${saveDir.path}/MT13_RO_Checklist_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.$format');
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
        title: Text("MT-13 RO Checklist", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: primary),
            tooltip: "Manage Master Templates",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ROMasterTemplateScreen())),
          ),
          IconButton(icon: const Icon(Icons.download_outlined, color: primary), onPressed: _showExportFormatDialog),
        ],
      ),
      body: Column(
        children: [
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
                    value: _selectedMonth, icon: const Icon(Icons.arrow_drop_down, color: primary),
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
                    value: _selectedYear, icon: const Icon(Icons.arrow_drop_down, color: primary),
                    items: _getYearItems(),
                    onChanged: _onYearChanged,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: primary)) : RefreshIndicator(
              color: primary, onRefresh: _fetchData,
              child: ListView.separated(
                padding: const EdgeInsets.all(16), itemCount: dates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final targetDate = dates[dates.length - 1 - i];
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
                            builder: (_) => ROChecklistFormScreen(date: targetDate, kitchenId: targetKitchenId)
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
                              child: Icon(isVerified ? Icons.verified : Icons.water_drop, color: isVerified ? Colors.green : (hasData ? Colors.orange : primary), size: 24),
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
// 2. DAILY ENTRY FORM SCREEN
// ============================================================================
class ROChecklistFormScreen extends StatefulWidget {
  final DateTime date;
  final String kitchenId;

  const ROChecklistFormScreen({super.key, required this.date, required this.kitchenId});

  @override
  State<ROChecklistFormScreen> createState() => _ROChecklistFormScreenState();
}

class _ROChecklistFormScreenState extends State<ROChecklistFormScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _isVerified = false;
  bool _isReadOnly = false;
  String? _logId;

  final _feedWaterCtrl = TextEditingController();
  final _productWaterCtrl = TextEditingController();
  final _rejectWaterCtrl = TextEditingController();

  List<Map<String, dynamic>> _checklistDetails = [];
  final Map<String, TextEditingController> _remarksCtrls = {};

  // Track the master master checkbox state
  bool _isMasterChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  @override
  void dispose() {
    _feedWaterCtrl.dispose();
    _productWaterCtrl.dispose();
    _rejectWaterCtrl.dispose();
    for (var ctrl in _remarksCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _initData() async {
    final dateStr = widget.date.toIso8601String().split('T')[0];

    try {
      final templatesRes = await _supabase.from('m_ro_checklist_template')
          .select().eq('kitchen_id', widget.kitchenId).eq('status', true).order('sequence_no');
      final templates = List<Map<String,dynamic>>.from(templatesRes);

      final logRes = await _supabase.from('daily_ro_checklist_log')
          .select()
          .eq('kitchen_id', widget.kitchenId)
          .eq('log_date', dateStr)
          .maybeSingle();

      if (logRes == null) {
        final newLog = await _supabase.from('daily_ro_checklist_log')
            .insert({'kitchen_id': widget.kitchenId, 'log_date': dateStr, 'feed_water': 0, 'product_water': 0, 'reject_water': 0})
            .select('id').single();
        _logId = newLog['id'];

        List<Map<String, dynamic>> inserts = [];
        for (var t in templates) {
          inserts.add({
            'log_id': _logId, 'procedure_step': t['id'],
            'expected_condition': t['expected_condition'], 'remarks': t['expected_condition'], 'is_checked': false
          });
        }
        if (inserts.isNotEmpty) {
          await _supabase.from('daily_ro_checklist_detail').insert(inserts);
        }

      } else {
        _logId = logRes['id'];
        _feedWaterCtrl.text = logRes['feed_water']?.toString() ?? "0";
        _productWaterCtrl.text = logRes['product_water']?.toString() ?? "0";
        _rejectWaterCtrl.text = logRes['reject_water']?.toString() ?? "0";
        _isVerified = logRes['verified_by'] != null;
        _isReadOnly = _isVerified;

        final detailsRes = await _supabase.from('daily_ro_checklist_detail')
            .select('id, is_checked, remarks, procedure_step, m_ro_checklist_template(sequence_no, procedure_step, expected_condition)')
            .eq('log_id', _logId!);

        List<Map<String, dynamic>> existingDetails = List<Map<String, dynamic>>.from(detailsRes);
        List<String> existingTemplateIds = existingDetails.map((e) => e['procedure_step'].toString()).toList();

        List<Map<String, dynamic>> missingInserts = [];
        for (var t in templates) {
          if (!existingTemplateIds.contains(t['id'].toString())) {
            missingInserts.add({
              'log_id': _logId, 'procedure_step': t['id'],
              'expected_condition': t['expected_condition'], 'remarks': t['expected_condition'], 'is_checked': false
            });
          }
        }

        if (missingInserts.isNotEmpty && !_isReadOnly) {
          await _supabase.from('daily_ro_checklist_detail').insert(missingInserts);
          final updatedDetailsRes = await _supabase.from('daily_ro_checklist_detail')
              .select('id, is_checked, remarks, procedure_step, m_ro_checklist_template(sequence_no, procedure_step, expected_condition)')
              .eq('log_id', _logId!);
          existingDetails = List<Map<String, dynamic>>.from(updatedDetailsRes);
        }

        _checklistDetails = existingDetails;
      }

      if (_checklistDetails.isEmpty && logRes == null) {
        final newDetailsFetch = await _supabase.from('daily_ro_checklist_detail')
            .select('id, is_checked, remarks, procedure_step, m_ro_checklist_template(sequence_no, procedure_step, expected_condition)')
            .eq('log_id', _logId!);
        _checklistDetails = List<Map<String, dynamic>>.from(newDetailsFetch);
      }

      _checklistDetails.sort((a, b) => (a['m_ro_checklist_template']['sequence_no'] as int).compareTo(b['m_ro_checklist_template']['sequence_no'] as int));

      for (var item in _checklistDetails) {
        _remarksCtrls[item['id']] = TextEditingController(text: item['remarks'] ?? '');
      }

      // Sync master check status from state values loaded
      _checkIfAllAreChecked();

    } catch (e) {
      debugPrint("Error initializing RO Form: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // Check if every item is true to accurately show master tick state
  void _checkIfAllAreChecked() {
    if (_checklistDetails.isEmpty) {
      _isMasterChecked = false;
      return;
    }
    bool allChecked = _checklistDetails.every((item) => item['is_checked'] == true);
    setState(() {
      _isMasterChecked = allChecked;
    });
  }

  // Toggles every element based on master state value
  void _toggleMasterCheckbox(bool? value) {
    if (_isReadOnly || value == null) return;
    setState(() {
      _isMasterChecked = value;
      for (var item in _checklistDetails) {
        item['is_checked'] = value;
      }
    });
  }

  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      await _supabase.from('daily_ro_checklist_log').update({
        'feed_water': double.tryParse(_feedWaterCtrl.text) ?? 0,
        'product_water': double.tryParse(_productWaterCtrl.text) ?? 0,
        'reject_water': double.tryParse(_rejectWaterCtrl.text) ?? 0,
        'prepared_by': currentUserId,
        if (_isVerified) 'verified_by': currentUserId,
      }).eq('id', _logId!);

      for (var item in _checklistDetails) {
        await _supabase.from('daily_ro_checklist_detail').update({
          'is_checked': item['is_checked'],
          'remarks': _remarksCtrls[item['id']]!.text,
        }).eq('id', item['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isVerified ? "Checklist Verified & Locked!" : "Draft Saved!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e"), backgroundColor: Colors.red));
    }
  }

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
      final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/ro-checklist/daily?kitchen_id=${widget.kitchenId}&date=$dateStr&format=$format');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid ? Directory('/storage/emulated/0/Download/Maintenance Reports') : Directory('${(await getApplicationDocumentsDirectory()).path}/Maintenance Reports');
        if (!await saveDir.exists()) await saveDir.create(recursive: true);
        final file = File('${saveDir.path}/MT13_RO_Checklist_$dateStr.$format');
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primary)));
    final dateStr = "${widget.date.day.toString().padLeft(2,'0')}/${widget.date.month.toString().padLeft(2,'0')}/${widget.date.year}";

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: surface, foregroundColor: primary, elevation: 0,
          title: Text(_isReadOnly ? "Verified Checklist" : "Checklist - $dateStr", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5, fontSize: 18)),
          actions: [
            if (_logId != null && _isReadOnly)
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
                      Expanded(child: Text("This checklist is verified and locked. You can now download the daily report.", style: GoogleFonts.inter(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 13))),
                    ],
                  ),
                ),

              // WATER METRICS CARD
              Container(
                margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: surface, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_drop, color: primary, size: 20),
                        const SizedBox(width: 8),
                        Text("Plant Parameters", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _feedWaterCtrl, enabled: !_isReadOnly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Feed Water", border: const OutlineInputBorder(), filled: true, fillColor: _isReadOnly ? Colors.grey.shade50 : Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _productWaterCtrl, enabled: !_isReadOnly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Product Water", border: const OutlineInputBorder(), filled: true, fillColor: _isReadOnly ? Colors.grey.shade50 : Colors.white))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _rejectWaterCtrl, enabled: !_isReadOnly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Reject Water", border: const OutlineInputBorder(), filled: true, fillColor: _isReadOnly ? Colors.grey.shade50 : Colors.white))),
                      ],
                    )
                  ],
                ),
              ),

              // REPLACED SECTION HEADER WITH SINGLE MASTER CHECKBOX UI ROW
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Procedures & Checks", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary, fontSize: 16)),
                    if (!_isReadOnly)
                      Row(
                        children: [
                          Text(
                              _isMasterChecked ? "Unmark All" : "Mark All",
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: _isMasterChecked ? Colors.orange.shade800 : Colors.green.shade700)
                          ),
                          const SizedBox(width: 4),
                          Checkbox(
                            value: _isMasterChecked,
                            activeColor: Colors.green.shade700,
                            onChanged: _toggleMasterCheckbox,
                          ),
                        ],
                      )
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // DYNAMIC CHECKLIST
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _checklistDetails.length,
                itemBuilder: (ctx, index) {
                  final item = _checklistDetails[index];
                  final template = item['m_ro_checklist_template'];
                  final itemId = item['id'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: surface, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          activeColor: Colors.green,
                          title: Text("${template['sequence_no']}. ${template['procedure_step']}", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text("Expected: ${template['expected_condition'] ?? 'N/A'}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                          value: item['is_checked'] ?? false,
                          onChanged: _isReadOnly ? null : (val) {
                            setState(() {
                              item['is_checked'] = val ?? false;
                            });
                            _checkIfAllAreChecked(); // Recalculate status values in real-time
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                          child: TextField(
                            controller: _remarksCtrls[itemId],
                            enabled: !_isReadOnly,
                            decoration: InputDecoration(
                                labelText: "Operator Remarks",
                                hintText: "Enter condition observed...",
                                isDense: true,
                                border: const OutlineInputBorder(),
                                filled: true, fillColor: _isReadOnly ? Colors.grey.shade50 : Colors.white
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),

              if (!_isReadOnly)
                Container(
                  margin: const EdgeInsets.only(bottom: 16, top: 16),
                  decoration: BoxDecoration(color: _isVerified ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _isVerified ? Colors.green.shade300 : Colors.orange.shade300)),
                  child: CheckboxListTile(
                    title: Text("Verify and Lock Checklist", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _isVerified ? Colors.green.shade800 : Colors.orange.shade900)),
                    subtitle: Text("Once verified, this list cannot be edited. Required for Daily Export.", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
                    value: _isVerified, activeColor: Colors.green.shade700,
                    checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) { FocusScope.of(context).unfocus(); setState(() => _isVerified = val ?? false); },
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        bottomNavigationBar: _isReadOnly ? null : SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _isVerified ? Colors.green.shade600 : primary, minimumSize: const Size(double.infinity, 54), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _isSaving ? null : _saveRecord,
              child: _isSaving ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isVerified ? "Confirm & Lock" : "Save Draft", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. MASTER TEMPLATE MANAGER SCREEN
// ============================================================================
class ROMasterTemplateScreen extends StatefulWidget {
  const ROMasterTemplateScreen({super.key});

  @override
  State<ROMasterTemplateScreen> createState() => _ROMasterTemplateScreenState();
}

class _ROMasterTemplateScreenState extends State<ROMasterTemplateScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchTemplates());
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

  Future<void> _fetchTemplates() async {
    setState(() => _isLoading = true);
    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId == null) return;

    try {
      final res = await _supabase
          .from('m_ro_checklist_template')
          .select()
          .eq('kitchen_id', targetKitchenId)
          .order('sequence_no');

      if (mounted) {
        setState(() {
          _templates = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showTemplateDialog({Map<String, dynamic>? existingRecord}) {
    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId == null) return;

    final seqCtrl = TextEditingController(text: existingRecord != null ? existingRecord['sequence_no'].toString() : (_templates.length + 1).toString());
    final stepCtrl = TextEditingController(text: existingRecord?['procedure_step'] ?? '');
    final expectCtrl = TextEditingController(text: existingRecord?['expected_condition'] ?? '');
    bool isActive = existingRecord?['status'] ?? true;
    bool isDialogSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existingRecord == null ? "Add Procedure" : "Edit Procedure", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: seqCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Sequence Number", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: stepCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Procedure Step", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: expectCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Expected Condition / Default Remark", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(isActive ? "Active (Visible)" : "Inactive (Hidden)", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: isActive,
                  activeColor: primary,
                  onChanged: (v) => setDialogState(() => isActive = v),
                )
              ],
            ),
          ),
          actions: [
            if (!isDialogSaving)
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              onPressed: isDialogSaving ? null : () async {
                if (stepCtrl.text.isEmpty) return;
                setDialogState(() => isDialogSaving = true);

                try {
                  final data = {
                    'kitchen_id': targetKitchenId,
                    'sequence_no': int.tryParse(seqCtrl.text) ?? 99,
                    'procedure_step': stepCtrl.text.trim(),
                    'expected_condition': expectCtrl.text.trim(),
                    'status': isActive,
                  };
                  if (existingRecord == null) {
                    await _supabase.from('m_ro_checklist_template').insert(data);
                  } else {
                    await _supabase.from('m_ro_checklist_template').update(data).eq('id', existingRecord['id']);
                  }

                  if (mounted) {
                    Navigator.pop(ctx);
                    _fetchTemplates();
                  }
                } catch (e) {
                  setDialogState(() => isDialogSaving = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: isDialogSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("SAVE", style: TextStyle(color: Colors.white)),
            ),
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
        backgroundColor: surface, foregroundColor: primary, elevation: 0,
        title: Text("RO Master Procedures", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: primary)) : _templates.isEmpty ? Center(child: Text("No procedures configured.", style: GoogleFonts.inter(color: Colors.grey))) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (ctx, i) {
          final item = _templates[i];
          final bool isActive = item['status'] == true;
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: isActive ? primary.withOpacity(0.1) : Colors.grey.shade200, child: Text("${item['sequence_no']}", style: TextStyle(color: isActive ? primary : Colors.grey))),
              title: Text("${item['procedure_step']}", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isActive ? Colors.black87 : Colors.grey)),
              subtitle: Text("Expected: ${item['expected_condition'] ?? '-'}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              trailing: IconButton(icon: const Icon(Icons.edit, color: primary), onPressed: () => _showTemplateDialog(existingRecord: item)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Step", style: TextStyle(color: Colors.white)),
        onPressed: () => _showTemplateDialog(),
      ),
    );
  }
}