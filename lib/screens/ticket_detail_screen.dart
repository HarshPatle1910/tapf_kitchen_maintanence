import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Added for Web Support
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

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

  // Form Controllers
  final _titleController = TextEditingController();
  final _causeController = TextEditingController();
  final _areaSearchController = TextEditingController();
  final _equipSearchController = TextEditingController();

  final FocusNode _areaFocusNode = FocusNode();
  final FocusNode _equipFocusNode = FocusNode();

  // States
  String? _selectedAreaId;
  String? _selectedWorker;
  String _priority = 'MEDIUM';
  bool _isLoading = false;

  // Multi-Select Equipment State
  List<Map<String, dynamic>> _selectedEquipments = [];

  // Multiple Image Upload State
  final List<XFile> _selectedImages = [];
  List<String> _beforeUrls = [];
  List<String> _afterUrls = [];
  bool _isLoadingMedia = false;

  // Dropdown Data
  List<Map<String, dynamic>> _allAreas = [];
  List<Map<String, dynamic>> _allEquipment = [];
  List<Map<String, dynamic>> _workers = [];

  bool get isEditing => widget.ticket != null;
  String get currentStatus => widget.ticket?['status'] ?? 'RAISED';

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      _titleController.text = widget.ticket!['title'] ?? '';
      _causeController.text = widget.ticket!['cause_of_issue'] ?? '';
      _priority = widget.ticket!['priority'] ?? 'MEDIUM';
      _selectedAreaId = widget.ticket!['area_id'];
      _selectedWorker = widget.ticket!['assigned_to_id'];

      _fetchMedia();
    }

    _fetchDropdownData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _causeController.dispose();
    _areaSearchController.dispose();
    _equipSearchController.dispose();
    _areaFocusNode.dispose();
    _equipFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchMedia() async {
    setState(() => _isLoadingMedia = true);
    try {
      final mediaRecords = await _supabase
          .from('ticket_media')
          .select('storage_path, upload_stage')
          .eq('ticket_id', widget.ticket!['id']);
      List<String> before = [];
      List<String> after = [];

      for (var record in mediaRecords) {
        final url = _supabase.storage
            .from('ticket-media')
            .getPublicUrl(record['storage_path']);
        if (record['upload_stage'] == 'COMPLETED') {
          after.add(url);
        } else {
          before.add(url);
        }
      }

      if (mounted) {
        setState(() {
          _beforeUrls = before;
          _afterUrls = after;
        });
      }
    } catch (e) {
      debugPrint("Error fetching media: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMedia = false);
    }
  }

  Future<void> _fetchDropdownData() async {
    try {
      final areasData = await _supabase.from('m_area').select().eq('status', true);
      final equipsData = await _supabase.from('m_equipment').select().eq('status', true);
      final staffData = await _supabase.from('m_user').select().eq('status', true);

      if (mounted) {
        setState(() {
          // Format Areas
          _allAreas = List<Map<String, dynamic>>.from(areasData);
          for (var a in _allAreas) {
            a['display_name'] = a['area_name'];
          }

          // Format Equipments
          _allEquipment = List<Map<String, dynamic>>.from(equipsData);
          for (var e in _allEquipment) {
            e['display_name'] = e['name'];
          }

          // Format Workers
          _workers = List<Map<String, dynamic>>.from(staffData);

          if (isEditing && _selectedWorker != null) {
            bool workerExistsInList = _workers.any((w) => w['id'].toString() == _selectedWorker);
            if (!workerExistsInList) {
              _workers.add({
                'id': _selectedWorker,
                'name': widget.ticket!['assigned_to']?['name'] ?? 'Inactive Worker',
              });
            }
          }

          if (isEditing && _selectedAreaId != null) {
            final area = _allAreas.firstWhere((a) => a['id'] == _selectedAreaId, orElse: () => {});
            if (area.isNotEmpty) {
              _areaSearchController.text = area['display_name'];
            }
            _fetchLinkedEquipments();
          }
        });
      }
    } catch (e) {
      debugPrint("Dropdown Fetch Error: $e");
    }
  }

  Future<void> _fetchLinkedEquipments() async {
    try {
      final linkedEq = await _supabase
          .from('ticket_equipments')
          .select('m_equipment(*)')
          .eq('ticket_id', widget.ticket!['id']);

      if (mounted) {
        setState(() {
          _selectedEquipments = List<Map<String, dynamic>>.from(
            linkedEq.map((e) {
              var eq = e['m_equipment'];
              eq['display_name'] = eq['name'];
              return eq;
            }),
          );
        });
      }
    } catch (e) {
      debugPrint("Error fetching linked equipment: $e");
    }
  }

  void _showImageSourceDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(fromCamera: true);
                },
              ),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: navy.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.photo_library_rounded, color: navy)),
                title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(fromCamera: false);
                },
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
      // FIX 1: Use XFile's native length() method instead of dart:io File for Web safety
      final bytes = await img.length();
      if (bytes <= 5242880) {
        validImages.add(img);
      } else {
        filesDropped = true;
      }
    }

    if (filesDropped && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Some images skipped (exceeded 5MB limit).', style: GoogleFonts.inter()), backgroundColor: Colors.orange),
      );
    }
    setState(() => _selectedImages.addAll(validImages));
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final isAdmin = (authProv.activeRole == 'admin');
    final isCompleting = isEditing && !isAdmin && currentStatus == 'IN_PROGRESS';
    final showCameraBox = !isEditing || isCompleting;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: navy,
          title: Text(
            isEditing ? (widget.ticket!['ticket_no'] ?? 'Ticket Details') : "Raise New Issue",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditing) ...[
                  _buildStatusBanner(),
                  const SizedBox(height: 12),
                ],

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. IMAGES FIRST
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEditing) _buildMediaGallery(),
                          if (showCameraBox) ...[
                            if (isEditing) const Divider(height: 32),
                            Text(
                              isCompleting ? "Upload Completion Photos *" : "Add Issue Photos",
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            _buildImageUploader(isCompleting),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Area Selection
                      _buildSleekAutocomplete(
                        hint: "Search Area *",
                        icon: Icons.place_outlined,
                        controller: _areaSearchController,
                        focusNode: _areaFocusNode,
                        options: _allAreas,
                        isDisabled: isEditing && !isAdmin,
                        onSelected: (val) {
                          setState(() {
                            _selectedAreaId = val['id'].toString();
                            _selectedEquipments.clear();
                            _equipSearchController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Multi-Select Equipment
                      _buildSleekAutocomplete(
                        hint: _selectedAreaId == null ? "Select an Area first" : "Search Equipment *",
                        icon: Icons.precision_manufacturing_outlined,
                        controller: _equipSearchController,
                        focusNode: _equipFocusNode,
                        options: _allEquipment.where((e) => e['area_id'] == _selectedAreaId).toList(),
                        isDisabled: (isEditing && !isAdmin) || _selectedAreaId == null,
                        onSelected: (val) {
                          setState(() {
                            if (!_selectedEquipments.any((e) => e['id'] == val['id'])) {
                              _selectedEquipments.add(val);
                            }
                            _equipSearchController.clear();
                          });
                        },
                      ),

                      // Display Selected Equipment Chips
                      if (_selectedEquipments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedEquipments.map((eq) => Chip(
                            backgroundColor: navy.withOpacity(0.05),
                            side: const BorderSide(color: navy),
                            label: Text(eq['name'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: navy)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: (isEditing && !isAdmin) ? null : () {
                              setState(() => _selectedEquipments.removeWhere((e) => e['id'] == eq['id']));
                            },
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Priority Selection
                      _buildDropdown(
                        "Priority *",
                        ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'],
                        _priority,
                        isEditing && !isAdmin ? null : (val) => setState(() => _priority = val!),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      _buildTextField(
                        ctrl: _titleController,
                        label: "Issue Title *",
                        icon: Icons.title,
                        isReadOnly: isEditing && !isAdmin,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),

                      // Cause of Issue
                      _buildTextField(
                        ctrl: _causeController,
                        label: "Cause of Issue",
                        icon: Icons.report_problem_outlined,
                        maxLines: 4,
                        isReadOnly: isEditing && !isAdmin,
                        isRequired: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Assignment (Admin Only)
                if (isEditing && isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: _buildWorkerDropdown("Assign Worker", _workers, _selectedWorker, (val) => setState(() => _selectedWorker = val)),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: isEditing ? _buildContextualActionButton(isAdmin) : _buildSubmitNewButton(),
      ),
    );
  }

  // --- UI WIDGETS ---
  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade300, width: 2)),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Current Status", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(currentStatus, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.orange.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController ctrl, required String label, required IconData icon, bool isReadOnly = false, bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      readOnly: isReadOnly,
      maxLines: maxLines,
      validator: isRequired ? (val) => val == null || val.trim().isEmpty ? 'Required' : null : null,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isReadOnly ? Colors.grey.shade700 : navy, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Padding(padding: EdgeInsets.only(bottom: maxLines > 1 ? 48.0 : 0), child: Icon(icon, color: Colors.grey.shade400, size: 20)),
        filled: true,
        fillColor: isReadOnly ? Colors.grey.shade100 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? val, Function(String?)? onChanged) {
    return DropdownButtonFormField<String>(
      value: val,
      isExpanded: true,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.keyboard_arrow_down, color: navy, size: 20),
      style: GoogleFonts.inter(color: navy, fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        filled: true,
        fillColor: onChanged == null ? Colors.grey.shade100 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildWorkerDropdown(String label, List<Map<String, dynamic>> items, String? val, Function(String?)? onChanged) {
    String? safeVal;
    if (val != null) {
      bool exists = items.any((i) => i['id'].toString() == val);
      safeVal = exists ? val : null;
    }
    return DropdownButtonFormField<String>(
      value: safeVal,
      isExpanded: true,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.keyboard_arrow_down, color: navy, size: 20),
      style: GoogleFonts.inter(color: navy, fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: const Icon(Icons.engineering, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
      ),
      items: items.isEmpty ? [const DropdownMenuItem<String>(value: null, child: Text("No workers available"))] : items.map((w) => DropdownMenuItem(value: w['id'].toString(), child: Text(w['name']))).toList(),
      onChanged: items.isEmpty ? null : onChanged,
    );
  }

  Widget _buildSleekAutocomplete({
    required String hint, required IconData icon, required TextEditingController controller,
    required FocusNode focusNode, required List<Map<String, dynamic>> options,
    required bool isDisabled, required Function(Map<String, dynamic>) onSelected,
  }) {
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (val) => val.text.isEmpty
          ? const Iterable<Map<String, dynamic>>.empty()
          : options.where((opt) => opt['display_name'].toString().toLowerCase().contains(val.text.toLowerCase())),
      displayStringForOption: (opt) => opt['display_name'].toString(),
      onSelected: (sel) {
        onSelected(sel);
        focusNode.unfocus();
      },
      fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
        controller: ctrl,
        focusNode: fNode,
        enabled: !isDisabled,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDisabled ? Colors.grey.shade700 : navy),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: isDisabled ? Colors.grey.shade100 : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
          suffixIcon: ctrl.text.isNotEmpty && !isDisabled ? IconButton(icon: const Icon(Icons.clear, size: 16, color: Colors.grey), onPressed: () => ctrl.clear()) : null,
        ),
      ),
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 72),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: opts.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (ctx, idx) => ListTile(
                dense: true,
                title: Text(opts.elementAt(idx)['display_name'], style: GoogleFonts.inter(fontSize: 13, color: navy, fontWeight: FontWeight.w500)),
                onTap: () => onSel(opts.elementAt(idx)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploader(bool isCompleting) {
    if (_selectedImages.isNotEmpty) {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              return GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
              );
            }
            return Stack(
              children: [
                Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // FIX 2: Safe cross-platform image preview!
                    child: kIsWeb
                        ? Image.network(_selectedImages[index].path, fit: BoxFit.cover)
                        : Image.file(File(_selectedImages[index].path), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 12,
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
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
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
        if (_beforeUrls.isNotEmpty) ...[Text("BEFORE (Issue Raised)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12)), const SizedBox(height: 8), _buildImageRow(_beforeUrls)],
        if (_beforeUrls.isNotEmpty && _afterUrls.isNotEmpty) ...[const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Icon(Icons.arrow_downward_rounded, size: 28, color: Colors.green)))],
        if (_afterUrls.isNotEmpty) ...[Text("AFTER (Work Completed)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)), const SizedBox(height: 8), _buildImageRow(_afterUrls)],
      ],
    );
  }

  Widget _buildImageRow(List<String> urls) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openImageViewer(context, urls[index]),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(urls[index], height: 100, width: 100, fit: BoxFit.cover)),
            ),
          );
        },
      ),
    );
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), elevation: 0), body: Center(child: InteractiveViewer(panEnabled: true, minScale: 0.5, maxScale: 4.0, child: Image.network(imageUrl))))));
  }

  // --- SUBMIT LOGIC ---
  Future<void> _uploadImages(String ticketId, String stage) async {
    final userId = _supabase.auth.currentUser?.id;

    for (var img in _selectedImages) {
      // FIX 3: Read bytes for secure Web upload + Name extraction
      final fileExt = img.name.contains('.') ? img.name.split('.').last : 'jpg';
      final fileName = '${stage.toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}.$fileExt';
      final storagePath = '$ticketId/$fileName';

      final imageBytes = await img.readAsBytes();

      await _supabase.storage.from('ticket-media').uploadBinary(storagePath, imageBytes);

      await _supabase.from('ticket_media').insert({
        'ticket_id': ticketId,
        'storage_path': storagePath,
        'upload_stage': stage,
        'uploaded_by': userId,
      });
    }
  }

  Future<void> _submitNewTicket() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate() || _selectedAreaId == null || _selectedEquipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an Area and at least one Equipment.', style: GoogleFonts.inter()), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      final kitchenResp = await _supabase.from('m_kitchen').select('id').limit(1).single();

      final newTicket = await _supabase.from('tickets').insert({
        'title': _titleController.text,
        'cause_of_issue': _causeController.text,
        'priority': _priority,
        'area_id': _selectedAreaId,
        'kitchen_id': kitchenResp['id'],
        'raised_by_id': userId,
      }).select().single();

      final equipmentInserts = _selectedEquipments.map((eq) => {
        'ticket_id': newTicket['id'],
        'equipment_id': eq['id']
      }).toList();

      await _supabase.from('ticket_equipments').insert(equipmentInserts);

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

    if (nextStatus == 'COMPLETED' && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload Completion Photos.', style: GoogleFonts.inter()), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
      if (nextStatus != null) updates['status'] = nextStatus;

      if (isAdmin) {
        updates['title'] = _titleController.text;
        updates['cause_of_issue'] = _causeController.text;
        updates['priority'] = _priority;
        updates['area_id'] = _selectedAreaId;

        if (_selectedWorker != null) {
          updates['assigned_to_id'] = _selectedWorker;
          if (currentStatus == 'RAISED') updates['status'] = 'ASSIGNED';
        }

        if (_selectedEquipments.isNotEmpty) {
          await _supabase.from('ticket_equipments').delete().eq('ticket_id', widget.ticket!['id']);
          final newMappings = _selectedEquipments.map((eq) => {
            'ticket_id': widget.ticket!['id'],
            'equipment_id': eq['id'],
          }).toList();
          await _supabase.from('ticket_equipments').insert(newMappings);
        }
      }

      await _supabase.from('tickets').update(updates).eq('id', widget.ticket!['id']);

      if (nextStatus == 'COMPLETED' && _selectedImages.isNotEmpty) {
        await _uploadImages(widget.ticket!['id'], 'COMPLETED');
      }

      if (mounted) {
        context.read<TicketProvider>().refreshTickets();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget? _buildContextualActionButton(bool isAdmin) {
    String buttonText = "UPDATE TICKET";
    String? nextStatus;

    if (isAdmin) {
      if (currentStatus == 'RAISED' && _selectedWorker != null) { buttonText = "ASSIGN WORKER"; nextStatus = 'ASSIGNED'; }
      else if (currentStatus == 'COMPLETED') { buttonText = "VERIFY & CLOSE"; nextStatus = 'VERIFIED'; }
    } else {
      if (currentStatus == 'ASSIGNED') { buttonText = "START WORK"; nextStatus = 'IN_PROGRESS'; }
      else if (currentStatus == 'IN_PROGRESS') { buttonText = "MARK COMPLETE"; nextStatus = 'COMPLETED'; }
      else { return null; }
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
}