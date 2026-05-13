import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ============================================================================
// 1. DASHBOARD SCREEN (Minimalistic UI)
// ============================================================================
class PMChecklistScreen extends StatefulWidget {
  const PMChecklistScreen({super.key});

  @override
  State<PMChecklistScreen> createState() => _PMChecklistScreenState();
}

class _PMChecklistScreenState extends State<PMChecklistScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _checklists = [];
  List<Map<String, dynamic>> _equipments = [];
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
      final checklistRes = await _supabase
          .from('preventive_maintenance_checklist')
          .select('*, equipment:m_equipment(name)')
          .eq('status', true)
          .order('date', ascending: false);

      final equipRes = await _supabase
          .from('m_equipment')
          .select('id, name')
          .eq('status', true)
          .order('name');

      if (mounted) {
        setState(() {
          _checklists = List<Map<String, dynamic>>.from(checklistRes);
          _equipments = List<Map<String, dynamic>>.from(equipRes);
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

  // --- EXPORT DIALOG & LOGIC ---
  String get _pythonApiBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (Platform.isAndroid) return 'http://192.168.0.45:8000/api';
    if (Platform.isIOS) return 'http://127.0.0.1:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  void _showExportDialog() {
    String exportMode = 'month'; // 'month' or 'machine'
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    String? selectedMachineId;
    String format = 'xlsx';

    final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final TextEditingController searchCtrl = TextEditingController();
    final FocusNode focusNode = FocusNode();

    InputDecoration _minimalDialogDecor(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        filled: true, fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary)),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Export MT-06 Reports", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Filter Mode", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text("By Month", style: GoogleFonts.inter(fontWeight: exportMode == 'month' ? FontWeight.bold : FontWeight.normal)),
                      selected: exportMode == 'month', selectedColor: primary.withOpacity(0.1), showCheckmark: false, side: BorderSide.none, backgroundColor: surface,
                      onSelected: (v) => setDialogState(() => exportMode = 'month'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text("By Machine", style: GoogleFonts.inter(fontWeight: exportMode == 'machine' ? FontWeight.bold : FontWeight.normal)),
                      selected: exportMode == 'machine', selectedColor: primary.withOpacity(0.1), showCheckmark: false, side: BorderSide.none, backgroundColor: surface,
                      onSelected: (v) => setDialogState(() => exportMode = 'machine'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (exportMode == 'month') ...[
                  Row(
                    children: [
                      Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: _minimalDialogDecor("Month"),
                            value: selectedMonth, borderRadius: BorderRadius.circular(16), dropdownColor: Colors.white,
                            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i], style: GoogleFonts.inter(fontSize: 14)))),
                            onChanged: (v) => setDialogState(() => selectedMonth = v!),
                          )
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: _minimalDialogDecor("Year"),
                            value: selectedYear, borderRadius: BorderRadius.circular(16), dropdownColor: Colors.white,
                            items: [2024, 2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: GoogleFonts.inter(fontSize: 14)))).toList(),
                            onChanged: (v) => setDialogState(() => selectedYear = v!),
                          )
                      ),
                    ],
                  )
                ] else ...[
                  RawAutocomplete<Map<String, dynamic>>(
                    textEditingController: searchCtrl, focusNode: focusNode,
                    optionsBuilder: (val) {
                      if (val.text.isEmpty) return _equipments;
                      return _equipments.where((e) => e['name'].toString().toLowerCase().contains(val.text.toLowerCase()));
                    },
                    displayStringForOption: (e) => e['name'],
                    onSelected: (sel) { setDialogState(() => selectedMachineId = sel['id']); focusNode.unfocus(); },
                    fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
                      controller: ctrl, focusNode: fNode,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
                      decoration: _minimalDialogDecor("Search Machine").copyWith(prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20)),
                    ),
                    optionsViewBuilder: (ctx, onSel, opts) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 2.0, borderRadius: BorderRadius.circular(10),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
                          child: ListView.separated(
                            padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (ctx, idx) => ListTile(
                              dense: true,
                              title: Text(opts.elementAt(idx)['name'], style: GoogleFonts.inter(fontSize: 13, color: primary, fontWeight: FontWeight.w500)),
                              onTap: () => onSel(opts.elementAt(idx)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Text("Format", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                        label: Text("Excel", style: GoogleFonts.inter(fontWeight: format == 'xlsx' ? FontWeight.bold : FontWeight.normal)),
                        selected: format == 'xlsx', selectedColor: primary.withOpacity(0.1), showCheckmark: false, side: BorderSide.none, backgroundColor: surface,
                        onSelected: (v) => setDialogState(() => format = 'xlsx')
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                        label: Text("PDF", style: GoogleFonts.inter(fontWeight: format == 'pdf' ? FontWeight.bold : FontWeight.normal)),
                        selected: format == 'pdf', selectedColor: primary.withOpacity(0.1), showCheckmark: false, side: BorderSide.none, backgroundColor: surface,
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
                _executeExport(exportMode, selectedMonth, selectedYear, selectedMachineId, format);
              },
              child: Text("GENERATE", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _executeExport(String mode, int month, int year, String? machineId, String format) async {
    if (mode == 'machine' && machineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a machine first.')));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primary)));

    try {
      String queryParams = "?format=$format";
      if (mode == 'month') {
        queryParams += "&month=$month&year=$year";
      } else {
        queryParams += "&machine_id=$machineId";
      }

      final url = Uri.parse('$_pythonApiBaseUrl/reports/pm-checklists$queryParams');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final contentDisposition = response.headers['content-disposition'];
        String filename = 'MT06_PM_Report.$format';
        if (contentDisposition != null && contentDisposition.contains('filename=')) {
          filename = contentDisposition.split('filename=')[1].replaceAll('"', '');
        }

        Directory? saveDir;
        if (Platform.isAndroid) {
          saveDir = Directory('/storage/emulated/0/Download/PM Checklists');
        } else {
          saveDir = Directory('${(await getApplicationDocumentsDirectory()).path}/PM Checklists');
        }
        if (!await saveDir.exists()) await saveDir.create(recursive: true);

        final file = File('${saveDir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context);
        OpenFilex.open(file.path);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Export Failed: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredChecklists = _checklists.where((c) {
      final machineName = (c['equipment']?['name'] ?? '').toString().toLowerCase();
      return machineName.contains(_searchQuery.toLowerCase());
    }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background, foregroundColor: primary, elevation: 0,
          title: Text("MT-06 Checklists", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          actions: [
            IconButton(icon: const Icon(Icons.download_outlined, color: primary), tooltip: "Export", onPressed: _showExportDialog)
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primary))
            : Column(
          children: [
            // Clean Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search by Machine Name...",
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
              child: filteredChecklists.isEmpty
                  ? Center(child: Text("No checklists found.", style: GoogleFonts.inter(color: Colors.grey)))
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredChecklists.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final item = filteredChecklists[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePMChecklistScreen(existingChecklist: item)));
                      if (result == true) _fetchData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
                            child: const Icon(Icons.engineering_outlined, color: primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['equipment']?['name'] ?? 'Unknown Machine', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), fontSize: 15)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text("${item['date']}", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                                      child: Text(item['frequency'], style: GoogleFonts.inter(color: primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
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
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePMChecklistScreen()));
            if (result == true) _fetchData();
          },
        ),
      ),
    );
  }
}

// ============================================================================
// 2. CREATE / EDIT FORM SCREEN (Minimalistic UI)
// ============================================================================
class CreatePMChecklistScreen extends StatefulWidget {
  final Map<String, dynamic>? existingChecklist;
  const CreatePMChecklistScreen({super.key, this.existingChecklist});

  @override
  State<CreatePMChecklistScreen> createState() => _CreatePMChecklistScreenState();
}

class _CreatePMChecklistScreenState extends State<CreatePMChecklistScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color surface = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipments = [];
  bool _isLoading = true;
  bool _isSaving = false;

  String? _selectedEquipmentId;
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = 'Monthly';
  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'];

  final List<Map<String, TextEditingController>> _activities = [];
  final List<String> _statusOptions = ['OK', 'Needs Repair', 'Failed', 'Completed', 'Needs Top-up'];

  final TextEditingController _machineSearchCtrl = TextEditingController();
  final FocusNode _machineFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _machineSearchCtrl.dispose();
    _machineFocusNode.dispose();
    for (var a in _activities) {
      a['activity']!.dispose();
      a['condition']!.dispose();
      a['status']!.dispose();
      a['observation']!.dispose();
    }
    super.dispose();
  }

  Future<void> _initData() async {
    await _fetchEquipments();
    await _loadExistingData();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchEquipments() async {
    try {
      final res = await _supabase.from('m_equipment').select('id, name').eq('status', true).order('name');
      _equipments = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint("Error fetching machines: $e");
    }
  }

  Future<void> _loadExistingData() async {
    if (widget.existingChecklist == null) {
      _addEmptyActivityRow();
      return;
    }

    _selectedEquipmentId = widget.existingChecklist!['equipment_id'];
    _selectedDate = DateTime.tryParse(widget.existingChecklist!['date']) ?? DateTime.now();
    _selectedFrequency = widget.existingChecklist!['frequency'] ?? 'Monthly';
    _machineSearchCtrl.text = widget.existingChecklist!['equipment']?['name'] ?? 'Unknown Machine';

    try {
      final res = await _supabase
          .from('preventive_maintenance_activity')
          .select()
          .eq('checklist_id', widget.existingChecklist!['id'])
          .order('created_at', ascending: true);

      if (res.isEmpty) {
        _addEmptyActivityRow();
      } else {
        for (var act in res) {
          _activities.add({
            'activity': TextEditingController(text: act['schedule_activity']),
            'condition': TextEditingController(text: act['standard_condition'] ?? ''),
            'status': TextEditingController(text: act['condition_status'] ?? 'OK'),
            'observation': TextEditingController(text: act['observation'] ?? ''),
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading activities: $e");
      _addEmptyActivityRow();
    }
  }

  void _addEmptyActivityRow() {
    setState(() {
      _activities.add({
        'activity': TextEditingController(),
        'condition': TextEditingController(),
        'status': TextEditingController(text: 'OK'),
        'observation': TextEditingController(),
      });
    });
  }

  void _removeActivityRow(int index) {
    setState(() {
      _activities.removeAt(index);
    });
  }

  Future<void> _saveChecklist() async {
    if (_selectedEquipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a machine.")));
      return;
    }

    for (var a in _activities) {
      if (a['activity']!.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill out all activity names.")));
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      String checklistId;

      if (widget.existingChecklist == null) {
        final headerRes = await _supabase.from('preventive_maintenance_checklist').insert({
          'date': _selectedDate.toIso8601String().split('T')[0],
          'equipment_id': _selectedEquipmentId,
          'frequency': _selectedFrequency,
        }).select('id').single();
        checklistId = headerRes['id'];
      } else {
        checklistId = widget.existingChecklist!['id'];
        await _supabase.from('preventive_maintenance_checklist').update({
          'date': _selectedDate.toIso8601String().split('T')[0],
          'equipment_id': _selectedEquipmentId,
          'frequency': _selectedFrequency,
        }).eq('id', checklistId);

        await _supabase.from('preventive_maintenance_activity').delete().eq('checklist_id', checklistId);
      }

      if (_activities.isNotEmpty) {
        final List<Map<String, dynamic>> activitiesToInsert = _activities.map((a) => {
          'checklist_id': checklistId,
          'schedule_activity': a['activity']!.text,
          'standard_condition': a['condition']!.text,
          'condition_status': a['status']!.text,
          'observation': a['observation']!.text,
        }).toList();

        await _supabase.from('preventive_maintenance_activity').insert(activitiesToInsert);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checklist Saved Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: $e"), backgroundColor: Colors.red));
    }
  }

  InputDecoration _minimalDecor(String label, {bool isLocked = false, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: isLocked ? Colors.grey.shade100 : surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // UPDATED: Added visible borders here
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primary)));

    final bool isEditing = widget.existingChecklist != null;

    // WRAPPED IN GESTURE DETECTOR TO DISMISS KEYBOARD ON TAP
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, foregroundColor: primary, elevation: 0,
          title: Text(isEditing ? "Edit PM Checklist" : "New PM Checklist", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              Text("Header Details", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: primary)),
              const SizedBox(height: 16),

              if (isEditing) ...[
                TextFormField(
                  initialValue: _machineSearchCtrl.text,
                  enabled: false,
                  style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 14),
                  decoration: _minimalDecor("Machine / Equipment", isLocked: true).copyWith(
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                  ),
                ),
              ] else ...[
                RawAutocomplete<Map<String, dynamic>>(
                  textEditingController: _machineSearchCtrl, focusNode: _machineFocusNode,
                  optionsBuilder: (val) {
                    if (val.text.isEmpty) return _equipments;
                    return _equipments.where((e) => e['name'].toString().toLowerCase().contains(val.text.toLowerCase()));
                  },
                  displayStringForOption: (e) => e['name'],
                  onSelected: (sel) { setState(() => _selectedEquipmentId = sel['id']); _machineFocusNode.unfocus(); },
                  fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
                    controller: ctrl, focusNode: fNode,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                    decoration: _minimalDecor("Search Machine").copyWith(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                      suffixIcon: _machineSearchCtrl.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () {
                          ctrl.clear();
                          setState(() => _selectedEquipmentId = null);
                        },
                      )
                          : null,
                    ),
                    onChanged: (val) { if (val.isEmpty) setState(() => _selectedEquipmentId = null); },
                  ),
                  optionsViewBuilder: (ctx, onSel, opts) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 2.0, borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 40),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
                        child: ListView.separated(
                          padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (ctx, idx) => ListTile(
                            dense: true,
                            title: Text(opts.elementAt(idx)['name'], style: GoogleFonts.inter(fontSize: 14, color: primary, fontWeight: FontWeight.w500)),
                            onTap: () => onSel(opts.elementAt(idx)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        FocusScope.of(context).unfocus(); // Dismiss keyboard when opening date picker
                        final picked = await showDatePicker(
                          context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now(),
                          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primary)), child: child!),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      child: InputDecorator(
                        decoration: _minimalDecor("Date"),
                        child: Text("${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}", style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: const Color(0xFF0F172A))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _minimalDecor("Frequency"),
                      value: _selectedFrequency,
                      borderRadius: BorderRadius.circular(16), dropdownColor: Colors.white,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: const Color(0xFF0F172A))))).toList(),
                      onChanged: (v) => setState(() => _selectedFrequency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- ACTIVITIES SECTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Activities", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: primary)),
                  TextButton.icon(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _addEmptyActivityRow();
                    },
                    icon: const Icon(Icons.add_circle_outline, color: primary, size: 18),
                    label: Text("Add Row", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primary)),
                  )
                ],
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) {
                  final activity = _activities[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                              child: Text("Task ${i + 1}", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 12)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                _removeActivityRow(i);
                              },
                              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(controller: activity['activity'], style: GoogleFonts.inter(fontSize: 14), decoration: _minimalDecor("Schedule Activity", hint: "e.g. Check Oil")),
                        const SizedBox(height: 12),
                        TextField(controller: activity['condition'], style: GoogleFonts.inter(fontSize: 14), decoration: _minimalDecor("Standard Condition")),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: _minimalDecor("Status"),
                          value: activity['status']!.text,
                          borderRadius: BorderRadius.circular(16), dropdownColor: Colors.white,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)))).toList(),
                          onChanged: (v) => setState(() => activity['status']!.text = v!),
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: activity['observation'], style: GoogleFonts.inter(fontSize: 14), decoration: _minimalDecor("Observation")),
                      ],
                    ),
                  );
                },
              )
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
              onPressed: _isSaving ? null : () {
                FocusScope.of(context).unfocus();
                _saveChecklist();
              },
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEditing ? "Save Changes" : "Save Checklist", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}