import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? ticket;

  const TicketDetailScreen({super.key, this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final Color _primaryColor = const Color(0xFF4A56E2);

  // Form Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Area Text Controller (Read-Only Auto-fill)
  final _areaTextController = TextEditingController();

  // Controller for Searchable Dropdown
  final _equipSearchController = TextEditingController();

  // States
  String? _selectedAreaId;
  String? _selectedEquipmentId;
  String? _selectedWorker;
  String _priority = 'MEDIUM';
  bool _isLoading = false;

  // Multiple Image Upload State
  final List<XFile> _selectedImages = [];

  // Gallery State
  List<String> _beforeUrls = [];
  List<String> _afterUrls = [];
  bool _isLoadingMedia = false;

  // Dropdown Data
  List<Map<String, dynamic>> _allEquipment = [];
  List<Map<String, dynamic>> _workers = [];

  bool get isEditing => widget.ticket != null;
  String get currentStatus => widget.ticket?['status'] ?? 'RAISED';

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();

    if (isEditing) {
      _titleController.text = widget.ticket!['title'] ?? '';
      _descController.text = widget.ticket!['description'] ?? '';
      _priority = widget.ticket!['priority'] ?? 'MEDIUM';
      _selectedAreaId = widget.ticket!['area_id'];
      _selectedEquipmentId = widget.ticket!['equipment_id'];
      _selectedWorker = widget.ticket!['assigned_to_id'];

      _fetchMedia();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _areaTextController.dispose();
    _equipSearchController.dispose();
    super.dispose();
  }

  // --- SAFE DATA HELPER ---
  Map<String, dynamic>? _getSafeItem(List<Map<String, dynamic>> list, String key, dynamic value) {
    if (value == null) return null;
    final items = list.where((item) => item[key] == value);
    return items.isNotEmpty ? items.first : null;
  }

  // --- FETCHING MEDIA ---
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
        final url = _supabase.storage.from('ticket-media').getPublicUrl(record['storage_path']);
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

  // --- FETCHING DROPDOWN DATA WITH JOIN ---
  Future<void> _fetchDropdownData() async {
    try {
      // THE MAGIC JOIN: Fetches equipment AND its linked area at the same time!
      final equipsData = await _supabase
          .from('m_equipment')
          .select('*, m_area(*)')
          .eq('status', true);

      final staffData = await _supabase
          .from('m_user')
          .select()
          .eq('role', 'worker')
          .eq('status', true);

      if (mounted) {
        setState(() {
          // Format the display name to show "Equipment (Area)"
          final formattedEquipList = List<Map<String, dynamic>>.from(equipsData);
          for (var i = 0; i < formattedEquipList.length; i++) {
            final areaObj = formattedEquipList[i]['m_area'];
            final areaName = areaObj != null ? areaObj['area_name'] : 'Unknown Area';
            formattedEquipList[i]['display_name'] = "${formattedEquipList[i]['name']} ($areaName)";
          }

          _allEquipment = formattedEquipList;
          _workers = List<Map<String, dynamic>>.from(staffData);

          // Pre-fill fields if Editing
          if (isEditing && _selectedEquipmentId != null) {
            final eq = _getSafeItem(_allEquipment, 'id', _selectedEquipmentId);
            if (eq != null) {
              _equipSearchController.text = eq['display_name'];
              _selectedAreaId = eq['area_id'];

              final areaObj = eq['m_area'];
              _areaTextController.text = areaObj != null ? areaObj['area_name'] : 'Unknown Area';
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Dropdown Fetch Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load form data: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- IMAGE SELECTION LOGIC ---
  void _showImageSourceDialog() {
    FocusManager.instance.primaryFocus?.unfocus();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              const Text("Add Photo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.camera_alt_rounded, color: _primaryColor)),
                title: const Text('Take a Photo (Camera)'),
                onTap: () { Navigator.pop(ctx); _pickImages(fromCamera: true); },
              ),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.photo_library_rounded, color: _primaryColor)),
                title: const Text('Choose from Gallery (Multiple)'),
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
      final bytes = await File(img.path).length();
      if (bytes <= 5242880) { // 5 MB limit
        validImages.add(img);
      } else {
        filesDropped = true;
      }
    }

    if (filesDropped && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Some images were skipped (exceeded 5MB limit).'), backgroundColor: Colors.orange));
    }

    setState(() => _selectedImages.addAll(validImages));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final isCompleting = isEditing && !isAdmin && currentStatus == 'IN_PROGRESS';
    final showCameraBox = !isEditing || isCompleting;

    // GESTURE DETECTOR TO DISMISS KEYBOARD ON TAP
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: Text(isEditing ? (widget.ticket!['ticket_no'] ?? 'Ticket Details') : "Raise New Issue", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // --- 1. TICKET STATUS BANNER ---
                if (isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade300, width: 2)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_rounded, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Current Status", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(currentStatus, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.orange)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- 2. PHOTOS & MEDIA ---
                const Text("Photos & Visuals", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEditing) _buildMediaGallery(),
                      if (showCameraBox) ...[
                        if (isEditing) const Divider(height: 32),
                        Text(isCompleting ? "Upload Completion Photos *" : "Add Issue Photos", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
                        const SizedBox(height: 12),
                        _buildImageUploader(isCompleting),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- 3. CORE FORM FIELDS ---
                const Text("Issue Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      _buildInputField(
                        ctrl: _titleController,
                        label: "Issue Title *",
                        isReadOnly: isEditing && !isAdmin,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // --- SEARCHABLE EQUIPMENT DROPDOWN ---
                      _buildSearchableDropdown(
                        label: "Select Equipment *",
                        icon: Icons.precision_manufacturing_outlined,
                        items: _allEquipment,
                        displayKey: 'display_name', // Uses the formatted "Equipment (Area)" string
                        valueKey: 'id',
                        selectedValue: _selectedEquipmentId,
                        controller: _equipSearchController,
                        isDisabled: isEditing && !isAdmin,
                        onSelected: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedEquipmentId = val;
                              // AUTO-FILL AREA LOGIC
                              final eq = _getSafeItem(_allEquipment, 'id', val);
                              if (eq != null && eq['area_id'] != null) {
                                _selectedAreaId = eq['area_id'];
                                final areaObj = eq['m_area'];
                                _areaTextController.text = areaObj != null ? areaObj['area_name'] : 'Unknown Area';
                              } else {
                                _selectedAreaId = null;
                                _areaTextController.text = 'No Area Assigned';
                              }
                            });
                          }
                        },
                      ),
                      if (_selectedEquipmentId == null)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(padding: EdgeInsets.only(left: 12, top: 4), child: Text("Required", style: TextStyle(color: Colors.red, fontSize: 12))),
                        ),
                      const SizedBox(height: 16),

                      // --- READ-ONLY AREA FIELD ---
                      _buildInputField(
                        ctrl: _areaTextController,
                        label: "Area (Auto-filled)",
                        isReadOnly: true,
                        fillColor: Colors.grey.shade100, // Indicates it's locked
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _priority,
                        decoration: _inputDecoration("Priority *"),
                        items: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: isEditing && !isAdmin ? null : (val) => setState(() => _priority = val!),
                      ),
                      const SizedBox(height: 16),

                      _buildInputField(
                        ctrl: _descController,
                        label: "Detailed Description",
                        maxLines: 4,
                        isReadOnly: isEditing && !isAdmin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- 4. ADMIN ACTIONS ---
                if (isEditing && isAdmin) ...[
                  const Text("Assignment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedWorker,
                      decoration: _inputDecoration("Assign Worker").copyWith(prefixIcon: const Icon(Icons.engineering)),
                      items: _workers.map((w) => DropdownMenuItem(value: w['id'].toString(), child: Text(w['name']))).toList(),
                      onChanged: (val) => setState(() => _selectedWorker = val),
                    ),
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

  // --- NATIVE SEARCHABLE DROPDOWN (MATERIAL 3) ---
  Widget _buildSearchableDropdown({
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required String valueKey,
    required String? selectedValue,
    required TextEditingController controller,
    required bool isDisabled,
    required Function(String?) onSelected,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          width: constraints.maxWidth,
          menuHeight: 300,
          enabled: !isDisabled,
          enableFilter: true, // Enables typing to search instantly
          requestFocusOnTap: true,
          leadingIcon: Icon(icon, color: isDisabled ? Colors.grey.shade400 : _primaryColor),
          label: Text(label),
          initialSelection: selectedValue,
          controller: controller,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: isDisabled ? Colors.grey.shade100 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
          ),
          dropdownMenuEntries: items.map((item) {
            return DropdownMenuEntry<String>(
              value: item[valueKey].toString(),
              label: item[displayKey].toString(),
            );
          }).toList(),
          onSelected: onSelected,
        );
      },
    );
  }

  // --- UPLOADER UI ---
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
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_selectedImages[index].path), fit: BoxFit.cover)),
                ),
                Positioned(
                  top: 4, right: 12,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImages.removeAt(index)),
                    child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                  ),
                )
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
        height: 120, width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isCompleting ? Colors.red.shade300 : Colors.grey.shade300, style: BorderStyle.solid)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 40, color: isCompleting ? Colors.red : _primaryColor),
            const SizedBox(height: 8),
            Text("Tap to add photos\n(Camera or Gallery)", textAlign: TextAlign.center, style: TextStyle(color: isCompleting ? Colors.red : Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // --- MEDIA GALLERY UI ---
  Widget _buildMediaGallery() {
    if (_isLoadingMedia) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
    if (_beforeUrls.isEmpty && _afterUrls.isEmpty) return Text("No photos attached yet.", style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_beforeUrls.isNotEmpty) ...[
          const Text("BEFORE (Issue Raised)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12)),
          const SizedBox(height: 8),
          _buildImageRow(_beforeUrls),
        ],
        if (_beforeUrls.isNotEmpty && _afterUrls.isNotEmpty) ...[
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Icon(Icons.arrow_downward_rounded, size: 28, color: Colors.green))),
        ],
        if (_afterUrls.isNotEmpty) ...[
          const Text("AFTER (Work Completed)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
          const SizedBox(height: 8),
          _buildImageRow(_afterUrls),
        ],
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  urls[index], height: 100, width: 100, fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) => progress == null ? child : Container(height: 100, width: 100, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator())),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
          body: Center(child: InteractiveViewer(panEnabled: true, minScale: 0.5, maxScale: 4.0, child: Image.network(imageUrl))),
        ),
      ),
    );
  }

  // --- SUBMIT & UPDATE LOGIC ---
  Future<void> _uploadImages(String ticketId, String stage) async {
    final userId = context.read<AuthProvider>().currentUserId;
    for (var img in _selectedImages) {
      final fileExt = img.path.split('.').last;
      final fileName = '${stage.toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}.$fileExt';
      final storagePath = '$ticketId/$fileName';

      await _supabase.storage.from('ticket-media').upload(storagePath, File(img.path));
      await _supabase.from('ticket_media').insert({ 'ticket_id': ticketId, 'storage_path': storagePath, 'upload_stage': stage, 'uploaded_by': userId });
    }
  }

  Future<void> _submitNewTicket() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate() || _selectedEquipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an Equipment.')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().currentUserId;
      final kitchenResp = await _supabase.from('m_kitchen').select('id').limit(1).single();

      final newTicket = await _supabase.from('tickets').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'priority': _priority,
        'area_id': _selectedAreaId,
        'equipment_id': _selectedEquipmentId,
        'kitchen_id': kitchenResp['id'],
        'raised_by_id': userId,
      }).select().single();

      if (_selectedImages.isNotEmpty) await _uploadImages(newTicket['id'], 'RAISED');

      if (mounted) {
        context.read<TicketProvider>().refreshTickets();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket Raised successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTicketStatus(String? nextStatus) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (nextStatus == 'COMPLETED' && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload Completion Photos.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updates = <String, dynamic>{
        'description': _descController.text,
        'priority': _priority,
        'area_id': _selectedAreaId,
        'equipment_id': _selectedEquipmentId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nextStatus != null) updates['status'] = nextStatus;

      if (_selectedWorker != null) {
        updates['assigned_to_id'] = _selectedWorker;
        if (currentStatus == 'UNDER_REVIEW' || currentStatus == 'RAISED') updates['status'] = 'ASSIGNED';
      }

      await _supabase.from('tickets').update(updates).eq('id', widget.ticket!['id']);
      if (nextStatus == 'COMPLETED' && _selectedImages.isNotEmpty) await _uploadImages(widget.ticket!['id'], 'COMPLETED');

      if (mounted) {
        context.read<TicketProvider>().refreshTickets();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- BUTTON UI ---
  Widget? _buildContextualActionButton(bool isAdmin) {
    String buttonText = "UPDATE TICKET";
    String? nextStatus;

    if (isAdmin) {
      if (currentStatus == 'RAISED') buttonText = "MARK UNDER REVIEW";
      if (currentStatus == 'COMPLETED') { buttonText = "VERIFY & CLOSE"; nextStatus = 'VERIFIED'; }
    } else {
      if (currentStatus == 'ASSIGNED') { buttonText = "START WORK"; nextStatus = 'IN_PROGRESS'; }
      else if (currentStatus == 'IN_PROGRESS') { buttonText = "MARK COMPLETE"; nextStatus = 'COMPLETED'; }
      else { return null; }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: _isLoading ? null : () => _updateTicketStatus(nextStatus),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildSubmitNewButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: _isLoading ? null : _submitNewTicket,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT TICKET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController ctrl, required String label, bool isReadOnly = false, int maxLines = 1, String? Function(String?)? validator, Color? fillColor}) {
    return TextFormField(
      controller: ctrl, readOnly: isReadOnly, maxLines: maxLines, validator: validator,
      decoration: _inputDecoration(label, fillColor: fillColor),
    );
  }

  InputDecoration _inputDecoration(String label, {Color? fillColor}) {
    return InputDecoration(
      labelText: label, filled: true, fillColor: fillColor ?? Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
    );
  }
}