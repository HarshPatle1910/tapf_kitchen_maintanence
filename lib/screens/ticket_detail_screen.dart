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

  // Form Controllers & State
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategory;
  String? _selectedEquipment;
  String? _selectedWorker;
  String _priority = 'MEDIUM';
  bool _isLoading = false;

  // Image State
  XFile? _issueImage;
  List<String> _mediaUrls = []; // NEW: To hold fetched image URLs
  bool _isLoadingMedia = false; // NEW: Loading state for images

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

      _fetchMedia(); // NEW: Fetch images when opening a ticket
    }
  }

  // NEW: Fetch images from the ticket_media table
  Future<void> _fetchMedia() async {
    setState(() => _isLoadingMedia = true);
    try {
      final mediaRecords = await _supabase
          .from('ticket_media')
          .select('storage_path')
          .eq('ticket_id', widget.ticket!['id']);

      List<String> urls = [];
      for (var record in mediaRecords) {
        // Generate the public URL for each image
        final url = _supabase.storage.from('ticket-media').getPublicUrl(record['storage_path']);
        urls.add(url);
      }

      if (mounted) setState(() => _mediaUrls = urls);
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final isCompleting = isEditing && !isAdmin && currentStatus == 'IN_PROGRESS';
    final showCameraBox = !isEditing || isCompleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? (widget.ticket!['ticket_no'] ?? 'Ticket Details') : "Raise New Issue"),
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
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text("Status: $currentStatus", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- 2. CORE FORM FIELDS ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Issue Title *", border: OutlineInputBorder()),
                readOnly: isEditing && !isAdmin,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: "Category *", border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: "Priority *", border: OutlineInputBorder()),
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
                decoration: const InputDecoration(labelText: "Equipment (Optional)", border: OutlineInputBorder()),
                items: _equipment.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text(e['name']))).toList(),
                onChanged: isEditing && !isAdmin ? null : (val) => setState(() => _selectedEquipment = val),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                readOnly: isEditing && !isAdmin,
              ),
              const SizedBox(height: 24),

              // --- 3. DYNAMIC PHOTO UPLOAD ---
              if (showCameraBox) ...[
                Text(
                    isCompleting ? "Completion Photo (Required)" : "Issue Photo (Optional)",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                    if (image != null) setState(() => _issueImage = image);
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _issueImage == null && isCompleting ? Colors.red : Colors.grey[400]!),
                    ),
                    child: _issueImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_issueImage!.path), fit: BoxFit.cover, width: double.infinity),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: _issueImage == null && isCompleting ? Colors.red : Colors.grey),
                        const SizedBox(height: 8),
                        Text("Tap to capture photo", style: TextStyle(color: _issueImage == null && isCompleting ? Colors.red : Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // --- 4. ADMIN ACTIONS ---
              if (isEditing && isAdmin) ...[
                const Divider(),
                const Text("Admin Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedWorker,
                  decoration: const InputDecoration(labelText: "Assign Worker", border: OutlineInputBorder(), prefixIcon: Icon(Icons.engineering)),
                  items: _workers.map((w) => DropdownMenuItem(value: w['id'].toString(), child: Text(w['name']))).toList(),
                  onChanged: (val) => setState(() => _selectedWorker = val),
                ),
                const SizedBox(height: 24),
              ],

              // --- 5. MEDIA & COMMENTS ---
              if (isEditing) ...[
                const Divider(),
                _buildMediaSection(),
                const SizedBox(height: 24),
                const Divider(),
                _buildCommentsSection(),
              ]
            ],
          ),
        ),
      ),
      bottomNavigationBar: isEditing ? _buildContextualActionButton(isAdmin) : _buildSubmitNewButton(),
    );
  }

  // NEW: Updated Media Section to display actual images
  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Media Gallery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        if (_isLoadingMedia)
          const Center(child: CircularProgressIndicator())
        else if (_mediaUrls.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!)
            ),
            child: Text("No photos attached to this ticket.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          )
        else
          SizedBox(
            height: 150, // Height for the horizontal image scroller
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mediaUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _mediaUrls[index],
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                      // Show a loading spinner while the image downloads
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                            height: 150, width: 150,
                            child: Center(child: CircularProgressIndicator())
                        );
                      },
                      // Fallback if the image fails to load
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150, width: 150, color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
          child: const Text("No comments yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: TextField(decoration: InputDecoration(hintText: "Add a comment...", border: OutlineInputBorder())),
            ),
            const SizedBox(width: 8),
            IconButton(
              style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              icon: const Icon(Icons.send),
              onPressed: () {},
            )
          ],
        )
      ],
    );
  }

  Widget _buildSubmitNewButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        onPressed: _isLoading ? null : _submitNewTicket,
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("SUBMIT TICKET", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

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
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        onPressed: () => _updateTicketStatus(nextStatus),
        child: Text(buttonText),
      ),
    );
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

      final newTicketId = newTicket['id'];

      if (_issueImage != null) {
        final fileExt = _issueImage!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final storagePath = '$newTicketId/$fileName';

        await _supabase.storage.from('ticket-media').upload(storagePath, File(_issueImage!.path));

        await _supabase.from('ticket_media').insert({
          'ticket_id': newTicketId,
          'storage_path': storagePath,
          'upload_stage': 'RAISED',
          'uploaded_by': userId,
        });
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
    if (nextStatus == 'COMPLETED' && _issueImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture a Completion Photo to mark this work as done.'), backgroundColor: Colors.red)
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

      if (nextStatus == 'COMPLETED' && _issueImage != null) {
        final userId = context.read<AuthProvider>().currentUserId;
        final ticketId = widget.ticket!['id'];
        final fileExt = _issueImage!.path.split('.').last;
        final fileName = 'completion_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final storagePath = '$ticketId/$fileName';

        await _supabase.storage.from('ticket-media').upload(storagePath, File(_issueImage!.path));

        await _supabase.from('ticket_media').insert({
          'ticket_id': ticketId,
          'storage_path': storagePath,
          'upload_stage': 'COMPLETED',
          'uploaded_by': userId,
        });
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
}