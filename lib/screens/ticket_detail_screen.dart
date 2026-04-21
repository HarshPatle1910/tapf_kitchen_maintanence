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

  // Form Controllers & State
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategory;
  String? _selectedEquipment;
  String? _selectedWorker;
  String _priority = 'MEDIUM';
  bool _isLoading = false;

  // Multiple Image Upload State
  List<XFile> _selectedImages = [];

  // Gallery State (Separated for Before & After)
  List<String> _beforeUrls = [];
  List<String> _afterUrls = [];
  bool _isLoadingMedia = false;

  // Dropdown Data
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _equipment = [];
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
      _selectedCategory = widget.ticket!['category_id'];
      _selectedEquipment = widget.ticket!['equipment_id'];
      _selectedWorker = widget.ticket!['assigned_to_id'];

      _fetchMedia();
    }
  }

  // --- FETCHING BEFORE & AFTER MEDIA ---
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

  Future<void> _fetchDropdownData() async {
    final cats = await _supabase.from('issue_categories').select().eq('is_active', true);
    final equips = await _supabase.from('m_equipment').select().eq('is_active', true);
    final staff = await _supabase.from('m_user').select().eq('role', 'worker').eq('status', true);

    if (mounted) {
      setState(() {
        _categories = List<Map<String, dynamic>>.from(cats);
        _equipment = List<Map<String, dynamic>>.from(equips);
        _workers = List<Map<String, dynamic>>.from(staff);
      });
    }
  }

  // --- NEW: IMAGE SELECTION LOGIC (CAMERA & GALLERY) ---

  void _showImageSourceDialog() {
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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.camera_alt_rounded, color: _primaryColor),
                ),
                title: const Text('Take a Photo (Camera)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(fromCamera: true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.photo_library_rounded, color: _primaryColor),
                ),
                title: const Text('Choose from Gallery (Multiple)'),
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
      final bytes = await File(img.path).length();
      // 5 MB limit (5 * 1024 * 1024 bytes)
      if (bytes <= 5242880) {
        validImages.add(img);
      } else {
        filesDropped = true;
      }
    }

    if (filesDropped && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Some images were skipped (exceeded 5MB limit).'),
              backgroundColor: Colors.orange
          )
      );
    }

    setState(() {
      _selectedImages.addAll(validImages);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final isCompleting = isEditing && !isAdmin && currentStatus == 'IN_PROGRESS';
    final showCameraBox = !isEditing || isCompleting;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(isEditing ? (widget.ticket!['ticket_no'] ?? 'Ticket Details') : "Raise New Issue", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text("Status: $currentStatus", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- 2. CORE FORM FIELDS ---
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

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            decoration: _inputDecoration("Category *"),
                            items: _categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
                            onChanged: isEditing && !isAdmin ? null : (val) => setState(() => _selectedCategory = val),
                            validator: (val) => val == null ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _priority,
                            decoration: _inputDecoration("Priority *"),
                            items: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: isEditing && !isAdmin ? null : (val) => setState(() => _priority = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedEquipment,
                      decoration: _inputDecoration("Equipment (Optional)"),
                      items: _equipment.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text(e['name']))).toList(),
                      onChanged: isEditing && !isAdmin ? null : (val) => setState(() => _selectedEquipment = val),
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                        ctrl: _descController,
                        label: "Description",
                        maxLines: 4,
                        isReadOnly: isEditing && !isAdmin
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. DYNAMIC PHOTO UPLOAD ---
              if (showCameraBox) ...[
                Text(
                    isCompleting ? "Completion Photos (Required)" : "Issue Photos (Optional)",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                ),
                const SizedBox(height: 12),

                // Show Selected Images
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        // Button to add more images
                        if (index == _selectedImages.length) {
                          return GestureDetector(
                            onTap: _showImageSourceDialog, // Changed to show the dialog
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)),
                              child: const Icon(Icons.add_a_photo, color: Colors.grey),
                            ),
                          );
                        }

                        // Display selected image with a remove button
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(_selectedImages[index].path), fit: BoxFit.cover),
                              ),
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
                  )
                else
                  InkWell(
                    onTap: _showImageSourceDialog, // Changed to show the dialog
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isCompleting ? Colors.red.shade300 : Colors.grey.shade300, width: 2, style: BorderStyle.none),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: isCompleting ? Colors.red : _primaryColor),
                          const SizedBox(height: 8),
                          Text("Tap to add photos\n(Camera or Gallery, Max 5MB)", textAlign: TextAlign.center, style: TextStyle(color: isCompleting ? Colors.red : Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // --- 4. ADMIN ACTIONS ---
              if (isEditing && isAdmin) ...[
                const Text("Admin Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 12),
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

              // --- 5. MEDIA GALLERY & COMMENTS ---
              // if (isEditing) ...[
              //   _buildMediaSection(),
              //   const SizedBox(height: 24),
              //   _buildCommentsSection(),
              // ]
            ],
          ),
        ),
      ),
      bottomNavigationBar: isEditing ? _buildContextualActionButton(isAdmin) : _buildSubmitNewButton(),
    );
  }

  // --- BEFORE & AFTER MEDIA GALLERY ---
  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Media Gallery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        if (_isLoadingMedia)
          const Center(child: CircularProgressIndicator())
        else if (_beforeUrls.isEmpty && _afterUrls.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Text("No photos attached to this ticket.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // BEFORE Images
                if (_beforeUrls.isNotEmpty) ...[
                  const Text("BEFORE (Issue Raised)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildImageRow(_beforeUrls),
                ],

                // ARROW Divider
                if (_beforeUrls.isNotEmpty && _afterUrls.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(Icons.arrow_downward_rounded, size: 32, color: Colors.green),
                  ),
                ],

                // AFTER Images
                if (_afterUrls.isNotEmpty) ...[
                  const Text("AFTER (Work Completed)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildImageRow(_afterUrls),
                ],
              ],
            ),
          )
      ],
    );
  }

  // Helper to build a scrolling row of images
  Widget _buildImageRow(List<String> urls) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openImageViewer(context, urls[index]),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  urls[index],
                  height: 120, width: 120, fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) => progress == null ? child : const SizedBox(height: 120, width: 120, child: Center(child: CircularProgressIndicator())),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- FULL SCREEN ZOOM VIEWER ---
  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl),
            ),
          ),
        )
    ));
  }

  // Widget _buildCommentsSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  //       const SizedBox(height: 12),
  //       Container(
  //         width: double.infinity,
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
  //         child: const Text("No comments yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
  //       ),
  //       const SizedBox(height: 12),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: TextField(decoration: _inputDecoration("Add a comment...")),
  //           ),
  //           const SizedBox(width: 8),
  //           Container(
  //             decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(12)),
  //             child: IconButton(
  //               color: Colors.white,
  //               icon: const Icon(Icons.send_rounded),
  //               onPressed: () {},
  //             ),
  //           )
  //         ],
  //       )
  //     ],
  //   );
  // }

  // --- UPLOAD LOGIC ---

  Future<void> _uploadImages(String ticketId, String stage) async {
    final userId = context.read<AuthProvider>().currentUserId;

    for (var img in _selectedImages) {
      final fileExt = img.path.split('.').last;
      final fileName = '${stage.toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}.$fileExt';
      final storagePath = '$ticketId/$fileName';

      await _supabase.storage.from('ticket-media').upload(storagePath, File(img.path));

      await _supabase.from('ticket_media').insert({
        'ticket_id': ticketId,
        'storage_path': storagePath,
        'upload_stage': stage,
        'uploaded_by': userId,
      });
    }
  }

  Future<void> _submitNewTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().currentUserId;
      final kitchenResp = await _supabase.from('m_kitchen').select('id').limit(1).single();

      final newTicket = await _supabase.from('tickets').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'priority': _priority,
        'category_id': _selectedCategory,
        'equipment_id': _selectedEquipment,
        'kitchen_id': kitchenResp['id'],
        'raised_by_id': userId,
      }).select().single();

      if (_selectedImages.isNotEmpty) {
        await _uploadImages(newTicket['id'], 'RAISED');
      }

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
    if (nextStatus == 'COMPLETED' && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload Completion Photos to mark this work as done.'), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updates = <String, dynamic>{
        'description': _descController.text,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nextStatus != null) updates['status'] = nextStatus;

      if (_selectedWorker != null) {
        updates['assigned_to_id'] = _selectedWorker;
        if (currentStatus == 'UNDER_REVIEW' || currentStatus == 'RAISED') {
          updates['status'] = 'ASSIGNED';
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI HELPERS ---

  Widget? _buildContextualActionButton(bool isAdmin) {
    String buttonText = "UPDATE TICKET";
    String? nextStatus;

    if (isAdmin) {
      if (currentStatus == 'RAISED') buttonText = "MARK UNDER REVIEW";
      if (currentStatus == 'COMPLETED') {
        buttonText = "VERIFY & CLOSE";
        nextStatus = 'VERIFIED';
      }
    } else {
      if (currentStatus == 'ASSIGNED') {
        buttonText = "START WORK";
        nextStatus = 'IN_PROGRESS';
      } else if (currentStatus == 'IN_PROGRESS') {
        buttonText = "MARK COMPLETE";
        nextStatus = 'COMPLETED';
      } else {
        return null;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: _isLoading ? null : () => _updateTicketStatus(nextStatus),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildSubmitNewButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: _isLoading ? null : _submitNewTicket,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT TICKET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController ctrl, required String label, bool isReadOnly = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      readOnly: isReadOnly,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
    );
  }
}