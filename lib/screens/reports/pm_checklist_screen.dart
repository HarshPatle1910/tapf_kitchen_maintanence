import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ============================================================================
// 1. DASHBOARD SCREEN (Lists Checklists & Handles Exports)
// ============================================================================
class PMChecklistScreen extends StatefulWidget {
  const PMChecklistScreen({super.key});

  @override
  State<PMChecklistScreen> createState() => _PMChecklistScreenState();
}

class _PMChecklistScreenState extends State<PMChecklistScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _checklists = [];
  List<Map<String, dynamic>> _equipments = [];
  bool _isLoading = true;

  // Search State
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
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

    // Controllers for Autocomplete
    final TextEditingController searchCtrl = TextEditingController();
    final FocusNode focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Export MT-06 Reports", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: RadioListTile<String>(title: Text("By Month", style: GoogleFonts.inter(fontSize: 13)), value: 'month', groupValue: exportMode, onChanged: (v) => setDialogState(() => exportMode = v!), contentPadding: EdgeInsets.zero)),
                    Expanded(child: RadioListTile<String>(title: Text("By Machine", style: GoogleFonts.inter(fontSize: 13)), value: 'machine', groupValue: exportMode, onChanged: (v) => setDialogState(() => exportMode = v!), contentPadding: EdgeInsets.zero)),
                  ],
                ),
                const SizedBox(height: 12),

                if (exportMode == 'month') ...[
                  Row(
                    children: [
                      Expanded(child: DropdownButtonFormField<int>(decoration: InputDecoration(labelText: "Month", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), value: selectedMonth, items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))), onChanged: (v) => setDialogState(() => selectedMonth = v!))),
                      const SizedBox(width: 8),
                      Expanded(child: DropdownButtonFormField<int>(decoration: InputDecoration(labelText: "Year", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), value: selectedYear, items: [2024, 2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(), onChanged: (v) => setDialogState(() => selectedYear = v!))),
                    ],
                  )
                ] else ...[
                  // NEW: Searchable RawAutocomplete in Export Dialog
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
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: navy),
                      decoration: InputDecoration(
                        labelText: "Search Machine",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true, fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    optionsViewBuilder: (ctx, onSel, opts) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0, borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: ListView.separated(
                            padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (ctx, idx) => ListTile(
                              title: Text(opts.elementAt(idx)['name'], style: GoogleFonts.inter(fontSize: 13, color: navy, fontWeight: FontWeight.w600)),
                              onTap: () => onSel(opts.elementAt(idx)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Text("Format:", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ChoiceChip(label: const Text("Excel"), selected: format == 'xlsx', onSelected: (v) => setDialogState(() => format = 'xlsx')),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text("PDF"), selected: format == 'pdf', onSelected: (v) => setDialogState(() => format = 'pdf')),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: golden),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExport(exportMode, selectedMonth, selectedYear, selectedMachineId, format);
              },
              child: const Text("GENERATE"),
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

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: golden)));

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
    // Filter checklists based on search query
    final filteredChecklists = _checklists.where((c) {
      final machineName = (c['equipment']?['name'] ?? '').toString().toLowerCase();
      return machineName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: navy, elevation: 0,
        title: Text("MT-06 Checklists", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: navy),
            tooltip: "Export Reports",
            onPressed: _showExportDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: golden))
          : Column(
        children: [
          // NEW: Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search by Machine Name...",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true, fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden)),
              ),
            ),
          ),
          Expanded(
            child: filteredChecklists.isEmpty
                ? Center(child: Text("No checklists found.", style: GoogleFonts.inter(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredChecklists.length,
              itemBuilder: (ctx, i) {
                final item = filteredChecklists[i];
                return Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePMChecklistScreen(existingChecklist: item)));
                      if (result == true) _fetchData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: navy.withOpacity(0.05), shape: BoxShape.circle),
                            child: const Icon(Icons.engineering, color: navy),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['equipment']?['name'] ?? 'Unknown Machine', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: navy, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text("Date: ${item['date']} • Freq: ${item['frequency']}", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_note, color: Colors.grey),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: golden,
        elevation: 4,
        icon: const Icon(Icons.add, color: navy),
        label: Text("NEW CHECKLIST", style: GoogleFonts.inter(color: navy, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePMChecklistScreen()));
          if (result == true) _fetchData();
        },
      ),
    );
  }
}

