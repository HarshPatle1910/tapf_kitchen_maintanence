// ignore_for_file: unused_element, unused_field, unused_local_variable
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
// Ensure correct path if needed

// ============================================================================
// 1. DASHBOARD SCREEN (List of Equipment & Status)
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

  List<Map<String, dynamic>> _equipments = [];
  Map<String, Map<String, dynamic>> _latestSchedules = {};
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedFilter =
      'All Status'; // Options: All Status, Unscheduled, Planned, Achieved

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      // 1. Fetch All Equipments for the Kitchen
      final equipRes = await _supabase
          .from('m_equipment')
          .select('id, name, m_area!inner(m_zone!inner(kitchen_id))')
          .eq('status', true)
          .eq('m_area.m_zone.kitchen_id', targetKitchenId)
          .order('name');

      // 2. Fetch all schedules to find the latest status of each equipment
      final schedRes = await _supabase
          .from('v_preventive_maintenance_schedule')
          .select()
          .eq('kitchen_id', targetKitchenId)
          .order('plan_date', ascending: false);

      Map<String, Map<String, dynamic>> schedulesMap = {};
      for (var s in schedRes) {
        String eqId = s['equipment_id'].toString();
        // Keep the most relevant schedule per machine (prefer Pending/Planned over Achieved)
        if (!schedulesMap.containsKey(eqId)) {
          schedulesMap[eqId] = s;
        } else {
          if (schedulesMap[eqId]!['is_achieved'] == true &&
              s['is_achieved'] == false) {
            schedulesMap[eqId] = s;
          }
        }
      }

      if (mounted) {
        setState(() {
          _equipments = List<Map<String, dynamic>>.from(equipRes);
          _latestSchedules = schedulesMap;
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

    InputDecoration minimalDialogDecor(String label) {
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
                      decoration: minimalDialogDecor("Month"),
                      initialValue: selectedMonth,
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
                      decoration: minimalDialogDecor("Year"),
                      initialValue: selectedYear,
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
                      "Excel (.xlsx)",
                      style: GoogleFonts.inter(
                        fontWeight: format == 'xlsx'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: format == 'xlsx',
                    selectedColor: primary.withValues(alpha: 0.1),
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
                    selectedColor: primary.withValues(alpha: 0.1),
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
    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator(color: primary)),
    );

    try {
      final monthStr = "$year-${month.toString().padLeft(2, '0')}";
      final url = Uri.parse(
        '${ApiConstants.pythonApiBaseUrl}/reports/preventive-maintenance/$monthStr?kitchen_id=$targetKitchenId&format=$format',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download/PM Schedules')
            : Directory(
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var filteredRecords = _equipments.where((eq) {
      final name = (eq['name'] ?? '').toString().toLowerCase();
      if (!name.contains(_searchQuery.toLowerCase())) return false;

      final sched = _latestSchedules[eq['id'].toString()];
      if (_selectedFilter == 'Unscheduled') return sched == null;
      if (_selectedFilter == 'Planned') {
        return sched != null && sched['is_achieved'] == false;
      }
      if (_selectedFilter == 'Achieved') {
        return sched != null && sched['is_achieved'] == true;
      }

      return true;
    }).toList();

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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.filter_alt_outlined,
                      color: primary,
                      size: 20,
                    ),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    dropdownColor: Colors.white,
                    items:
                    [
                      'All Status',
                      'Unscheduled',
                      'Planned',
                      'Achieved',
                    ].map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(val),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedFilter = v!);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredRecords.isEmpty
                  ? Center(
                child: Text(
                  "No equipment matches your filter.",
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: filteredRecords.length,
                separatorBuilder: (_, _) =>
                const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final eq = filteredRecords[i];
                  final sched =
                  _latestSchedules[eq['id'].toString()];

                  bool isAchieved = false;
                  bool isPlanned = false;
                  String statusText = "Unscheduled";
                  Color statusColor = Colors.grey.shade500;
                  Color statusBg = Colors.grey.shade100;

                  if (sched != null) {
                    isAchieved = sched['is_achieved'] == true;
                    isPlanned = sched['is_planned'] == true;
                    if (isAchieved) {
                      statusText =
                      "Achieved: ${sched['achieved_date']}";
                      statusColor = Colors.green.shade700;
                      statusBg = Colors.green.shade50;
                    } else if (isPlanned) {
                      statusText = "Planned: ${sched['plan_date']}";
                      statusColor = primary;
                      statusBg = primary.withValues(alpha: 0.08);
                    }
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateEditPMScheduleScreen(
                                equipmentId: eq['id'],
                                machineName: eq['name'],
                                existingRecord: sched,
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
                        color: Colors.white,
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: Icon(
                              sched == null
                                  ? Icons.precision_manufacturing
                                  : (isAchieved
                                  ? Icons.verified
                                  : Icons.date_range),
                              color: statusColor,
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
                                  eq['name'] ?? 'Unknown Machine',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius:
                                    BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: GoogleFonts.inter(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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

// ============================================================================
// 2. CREATE / EDIT FORM SCREEN (Locked to specific machine)
// ============================================================================
class CreateEditPMScheduleScreen extends StatefulWidget {
  final String equipmentId;
  final String machineName;
  final Map<String, dynamic>? existingRecord;

  const CreateEditPMScheduleScreen({
    super.key,
    required this.equipmentId,
    required this.machineName,
    this.existingRecord,
  });

  @override
  State<CreateEditPMScheduleScreen> createState() =>
      _CreateEditPMScheduleScreenState();
}

class _CreateEditPMScheduleScreenState
    extends State<CreateEditPMScheduleScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color surface = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  String? _currentUserId;
  String _currentUserName = 'Loading...';
  String? _selectedDoneById;
  String? _savedDoneByName;

  bool _isPlanned = true;
  DateTime? _planDate = DateTime.now();

  bool _isAchieved = false;
  DateTime? _achievedDate;

  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final bool isEditing = widget.existingRecord != null;

    if (isEditing) {
      _isPlanned = widget.existingRecord!['is_planned'] ?? false;
      if (widget.existingRecord!['plan_date'] != null) {
        _planDate = DateTime.tryParse(widget.existingRecord!['plan_date']);
      }
      _isAchieved = widget.existingRecord!['is_achieved'] ?? false;
      if (widget.existingRecord!['achieved_date'] != null) {
        _achievedDate = DateTime.tryParse(
          widget.existingRecord!['achieved_date'],
        );
      }
      _remarksController.text = widget.existingRecord!['remarks'] ?? '';
      _selectedDoneById = widget.existingRecord!['done_by_id'];
      _savedDoneByName = widget.existingRecord!['done_by_name'];
    } else {
      _isPlanned = true;
      _isAchieved = false;
    }

    try {
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
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecord() async {
    if (_isPlanned && _planDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Plan date is required.")));
      return;
    }
    if (_isAchieved && _achievedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Achieved date is required.")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'equipment_id': widget.equipmentId,
        'is_planned': _isPlanned,
        'plan_date': _isPlanned
            ? _planDate?.toIso8601String().split('T')[0]
            : null,
        'is_achieved': _isAchieved,
        'achieved_date': _isAchieved
            ? _achievedDate?.toIso8601String().split('T')[0]
            : null,
        'remarks': _remarksController.text.trim(),
        'done_by': _isAchieved ? (_selectedDoneById ?? _currentUserId) : null,
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
            content: Text("Saved Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  InputDecoration _minimalDecor(String label, {bool isLocked = false}) {
    return InputDecoration(
      labelText: label,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }
    final bool isEditing = widget.existingRecord != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: primary,
          elevation: 0,
          title: Text(isEditing ? "Modify Schedule" : "New Schedule"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Equipment",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),

              // Read-only field for the passed machine name
              TextFormField(
                initialValue: widget.machineName,
                enabled: false,
                decoration: _minimalDecor("Machine", isLocked: true).copyWith(
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _minimalDatePicker(
                "Plan Date",
                _planDate,
                    (d) => setState(() => _planDate = d),
                enabled: !isEditing,
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: Text(
                  "Is Task Achieved?",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                value: _isAchieved,
                activeThumbColor: primary,
                onChanged: (v) => setState(() => _isAchieved = v),
              ),

              if (_isAchieved) ...[
                const SizedBox(height: 12),
                _minimalDatePicker(
                  "Achieved Date",
                  _achievedDate,
                      (d) => setState(() => _achievedDate = d),
                ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: _minimalDecor("Remarks"),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSaving ? null : _saveRecord,
                child: Text(
                  isEditing ? "Update Status" : "Save Schedule",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _minimalDatePicker(
      String label,
      DateTime? date,
      Function(DateTime?) onSelected, {
        bool enabled = true,
      }) {
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (d != null) onSelected(d);
      },
      child: InputDecorator(
        decoration: _minimalDecor(label, isLocked: !enabled),
        child: Text(
          date != null
              ? "${date.day}-${date.month}-${date.year}"
              : "Select Date",
        ),
      ),
    );
  }
}