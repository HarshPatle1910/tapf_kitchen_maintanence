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
class BoilerLogListScreen extends StatefulWidget {
  const BoilerLogListScreen({super.key});

  @override
  State<BoilerLogListScreen> createState() => _BoilerLogListScreenState();
}

class _BoilerLogListScreenState extends State<BoilerLogListScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    // Clamp to minimum May 2026
    if (_selectedYear < 2026) _selectedYear = 2026;
    if (_selectedYear == 2026 && _selectedMonth < 5) _selectedMonth = 5;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  String? _getActiveKitchenId() {
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    String targetKitchenId = ticketProv.kitchenFilter;
    if (targetKitchenId == 'ALL' || targetKitchenId.isEmpty) {
      if (authProv.assignedKitchens.isNotEmpty)
        return authProv.assignedKitchens.first['id'].toString();
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
      final startDate = DateTime(
        _selectedYear,
        _selectedMonth,
        1,
      ).toIso8601String().split('T')[0];
      final endDate = DateTime(
        _selectedYear,
        _selectedMonth + 1,
        0,
      ).toIso8601String().split('T')[0];

      final res = await _supabase
          .from('daily_boiler_log')
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<DateTime> _getDatesForMonth() {
    final now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    int targetDays = (_selectedYear == now.year && _selectedMonth == now.month)
        ? now.day
        : daysInMonth;

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
    return years
        .map(
          (y) => DropdownMenuItem(
            value: y,
            child: Text(
              y.toString(),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem<int>> _getMonthItems() {
    int startMonth = (_selectedYear == 2026) ? 5 : 1;
    int endMonth = (_selectedYear == DateTime.now().year)
        ? DateTime.now().month
        : 12;

    List<DropdownMenuItem<int>> items = [];
    for (int m = startMonth; m <= endMonth; m++) {
      items.add(
        DropdownMenuItem(
          value: m,
          child: Text(
            _months[m - 1],
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      );
    }
    return items;
  }

  void _onYearChanged(int? newYear) {
    if (newYear == null) return;
    setState(() {
      _selectedYear = newYear;
      if (_selectedYear == 2026 && _selectedMonth < 5) _selectedMonth = 5;
      if (_selectedYear == DateTime.now().year &&
          _selectedMonth > DateTime.now().month)
        _selectedMonth = DateTime.now().month;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Export MT-11 Report",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Generating report for ${_months[_selectedMonth - 1]} $_selectedYear.",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Select Format",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      "Excel",
                      style: GoogleFonts.inter(
                        fontWeight: format == 'xlsx'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: format == 'xlsx',
                    selectedColor: primary.withOpacity(0.1),
                    side: BorderSide(
                      color: format == 'xlsx' ? primary : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (v) => setDialogState(() => format = 'xlsx'),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: Text(
                      "PDF",
                      style: GoogleFonts.inter(
                        fontWeight: format == 'pdf'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: format == 'pdf',
                    selectedColor: primary.withOpacity(0.1),
                    side: BorderSide(
                      color: format == 'pdf' ? primary : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (v) => setDialogState(() => format = 'pdf'),
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "CANCEL",
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExport(format);
              },
              child: Text(
                "DOWNLOAD",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeExport(String format) async {
    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: primary)),
    );

    try {
      final url = Uri.parse(
        '${ApiConstants.pythonApiBaseUrl}/reports/boiler-log/monthly?kitchen_id=$targetKitchenId&month=$_selectedMonth&year=$_selectedYear&format=$format',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download/Maintenance Reports')
            : Directory(
                '${(await getApplicationDocumentsDirectory()).path}/Maintenance Reports',
              );
        if (!await saveDir.exists()) await saveDir.create(recursive: true);
        final file = File(
          '${saveDir.path}/MT11_Boiler_Log_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.$format',
        );
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) Navigator.pop(context);
        OpenFilex.open(file.path);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetKitchenId = _getActiveKitchenId();
    final dates = _getDatesForMonth();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
        title: Text(
          "MT-11 Boiler Log",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: primary),
            onPressed: _showExportFormatDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    borderRadius: BorderRadius.circular(24),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    value: _selectedMonth,
                    icon: const Icon(Icons.arrow_drop_down, color: primary),
                    items: _getMonthItems(),
                    onChanged: (v) {
                      setState(() => _selectedMonth = v!);
                      _fetchData();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    borderRadius: BorderRadius.circular(24),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : RefreshIndicator(
                    color: primary,
                    onRefresh: _fetchData,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: dates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final targetDate = dates[dates.length - 1 - i];
                        final dateStr = targetDate.toIso8601String().split(
                          'T',
                        )[0];
                        final existingRecord = _records
                            .cast<Map<String, dynamic>?>()
                            .firstWhere(
                              (r) => r?['log_date'] == dateStr,
                              orElse: () => null,
                            );

                        final bool hasData = existingRecord != null;
                        final bool isVerified =
                            existingRecord != null &&
                            existingRecord['verified_by'] != null;

                        return Material(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              if (targetKitchenId == null) return;
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BoilerLogFormScreen(
                                    date: targetDate,
                                    kitchenId: targetKitchenId,
                                    existingLogId: existingRecord?['id'],
                                  ),
                                ),
                              );
                              if (result == true) _fetchData();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isVerified
                                          ? Colors.green.shade50
                                          : (hasData
                                                ? Colors.orange.shade50
                                                : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isVerified
                                            ? Colors.green.shade100
                                            : (hasData
                                                  ? Colors.orange.shade100
                                                  : Colors.grey.shade100),
                                      ),
                                    ),
                                    child: Icon(
                                      isVerified
                                          ? Icons.verified
                                          : Icons.local_fire_department,
                                      color: isVerified
                                          ? Colors.green
                                          : (hasData ? Colors.orange : primary),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${targetDate.day.toString().padLeft(2, '0')} ${_months[targetDate.month - 1]} ${targetDate.year}",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isVerified
                                                    ? Colors.green.shade50
                                                    : (hasData
                                                          ? Colors
                                                                .orange
                                                                .shade50
                                                          : Colors
                                                                .grey
                                                                .shade100),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isVerified
                                                    ? "Verified & Locked"
                                                    : (hasData
                                                          ? "Draft Saved"
                                                          : "No Entry"),
                                                style: GoogleFonts.inter(
                                                  color: isVerified
                                                      ? Colors.green.shade700
                                                      : (hasData
                                                            ? Colors
                                                                  .orange
                                                                  .shade800
                                                            : Colors
                                                                  .grey
                                                                  .shade600),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
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
// 2. DAILY ENTRY FORM SCREEN (DYNAMIC UPDATES)
// ============================================================================
class BoilerLogFormScreen extends StatefulWidget {
  final DateTime date;
  final String kitchenId;
  final String? existingLogId;

  const BoilerLogFormScreen({
    super.key,
    required this.date,
    required this.kitchenId,
    this.existingLogId,
  });

  @override
  State<BoilerLogFormScreen> createState() => _BoilerLogFormScreenState();
}

class _BoilerLogFormScreenState extends State<BoilerLogFormScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _isVerified = false;
  bool _isReadOnly = false;

  String? _dailyLogId;
  String? _detailId;

  // Users List for Operators
  List<Map<String, dynamic>> _userList = [];

  // Detail Controllers
  final _fWphCtrl = TextEditingController();
  final _fWtdsCtrl = TextEditingController();
  final _fWhardCtrl = TextEditingController();
  final _bWphCtrl = TextEditingController();
  final _bWtdsCtrl = TextEditingController();
  final _bWhardCtrl = TextEditingController();

  final _condOpenCtrl = TextEditingController();
  final _condCloseCtrl = TextEditingController();
  final _boilerStartCtrl = TextEditingController();
  final _boilerEndCtrl = TextEditingController();
  final _mainValveOpenCtrl = TextEditingController();
  final _mainValveCloseCtrl = TextEditingController();

  final _recoveryCtrl = TextEditingController();
  final _airPressCtrl = TextEditingController();
  final _pitLevelCtrl = TextEditingController();

  final _bq1OpCtrl = TextEditingController();
  final _bq1ConCtrl = TextEditingController();
  final _bq1ClCtrl = TextEditingController();
  final _bq2OpCtrl = TextEditingController();
  final _bq2ConCtrl = TextEditingController();
  final _bq2ClCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  // DYNAMIC: Hourly Readings List
  List<Map<String, dynamic>> _dynamicReadings = [];

  // DYNAMIC: Operators List (Max 4)
  List<Map<String, dynamic>> _operators = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  @override
  void dispose() {
    _fWphCtrl.dispose();
    _fWtdsCtrl.dispose();
    _fWhardCtrl.dispose();
    _bWphCtrl.dispose();
    _bWtdsCtrl.dispose();
    _bWhardCtrl.dispose();
    _condOpenCtrl.dispose();
    _condCloseCtrl.dispose();
    _boilerStartCtrl.dispose();
    _boilerEndCtrl.dispose();
    _mainValveOpenCtrl.dispose();
    _mainValveCloseCtrl.dispose();
    _recoveryCtrl.dispose();
    _airPressCtrl.dispose();
    _pitLevelCtrl.dispose();
    _bq1OpCtrl.dispose();
    _bq1ConCtrl.dispose();
    _bq1ClCtrl.dispose();
    _bq2OpCtrl.dispose();
    _bq2ConCtrl.dispose();
    _bq2ClCtrl.dispose();
    _remarksCtrl.dispose();

    for (var r in _dynamicReadings) {
      r['steam_pressure']?.dispose();
      r['drum_level']?.dispose();
      r['feed_tank_level']?.dispose();
      r['aph_il']?.dispose();
      r['aph_ol']?.dispose();
    }
    for (var op in _operators) {
      op['controller']?.dispose();
    }
    super.dispose();
  }

  Future<void> _initData() async {
    _dailyLogId = widget.existingLogId;

    try {
      // Fetch users for the Operator Dropdown
      final usersRes = await _supabase.from('m_user').select('id, name');
      _userList = List<Map<String, dynamic>>.from(usersRes);

      if (_dailyLogId != null) {
        final masterRes = await _supabase
            .from('daily_boiler_log')
            .select()
            .eq('id', _dailyLogId!)
            .single();
        _isVerified = masterRes['verified_by'] != null;
        _isReadOnly = _isVerified;
        _remarksCtrl.text = masterRes['final_remarks'] ?? '';

        final detailRes = await _supabase
            .from('daily_boiler_log_detail')
            .select()
            .eq('log_id', _dailyLogId!)
            .maybeSingle();
        if (detailRes != null) {
          _detailId = detailRes['id'];
          _fWphCtrl.text = detailRes['feed_water_ph'] ?? '';
          _fWtdsCtrl.text = detailRes['feed_water_tds'] ?? '';
          _fWhardCtrl.text = detailRes['feed_water_hardness'] ?? '';
          _bWphCtrl.text = detailRes['blowdown_water_ph'] ?? '';
          _bWtdsCtrl.text = detailRes['blowdown_water_tds'] ?? '';
          _bWhardCtrl.text = detailRes['blowdown_water_hardness'] ?? '';

          _condOpenCtrl.text = _formatTimeDisplay(
            detailRes['condenset_opening_time'],
          );
          _condCloseCtrl.text = _formatTimeDisplay(
            detailRes['condenset_closing_time'],
          );
          _boilerStartCtrl.text = _formatTimeDisplay(
            detailRes['boiler_start_time'],
          );
          _boilerEndCtrl.text = _formatTimeDisplay(
            detailRes['boiler_end_time'],
          );
          _mainValveOpenCtrl.text = _formatTimeDisplay(
            detailRes['main_valve_open_time'],
          );
          _mainValveCloseCtrl.text = _formatTimeDisplay(
            detailRes['main_valve_close_time'],
          );

          _recoveryCtrl.text = detailRes['recovery']?.toString() ?? '';
          _airPressCtrl.text = detailRes['air_pressure']?.toString() ?? '';
          _pitLevelCtrl.text = detailRes['blowdown_pit_level'] ?? '';

          _bq1OpCtrl.text =
              detailRes['briquettes_opening_stock_1']?.toString() ?? '';
          _bq1ConCtrl.text =
              detailRes['briquettes_consumption_1']?.toString() ?? '';
          _bq1ClCtrl.text =
              detailRes['briquettes_closing_stock_1']?.toString() ?? '';
          _bq2OpCtrl.text =
              detailRes['briquettes_opening_stock_2']?.toString() ?? '';
          _bq2ConCtrl.text =
              detailRes['briquettes_consumption_2']?.toString() ?? '';
          _bq2ClCtrl.text =
              detailRes['briquettes_closing_stock_2']?.toString() ?? '';

          // Load existing Operators (Max 4)
          for (int i = 1; i <= 4; i++) {
            if (detailRes['operator_${i}_name'] != null ||
                detailRes['operator_${i}_sign'] != null) {
              String? url;
              if (detailRes['operator_${i}_sign'] != null) {
                url =
                    detailRes['operator_${i}_sign'].toString().startsWith(
                      'http',
                    )
                    ? detailRes['operator_${i}_sign']
                    : _supabase.storage
                          .from('ticket-media')
                          .getPublicUrl(detailRes['operator_${i}_sign']);
              }
              _addOperatorUI(url, detailRes['operator_${i}_name']);
            }
          }
        }

        // Load Dynamic Hourly Entries
        final entriesRes = await _supabase
            .from('daily_boiler_log_entry')
            .select()
            .eq('log_id', _dailyLogId!)
            .order('entry_time');
        final List<dynamic> entries = entriesRes;
        for (var row in entries) {
          _addReadingUI(
            timeStr: row['entry_time'],
            sp: row['steam_pressure']?.toString(),
            dl: row['drum_level']?.toString(),
            ft: row['feed_tank_level']?.toString(),
            ai: row['aph_il']?.toString(),
            ao: row['aph_ol']?.toString(),
          );
        }
      }
    } catch (e) {
      debugPrint("Error loading log: $e");
    }

    // Default setups if completely empty
    if (_dynamicReadings.isEmpty)
      _addReadingUI(timeStr: _timeOfDayToDBString(TimeOfDay.now()));
    if (_operators.isEmpty) _addOperatorUI(null, null);

    if (mounted) setState(() => _isLoading = false);
  }

  // --- DYNAMIC UI HELPERS ---

  void _addReadingUI({
    String? timeStr,
    String? sp,
    String? dl,
    String? ft,
    String? ai,
    String? ao,
  }) {
    setState(() {
      _dynamicReadings.add({
        'time':
            timeStr ?? _timeOfDayToDBString(TimeOfDay.now()), // format HH:mm:ss
        'steam_pressure': TextEditingController(text: sp),
        'drum_level': TextEditingController(text: dl),
        'feed_tank_level': TextEditingController(text: ft),
        'aph_il': TextEditingController(text: ai),
        'aph_ol': TextEditingController(text: ao),
      });
    });
  }

  void _addOperatorUI(String? url, String? operatorId) {
    if (_operators.length >= 4) return;

    // Ensure the operator ID actually exists in the fetched list (prevents dropdown crash)
    bool userExists = _userList.any((u) => u['id'] == operatorId);

    setState(() {
      _operators.add({
        'id': userExists ? operatorId : null,
        'url': url,
        'controller': SignatureController(
          penStrokeWidth: 3,
          penColor: Colors.black,
          exportBackgroundColor: Colors.transparent,
        ),
      });
    });
  }

  // --- TIME FORMATTING HELPERS ---

  String _timeOfDayToDBString(TimeOfDay tod) {
    final hr = tod.hour.toString().padLeft(2, '0');
    final min = tod.minute.toString().padLeft(2, '0');
    return "$hr:$min:00";
  }

  String _formatTimeDisplay(String? dbTime) {
    if (dbTime == null || dbTime.isEmpty) return "";
    return dbTime.substring(0, 5); // Extracts HH:mm
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    if (_isReadOnly) return;
    TimeOfDay initialTime = TimeOfDay.now();

    if (ctrl.text.isNotEmpty && ctrl.text.contains(':')) {
      final parts = ctrl.text.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode:
          TimePickerEntryMode.dial, // Strict 12-hour Watch dial UI
    );

    if (picked != null) {
      setState(() {
        ctrl.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  // --- SAVE & EXPORT LOGIC ---

  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final dateStr = widget.date.toIso8601String().split('T')[0];

      // 1. Master Upsert
      final masterData = {
        'kitchen_id': widget.kitchenId,
        'log_date': dateStr,
        'final_remarks': _remarksCtrl.text.trim(),
        'prepared_by': currentUserId,
        if (_isVerified) 'verified_by': currentUserId,
      };
      final upsertRes = await _supabase
          .from('daily_boiler_log')
          .upsert(masterData, onConflict: 'kitchen_id, log_date')
          .select('id')
          .single();
      final activeLogId = upsertRes['id'];

      // 2. Upload Signatures dynamically
      List<String?> uploadedSigns = [null, null, null, null];
      for (int i = 0; i < _operators.length; i++) {
        if (_operators[i]['controller'].isNotEmpty) {
          final Uint8List? signatureBytes = await _operators[i]['controller']
              .toPngBytes();
          if (signatureBytes != null) {
            final fileName =
                'boiler_signatures/${DateTime.now().millisecondsSinceEpoch}_op$i.png';
            await _supabase.storage
                .from('ticket-media')
                .uploadBinary(fileName, signatureBytes);
            uploadedSigns[i] = fileName;
          }
        } else {
          uploadedSigns[i] = _operators[i]['url']; // retain existing
        }
      }

      // 3. Detail Upsert
      final detailData = {
        'log_id': activeLogId,
        'feed_water_ph': _fWphCtrl.text,
        'feed_water_tds': _fWtdsCtrl.text,
        'feed_water_hardness': _fWhardCtrl.text,
        'blowdown_water_ph': _bWphCtrl.text,
        'blowdown_water_tds': _bWtdsCtrl.text,
        'blowdown_water_hardness': _bWhardCtrl.text,

        'condenset_opening_time': _condOpenCtrl.text.isEmpty
            ? null
            : "${_condOpenCtrl.text}:00",
        'condenset_closing_time': _condCloseCtrl.text.isEmpty
            ? null
            : "${_condCloseCtrl.text}:00",
        'boiler_start_time': _boilerStartCtrl.text.isEmpty
            ? null
            : "${_boilerStartCtrl.text}:00",
        'boiler_end_time': _boilerEndCtrl.text.isEmpty
            ? null
            : "${_boilerEndCtrl.text}:00",
        'main_valve_open_time': _mainValveOpenCtrl.text.isEmpty
            ? null
            : "${_mainValveOpenCtrl.text}:00",
        'main_valve_close_time': _mainValveCloseCtrl.text.isEmpty
            ? null
            : "${_mainValveCloseCtrl.text}:00",

        'recovery': double.tryParse(_recoveryCtrl.text),
        'air_pressure': double.tryParse(_airPressCtrl.text),
        'blowdown_pit_level': _pitLevelCtrl.text,

        'briquettes_opening_stock_1': double.tryParse(_bq1OpCtrl.text),
        'briquettes_consumption_1': double.tryParse(_bq1ConCtrl.text),
        'briquettes_closing_stock_1': double.tryParse(_bq1ClCtrl.text),
        'briquettes_opening_stock_2': double.tryParse(_bq2OpCtrl.text),
        'briquettes_consumption_2': double.tryParse(_bq2ConCtrl.text),
        'briquettes_closing_stock_2': double.tryParse(_bq2ClCtrl.text),

        // Match operators list safely
        'operator_1_name': _operators.isNotEmpty ? _operators[0]['id'] : null,
        'operator_1_sign': uploadedSigns[0],
        'operator_2_name': _operators.length > 1 ? _operators[1]['id'] : null,
        'operator_2_sign': uploadedSigns[1],
        'operator_3_name': _operators.length > 2 ? _operators[2]['id'] : null,
        'operator_3_sign': uploadedSigns[2],
        'operator_4_name': _operators.length > 3 ? _operators[3]['id'] : null,
        'operator_4_sign': uploadedSigns[3],
      };

      if (_detailId == null) {
        await _supabase.from('daily_boiler_log_detail').insert(detailData);
      } else {
        await _supabase
            .from('daily_boiler_log_detail')
            .update(detailData)
            .eq('id', _detailId!);
      }

      // 4. Dynamic Hourly Entries
      List<Map<String, dynamic>> readingsToInsert = [];
      int seq = 1;
      for (var r in _dynamicReadings) {
        if (r['steam_pressure']!.text.isNotEmpty ||
            r['drum_level']!.text.isNotEmpty ||
            r['aph_il']!.text.isNotEmpty) {
          readingsToInsert.add({
            'log_id': activeLogId,
            'sequence_no': seq,
            'entry_time': r['time'], // Already in HH:mm:ss
            'steam_pressure': double.tryParse(r['steam_pressure']!.text),
            'drum_level': double.tryParse(r['drum_level']!.text),
            'feed_tank_level': double.tryParse(r['feed_tank_level']!.text),
            'aph_il': double.tryParse(r['aph_il']!.text),
            'aph_ol': double.tryParse(r['aph_ol']!.text),
          });
        }
        seq++;
      }

      await _supabase
          .from('daily_boiler_log_entry')
          .delete()
          .eq('log_id', activeLogId);
      if (readingsToInsert.isNotEmpty) {
        await _supabase.from('daily_boiler_log_entry').insert(readingsToInsert);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isVerified ? "Log Verified & Locked!" : "Draft Saved!",
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Export Daily Log",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Exporting report for $dateStr.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Select Format",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      "Excel",
                      style: GoogleFonts.inter(
                        fontWeight: format == 'xlsx'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: format == 'xlsx',
                    selectedColor: primary.withOpacity(0.1),
                    side: BorderSide(
                      color: format == 'xlsx' ? primary : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (v) => setDialogState(() => format = 'xlsx'),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: Text(
                      "PDF",
                      style: GoogleFonts.inter(
                        fontWeight: format == 'pdf'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: format == 'pdf',
                    selectedColor: primary.withOpacity(0.1),
                    side: BorderSide(
                      color: format == 'pdf' ? primary : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (v) => setDialogState(() => format = 'pdf'),
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "CANCEL",
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _executeDailyExport(dateStr, format);
              },
              child: Text(
                "DOWNLOAD",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeDailyExport(String dateStr, String format) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: primary)),
    );
    try {
      final url = Uri.parse(
        '${ApiConstants.pythonApiBaseUrl}/reports/boiler-log/daily?kitchen_id=${widget.kitchenId}&date=$dateStr&format=$format',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download/Maintenance Reports')
            : Directory(
                '${(await getApplicationDocumentsDirectory()).path}/Maintenance Reports',
              );
        if (!await saveDir.exists()) await saveDir.create(recursive: true);
        final file = File('${saveDir.path}/MT11_Boiler_Log_$dateStr.$format');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) Navigator.pop(context);
        OpenFilex.open(file.path);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // --- UI BUILDING BLOCKS ---

  InputDecoration _decor(
    String label, {
    String? suffixText,
    Widget? suffixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
      filled: true,
      fillColor: _isReadOnly ? Colors.grey.shade50 : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary),
      ),
    );
  }

  Widget _buildMetricRow(
    String l1,
    TextEditingController c1,
    String l2,
    TextEditingController c2, {
    String? s1,
    String? s2,
    bool isNumeric = true,
    bool isTime = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: isTime
                ? InkWell(
                    onTap: () => _pickTime(c1),
                    child: IgnorePointer(
                      child: TextField(
                        controller: c1,
                        decoration: _decor(
                          l1,
                          suffixIcon: const Icon(
                            Icons.access_time,
                            size: 16,
                            color: primary,
                          ),
                          hint: "Tap to set time",
                        ),
                      ),
                    ),
                  )
                : TextField(
                    controller: c1,
                    enabled: !_isReadOnly,
                    keyboardType: isNumeric
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: _decor(l1, suffixText: s1),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isTime
                ? InkWell(
                    onTap: () => _pickTime(c2),
                    child: IgnorePointer(
                      child: TextField(
                        controller: c2,
                        decoration: _decor(
                          l2,
                          suffixIcon: const Icon(
                            Icons.access_time,
                            size: 16,
                            color: primary,
                          ),
                          hint: "Tap to set time",
                        ),
                      ),
                    ),
                  )
                : TextField(
                    controller: c2,
                    enabled: !_isReadOnly,
                    keyboardType: isNumeric
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: _decor(l2, suffixText: s2),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF0F172A),
                ),
              ),
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
    if (_isLoading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    final dateStr =
        "${widget.date.day.toString().padLeft(2, '0')}/${widget.date.month.toString().padLeft(2, '0')}/${widget.date.year}";

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: surface,
          foregroundColor: primary,
          elevation: 0,
          title: Text(
            _isReadOnly ? "View Verified Log" : "Edit Log - $dateStr",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              fontSize: 18,
            ),
          ),
          actions: [
            if (_dailyLogId != null && _isReadOnly)
              IconButton(
                icon: const Icon(Icons.download_rounded, color: primary),
                onPressed: _showDailyExportFormatDialog,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isReadOnly)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "This boiler log is verified and permanently locked.",
                          style: GoogleFonts.inter(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildSectionCard(
                title: "Water Parameters",
                icon: Icons.water_drop_outlined,
                children: [
                  Text(
                    "Feed Water",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMetricRow(
                    "PH",
                    _fWphCtrl,
                    "TDS",
                    _fWtdsCtrl,
                    isNumeric: false,
                  ),
                  TextField(
                    controller: _fWhardCtrl,
                    enabled: !_isReadOnly,
                    decoration: _decor("Hardness"),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Blowdown Water",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMetricRow(
                    "PH",
                    _bWphCtrl,
                    "TDS",
                    _bWtdsCtrl,
                    isNumeric: false,
                  ),
                  TextField(
                    controller: _bWhardCtrl,
                    enabled: !_isReadOnly,
                    decoration: _decor("Hardness"),
                  ),
                ],
              ),

              _buildSectionCard(
                title: "Operational Time & Metrics",
                icon: Icons.timer_outlined,
                children: [
                  _buildMetricRow(
                    "Boiler Start",
                    _boilerStartCtrl,
                    "Boiler End",
                    _boilerEndCtrl,
                    isNumeric: false,
                    isTime: true,
                  ),
                  _buildMetricRow(
                    "Condensate Open",
                    _condOpenCtrl,
                    "Condensate Close",
                    _condCloseCtrl,
                    isNumeric: false,
                    isTime: true,
                  ),
                  _buildMetricRow(
                    "Main Valve Open",
                    _mainValveOpenCtrl,
                    "Main Valve Close",
                    _mainValveCloseCtrl,
                    isNumeric: false,
                    isTime: true,
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _recoveryCtrl,
                            enabled: !_isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _decor("Recovery"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _airPressCtrl,
                            enabled: !_isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _decor(
                              "Air Pressure",
                              suffixText: "kg/cm²",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  TextField(
                    controller: _pitLevelCtrl,
                    enabled: !_isReadOnly,
                    keyboardType: TextInputType.text,
                    decoration: _decor("Blowdown Pit Lvl"),
                  ),
                ],
              ),

              _buildSectionCard(
                title: "Briquettes Consumption",
                icon: Icons.local_fire_department_outlined,
                children: [
                  Text(
                    "Stock 1",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMetricRow(
                    "Opening",
                    _bq1OpCtrl,
                    "Consumption",
                    _bq1ConCtrl,
                  ),
                  TextField(
                    controller: _bq1ClCtrl,
                    enabled: !_isReadOnly,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decor("Closing Stock"),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Stock 2",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMetricRow(
                    "Opening",
                    _bq2OpCtrl,
                    "Consumption",
                    _bq2ConCtrl,
                  ),
                  TextField(
                    controller: _bq2ClCtrl,
                    enabled: !_isReadOnly,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decor("Closing Stock"),
                  ),
                ],
              ),

              // DYNAMIC HOURLY READINGS UI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hourly Readings",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: primary,
                      fontSize: 16,
                    ),
                  ),
                  if (!_isReadOnly)
                    TextButton.icon(
                      onPressed: () => _addReadingUI(
                        timeStr: _timeOfDayToDBString(TimeOfDay.now()),
                      ),
                      icon: const Icon(Icons.add_circle, size: 16),
                      label: Text(
                        "Add Reading",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(foregroundColor: primary),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dynamicReadings.length,
                itemBuilder: (ctx, i) {
                  final reading = _dynamicReadings[i];
                  final String dbTime = reading['time'];
                  // Convert "14:30:00" to "02:30 PM"
                  final hour = int.parse(dbTime.substring(0, 2));
                  final ampm = hour >= 12 ? 'PM' : 'AM';
                  final formattedHour = hour > 12
                      ? hour - 12
                      : (hour == 0 ? 12 : hour);
                  final uiTime =
                      "${formattedHour.toString().padLeft(2, '0')}:${dbTime.substring(3, 5)} $ampm";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        collapsedIconColor: primary,
                        iconColor: primary,
                        title: Text(
                          "Reading at $uiTime",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            fontSize: 15,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(
                              16.0,
                            ).copyWith(top: 0),
                            child: Column(
                              children: [
                                _buildMetricRow(
                                  "Steam Pressure",
                                  reading['steam_pressure'],
                                  "Drum Level",
                                  reading['drum_level'],
                                  s1: "kg/cm²",
                                  s2: "%",
                                ),
                                _buildMetricRow(
                                  "Feed Tank Level",
                                  reading['feed_tank_level'],
                                  "APH I/L Temp",
                                  reading['aph_il'],
                                  s1: "%",
                                  s2: "°C",
                                ),
                                TextField(
                                  controller: reading['aph_ol'],
                                  enabled: !_isReadOnly,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _decor(
                                    "APH O/L Temp",
                                    suffixText: "°C",
                                  ),
                                ),

                                if (!_isReadOnly)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => setState(
                                        () => _dynamicReadings.removeAt(i),
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                      ),
                                      label: Text(
                                        "Remove Reading",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // MULTIPLE OPERATOR SIGNATURES
              _buildSectionCard(
                title: "Final Remarks & Signatures",
                icon: Icons.draw_outlined,
                children: [
                  TextField(
                    controller: _remarksCtrl,
                    enabled: !_isReadOnly,
                    maxLines: 3,
                    decoration: _decor("Enter end of day observations here..."),
                  ),
                  const SizedBox(height: 20),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _operators.length,
                    itemBuilder: (ctx, i) {
                      final op = _operators[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Operator ${i + 1}",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (!_isReadOnly)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _operators.removeAt(i)),
                                  ),
                              ],
                            ),

                            // SELECT OPERATOR DROPDOWN
                            DropdownButtonFormField<String>(
                              value: op['id'],
                              decoration: _decor("Select Operator"),
                              items: _userList
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u['id'].toString(),
                                      child: Text(u['name'].toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isReadOnly
                                  ? null
                                  : (val) => setState(() => op['id'] = val),
                            ),
                            const SizedBox(height: 12),

                            // ONLY SHOW SIGNATURE PAD IF AN OPERATOR IS SELECTED
                            if (op['id'] != null) ...[
                              Text(
                                "Signature",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              if (op['url'] != null &&
                                  op['controller'].isEmpty) ...[
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      op['url'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                if (!_isReadOnly)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          setState(() => op['url'] = null),
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: Text(
                                        "Redraw",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ] else if (!_isReadOnly) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: primary.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Signature(
                                      controller: op['controller'],
                                      height: 120,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => op['controller'].clear(),
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    label: Text(
                                      "Clear Panel",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  if (!_isReadOnly && _operators.length < 4)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _addOperatorUI(null, null),
                        icon: const Icon(Icons.person_add),
                        label: Text(
                          "Add Another Operator",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              if (!_isReadOnly)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _isVerified
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isVerified
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      "Verify and Lock this Log",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: _isVerified
                            ? Colors.green.shade800
                            : Colors.orange.shade900,
                      ),
                    ),
                    subtitle: Text(
                      "Once verified, this log cannot be edited.",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    value: _isVerified,
                    activeColor: Colors.green.shade700,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
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
                  decoration: BoxDecoration(
                    color: surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isVerified
                          ? Colors.green.shade600
                          : primary,
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveRecord,
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isVerified ? "Confirm & Lock Log" : "Save Draft",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
      ),
    );
  }
}