// ============================================================================
// 2. CREATE / EDIT FORM SCREEN
// ============================================================================
class CreatePMChecklistScreen extends StatefulWidget {
  final Map<String, dynamic>? existingChecklist;
  const CreatePMChecklistScreen({super.key, this.existingChecklist});

  @override
  State<CreatePMChecklistScreen> createState() => _CreatePMChecklistScreenState();
}

class _CreatePMChecklistScreenState extends State<CreatePMChecklistScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipments = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Header State
  String? _selectedEquipmentId;
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = 'Monthly';
  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'];

  // Detail State (Dynamic Activities)
  final List<Map<String, TextEditingController>> _activities = [];
  final List<String> _statusOptions = ['OK', 'Needs Repair', 'Failed', 'Completed', 'Needs Top-up'];

  // Search Controllers
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

    // Load Header
    _selectedEquipmentId = widget.existingChecklist!['equipment_id'];
    _selectedDate = DateTime.tryParse(widget.existingChecklist!['date']) ?? DateTime.now();
    _selectedFrequency = widget.existingChecklist!['frequency'] ?? 'Monthly';

    // Set the locked controller text
    _machineSearchCtrl.text = widget.existingChecklist!['equipment']?['name'] ?? 'Unknown Machine';

    // Load Activities
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
        // --- CREATE NEW CHECKLIST ---
        final headerRes = await _supabase.from('preventive_maintenance_checklist').insert({
          'date': _selectedDate.toIso8601String().split('T')[0],
          'equipment_id': _selectedEquipmentId,
          'frequency': _selectedFrequency,
        }).select('id').single();
        checklistId = headerRes['id'];
      } else {
        // --- EDIT EXISTING CHECKLIST ---
        checklistId = widget.existingChecklist!['id'];

        // 1. Update Header
        await _supabase.from('preventive_maintenance_checklist').update({
          'date': _selectedDate.toIso8601String().split('T')[0],
          'equipment_id': _selectedEquipmentId,
          'frequency': _selectedFrequency,
        }).eq('id', checklistId);

        // 2. Clear Old Activities
        await _supabase.from('preventive_maintenance_activity').delete().eq('checklist_id', checklistId);
      }

      // Insert All Activities
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: golden)));

    final bool isEditing = widget.existingChecklist != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: navy, elevation: 0,
        title: Text(isEditing ? "Edit PM Checklist" : "New PM Checklist", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER SECTION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Checklist Details", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                  const SizedBox(height: 16),

                  // NEW: Searchable RawAutocomplete or Locked Text Field
                  if (isEditing) ...[
                    TextFormField(
                      initialValue: _machineSearchCtrl.text,
                      enabled: false,
                      style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Machine / Equipment",
                        filled: true, fillColor: Colors.grey.shade200, // Locked appearance
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: navy),
                        decoration: InputDecoration(
                          labelText: "Search Machine",
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true, fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                        ),
                      ),
                      optionsViewBuilder: (ctx, onSel, opts) => Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0, borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 72),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: ListView.separated(
                              padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (ctx, idx) => ListTile(
                                title: Text(opts.elementAt(idx)['name'], style: GoogleFonts.inter(fontSize: 14, color: navy, fontWeight: FontWeight.bold)),
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
                            final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(labelText: "Date", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300))),
                            child: Text("${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: "Frequency", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300))),
                          value: _selectedFrequency,
                          items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.inter(fontWeight: FontWeight.w600)))).toList(),
                          onChanged: (v) => setState(() => _selectedFrequency = v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- ACTIVITIES SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Activities", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                TextButton.icon(
                  onPressed: _addEmptyActivityRow,
                  icon: const Icon(Icons.add_circle, color: golden),
                  label: Text("Add Row", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy)),
                )
              ],
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length,
              itemBuilder: (ctx, i) {
                final activity = _activities[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: navy.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text("Task ${i + 1}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy, fontSize: 12)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeActivityRow(i),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: activity['activity'], decoration: InputDecoration(labelText: "Schedule Activity (e.g. Check Oil)", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 12),
                        TextField(controller: activity['condition'], decoration: InputDecoration(labelText: "Standard Condition", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: "Status", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          value: activity['status']!.text,
                          items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                          onChanged: (v) => setState(() => activity['status']!.text = v!),
                        ),
                        SizedBox(height: 12,),
                        TextField(controller: activity['observation'], decoration: InputDecoration(labelText: "Observation", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _isSaving ? null : _saveChecklist,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEditing ? "UPDATE CHECKLIST" : "SAVE CHECKLIST", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}