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
// 1. DASHBOARD SCREEN
// ============================================================================
class TestingEquipmentScreen extends StatefulWidget {
  const TestingEquipmentScreen({super.key});

  @override
  State<TestingEquipmentScreen> createState() => _TestingEquipmentScreenState();
}

class _TestingEquipmentScreenState extends State<TestingEquipmentScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _areas = [];
  bool _isLoading = true;

  // Search and Filter State
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedFilter =
      'All'; // Options: 'All', 'Due This Week', 'Due This Month'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAreas();
      _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getActiveKitchenId() {
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    String activeId = ticketProv.kitchenFilter;
    if (activeId == 'ALL' || activeId.isEmpty) {
      if (authProv.assignedKitchens.isNotEmpty) {
        activeId = authProv.assignedKitchens.first['id'].toString();
      } else {
        activeId = '';
      }
    }
    return activeId;
  }

  Future<void> _fetchAreas() async {
    final kitchenId = _getActiveKitchenId();
    if (kitchenId.isEmpty) return;

    try {
      final response = await _supabase
          .from('m_area')
          .select('id, area_name, m_zone!inner(kitchen_id)')
          .eq('status', true)
          .eq('m_zone.kitchen_id', kitchenId);

      if (mounted) {
        setState(() {
          _areas = List<Map<String, dynamic>>.from(response);
          for (var a in _areas) {
            a['display_name'] = a['area_name'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching areas: $e");
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final kitchenId = _getActiveKitchenId();
    if (kitchenId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await _supabase
          .from('v_testing_equipment_master')
          .select('*')
          .eq('kitchen_id', kitchenId)
          .order('next_due_date', ascending: true);

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

  // --- Date Calculation Filters ---
  bool _isDueThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );
    return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(seconds: 1)));
  }

  bool _isDueThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  List<Map<String, dynamic>> get _filteredRecords {
    return _records.where((r) {
      // 1. Search filter
      final name = (r['equipment_name'] ?? '').toLowerCase();
      if (_searchQuery.isNotEmpty &&
          !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // 2. Chip filters
      if (_selectedFilter != 'All') {
        if (r['next_due_date'] == null) return false;
        final dueDate = DateTime.parse(r['next_due_date']);

        if (_selectedFilter == 'Due This Week') {
          return _isDueThisWeek(dueDate) ||
              dueDate.isBefore(DateTime.now()); // Include overdues
        } else if (_selectedFilter == 'Due This Month') {
          return _isDueThisMonth(dueDate) ||
              dueDate.isBefore(DateTime.now()); // Include overdues
        }
      }
      return true;
    }).toList();
  }

  void _showAddEditDialog([Map<String, dynamic>? record]) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TestingEquipmentFormBottomSheet(
        existingRecord: record,
        areas: _areas,
      ),
    );

    if (result == true) {
      _fetchData();
    }
  }

  // --- Export Functionality (UPDATED TO MATCH API) ---
  void _showExportFormatDialog() {
    String format = 'docx';
    bool exportAll = true;
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    final List<String> months = [
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Export Testing Equipment",
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
                "Select timeframe for the master list.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),

              // Timeframe Selection
              Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      "All Time",
                      style: GoogleFonts.inter(
                        fontWeight: exportAll
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: exportAll ? primary : Colors.black87,
                      ),
                    ),
                    selected: exportAll,
                    onSelected: (v) => setDialogState(() => exportAll = true),
                    selectedColor: primary.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: exportAll ? primary : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      "Month-wise",
                      style: GoogleFonts.inter(
                        fontWeight: !exportAll
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: !exportAll ? primary : Colors.black87,
                      ),
                    ),
                    selected: !exportAll,
                    onSelected: (v) => setDialogState(() => exportAll = false),
                    selectedColor: primary.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: !exportAll ? primary : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),

              // Month & Year Dropdowns (Shown only if Specific Month is chosen)
              if (!exportAll) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        initialValue: selectedMonth,
                        items: List.generate(
                          12,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              months[index],
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                        ).toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        initialValue: selectedYear,
                        items: List.generate(
                          5,
                          (index) => DropdownMenuItem(
                            value: DateTime.now().year - index,
                            child: Text(
                              (DateTime.now().year - index).toString(),
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                        ).toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedYear = v!),
                      ),
                    ),
                  ],
                ),
              ],

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
                      "Word (.docx)",
                      style: GoogleFonts.inter(
                        fontWeight: format == 'docx'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: format == 'docx',
                    selectedColor: primary.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: format == 'docx' ? primary : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (v) => setDialogState(() => format = 'docx'),
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
                    selectedColor: primary.withValues(alpha: 0.1),
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
                _executeExport(format, exportAll, selectedMonth, selectedYear);
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

  Future<void> _executeExport(
    String format,
    bool exportAll,
    int month,
    int year,
  ) async {
    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Kitchen Selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: primary)),
    );

    try {
      // Base URL points to testing-equipments (with an 's') as defined in python API
      String urlString =
          '${ApiConstants.pythonApiBaseUrl}/reports/testing-equipments?kitchen_id=$targetKitchenId&format=$format';

      // Append month and year if specific month is requested
      if (!exportAll) {
        urlString += '&month=$month&year=$year';
      }

      debugPrint("Download URL: $urlString");

      final url = Uri.parse(urlString);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Safe path that bypasses Android 11+ Scoped Storage restrictions
        final saveDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File(
          '${saveDir.path}/MT03_Testing_Equipment_$timestamp.$format',
        );

        await file.writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context); // Close loading dialog

        // Open the file using the native device viewer
        final openResult = await OpenFilex.open(file.path);

        if (openResult.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saved successfully, but no app found to open $format files.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception(
          "Server Error ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _filteredRecords;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: surface,
          foregroundColor: primary,
          elevation: 0,
          title: Text(
            "Testing Equipment",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined, color: primary),
              tooltip: "Download Report",
              onPressed: _showExportFormatDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // SEARCH & FILTERS
            Container(
              color: surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search equipment...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: background,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Due This Week', 'Due This Month'].map((
                        filter,
                      ) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: GoogleFonts.inter(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedFilter = filter);
                            },
                            selectedColor: primary,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? primary
                                  : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // LIST VIEW
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primary),
                    )
                  : filteredData.isEmpty
                  ? Center(
                      child: Text(
                        "No testing equipment found.",
                        style: GoogleFonts.inter(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final item = filteredData[index];
                        final isDue =
                            item['next_due_date'] != null &&
                            !DateTime.parse(
                              item['next_due_date'],
                            ).isAfter(DateTime.now());

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDue
                                  ? Colors.red.shade200
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            onTap: () => _showAddEditDialog(item),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['equipment_name'] ?? 'Unnamed',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: primary,
                                    ),
                                  ),
                                ),
                                if (isDue)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "OVERDUE",
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.place_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['location'] ?? 'N/A',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.event_repeat,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Freq: ${item['calibration_frequency'] ?? 'N/A'}",
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Last Calib",
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              item['last_calibration_date'] ??
                                                  'N/A',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "Next Due",
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              item['next_due_date'] ?? 'N/A',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: isDue
                                                    ? Colors.red
                                                    : Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: golden,
          foregroundColor: primary,
          elevation: 4,
          onPressed: () {
            _searchFocusNode.unfocus();
            _showAddEditDialog();
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(
            "Add Equipment",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DEDICATED STATEFUL BOTTOM SHEET FORM
// ============================================================================
class _TestingEquipmentFormBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? existingRecord;
  final List<Map<String, dynamic>> areas;

  const _TestingEquipmentFormBottomSheet({
    this.existingRecord,
    required this.areas,
  });

  @override
  State<_TestingEquipmentFormBottomSheet> createState() =>
      _TestingEquipmentFormBottomSheetState();
}

class _TestingEquipmentFormBottomSheetState
    extends State<_TestingEquipmentFormBottomSheet> {
  static const Color primary = Color(0xFF26538D);

  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isActive = true;

  late TextEditingController _nameController;
  late TextEditingController _opRangeController;
  late TextEditingController _remarksController;

  // Autocomplete Area
  late TextEditingController _areaSearchController;
  late FocusNode _areaFocusNode;

  String? _selectedAreaId;
  DateTime? _commissionDate;
  DateTime? _lastCalibrationDate;
  DateTime? _nextDueDate;
  String? _frequency;

  final List<String> _freqOptions = [
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Half Yearly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingRecord?['equipment_name'] ?? '',
    );
    _opRangeController = TextEditingController(
      text: widget.existingRecord?['operating_range'] ?? '',
    );
    _remarksController = TextEditingController(
      text: widget.existingRecord?['remarks'] ?? '',
    );

    _areaSearchController = TextEditingController();
    _areaFocusNode = FocusNode();
    _isActive = true;

    if (widget.existingRecord != null) {
      _frequency = widget.existingRecord!['calibration_frequency'];
      _commissionDate = widget.existingRecord!['date_of_commission'] != null
          ? DateTime.parse(widget.existingRecord!['date_of_commission'])
          : null;
      _lastCalibrationDate =
          widget.existingRecord!['last_calibration_date'] != null
          ? DateTime.parse(widget.existingRecord!['last_calibration_date'])
          : null;
      _nextDueDate = widget.existingRecord!['next_due_date'] != null
          ? DateTime.parse(widget.existingRecord!['next_due_date'])
          : null;

      final locationName = widget.existingRecord!['location'];
      if (locationName != null && locationName != 'N/A') {
        final match = widget.areas.firstWhere(
          (a) => a['area_name'] == locationName,
          orElse: () => <String, dynamic>{},
        );
        if (match.isNotEmpty) {
          _selectedAreaId = match['id'].toString();
          _areaSearchController.text = match['area_name'];
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _opRangeController.dispose();
    _remarksController.dispose();
    _areaSearchController.dispose();
    _areaFocusNode.dispose();
    super.dispose();
  }

  // --- Dynamic Due State Check ---
  bool get _isDue {
    if (_nextDueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      _nextDueDate!.year,
      _nextDueDate!.month,
      _nextDueDate!.day,
    );
    // If due date is today or in the past, it's due
    return due.isBefore(today) || due.isAtSameMomentAs(today);
  }

  // --- Auto Calculation Logic ---
  DateTime? _calculateNextDueDate(DateTime? lastCalib, String? freq) {
    if (lastCalib == null || freq == null) return null;
    switch (freq) {
      case 'Daily':
        return lastCalib.add(const Duration(days: 1));
      case 'Weekly':
        return lastCalib.add(const Duration(days: 7));
      case 'Monthly':
        return DateTime(lastCalib.year, lastCalib.month + 1, lastCalib.day);
      case 'Quarterly':
        return DateTime(lastCalib.year, lastCalib.month + 3, lastCalib.day);
      case 'Half Yearly':
        return DateTime(lastCalib.year, lastCalib.month + 6, lastCalib.day);
      case 'Yearly':
        return DateTime(lastCalib.year + 1, lastCalib.month, lastCalib.day);
      default:
        return null;
    }
  }

  void _recalcNextDue() {
    setState(() {
      _nextDueDate = _calculateNextDueDate(_lastCalibrationDate, _frequency);
    });
  }

  // --- Date Pickers ---
  Future<void> _pickCommissionDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _commissionDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Restrict to past/present
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _commissionDate = picked;
        // If last calibration is before new commission date, reset it
        if (_lastCalibrationDate != null &&
            _lastCalibrationDate!.isBefore(_commissionDate!)) {
          _lastCalibrationDate = null;
          _nextDueDate = null;
        }
      });
    }
  }

  Future<void> _pickLastCalibrationDate() async {
    FocusScope.of(context).unfocus();
    if (_commissionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Date of Commission first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _lastCalibrationDate ?? DateTime.now(),
      firstDate: _commissionDate!, // Restrict >= Commission Date
      lastDate: DateTime.now(), // Restrict <= Today
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _lastCalibrationDate = picked;
        _recalcNextDue();
      });
    }
  }

  // --- DB Save Execution ---
  Future<void> _saveRecord() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Area.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_commissionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date of Commission is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_frequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calibration Frequency is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_lastCalibrationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Last Calibration Date is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'date_of_commission': _commissionDate?.toIso8601String().split('T')[0],
        'area_id': _selectedAreaId,
        'operating_range': _opRangeController.text.trim(),
        'calibration_frequency': _frequency,
        'last_calibration_date': _lastCalibrationDate?.toIso8601String().split(
          'T',
        )[0],
        'next_due_date': _nextDueDate?.toIso8601String().split('T')[0],
        'status': _isActive,
        'is_testing_completed': false,
        'remarks': _remarksController.text.trim(),
      };

      if (widget.existingRecord == null) {
        await _supabase.from('m_testing_equipment').insert(payload);
      } else {
        await _supabase
            .from('m_testing_equipment')
            .update(payload)
            .eq('id', widget.existingRecord!['id']);
      }

      if (mounted) {
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Equipment saved successfully!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  // --- Mark Complete & Save Macro ---
  Future<void> _markCompleteAndSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // Automatically roll dates forward using Today as the actual completion date
    setState(() {
      final now = DateTime.now();
      _lastCalibrationDate = DateTime(now.year, now.month, now.day);
      _recalcNextDue();
    });

    await _saveRecord();
  }

  InputDecoration _minimalDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingRecord != null;

    // Determine bottom button state based on the current due date logic
    final String btnText = !isEditing
        ? "CREATE EQUIPMENT"
        : (_isDue ? "MARK COMPLETE" : "SAVE CHANGES");
    final Color btnColor = (!isEditing || !_isDue)
        ? primary
        : Colors.green.shade600;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24).copyWith(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  isEditing ? "Edit Equipment" : "Register Equipment",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration: _minimalDecor("Equipment Name *"),
                ),
                const SizedBox(height: 16),

                // Area AutoComplete
                RawAutocomplete<Map<String, dynamic>>(
                  textEditingController: _areaSearchController,
                  focusNode: _areaFocusNode,
                  optionsBuilder: (val) {
                    if (val.text.isEmpty) return widget.areas;
                    return widget.areas.where(
                      (opt) => opt['display_name']
                          .toString()
                          .toLowerCase()
                          .contains(val.text.toLowerCase()),
                    );
                  },
                  displayStringForOption: (opt) =>
                      opt['display_name'].toString(),
                  onSelected: (sel) {
                    setState(() {
                      _selectedAreaId = sel['id'].toString();
                    });
                    _areaFocusNode.unfocus();
                  },
                  fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
                    controller: ctrl,
                    focusNode: fNode,
                    validator: (v) =>
                        _selectedAreaId == null ? 'Required' : null,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _minimalDecor("Search Area *").copyWith(
                      suffixIcon: ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                ctrl.clear();
                                setState(() => _selectedAreaId = null);
                              },
                            )
                          : null,
                    ),
                  ),
                  optionsViewBuilder: (ctx, onSel, opts) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          maxWidth: MediaQuery.of(context).size.width - 48,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: opts.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (ctx, idx) => ListTile(
                            title: Text(
                              opts.elementAt(idx)['display_name'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => onSel(opts.elementAt(idx)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Operating Range
                TextFormField(
                  controller: _opRangeController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: _minimalDecor(
                    "Operating Range * (e.g., 0-100°C)",
                  ),
                ),
                const SizedBox(height: 16),

                // Frequency Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  validator: (v) => v == null ? 'Required' : null,
                  dropdownColor: Colors.white,
                  items: _freqOptions
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _frequency = val;
                      _recalcNextDue();
                    });
                  },
                  decoration: _minimalDecor("Calibration Frequency *"),
                ),
                const SizedBox(height: 16),

                // Commission Date
                InkWell(
                  onTap: _pickCommissionDate,
                  child: InputDecorator(
                    decoration: _minimalDecor("Date of Commission *").copyWith(
                      errorText:
                          _commissionDate == null &&
                              _formKey.currentState?.validate() == false
                          ? 'Required'
                          : null,
                    ),
                    child: Text(
                      _commissionDate != null
                          ? "${_commissionDate!.year}-${_commissionDate!.month.toString().padLeft(2, '0')}-${_commissionDate!.day.toString().padLeft(2, '0')}"
                          : "Select Date",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _commissionDate != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Last Calibration
                InkWell(
                  onTap: _pickLastCalibrationDate,
                  child: InputDecorator(
                    decoration: _minimalDecor("Last Calibration Date *")
                        .copyWith(
                          errorText:
                              _lastCalibrationDate == null &&
                                  _formKey.currentState?.validate() == false
                              ? 'Required'
                              : null,
                        ),
                    child: Text(
                      _lastCalibrationDate != null
                          ? "${_lastCalibrationDate!.year}-${_lastCalibrationDate!.month.toString().padLeft(2, '0')}-${_lastCalibrationDate!.day.toString().padLeft(2, '0')}"
                          : "Select Date",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _lastCalibrationDate != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // LOCKED Auto-Calculated Next Due Date
                InputDecorator(
                  decoration: _minimalDecor("Next Due Date (Auto-Calculated)"),
                  child: Text(
                    _nextDueDate != null
                        ? "${_nextDueDate!.year}-${_nextDueDate!.month.toString().padLeft(2, '0')}-${_nextDueDate!.day.toString().padLeft(2, '0')}"
                        : "Pending calculation",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _nextDueDate != null
                          ? primary
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Status Toggle
                if (isEditing) ...[
                  SwitchListTile(
                    title: Text(
                      "Equipment Active",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    subtitle: Text(
                      "Turn off to retire and hide from list",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    value: _isActive,
                    activeThumbColor: Colors.green,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      FocusScope.of(context).unfocus();
                      setState(() => _isActive = val);
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                // Remarks
                TextField(
                  controller: _remarksController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: _minimalDecor("Remarks / Notes (Optional)"),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : (isEditing && _isDue
                              ? _markCompleteAndSave
                              : _saveRecord),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            btnText,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
