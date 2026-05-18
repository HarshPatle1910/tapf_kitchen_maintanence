import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart'; // <-- FIXED: Added missing import

import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';


// ============================================================================
// 1. DASHBOARD SCREEN (Minimalistic UI)
// ============================================================================
class TestingEquipmentScreen extends StatefulWidget {
  const TestingEquipmentScreen({super.key});

  @override
  State<TestingEquipmentScreen> createState() => _TestingEquipmentScreenState();
}

class _TestingEquipmentScreenState extends State<TestingEquipmentScreen> {
  // Single Primary Color as requested
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  // Search and Filter State
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // Options: 'All', 'Verified', 'Due'

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
    setState(() => _isLoading = true);

    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await _supabase
          .from('v_testing_equipment_master')
          .select()
          .eq('kitchen_id', targetKitchenId) // <--- Added Filter
          .order('next_due_date', ascending: true);

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
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

  // --- EXPORT LOGIC ---
  void _showExportDialog() {
    String format = 'docx';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Export Master List", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Generate the MT-03 equipment master list.",
                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Text("Format", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                      label: Text("Word", style: GoogleFonts.inter(fontWeight: format == 'docx' ? FontWeight.bold : FontWeight.normal)),
                      selected: format == 'docx',
                      selectedColor: primary.withOpacity(0.1),
                      showCheckmark: false,
                      onSelected: (v) => setDialogState(() => format = 'docx')),
                  const SizedBox(width: 8),
                  ChoiceChip(
                      label: Text("PDF", style: GoogleFonts.inter(fontWeight: format == 'pdf' ? FontWeight.bold : FontWeight.normal)),
                      selected: format == 'pdf',
                      selectedColor: primary.withOpacity(0.1),
                      showCheckmark: false,
                      onSelected: (v) => setDialogState(() => format = 'pdf')),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.grey.shade600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExport(format);
              },
              child: Text("GENERATE", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            )
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
      final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/testing-equipments?kitchen_id=$targetKitchenId&format=$format');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        String expectedFilename = 'MT03_Master_List_Testing_Equipments.$format';
        Directory? saveDir;
        if (Platform.isAndroid) saveDir = Directory('/storage/emulated/0/Download/Equipment Reports');
        else saveDir = Directory('${(await getApplicationDocumentsDirectory()).path}/Equipment Reports');
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

