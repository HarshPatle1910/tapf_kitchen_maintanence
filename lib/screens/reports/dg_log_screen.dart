import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

// ============================================================================
// 1. DASHBOARD LIST SCREEN
// ============================================================================
class DGLogListScreen extends StatefulWidget {
  const DGLogListScreen({super.key});

  @override
  State<DGLogListScreen> createState() => _DGLogListScreenState();
}

class _DGLogListScreenState extends State<DGLogListScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  // Filter State
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

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
      final startDate = DateTime(_selectedYear, _selectedMonth, 1).toIso8601String().split('T')[0];
      final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0).toIso8601String().split('T')[0];

      final res = await _supabase
          .from('v_dg_set_logbook')
          .select()
          .eq('kitchen_id', targetKitchenId)
          .gte('log_date', startDate)
          .lte('log_date', endDate)
          .order('log_date', ascending: false);

      List<Map<String, dynamic>> fetchedRecords = List<Map<String, dynamic>>.from(res);

      // =================================================================
      // FAIL-SAFE: If it's the current month, ensure TODAY's record exists
      // (In case the Python Cron Job failed or hasn't run yet)
      // =================================================================
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final isCurrentMonth = _selectedMonth == DateTime.now().month && _selectedYear == DateTime.now().year;

      if (isCurrentMonth) {
        final todayExists = fetchedRecords.any((r) => r['log_date'] == todayStr);
        if (!todayExists) {
          // Create blank row for today dynamically
          await _supabase.from('dg_set_logbook').insert({
            'kitchen_id': targetKitchenId,
            'log_date': todayStr,
            'is_verified': false
          });

          // Re-fetch to get the newly created row with the proper view joins (kitchen_name)
          final reFetch = await _supabase
              .from('v_dg_set_logbook')
              .select()
              .eq('kitchen_id', targetKitchenId)
              .gte('log_date', startDate)
              .lte('log_date', endDate)
              .order('log_date', ascending: false);
          fetchedRecords = List<Map<String, dynamic>>.from(reFetch);
        }
      }

      if (mounted) {
        setState(() {
          _records = fetchedRecords;
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
    int expMonth = _selectedMonth;
    int expYear = _selectedYear;
    String format = 'xlsx';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Export MT-14 Report", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
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
                  ChoiceChip(label: Text("Excel", style: GoogleFonts.inter(fontWeight: format == 'xlsx' ? FontWeight.bold : FontWeight.normal)), selected: format == 'xlsx', selectedColor: primary.withOpacity(0.1), side: BorderSide.none, onSelected: (v) => setDialogState(() => format = 'xlsx')),
                  const SizedBox(width: 8),
                  ChoiceChip(label: Text("PDF", style: GoogleFonts.inter(fontWeight: format == 'pdf' ? FontWeight.bold : FontWeight.normal)), selected: format == 'pdf', selectedColor: primary.withOpacity(0.1), side: BorderSide.none, onSelected: (v) => setDialogState(() => format = 'pdf')),
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
      final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/dg-set?kitchen_id=$targetKitchenId&month=$month&year=$year&format=$format');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid ? Directory('/storage/emulated/0/Download/DG Reports') : Directory('${(await getApplicationDocumentsDirectory()).path}/DG Reports');
        if (!await saveDir.exists()) await saveDir.create(recursive: true);

        final expectedFilename = 'MT14_DG_Report_${year}_${month.toString().padLeft(2, '0')}.$format';
        final file = File('${saveDir.path}/$expectedFilename');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context);
        OpenFilex.open(file.path);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface, foregroundColor: primary, elevation: 0,
        title: Text("MT-14 DG Logbook", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        actions: [IconButton(icon: const Icon(Icons.download_outlined, color: primary), onPressed: _showExportDialog)],
      ),
      body: Column(
        children: [
          // MONTH & YEAR FILTER HEADER
          Container(
            color: surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    value: _selectedMonth,
                    icon: const Icon(Icons.arrow_drop_down, color: primary),
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i], style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))))),
                    onChanged: (v) {
                      setState(() => _selectedMonth = v!);
                      _fetchData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    value: _selectedYear,
                    icon: const Icon(Icons.arrow_drop_down, color: primary),
                    items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedYear = v!);
                      _fetchData();
                    },
                  ),
                ),
              ],
            ),
          ),

          // RECORDS LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _records.isEmpty
                ? Center(child: Text("No DG logs found for ${_months[_selectedMonth - 1]} $_selectedYear.", style: GoogleFonts.inter(color: Colors.grey)))
                : RefreshIndicator(
              color: primary,
              onRefresh: _fetchData,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _records.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final item = _records[i];
                  final bool isVerified = item['is_verified'] == true;

                  // Check if the record is completely blank (just generated)
                  final bool isBlank = item['total_running_hours'] == null && item['total_kwh'] == null;

                  return Material(
                    color: surface, borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => DGLogFormScreen(existingRecord: item)));
                        if (result == true) _fetchData();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: isVerified ? Colors.green.shade50 : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isVerified ? Colors.green.shade200 : Colors.grey.shade100)
                              ),
                              child: Icon(isVerified ? Icons.verified : Icons.bolt, color: isVerified ? Colors.green : primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text("${item['log_date']}", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [

                                      // BADGE LOGIC
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: isVerified ? Colors.green.shade50 : (isBlank ? Colors.grey.shade100 : Colors.orange.shade50),
                                            borderRadius: BorderRadius.circular(4)
                                        ),
                                        child: Row(
                                          children: [
                                            if (isVerified) ...[
                                              Icon(Icons.draw, size: 10, color: Colors.green.shade700),
                                              const SizedBox(width: 4),
                                              Text("Signed & Verified", style: GoogleFonts.inter(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ] else if (isBlank) ...[
                                              Text("Needs Action", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ] else ...[
                                              Text("Pending Verification", style: GoogleFonts.inter(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isBlank) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                                          child: Text("${item['total_running_hours']} H", style: GoogleFonts.inter(color: primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                          child: Text("${item['total_kwh']} kWH", style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    )
                                  ]
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
      // FAB REMOVED - All additions are handled by the auto-provisioner!
    );
  }
}

// ============================================================================
// 2. CREATE / EDIT FORM SCREEN (With Verification Logic)
// ============================================================================
class DGLogFormScreen extends StatefulWidget {
  final Map<String, dynamic> existingRecord;
  const DGLogFormScreen({super.key, required this.existingRecord});

  @override
  State<DGLogFormScreen> createState() => _DGLogFormScreenState();
}

class _DGLogFormScreenState extends State<DGLogFormScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _isVerified = false;
  bool _isReadOnly = false;

  late String _kitchenId;
  late String _kitchenName;
  late DateTime _logDate;

  final _coolantTempCtrl = TextEditingController();
  final _engineOilTempCtrl = TextEditingController();
  final _batteryVoltageCtrl = TextEditingController();
  final _dgFrequencyCtrl = TextEditingController();
  final _engineOilPressureCtrl = TextEditingController();
  final _runningHoursCtrl = TextEditingController();
  final _totalKwhCtrl = TextEditingController();
  final _dieselFillCtrl = TextEditingController();
  final _dieselConsCtrl = TextEditingController();
  final _dieselStockCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.transparent,
  );
  String? _existingSignatureUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  @override
  void dispose() {
    _coolantTempCtrl.dispose(); _engineOilTempCtrl.dispose(); _batteryVoltageCtrl.dispose();
    _dgFrequencyCtrl.dispose(); _engineOilPressureCtrl.dispose(); _runningHoursCtrl.dispose();
    _totalKwhCtrl.dispose(); _dieselFillCtrl.dispose(); _dieselConsCtrl.dispose();
    _dieselStockCtrl.dispose(); _remarksCtrl.dispose(); _signatureController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final r = widget.existingRecord;

    _isVerified = r['is_verified'] == true;
    _isReadOnly = _isVerified;

    _kitchenId = r['kitchen_id']?.toString() ?? '';
    _kitchenName = r['kitchen_name'] ?? 'Facility';
    _logDate = DateTime.tryParse(r['log_date']) ?? DateTime.now();

    _coolantTempCtrl.text = r['coolant_temperature']?.toString() ?? '';
    _engineOilTempCtrl.text = r['engine_oil_temperature']?.toString() ?? '';
    _batteryVoltageCtrl.text = r['battery_voltage']?.toString() ?? '';
    _dgFrequencyCtrl.text = r['dg_frequency']?.toString() ?? '';
    _engineOilPressureCtrl.text = r['engine_oil_pressure']?.toString() ?? '';
    _runningHoursCtrl.text = r['total_running_hours']?.toString() ?? '';
    _totalKwhCtrl.text = r['total_kwh']?.toString() ?? '';
    _dieselFillCtrl.text = r['diesel_fill']?.toString() ?? '';
    _dieselConsCtrl.text = r['diesel_consumption']?.toString() ?? '';
    _dieselStockCtrl.text = r['diesel_stock']?.toString() ?? '';
    _remarksCtrl.text = r['remarks'] ?? '';

    if (r['signature'] != null && !r['signature'].toString().startsWith('http')) {
      _existingSignatureUrl = _supabase.storage.from('ticket-media').getPublicUrl(r['signature']);
    } else {
      _existingSignatureUrl = r['signature'];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);
    try {
      String? finalSignatureUrl = _existingSignatureUrl;

      if (_signatureController.isNotEmpty) {
        final Uint8List? signatureBytes = await _signatureController.toPngBytes();
        if (signatureBytes != null) {
          final fileName = 'dg_signatures/${DateTime.now().millisecondsSinceEpoch}.png';
          await _supabase.storage.from('ticket-media').uploadBinary(fileName, signatureBytes);
          finalSignatureUrl = fileName;
        }
      }

      final data = {
        'coolant_temperature': double.tryParse(_coolantTempCtrl.text),
        'engine_oil_temperature': double.tryParse(_engineOilTempCtrl.text),
        'battery_voltage': double.tryParse(_batteryVoltageCtrl.text),
        'dg_frequency': double.tryParse(_dgFrequencyCtrl.text),
        'engine_oil_pressure': double.tryParse(_engineOilPressureCtrl.text),
        'total_running_hours': double.tryParse(_runningHoursCtrl.text),
        'total_kwh': double.tryParse(_totalKwhCtrl.text),
        'diesel_fill': double.tryParse(_dieselFillCtrl.text),
        'diesel_consumption': double.tryParse(_dieselConsCtrl.text),
        'diesel_stock': double.tryParse(_dieselStockCtrl.text),
        'signature': finalSignatureUrl,
        'remarks': _remarksCtrl.text.trim(),
        'is_verified': _isVerified,
      };

      // ALWAYS UPDATE (Because row is auto-generated initially)
      await _supabase.from('dg_set_logbook').update(data).eq('id', widget.existingRecord['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isVerified ? "Log Verified & Locked!" : "Log Saved!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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

  Widget _buildMetricRow(String l1, TextEditingController c1, String s1, String l2, TextEditingController c2, String s2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: TextField(controller: c1, enabled: !_isReadOnly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _decor(l1, suffix: s1))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: c2, enabled: !_isReadOnly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _decor(l2, suffix: s2))),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: surface, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primary)));
    final bool isBlank = widget.existingRecord['total_running_hours'] == null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
            backgroundColor: surface, foregroundColor: primary, elevation: 0,
            title: Text(_isReadOnly ? "View Confirmed Log" : (isBlank ? "Fill Log Entry" : "Edit Log Entry"), style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5))
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
                      Expanded(child: Text("This log has been verified and is permanently locked.", style: GoogleFonts.inter(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 13))),
                    ],
                  ),
                ),

              _buildSectionCard(
                  title: "General Specifications", icon: Icons.info_outline,
                  children: [
                    TextFormField(
                      initialValue: _kitchenName, enabled: false,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      decoration: _decor("Assigned Facility/Kitchen").copyWith(prefixIcon: const Icon(Icons.storefront, size: 20, color: Colors.grey)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: "${_logDate.day.toString().padLeft(2, '0')}-${_logDate.month.toString().padLeft(2, '0')}-${_logDate.year}", enabled: false,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      decoration: _decor("Log Entry Date").copyWith(prefixIcon: const Icon(Icons.calendar_today, size: 18, color: Colors.grey)),
                    ),
                  ]
              ),

              _buildSectionCard(
                  title: "Engine Parameters", icon: Icons.engineering_outlined,
                  children: [
                    _buildMetricRow("Coolant Temp", _coolantTempCtrl, "°C", "Oil Temp", _engineOilTempCtrl, "°C"),
                    _buildMetricRow("Oil Pressure", _engineOilPressureCtrl, "Bar", "Running Hours", _runningHoursCtrl, "H"),
                  ]
              ),

              _buildSectionCard(
                  title: "Electrical Metrics", icon: Icons.electrical_services_outlined,
                  children: [
                    _buildMetricRow("Battery Volts", _batteryVoltageCtrl, "V", "Frequency", _dgFrequencyCtrl, "Hz"),
                    TextField(controller: _totalKwhCtrl, enabled: !_isReadOnly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _decor("Total Meter KWH", suffix: "kWH")),
                  ]
              ),

              _buildSectionCard(
                  title: "Diesel Tracking", icon: Icons.local_gas_station_outlined,
                  children: [
                    _buildMetricRow("Diesel Added", _dieselFillCtrl, "L", "Consumption", _dieselConsCtrl, "L"),
                    TextField(controller: _dieselStockCtrl, enabled: !_isReadOnly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _decor("Diesel Stock Status", suffix: "%")),
                  ]
              ),

              _buildSectionCard(
                  title: "Observations & Confirmations", icon: Icons.draw_outlined,
                  children: [
                    TextField(controller: _remarksCtrl, enabled: !_isReadOnly, maxLines: 3, decoration: _decor("Enter observations or write standard notes here...")),
                    const SizedBox(height: 20),
                    Text("Operator Verification Signature", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),

                    if (_existingSignatureUrl != null) ...[
                      Container(
                        height: 140, width: double.infinity,
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_existingSignatureUrl!, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Center(child: Text("Signature unavailable")))),
                      ),
                      if (!_isReadOnly)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _existingSignatureUrl = null),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text("Redraw", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        )
                    ] else if (!_isReadOnly) ...[
                      Container(
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: primary.withOpacity(0.3), width: 1.5), borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Signature(controller: _signatureController, height: 140, backgroundColor: const Color(0xFFF8FAFC))),
                      ),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                              onPressed: () => _signatureController.clear(),
                              icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                              label: Text("Clear Canvas", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.red))
                          )
                      )
                    ] else ...[
                      Container(
                        height: 140, width: double.infinity,
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text("No signature recorded", style: TextStyle(color: Colors.grey))),
                      ),
                    ],
                  ]
              ),

              if (!_isReadOnly)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: _isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isVerified ? Colors.green.shade300 : Colors.orange.shade300)
                  ),
                  child: CheckboxListTile(
                    title: Text("Verify and Lock this Log", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _isVerified ? Colors.green.shade800 : Colors.orange.shade900)),
                    subtitle: Text("Once verified, this record cannot be edited again.", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
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