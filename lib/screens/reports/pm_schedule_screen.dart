import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ============================================================================
// 1. DASHBOARD SCREEN
// ============================================================================
class PMScheduleScreen extends StatefulWidget {
  const PMScheduleScreen({super.key});

  @override
  State<PMScheduleScreen> createState() => _PMScheduleScreenState();
}

class _PMScheduleScreenState extends State<PMScheduleScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  String _searchQuery = '';

  // NEW: Updated Filter and Sort States
  String _selectedFilter = 'All Status';
  String _sortOrder = 'Date: Newest';

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
      final res = await _supabase
          .from('v_preventive_maintenance_schedule')
          .select();

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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    String format = 'xlsx';

    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    InputDecoration _minimalDialogDecor(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Export MT-05 Schedule",
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
                "Select Timeframe",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: _minimalDialogDecor("Month"),
                      value: selectedMonth,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(
                            months[i],
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ),
                      ),
                      onChanged: (v) =>
                          setDialogState(() => selectedMonth = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: _minimalDialogDecor("Year"),
                      value: selectedYear,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      items: [2024, 2025, 2026, 2027]
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text(
                                y.toString(),
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedYear = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Format",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      "Word (.xlsx)",
                      style: GoogleFonts.inter(
                        fontWeight: format == 'xlsx'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: format == 'xlsx',
                    selectedColor: primary.withOpacity(0.1),
                    backgroundColor: surface,
                    side: BorderSide.none,
                    showCheckmark: false,
                    onSelected: (v) => setDialogState(() => format = 'xlsx'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      "PDF (.pdf)",
                      style: GoogleFonts.inter(
                        fontWeight: format == 'pdf'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: format == 'pdf',
                    selectedColor: primary.withOpacity(0.1),
                    backgroundColor: surface,
                    side: BorderSide.none,
                    showCheckmark: false,
                    onSelected: (v) => setDialogState(() => format = 'pdf'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "CANCEL",
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExport(selectedMonth, selectedYear, format);
              },
              child: Text(
                "GENERATE",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeExport(int month, int year, String format) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: primary)),
    );

    try {
      final monthStr = "$year-${month.toString().padLeft(2, '0')}";
      final url = Uri.parse(
        '$_pythonApiBaseUrl/reports/preventive-maintenance/$monthStr?format=$format',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Directory? saveDir;
        if (Platform.isAndroid)
          saveDir = Directory('/storage/emulated/0/Download/PM Schedules');
        else
          saveDir = Directory(
            '${(await getApplicationDocumentsDirectory()).path}/PM Schedules',
          );
        if (!await saveDir.exists()) await saveDir.create(recursive: true);

        final expectedFilename = 'MT05_PM_Schedule_$monthStr.$format';
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // --- NEW: Custom UI Dropdown Builder ---
  Widget _buildControlDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey,
            size: 18,
          ),
          style: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Row(
                children: [
                  Icon(icon, size: 16, color: primary),
                  const SizedBox(width: 8),
                  Text(val, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Apply Status Filter & Search
    var filteredRecords = _records.where((r) {
      final machineName = (r['machine_name'] ?? '').toString().toLowerCase();
      final bool matchesSearch = machineName.contains(
        _searchQuery.toLowerCase(),
      );

      bool matchesFilter = true;
      if (_selectedFilter == 'Pending') {
        matchesFilter = (r['is_planned'] == true && r['is_achieved'] != true);
      } else if (_selectedFilter == 'Achieved') {
        matchesFilter = r['is_achieved'] == true;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    // 2. Apply Dynamic Sorting
    filteredRecords.sort((a, b) {
      if (_sortOrder.startsWith('Date')) {
        DateTime dateA =
            DateTime.tryParse(a['plan_date'] ?? '1970-01-01') ?? DateTime(1970);
        DateTime dateB =
            DateTime.tryParse(b['plan_date'] ?? '1970-01-01') ?? DateTime(1970);
        return _sortOrder == 'Date: Newest'
            ? dateB.compareTo(dateA)
            : dateA.compareTo(dateB);
      } else {
        String nameA = (a['machine_name'] ?? '').toString().toLowerCase();
        String nameB = (b['machine_name'] ?? '').toString().toLowerCase();
        return _sortOrder == 'Machine: A-Z'
            ? nameA.compareTo(nameB)
            : nameB.compareTo(nameA);
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          foregroundColor: primary,
          elevation: 0,
          title: Text(
            "PM Schedule (MT-05)",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined, color: primary),
              tooltip: "Export Report",
              onPressed: _showExportDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primary))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Search Machine Name...",
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // NEW: Clean Filter & Sort Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildControlDropdown(
                            value: _selectedFilter,
                            items: ['All Status', 'Pending', 'Achieved'],
                            icon: Icons.filter_alt_outlined,
                            onChanged: (v) {
                              setState(() => _selectedFilter = v!);
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildControlDropdown(
                            value: _sortOrder,
                            items: [
                              'Date: Newest',
                              'Date: Oldest',
                              'Machine: A-Z',
                              'Machine: Z-A',
                            ],
                            icon: Icons.swap_vert,
                            onChanged: (v) {
                              setState(() => _sortOrder = v!);
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: filteredRecords.isEmpty
                        ? Center(
                            child: Text(
                              "No schedules found.",
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filteredRecords.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final item = filteredRecords[i];
                              final bool isAchieved =
                                  item['is_achieved'] == true;
                              final bool isPlanned = item['is_planned'] == true;

                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    FocusScope.of(context).unfocus();
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateEditPMScheduleScreen(
                                              existingRecord: item,
                                            ),
                                      ),
                                    );
                                    if (result == true) _fetchData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isAchieved
                                                ? Colors.green.withOpacity(0.08)
                                                : surface,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: isAchieved
                                                  ? Colors.green.withOpacity(
                                                      0.2,
                                                    )
                                                  : Colors.grey.shade100,
                                            ),
                                          ),
                                          child: Icon(
                                            isAchieved
                                                ? Icons.check_circle_outline
                                                : Icons.date_range,
                                            color: isAchieved
                                                ? Colors.green.shade600
                                                : primary,
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
                                                item['machine_name'] ??
                                                    'Unknown Machine',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 8),

                                              if (isPlanned &&
                                                  item['plan_date'] != null)
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_month,
                                                      size: 14,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Planned: ${item['plan_date']}",
                                                      style: GoogleFonts.inter(
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (isAchieved &&
                                                  item['achieved_date'] !=
                                                      null) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.verified,
                                                      size: 14,
                                                      color:
                                                          Colors.green.shade400,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Achieved: ${item['achieved_date']}",
                                                      style: GoogleFonts.inter(
                                                        color: Colors
                                                            .green
                                                            .shade700,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              if (isAchieved &&
                                                  item['done_by_name'] !=
                                                      null) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 14,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "By: ${item['done_by_name']}",
                                                      style: GoogleFonts.inter(
                                                        color: Colors
                                                            .grey
                                                            .shade500,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
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
                ],
              ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primary,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateEditPMScheduleScreen(),
              ),
            );
            if (result == true) _fetchData();
          },
        ),
      ),
    );
  }
}

// ============================================================================
// 2. CREATE / EDIT FORM SCREEN
// ============================================================================
class CreateEditPMScheduleScreen extends StatefulWidget {
  final Map<String, dynamic>? existingRecord;
  const CreateEditPMScheduleScreen({super.key, this.existingRecord});

  @override
  State<CreateEditPMScheduleScreen> createState() =>
      _CreateEditPMScheduleScreenState();
}

class _CreateEditPMScheduleScreenState
    extends State<CreateEditPMScheduleScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color surface = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipments = [];
  bool _isLoading = true;
  bool _isSaving = false;

  String? _selectedEquipmentId;

  String? _currentUserId;
  String _currentUserName = 'Loading...';
  String? _selectedDoneById;
  String? _savedDoneByName;

  bool _isPlanned = true;
  DateTime? _planDate = DateTime.now();

  bool _isAchieved = false;
  DateTime? _achievedDate;

  final TextEditingController _remarksController = TextEditingController();

  final TextEditingController _machineSearchCtrl = TextEditingController();
  final FocusNode _machineFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _machineSearchCtrl.dispose();
    _machineFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final bool isEditing = widget.existingRecord != null;

    if (isEditing) {
      _machineSearchCtrl.text = widget.existingRecord!['machine_name'] ?? '';
      _selectedEquipmentId = widget.existingRecord!['equipment_id'];

      _isPlanned = widget.existingRecord!['is_planned'] ?? false;
      if (widget.existingRecord!['plan_date'] != null)
        _planDate = DateTime.tryParse(widget.existingRecord!['plan_date']);

      _isAchieved = widget.existingRecord!['is_achieved'] ?? false;
      if (widget.existingRecord!['achieved_date'] != null)
        _achievedDate = DateTime.tryParse(
          widget.existingRecord!['achieved_date'],
        );

      _remarksController.text = widget.existingRecord!['remarks'] ?? '';

      _selectedDoneById = widget.existingRecord!['done_by_id'];
      _savedDoneByName = widget.existingRecord!['done_by_name'];
    } else {
      _isPlanned = true;
      _isAchieved = false;
    }

    try {
      final equipRes = await _supabase
          .from('m_equipment')
          .select('id, name')
          .eq('status', true)
          .order('name');
      List<Map<String, dynamic>> allEquips = List<Map<String, dynamic>>.from(
        equipRes,
      );

      // NEW: Only filter out machines if we are creating a brand NEW schedule
      if (!isEditing) {
        // Fetch machines that already have a pending schedule (planned, but not achieved)
        final plannedRes = await _supabase
            .from('rep_preventive_machine_schedule')
            .select('equipment_id')
            .eq('status', true)
            .eq('is_planned', true)
            .eq('is_achieved', false);

        final Set<String> plannedIds = (plannedRes as List)
            .map((e) => e['equipment_id'].toString())
            .toSet();

        // Remove those machines from the available dropdown
        _equipments = allEquips
            .where((e) => !plannedIds.contains(e['id'].toString()))
            .toList();
      } else {
        _equipments = allEquips;
      }

      final authUser = _supabase.auth.currentUser;
      if (authUser != null) {
        final userProfile = await _supabase
            .from('m_user')
            .select('id, name')
            .eq('id', authUser.id)
            .maybeSingle();
        if (userProfile != null) {
          _currentUserId = userProfile['id'];
          _currentUserName = userProfile['name'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching initial data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecord() async {
    if (_selectedEquipmentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a machine.")));
      return;
    }
    if (_isPlanned && _planDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plan date is required if planned.")),
      );
      return;
    }
    if (_isAchieved && _achievedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Achieved date is required if achieved.")),
      );
      return;
    }

    if (_isPlanned &&
        _planDate != null &&
        _isAchieved &&
        _achievedDate != null) {
      final plan = DateTime(_planDate!.year, _planDate!.month, _planDate!.day);
      final achieved = DateTime(
        _achievedDate!.year,
        _achievedDate!.month,
        _achievedDate!.day,
      );

      if (achieved.isBefore(plan)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Achieved date cannot be earlier than Planned date."),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    if (_isAchieved && _selectedDoneById == null) {
      _selectedDoneById = _currentUserId;
    }

    try {
      final data = {
        'equipment_id': _selectedEquipmentId,
        'is_planned': _isPlanned,
        'plan_date': _isPlanned
            ? _planDate?.toIso8601String().split('T')[0]
            : null,
        'is_achieved': _isAchieved,
        'achieved_date': _isAchieved
            ? _achievedDate?.toIso8601String().split('T')[0]
            : null,
        'remarks': _remarksController.text.trim(),
        'done_by': _isAchieved ? _selectedDoneById : null,
      };

      if (widget.existingRecord == null) {
        await _supabase.from('rep_preventive_machine_schedule').insert(data);
      } else {
        await _supabase
            .from('rep_preventive_machine_schedule')
            .update(data)
            .eq('id', widget.existingRecord!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Schedule Saved Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _minimalDecor(
    String label, {
    bool isLocked = false,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: isLocked ? Colors.grey.shade100 : surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onDateSelected, {
    bool enabled = true,
    DateTime? minimumDate,
  }) {
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              FocusScope.of(context).unfocus();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? (minimumDate ?? DateTime.now()),
                firstDate: minimumDate ?? DateTime(2020),
                lastDate:
                    DateTime.now(), // RESTRICTION: Up to present date only
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: primary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) onDateSelected(picked);
            },
      child: InputDecorator(
        decoration: _minimalDecor(label, isLocked: !enabled),
        child: Text(
          selectedDate != null
              ? "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}"
              : "Select Date",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: !enabled
                ? Colors.grey.shade400
                : (selectedDate != null
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade500),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );

    final bool isEditing = widget.existingRecord != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: primary,
          elevation: 0,
          title: Text(
            isEditing ? "Complete Schedule" : "New Plan",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Equipment",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),

              if (isEditing) ...[
                TextFormField(
                  initialValue: _machineSearchCtrl.text,
                  enabled: false,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration:
                      _minimalDecor(
                        "Machine / Equipment",
                        isLocked: true,
                      ).copyWith(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                ),
              ] else ...[
                RawAutocomplete<Map<String, dynamic>>(
                  textEditingController: _machineSearchCtrl,
                  focusNode: _machineFocusNode,
                  optionsBuilder: (val) {
                    if (val.text.isEmpty) return _equipments;
                    return _equipments.where(
                      (e) => e['name'].toString().toLowerCase().contains(
                        val.text.toLowerCase(),
                      ),
                    );
                  },
                  displayStringForOption: (e) => e['name'],
                  onSelected: (sel) {
                    setState(() => _selectedEquipmentId = sel['id']);
                    _machineFocusNode.unfocus();
                  },
                  fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
                    controller: ctrl,
                    focusNode: fNode,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: _minimalDecor("Search Available Machine...")
                        .copyWith(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),
                          suffixIcon: _machineSearchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ctrl.clear();
                                    setState(() => _selectedEquipmentId = null);
                                  },
                                )
                              : null,
                        ),
                    onChanged: (val) {
                      if (val.isEmpty)
                        setState(() => _selectedEquipmentId = null);
                    },
                  ),
                  optionsViewBuilder: (ctx, onSel, opts) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 2.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          maxWidth: MediaQuery.of(context).size.width - 40,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: opts.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (ctx, idx) => ListTile(
                            dense: true,
                            title: Text(
                              opts.elementAt(idx)['name'],
                              style: GoogleFonts.inter(
                                fontSize: 14,
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
              ],

              const SizedBox(height: 32),
              Text(
                "Schedule Status",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),

              // 1. PLANNED CARD (Locked to True)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Is Planned?",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Switch(
                          value: _isPlanned,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.grey.shade400,
                          onChanged: null, // Strictly Locked!
                        ),
                      ],
                    ),
                    if (_isPlanned) ...[
                      const SizedBox(height: 12),
                      _buildDatePicker(
                        "Plan Date",
                        _planDate,
                        (d) => setState(() => _planDate = d),
                        enabled: !isEditing,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. ACHIEVED CARD (Only accessible if Editing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Is Achieved?",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: !isEditing
                                ? Colors.grey.shade400
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Switch(
                          value: _isAchieved,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.green,
                          onChanged: !isEditing
                              ? null
                              : (v) {
                                  setState(() {
                                    _isAchieved = v;
                                    if (!v) _achievedDate = null;
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                        ),
                      ],
                    ),
                    if (_isAchieved) ...[
                      const SizedBox(height: 12),

                      _buildDatePicker(
                        "Achieved Date",
                        _achievedDate,
                        (d) => setState(() => _achievedDate = d),
                        minimumDate: _isPlanned ? _planDate : null,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: _savedDoneByName ?? _currentUserName,
                        enabled: false,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        decoration:
                            _minimalDecor(
                              "Done By (Auto Allocated)",
                              isLocked: true,
                            ).copyWith(
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                "Additional Notes",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: _minimalDecor("Remarks (Optional)"),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      _saveRecord();
                    },
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
                      isEditing ? "Complete Schedule" : "Create Plan",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
