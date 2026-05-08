import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

// Import newly separated UI components
import '../../widgets/ticket/ticket_status_banner.dart';
import '../../widgets/ticket/ticket_timeline.dart';
import '../../widgets/ticket/ticket_form_fields.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? ticket;

  const TicketDetailScreen({super.key, this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _causeController = TextEditingController();
  final _actionTakenController = TextEditingController();
  final _areaSearchController = TextEditingController();
  final _equipSearchController = TextEditingController();
  final _workerSearchController = TextEditingController();
  final _spareSearchController = TextEditingController();
  final _spareQtyController = TextEditingController();
  final _toolSearchController = TextEditingController();

  final FocusNode _areaFocusNode = FocusNode();
  final FocusNode _equipFocusNode = FocusNode();
  final FocusNode _workerFocusNode = FocusNode();
  final FocusNode _spareFocusNode = FocusNode();
  final FocusNode _toolFocusNode = FocusNode();

  String? _selectedAreaId;
  String? _selectedWorker;
  DateTime? _breakdownTime;
  String _priority = 'MEDIUM';
  String _category = 'In Breakdown Condition';
  bool _isLoading = false;

  List<Map<String, dynamic>> _selectedEquipments = [];
  List<Map<String, dynamic>> _usedSpares = [];
  List<Map<String, dynamic>> _usedTools = [];

  final List<XFile> _selectedImages = [];
  List<String> _beforeUrls = [];
  List<String> _afterUrls = [];
  bool _isLoadingMedia = false;

  List<Map<String, dynamic>> _allAreas = [];
  List<Map<String, dynamic>> _allEquipment = [];
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _availableSpares = [];
  List<Map<String, dynamic>> _availableTools = [];

  Map<String, dynamic>? _currentlySelectedSpareToAdd;
  Map<String, dynamic>? _currentlySelectedToolToAdd;

  bool get isEditing => widget.ticket != null;
  String get currentStatus => widget.ticket?['status'] ?? 'RAISED';
  bool get isTicketClosed => currentStatus == 'VERIFIED';

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      _titleController.text = widget.ticket!['title'] ?? '';
      _causeController.text = widget.ticket!['cause_of_issue'] ?? '';
      _actionTakenController.text = widget.ticket!['action_taken'] ?? '';
      _priority = widget.ticket!['priority'] ?? 'MEDIUM';
      _category = widget.ticket!['category'] ?? 'In Breakdown Condition';
      _selectedAreaId = widget.ticket!['area_id']?.toString();
      _selectedWorker = widget.ticket!['assigned_to_id']?.toString();

      if (widget.ticket!['breakdown_time'] != null) {
        _breakdownTime = DateTime.parse(widget.ticket!['breakdown_time']).toLocal();
      }

      _fetchMedia();
      _fetchUsedSpares();
      _fetchUsedTools();
    } else {
      _breakdownTime = DateTime.now();
    }

    _fetchDropdownData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _causeController.dispose();
    _actionTakenController.dispose();
    _areaSearchController.dispose();
    _equipSearchController.dispose();
    _workerSearchController.dispose();
    _spareSearchController.dispose();
    _spareQtyController.dispose();
    _toolSearchController.dispose();
    _areaFocusNode.dispose();
    _equipFocusNode.dispose();
    _workerFocusNode.dispose();
    _spareFocusNode.dispose();
    _toolFocusNode.dispose();
    super.dispose();
  }

  String _formatToCamelCase(String text) {
    if (text.trim().isEmpty) return text;
    return text.split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  String _formatDateTimeLocal(DateTime? d) {
    if (d == null) return 'Select Breakdown Time *';
    final int hour12 = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final String amPm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} $hour12:${d.minute.toString().padLeft(2, '0')} $amPm';
  }

  Future<void> _pickBreakdownTime() async {
    final DateTime? date = await showDatePicker(
      context: context, initialDate: _breakdownTime ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: navy)), child: child!),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(_breakdownTime ?? DateTime.now()),
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: navy)), child: child!),
    );
    if (time == null) return;

    setState(() { _breakdownTime = DateTime(date.year, date.month, date.day, time.hour, time.minute); });
  }

  Future<void> _fetchMedia() async {
    setState(() => _isLoadingMedia = true);
    try {
      final mediaRecords = await _supabase.from('ticket_media').select('storage_path, upload_stage').eq('ticket_id', widget.ticket!['id']);
      List<String> before = [];
      List<String> after = [];

      for (var record in mediaRecords) {
        final url = _supabase.storage.from('ticket-media').getPublicUrl(record['storage_path']);
        if (record['upload_stage'] == 'COMPLETED') after.add(url);
        else before.add(url);
      }
      if (mounted) setState(() { _beforeUrls = before; _afterUrls = after; });
    } catch (e) {
      debugPrint("Error fetching media: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMedia = false);
    }
  }

  Future<void> _fetchUsedSpares() async {
    try {
      final records = await _supabase.from('spare_ticket').select('used_qty, m_spares(*, m_vendor(name), spare_tracker(current_qty))').eq('ticket_id', widget.ticket!['id']);
      if (mounted) setState(() { _usedSpares = records.map((r) => {'qty': r['used_qty'], 'spare': r['m_spares'], 'is_existing': true}).toList(); });
    } catch (e) { debugPrint("Error fetching used spares: $e"); }
  }

  Future<void> _fetchUsedTools() async {
    try {
      final records = await _supabase.from('ticket_tools').select('m_tools(*)').eq('ticket_id', widget.ticket!['id']);
      if (mounted) setState(() { _usedTools = records.map((r) => {'tool': r['m_tools'], 'is_existing': true}).toList(); });
    } catch (e) { debugPrint("Error fetching used tools: $e"); }
  }

  Future<void> _fetchDropdownData() async {
    try {
      final areasData = await _supabase.from('m_area').select().eq('status', true);
      final equipsData = await _supabase.from('m_equipment').select().eq('status', true);
      final staffData = await _supabase.from('m_user').select('*, user_kitchens(kitchen_id)').eq('status', true);

      final kitchenId = isEditing ? widget.ticket!['kitchen_id'] : context.read<AuthProvider>().assignedKitchens.firstOrNull?['id'];

      final sparesData = await _supabase.from('m_spares').select('*, m_vendor(name), spare_tracker(current_qty)').eq('status', true).eq('kitchen_id', kitchenId ?? '');
      final toolsData = await _supabase.from('m_tools').select('*').eq('status', true).eq('kitchen_id', kitchenId ?? '');

      if (mounted) {
        setState(() {
          _allAreas = List<Map<String, dynamic>>.from(areasData);
          for (var a in _allAreas) { a['display_name'] = a['area_name']; }

          _allEquipment = List<Map<String, dynamic>>.from(equipsData);
          for (var e in _allEquipment) { e['display_name'] = e['name']; }

          _workers = List<Map<String, dynamic>>.from(staffData);
          for (var w in _workers) { w['display_name'] = w['name']; }

          _availableSpares = List<Map<String, dynamic>>.from(sparesData);
          for (var s in _availableSpares) {
            String vendorName = s['m_vendor']?['name'] != null ? " (${s['m_vendor']['name']})" : "";
            s['display_name'] = "${s['spare_name']}$vendorName";
          }

          _availableTools = List<Map<String, dynamic>>.from(toolsData);
          for (var t in _availableTools) { t['display_name'] = t['tool_name']; }

          if (isEditing && _selectedWorker != null) {
            final worker = _workers.firstWhere((w) => w['id'].toString() == _selectedWorker, orElse: () => <String, dynamic>{});
            if (worker.isNotEmpty) _workerSearchController.text = worker['display_name'];
            else _workerSearchController.text = widget.ticket!['assigned_to']?['name'] ?? 'Inactive Worker';
          }

          if (isEditing && _selectedAreaId != null) {
            final area = _allAreas.firstWhere((a) => a['id'].toString() == _selectedAreaId, orElse: () => <String, dynamic>{});
            if (area.isNotEmpty) _areaSearchController.text = area['display_name'];
            _fetchLinkedEquipments();
          }
        });
      }
    } catch (e) { debugPrint("Dropdown Fetch Error: $e"); }
  }

  Future<void> _fetchLinkedEquipments() async {
    try {
      final linkedEq = await _supabase.from('ticket_equipments').select('m_equipment(*)').eq('ticket_id', widget.ticket!['id']);
      if (mounted) {
        setState(() {
          _selectedEquipments = List<Map<String, dynamic>>.from(linkedEq.map((e) {
            var eq = e['m_equipment'];
            eq['display_name'] = eq['name'];
            return eq;
          }));
        });
      }
    } catch (e) { debugPrint("Error fetching linked equipment: $e"); }
  }

  void _showImageSourceDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 12),
              Text("Add Photo", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: navy)),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: navy.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: navy)),
                title: Text('Take a Photo (Camera)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(ctx); _pickImages(fromCamera: true); },
              ),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: navy.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.photo_library_rounded, color: navy)),
                title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(ctx); _pickImages(fromCamera: false); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages({required bool fromCamera}) async {
    final picker = ImagePicker();
    List<XFile> pickedFiles = [];

    if (fromCamera) {
      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (image != null) pickedFiles.add(image);
    } else {
      final images = await picker.pickMultiImage(imageQuality: 70);
      pickedFiles.addAll(images);
    }

    if (pickedFiles.isEmpty) return;
    List<XFile> validImages = [];
    bool filesDropped = false;

    for (var img in pickedFiles) {
      if ((await img.length()) <= 5242880) validImages.add(img);
      else filesDropped = true;
    }

    if (filesDropped && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Some images skipped (exceeded 5MB).', style: GoogleFonts.inter()), backgroundColor: Colors.orange));
    setState(() => _selectedImages.addAll(validImages));
  }

  int _getSpareCurrentQty(Map<String, dynamic> spare) {
    final tracker = spare['spare_tracker'];
    if (tracker == null) return 0;
    if (tracker is List && tracker.isNotEmpty) return tracker[0]['current_qty'] ?? 0;
    if (tracker is Map) return tracker['current_qty'] ?? 0;
    return 0;
  }

  void _addSpareToTicket() {
    if (_currentlySelectedSpareToAdd == null) return;
    int qtyToAdd = int.tryParse(_spareQtyController.text.trim()) ?? 0;

    if (qtyToAdd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quantity must be greater than 0"), backgroundColor: Colors.red));
      return;
    }

    int availableQty = _getSpareCurrentQty(_currentlySelectedSpareToAdd!);
    if (qtyToAdd > availableQty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Only $availableQty available in stock!"), backgroundColor: Colors.red));
      return;
    }

    if (_usedSpares.any((item) => item['spare']['id'] == _currentlySelectedSpareToAdd!['id'])) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Spare already added. Remove and add again to adjust quantity."), backgroundColor: Colors.orange));
      return;
    }

    setState(() {
      _usedSpares.add({'spare': _currentlySelectedSpareToAdd, 'qty': qtyToAdd, 'is_existing': false});
      _currentlySelectedSpareToAdd = null;
      _spareSearchController.clear();
      _spareQtyController.clear();
      _spareFocusNode.unfocus();
    });
  }

  void _addToolToTicket() {
    if (_currentlySelectedToolToAdd == null) return;
    if (_usedTools.any((item) => item['tool']['id'] == _currentlySelectedToolToAdd!['id'])) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tool already added to this ticket."), backgroundColor: Colors.orange));
      return;
    }

    setState(() {
      _usedTools.add({'tool': _currentlySelectedToolToAdd, 'is_existing': false});
      _currentlySelectedToolToAdd = null;
      _toolSearchController.clear();
      _toolFocusNode.unfocus();
    });
  }

  // --- SUBMIT / UPDATE LOGIC ---
  Future<void> _uploadImages(String ticketId, String stage) async {
    final userId = _supabase.auth.currentUser?.id;
    for (var img in _selectedImages) {
      final fileExt = img.name.contains('.') ? img.name.split('.').last : 'jpg';
      final fileName = '${stage.toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}.$fileExt';
      final storagePath = '$ticketId/$fileName';

      final imageBytes = await img.readAsBytes();
      await _supabase.storage.from('ticket-media').uploadBinary(storagePath, imageBytes);
      await _supabase.from('ticket_media').insert({
        'ticket_id': ticketId, 'storage_path': storagePath, 'upload_stage': stage, 'uploaded_by': userId,
      });
    }
  }

  Future<void> _submitNewTicket() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _titleController.text = _formatToCamelCase(_titleController.text);

    if (!_formKey.currentState!.validate() || _selectedAreaId == null || _breakdownTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all required fields including Area and Breakdown Time.', style: GoogleFonts.inter()), backgroundColor: Colors.red));
      return;
    }

    final availableEquipments = _allEquipment.where((e) => e['area_id']?.toString() == _selectedAreaId).toList();
    if (availableEquipments.isNotEmpty && _selectedEquipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select at least one Equipment.', style: GoogleFonts.inter()), backgroundColor: Colors.red));
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload at least one photo of the issue.', style: GoogleFonts.inter()), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProv = context.read<AuthProvider>();
      final ticketProv = context.read<TicketProvider>();
      final userId = _supabase.auth.currentUser?.id;

      dynamic exactKitchenId;
      if (authProv.assignedKitchens.isNotEmpty) {
        int index = authProv.assignedKitchens.indexWhere((k) => k['id'].toString() == ticketProv.kitchenFilter);
        final activeKitchen = index != -1 ? authProv.assignedKitchens[index] : authProv.assignedKitchens.first;
        exactKitchenId = activeKitchen['id'];
      } else {
        final kitchenResp = await _supabase.from('m_kitchen').select('id').limit(1).single();
        exactKitchenId = kitchenResp['id'];
      }

      Map<String, dynamic> insertData = {
        'title': _titleController.text, 'cause_of_issue': _causeController.text, 'priority': _priority, 'category': _category,
        'area_id': _selectedAreaId, 'kitchen_id': exactKitchenId, 'raised_by_id': userId,
        'breakdown_time': _breakdownTime!.toUtc().toIso8601String(),
      };

      final newTicket = await _supabase.from('tickets').insert(insertData).select().single();

      final equipmentInserts = _selectedEquipments.map((eq) => {'ticket_id': newTicket['id'], 'equipment_id': eq['id']}).toList();
      if (equipmentInserts.isNotEmpty) await _supabase.from('ticket_equipments').insert(equipmentInserts);

      if (_selectedImages.isNotEmpty) await _uploadImages(newTicket['id'], 'RAISED');

      if (mounted) {
        context.read<TicketProvider>().refreshTickets();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ticket Raised successfully!', style: GoogleFonts.inter()), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTicketStatus(String? nextStatus, bool isAdmin) async {
    FocusManager.instance.primaryFocus?.unfocus();
    _titleController.text = _formatToCamelCase(_titleController.text);

    if (nextStatus == 'COMPLETED') {
      if (_actionTakenController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter the Action Taken.', style: GoogleFonts.inter()), backgroundColor: Colors.red));
        return;
      }
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload Completion Photos.', style: GoogleFonts.inter()), backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final nowISO = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{'updated_at': nowISO};

      if (nextStatus != null) {
        updates['status'] = nextStatus;
        if (nextStatus == 'IN_PROGRESS') updates['repair_start_time'] = nowISO;
        else if (nextStatus == 'COMPLETED') {
          updates['ticket_completion_time'] = nowISO;
          updates['action_taken'] = _actionTakenController.text.trim();
        }
        else if (nextStatus == 'VERIFIED') updates['verified_by_id'] = _supabase.auth.currentUser?.id;
      } else {
        if (_actionTakenController.text.isNotEmpty) updates['action_taken'] = _actionTakenController.text.trim();
      }

      if (isAdmin && !isTicketClosed) {
        updates['title'] = _titleController.text; updates['cause_of_issue'] = _causeController.text;
        updates['priority'] = _priority; updates['category'] = _category; updates['area_id'] = _selectedAreaId;
        if (_breakdownTime != null) updates['breakdown_time'] = _breakdownTime!.toUtc().toIso8601String();
        if (_selectedWorker != null) {
          updates['assigned_to_id'] = _selectedWorker;
          if (currentStatus == 'RAISED') updates['status'] = 'ASSIGNED';
        }

        await _supabase.from('ticket_equipments').delete().eq('ticket_id', widget.ticket!['id']);
        if (_selectedEquipments.isNotEmpty) {
          final newMappings = _selectedEquipments.map((eq) => {'ticket_id': widget.ticket!['id'], 'equipment_id': eq['id']}).toList();
          await _supabase.from('ticket_equipments').insert(newMappings);
        }
      }

      if (_usedTools.isNotEmpty) {
        for (var item in _usedTools) {
          if (item['is_existing'] == true) continue;
          await _supabase.from('ticket_tools').insert({
            'ticket_id': widget.ticket!['id'], 'tool_id': item['tool']['id'], 'employee_id': _supabase.auth.currentUser?.id,
          });
        }
      }

      if (_usedSpares.isNotEmpty) {
        for (var item in _usedSpares) {
          if (item['is_existing'] == true) continue;
          final spare = item['spare'];
          final int qty = item['qty'];
          await _supabase.from('spare_ticket').insert({
            'ticket_id': widget.ticket!['id'], 'spare_id': spare['id'], 'used_qty': qty,
            'used_qty_time': nowISO, 'logged_by_id': _supabase.auth.currentUser?.id,
          });
          int currentStock = _getSpareCurrentQty(spare);
          await _supabase.from('spare_tracker').update({'current_qty': currentStock - qty}).eq('spare_id', spare['id']);
        }
      }

      await _supabase.from('tickets').update(updates).eq('id', widget.ticket!['id']);
      if (nextStatus == 'COMPLETED' && _selectedImages.isNotEmpty) await _uploadImages(widget.ticket!['id'], 'COMPLETED');

      if (mounted) {
        if (widget.ticket != null) widget.ticket!.addAll(updates);
        context.read<TicketProvider>().refreshTickets();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI RENDERERS FOR MEDIA / CONTEXTUAL ACTIONS ---
  Widget _buildImageUploader(bool isCompleting) {
    if (_selectedImages.isNotEmpty) {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: _selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              return GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: 100, margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
              );
            }
            return Stack(
              children: [
                Container(
                  width: 100, margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb ? Image.network(_selectedImages[index].path, fit: BoxFit.cover) : Image.file(File(_selectedImages[index].path), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 4, right: 12,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImages.removeAt(index)),
                    child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    return InkWell(
      onTap: _showImageSourceDialog, borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120, width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCompleting ? Colors.red.shade300 : Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 40, color: isCompleting ? Colors.red : navy),
            const SizedBox(height: 8),
            Text("Tap to add photos\n(Camera or Gallery)", textAlign: TextAlign.center, style: GoogleFonts.inter(color: isCompleting ? Colors.red : Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGallery() {
    if (_isLoadingMedia) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: golden)));
    if (_beforeUrls.isEmpty && _afterUrls.isEmpty) return Text("No photos attached yet.", style: GoogleFonts.inter(color: Colors.grey.shade500, fontStyle: FontStyle.italic));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_beforeUrls.isNotEmpty) ...[
          Text("BEFORE (Issue Raised)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, itemCount: _beforeUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openImageViewer(context, _beforeUrls[index]),
                  child: Padding(padding: const EdgeInsets.only(right: 8.0), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_beforeUrls[index], height: 100, width: 100, fit: BoxFit.cover))),
                );
              },
            ),
          )
        ],
        if (_beforeUrls.isNotEmpty && _afterUrls.isNotEmpty) ...[
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Icon(Icons.arrow_downward_rounded, size: 28, color: Colors.green))),
        ],
        if (_afterUrls.isNotEmpty) ...[
          Text("AFTER (Work Completed)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, itemCount: _afterUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openImageViewer(context, _afterUrls[index]),
                  child: Padding(padding: const EdgeInsets.only(right: 8.0), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_afterUrls[index], height: 100, width: 100, fit: BoxFit.cover))),
                );
              },
            ),
          )
        ],
      ],
    );
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
        body: Center(child: InteractiveViewer(panEnabled: true, minScale: 0.5, maxScale: 4.0, child: Image.network(imageUrl))),
      ),
    ));
  }

  Widget? _buildContextualActionButton(bool isAdmin, bool isAssignedWorker, bool canEditWorkDetails) {
    if (currentStatus == 'VERIFIED') return null;

    String buttonText = "UPDATE TICKET";
    String? nextStatus;

    if (currentStatus == 'RAISED') {
      if (isAdmin && _selectedWorker != null) {
        buttonText = "ASSIGN WORKER";
        nextStatus = 'ASSIGNED';
      } else if (isAdmin) {
        buttonText = "UPDATE TICKET";
      } else { return null; }
    } else if (currentStatus == 'ASSIGNED') {
      if (isAssignedWorker) {
        buttonText = "START WORK";
        nextStatus = 'IN_PROGRESS';
      } else if (isAdmin) {
        buttonText = "UPDATE TICKET";
      } else { return null; }
    } else if (currentStatus == 'IN_PROGRESS') {
      if (isAssignedWorker) {
        buttonText = "MARK COMPLETE";
        nextStatus = 'COMPLETED';
      } else if (isAdmin) {
        buttonText = "UPDATE TICKET";
      } else { return null; }
    } else if (currentStatus == 'COMPLETED') {
      if (isAdmin) {
        buttonText = "VERIFY & CLOSE";
        nextStatus = 'VERIFIED';
      } else { return null; }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            onPressed: _isLoading ? null : () => _updateTicketStatus(nextStatus, isAdmin),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(buttonText, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitNewButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            onPressed: _isLoading ? null : _submitNewTicket,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("SUBMIT TICKET", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }

  // --- CORE BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final ticketProv = context.watch<TicketProvider>();
    final currentUserId = _supabase.auth.currentUser?.id;

    final isAdmin = (authProv.activeRole == 'admin');
    final isAssignedWorker = _selectedWorker != null && _selectedWorker == currentUserId;

    final canEditWorkDetails = (isAssignedWorker && currentStatus == 'IN_PROGRESS') || (isAdmin && (currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED'));
    final bool readOnlyFields = isTicketClosed || (isEditing && !isAdmin);
    final showCameraBox = (!isEditing || canEditWorkDetails) && currentStatus != 'VERIFIED';

    String activeKitchenName = "Loading Kitchen...";
    String activeKitchenId = "";

    if (!isEditing && authProv.assignedKitchens.isNotEmpty) {
      int activeIndex = authProv.assignedKitchens.indexWhere((k) => k['id'].toString() == ticketProv.kitchenFilter);
      final activeK = activeIndex != -1 ? authProv.assignedKitchens[activeIndex] : authProv.assignedKitchens.first;
      activeKitchenName = activeK['name']?.toString() ?? 'Unknown Kitchen';
      activeKitchenId = activeK['id']?.toString() ?? "";
    } else if (isEditing) {
      activeKitchenName = widget.ticket?['m_kitchen']?['name']?.toString() ?? 'Unknown Kitchen';
      activeKitchenId = widget.ticket?['kitchen_id']?.toString() ?? "";
    }

    final List<Map<String, dynamic>> availableEquipments = _selectedAreaId == null ? [] : _allEquipment.where((e) => e['area_id']?.toString() == _selectedAreaId).toList();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0, backgroundColor: Colors.white, foregroundColor: navy,
          title: Text(isEditing ? (widget.ticket!['ticket_no'] ?? 'Ticket Details') : "Raise New Issue", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditing) ...[
                  TicketStatusBanner(currentStatus: currentStatus),
                  const SizedBox(height: 12),
                  TicketTimeline(ticket: widget.ticket!),
                  const SizedBox(height: 12),
                ],

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TicketFormFields.buildTextField(ctrl: TextEditingController(text: activeKitchenName), label: "Target Kitchen", icon: Icons.kitchen, isReadOnly: true),
                      const SizedBox(height: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEditing) _buildMediaGallery(),
                          if (showCameraBox) ...[
                            if (isEditing) const Divider(height: 32),
                            Text(canEditWorkDetails ? "Upload Completion Photos *" : "Add Issue Photos *", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
                            const SizedBox(height: 12),
                            _buildImageUploader(canEditWorkDetails),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      InkWell(
                        onTap: readOnlyFields ? null : _pickBreakdownTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                              color: readOnlyFields ? Colors.grey.shade100 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_filled, color: Colors.grey.shade400, size: 20),
                              const SizedBox(width: 12),
                              Text(_formatDateTimeLocal(_breakdownTime), style: GoogleFonts.inter(color: _breakdownTime == null ? Colors.red.shade400 : navy, fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TicketFormFields.buildSleekAutocomplete(
                          context: context, hint: "Search Area *", icon: Icons.place_outlined, controller: _areaSearchController, focusNode: _areaFocusNode, options: _allAreas, isDisabled: readOnlyFields,
                          onSelected: (val) { setState(() { _selectedAreaId = val['id'].toString(); _selectedEquipments.clear(); _equipSearchController.clear(); }); },
                          onCleared: () { setState(() { _selectedAreaId = null; _selectedEquipments.clear(); _equipSearchController.clear(); }); }
                      ),
                      const SizedBox(height: 12),

                      TicketFormFields.buildSleekAutocomplete(
                          key: ValueKey(_selectedAreaId ?? 'no_area'), context: context,
                          hint: _selectedAreaId == null ? "Select an Area first" : (availableEquipments.isNotEmpty ? "Search Equipment *" : "No equipment in this area"),
                          icon: Icons.precision_manufacturing_outlined, controller: _equipSearchController, focusNode: _equipFocusNode, options: availableEquipments, isDisabled: readOnlyFields || _selectedAreaId == null || availableEquipments.isEmpty,
                          onSelected: (val) { setState(() { if (!_selectedEquipments.any((e) => e['id'] == val['id'])) _selectedEquipments.add(val); _equipSearchController.clear(); }); }
                      ),

                      if (_selectedEquipments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _selectedEquipments.map((eq) => Chip(
                            backgroundColor: navy.withOpacity(0.05), side: const BorderSide(color: navy),
                            label: Text(eq['name'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: navy)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: readOnlyFields ? null : () => setState(() => _selectedEquipments.removeWhere((e) => e['id'] == eq['id'])),
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),

                      TicketFormFields.buildDropdown(label: "Priority *", items: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'], val: _priority, onChanged: readOnlyFields ? null : (val) => setState(() => _priority = val!)),
                      const SizedBox(height: 12),
                      TicketFormFields.buildDropdown(label: "Category *", items: ['In Running Condition', 'In Breakdown Condition', 'Running at Risk'], val: _category, onChanged: readOnlyFields ? null : (val) => setState(() => _category = val!)),
                      const SizedBox(height: 12),
                      TicketFormFields.buildTextField(ctrl: _titleController, label: "Issue Title *", icon: Icons.title, isReadOnly: readOnlyFields, isRequired: true, textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 12),
                      TicketFormFields.buildTextField(ctrl: _causeController, label: "Cause of Issue *", icon: Icons.report_problem_outlined, maxLines: 3, isReadOnly: readOnlyFields, isRequired: true, textCapitalization: TextCapitalization.sentences),
                    ],
                  ),
                ),

                if (currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED' || currentStatus == 'VERIFIED') ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Work Details", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                        const Divider(height: 24),

                        TicketFormFields.buildTextField(
                          ctrl: _actionTakenController, label: "Action Taken *", icon: Icons.handyman, maxLines: 3, isReadOnly: !canEditWorkDetails, isRequired: canEditWorkDetails, textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 24),

                        Text("Tools Checked Out", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800)),
                        const SizedBox(height: 8),

                        if (canEditWorkDetails) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TicketFormFields.buildSleekAutocomplete(
                                    context: context, hint: "Search Required Tool", icon: Icons.plumbing, controller: _toolSearchController, focusNode: _toolFocusNode, options: _availableTools, isDisabled: false,
                                    onSelected: (val) { setState(() => _currentlySelectedToolToAdd = val); },
                                    onCleared: () { setState(() => _currentlySelectedToolToAdd = null); }
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(10)),
                                child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _addToolToTicket),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (_usedTools.isEmpty) Text("No tools logged.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                        ..._usedTools.map((item) {
                          final tool = item['tool'];
                          final bool isExisting = item['is_existing'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.handyman_outlined, size: 16, color: navy), const SizedBox(width: 8),
                                Expanded(child: Text(tool['tool_name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: navy))),
                                if (canEditWorkDetails && !isExisting) IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => setState(() => _usedTools.remove(item)))
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 24),

                        Text("Spares Used", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800)),
                        const SizedBox(height: 8),

                        if (canEditWorkDetails) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: TicketFormFields.buildSleekAutocomplete(
                                    context: context, hint: "Search Spare (Name/Vendor)", icon: Icons.build_circle, controller: _spareSearchController, focusNode: _spareFocusNode, options: _availableSpares, isDisabled: false,
                                    onSelected: (val) { setState(() => _currentlySelectedSpareToAdd = val); },
                                    onCleared: () { setState(() => _currentlySelectedSpareToAdd = null); }
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _spareQtyController, keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                                  decoration: InputDecoration(
                                    labelText: "Qty", filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(decoration: BoxDecoration(color: golden, borderRadius: BorderRadius.circular(10)), child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _addSpareToTicket))
                            ],
                          ),
                          if (_currentlySelectedSpareToAdd != null)
                            Padding(padding: const EdgeInsets.only(top: 6.0, left: 4), child: Text("Available in Stock: ${_getSpareCurrentQty(_currentlySelectedSpareToAdd!)}", style: GoogleFonts.inter(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold))),
                          const SizedBox(height: 12),
                        ],

                        if (_usedSpares.isEmpty) Text("No spares selected.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                        ..._usedSpares.map((item) {
                          final spare = item['spare'];
                          final bool isExisting = item['is_existing'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.settings, size: 16, color: navy), const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(spare['spare_name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: navy)),
                                      if (spare['m_vendor']?['name'] != null) Text("Vendor: ${spare['m_vendor']['name']}", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Text("Qty: ${item['qty']}", style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: navy)),
                                if (canEditWorkDetails && !isExisting) IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => setState(() => _usedSpares.remove(item)))
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  )
                ],

                const SizedBox(height: 20),
                if (isEditing && isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: TicketFormFields.buildSleekAutocomplete(
                      context: context, hint: "Search & Assign Worker", icon: Icons.engineering_outlined, controller: _workerSearchController, focusNode: _workerFocusNode,
                      options: _workers.where((w) {
                        final assignedKitchensList = w['user_kitchens'] as List<dynamic>? ?? [];
                        return assignedKitchensList.any((uk) => uk['kitchen_id'].toString() == activeKitchenId);
                      }).toList(),
                      isDisabled: isTicketClosed,
                      onSelected: (val) { setState(() { _selectedWorker = val['id'].toString(); }); },
                      onCleared: () { setState(() { _selectedWorker = null; }); },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: isEditing ? _buildContextualActionButton(isAdmin, isAssignedWorker, canEditWorkDetails) : _buildSubmitNewButton(),
      ),
    );
  }
}