  @override
  Widget build(BuildContext context) {
    // Apply Search AND Status Filters
    final filteredRecords = _records.where((r) {
      final name = (r['equipment_name'] ?? '').toString().toLowerCase();
      final location = (r['location'] ?? '').toString().toLowerCase();
      final bool matchesSearch = name.contains(_searchQuery.toLowerCase()) || location.contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (_selectedFilter == 'Verified') {
        matchesFilter = r['is_testing_completed'] == true;
      } else if (_selectedFilter == 'Due') {
        matchesFilter = r['is_testing_completed'] != true;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background, foregroundColor: primary, elevation: 0,
        title: Text("MT-03 Master List", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        actions: [
          IconButton(icon: const Icon(Icons.download_outlined, color: primary), tooltip: "Export", onPressed: _showExportDialog)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar with Clear 'X' Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search equipment or location...",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true, fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // 2. Status Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', 'Verified', 'Due'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                        filter,
                        style: GoogleFonts.inter(
                            color: _selectedFilter == filter ? primary : Colors.grey.shade600,
                            fontWeight: _selectedFilter == filter ? FontWeight.w600 : FontWeight.normal
                        )
                    ),
                    selected: _selectedFilter == filter,
                    selectedColor: primary.withOpacity(0.1),
                    backgroundColor: surface,
                    side: BorderSide.none,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // 3. Minimal List View
          Expanded(
            child: filteredRecords.isEmpty
                ? Center(child: Text("No equipment found.", style: GoogleFonts.inter(color: Colors.grey)))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredRecords.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final item = filteredRecords[i];
                final bool isCompleted = item['is_testing_completed'] == true;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditTestingEquipmentScreen(existingRecord: item)));
                    if (result == true) _fetchData();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['equipment_name'] ?? 'Unknown Equipment', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(item['location'] ?? 'Unknown Location', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: isCompleted ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                              child: Text(isCompleted ? "Verified" : "Due", style: GoogleFonts.inter(color: isCompleted ? Colors.green.shade700 : Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildMinimalDetail("Range", item['operating_range'] ?? 'N/A'),
                            _buildMinimalDetail("Freq", item['calibration_frequency'] ?? 'N/A'),
                            _buildMinimalDetail("Due", item['next_due_date'] ?? 'N/A', isWarning: !isCompleted),
                          ],
                        )
                      ],
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
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEditTestingEquipmentScreen()));
          if (result == true) _fetchData();
        },
      ),
    );
  }

  Widget _buildMinimalDetail(String label, String value, {bool isWarning = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(color: isWarning ? Colors.red.shade700 : primary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. CREATE / EDIT FORM SCREEN (Minimalistic & RawAutocomplete)
// ============================================================================
class CreateEditTestingEquipmentScreen extends StatefulWidget {
  final Map<String, dynamic>? existingRecord;

  const CreateEditTestingEquipmentScreen({super.key, this.existingRecord});

  @override
  State<CreateEditTestingEquipmentScreen> createState() => _CreateEditTestingEquipmentScreenState();
}

class _CreateEditTestingEquipmentScreenState extends State<CreateEditTestingEquipmentScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color surface = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _operatingRangeController = TextEditingController();
  final _calibrationFreqController = TextEditingController();
  final _remarksController = TextEditingController();

  // Area Autocomplete
  final TextEditingController _areaSearchCtrl = TextEditingController();
  final FocusNode _areaFocusNode = FocusNode();

  String? _selectedAreaId;
  DateTime? _dateOfCommission;
  DateTime? _lastCalibrationDate;
  DateTime? _nextDueDate;
  bool _isTestingCompleted = false;

  List<Map<String, dynamic>> _areas = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _operatingRangeController.dispose();
    _calibrationFreqController.dispose();
    _remarksController.dispose();
    _areaSearchCtrl.dispose();
    _areaFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    if (widget.existingRecord != null) {
      _nameController.text = widget.existingRecord!['equipment_name'] ?? '';
      _operatingRangeController.text = widget.existingRecord!['operating_range'] ?? '';
      _calibrationFreqController.text = widget.existingRecord!['calibration_frequency'] ?? '';
      _remarksController.text = widget.existingRecord!['remarks'] ?? '';
      _isTestingCompleted = widget.existingRecord!['is_testing_completed'] == true;

      String existingLocation = widget.existingRecord!['location'] ?? '';
      if (existingLocation != 'N/A') _areaSearchCtrl.text = existingLocation;

      if (widget.existingRecord!['date_of_commission'] != null) _dateOfCommission = DateTime.tryParse(widget.existingRecord!['date_of_commission']);
      if (widget.existingRecord!['last_calibration_date'] != null) _lastCalibrationDate = DateTime.tryParse(widget.existingRecord!['last_calibration_date']);
      if (widget.existingRecord!['next_due_date'] != null) _nextDueDate = DateTime.tryParse(widget.existingRecord!['next_due_date']);
    }

    try {
      final areaRes = await _supabase.from('m_area').select('id, area_name').eq('status', true).order('area_name');
      _areas = List<Map<String, dynamic>>.from(areaRes);

      if (widget.existingRecord != null) {
        final baseRec = await _supabase.from('m_testing_equipment').select('area_id').eq('id', widget.existingRecord!['id']).single();
        _selectedAreaId = baseRec['area_id'];
      }
    } catch (e) {
      debugPrint("Error loading dropdown data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecord() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Equipment Name is required.")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        if (widget.existingRecord == null) 'name': _nameController.text.trim(),
        'area_id': _selectedAreaId,
        'operating_range': _operatingRangeController.text.trim(),
        'calibration_frequency': _calibrationFreqController.text.trim(),
        'remarks': _remarksController.text.trim(),
        'is_testing_completed': _isTestingCompleted,
        'date_of_commission': _dateOfCommission?.toIso8601String().split('T')[0],
        'last_calibration_date': _lastCalibrationDate?.toIso8601String().split('T')[0],
        'next_due_date': _nextDueDate?.toIso8601String().split('T')[0],
      };

      if (widget.existingRecord == null) {
        await _supabase.from('m_testing_equipment').insert(data);
      } else {
        await _supabase.from('m_testing_equipment').update(data).eq('id', widget.existingRecord!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: $e"), backgroundColor: Colors.red));
    }
  }

  InputDecoration _minimalDecor(String label, {bool isLocked = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: isLocked ? Colors.grey.shade100 : surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime?) onDateSelected) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onDateSelected(picked);
      },
      child: InputDecorator(
        decoration: _minimalDecor(label),
        child: Text(
            selectedDate != null ? "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}" : "Select Date",
            style: GoogleFonts.inter(color: selectedDate != null ? primary : Colors.grey.shade400, fontWeight: FontWeight.w500, fontSize: 14)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingRecord != null;
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primary)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: primary, elevation: 0,
        title: Text(isEditing ? "Edit Equipment" : "Add Equipment", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Name Field (LOCKED IF EDITING)
            TextFormField(
              controller: _nameController,
              enabled: !isEditing,
              style: GoogleFonts.inter(color: isEditing ? Colors.grey.shade500 : primary, fontWeight: FontWeight.w600, fontSize: 15),
              decoration: _minimalDecor("Equipment Name *", isLocked: isEditing).copyWith(
                prefixIcon: isEditing ? const Icon(Icons.lock_outline, color: Colors.grey, size: 18) : null,
              ),
            ),
            const SizedBox(height: 16),

            // 2. Area RawAutocomplete
            RawAutocomplete<Map<String, dynamic>>(
              textEditingController: _areaSearchCtrl,
              focusNode: _areaFocusNode,
              optionsBuilder: (val) {
                if (val.text.isEmpty) return _areas;
                return _areas.where((a) => a['area_name'].toString().toLowerCase().contains(val.text.toLowerCase()));
              },
              displayStringForOption: (a) => a['area_name'],
              onSelected: (sel) { setState(() => _selectedAreaId = sel['id']); _areaFocusNode.unfocus(); },
              fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
                controller: ctrl, focusNode: fNode,
                style: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w500, fontSize: 15),
                decoration: _minimalDecor("Location / Area").copyWith(
                  suffixIcon: _areaSearchCtrl.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      ctrl.clear();
                      setState(() => _selectedAreaId = null);
                    },
                  )
                      : const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ),
                onChanged: (val) { if (val.isEmpty) setState(() => _selectedAreaId = null); },
              ),
              optionsViewBuilder: (ctx, onSel, opts) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 2.0, borderRadius: BorderRadius.circular(10), shadowColor: Colors.black.withOpacity(0.2),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 40),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
                    child: ListView.separated(
                      padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (ctx, idx) => ListTile(
                        dense: true,
                        title: Text(opts.elementAt(idx)['area_name'], style: GoogleFonts.inter(fontSize: 14, color: primary, fontWeight: FontWeight.w500)),
                        onTap: () => onSel(opts.elementAt(idx)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Configs
            Row(
              children: [
                Expanded(child: TextField(controller: _operatingRangeController, style: GoogleFonts.inter(fontSize: 14), decoration: _minimalDecor("Operating Range"))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _calibrationFreqController, style: GoogleFonts.inter(fontSize: 14), decoration: _minimalDecor("Calib. Freq (e.g. 1 Yr)"))),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Dates
            _buildDatePicker("Date of Commission", _dateOfCommission, (d) => setState(() => _dateOfCommission = d)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDatePicker("Last Calibration", _lastCalibrationDate, (d) => setState(() => _lastCalibrationDate = d))),
                const SizedBox(width: 12),
                Expanded(child: _buildDatePicker("Next Due Date", _nextDueDate, (d) => setState(() => _nextDueDate = d))),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Status Toggle (Clean look)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text("Testing Completed", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: primary)),
                value: _isTestingCompleted,
                activeColor: Colors.white,
                activeTrackColor: Colors.green.shade500,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
                onChanged: (val) => setState(() => _isTestingCompleted = val),
              ),
            ),
            const SizedBox(height: 16),

            // 6. Remarks
            TextField(
              controller: _remarksController,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: _minimalDecor("Remarks / Notes"),
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
                backgroundColor: primary, minimumSize: const Size(double.infinity, 54), elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: _isSaving ? null : _saveRecord,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEditing ? "Save Changes" : "Create Equipment", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}