import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:video_compress/video_compress.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'video_player_screen.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

import '../../widgets/ticket/ticket_status_banner.dart';
import '../../widgets/ticket/ticket_timeline.dart';
import '../../widgets/ticket/ticket_form_fields.dart';
import '../core/constants/api_constants.dart';

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

  Map<String, dynamic>? _localTicket;
  bool _isFetchingTicket = false;

  final _titleController = TextEditingController();
  final _causeController = TextEditingController();
  final _actionTakenController = TextEditingController();
  final _customEquipmentController = TextEditingController();
  bool _isCustomEquipment = false;

  // Spares and Tools remain autocomplete because they have hundreds of items
  final _spareSearchController = TextEditingController();
  final _spareQtyController = TextEditingController();
  final _toolSearchController = TextEditingController();

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

  bool _workerToolsReturned = false;
  bool _toolsReturned = false;

  final List<XFile> _selectedImages = [];
  List<String> _beforeUrls = [];
  List<String> _afterUrls = [];
  List<Map<String, dynamic>> _beforeMedia = [];
  List<Map<String, dynamic>> _afterMedia = [];
  bool _isLoadingMedia = false;

  bool _isVideoExtension(String pathOrUrl) {
    final lower = pathOrUrl.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.m4v');
  }

  String _formatMediaCount(List<Map<String, dynamic>> mediaList) {
    final int photos = mediaList.where((m) => m['type'] != 'video').length;
    final int videos = mediaList.where((m) => m['type'] == 'video').length;
    if (photos > 0 && videos > 0) {
      return "$photos ${photos == 1 ? 'Photo' : 'Photos'}, $videos ${videos == 1 ? 'Video' : 'Videos'}";
    } else if (videos > 0) {
      return "$videos ${videos == 1 ? 'Video' : 'Videos'}";
    } else {
      return "$photos ${photos == 1 ? 'Photo' : 'Photos'}";
    }
  }

  List<Map<String, dynamic>> _allAreas = [];
  List<Map<String, dynamic>> _allEquipment = [];
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _availableSpares = [];
  List<Map<String, dynamic>> _availableTools = [];

  Map<String, dynamic>? _currentlySelectedSpareToAdd;
  Map<String, dynamic>? _currentlySelectedToolToAdd;

  bool get isEditing => _localTicket != null;
  String get currentStatus => _localTicket?['status'] ?? 'RAISED';
  bool get isTicketClosed => currentStatus == 'VERIFIED';

  @override
  void initState() {
    super.initState();

    if (widget.ticket != null) {
      _localTicket = Map<String, dynamic>.from(widget.ticket!);

      if (_localTicket!['title'] == null) {
        _fetchTicketFromDB(_localTicket!['id']);
      } else {
        _setupEditingData();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _fetchDropdownData(),
        );
      }
    } else {
      _breakdownTime = DateTime.now();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDropdownData());
    }
  }

  // --- TIME HELPERS FOR INDIAN STANDARD TIME (IST) ---
  String _getCurrentIST() {
    final istNow = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    return _formatToIST(istNow);
  }

  String _formatToIST(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$year-$month-${day}T$hour:$minute:$second+05:30';
  }

  Future<void> _fetchTicketFromDB(String id) async {
    setState(() => _isFetchingTicket = true);
    try {
      final res = await _supabase
          .from('tickets')
          .select('*, m_kitchen(name), assigned_to:m_user!assigned_to_id(name)')
          .eq('id', id)
          .single();

      setState(() {
        _localTicket = res;
        _setupEditingData();
      });
      _fetchDropdownData();
    } catch (e) {
      debugPrint("Error fetching ticket from notification: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load ticket details."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingTicket = false);
    }
  }

  void _setupEditingData() {
    _titleController.text = _localTicket!['title'] ?? '';
    _causeController.text = _localTicket!['cause_of_issue'] ?? '';
    _actionTakenController.text = _localTicket!['action_taken'] ?? '';
    _priority = _localTicket!['priority'] ?? 'MEDIUM';
    _category = _localTicket!['category'] ?? 'In Breakdown Condition';

    if (_localTicket!['custom_equipment'] != null &&
        _localTicket!['custom_equipment'].toString().isNotEmpty) {
      _customEquipmentController.text = _localTicket!['custom_equipment'];
      _isCustomEquipment = true;
      _selectedEquipments = [
        {'id': 'others', 'display_name': 'Others (Manual Entry)'},
      ];
    }
    _selectedAreaId = _localTicket!['area_id']?.toString();
    _selectedWorker = _localTicket!['assigned_to_id']?.toString();

    if (_localTicket!['breakdown_time'] != null) {
      _breakdownTime = DateTime.parse(
        _localTicket!['breakdown_time'],
      ).toLocal();
    }

    _fetchMedia();
    _fetchUsedSpares();
    _fetchUsedTools();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _causeController.dispose();
    _actionTakenController.dispose();
    _spareSearchController.dispose();
    _spareQtyController.dispose();
    _toolSearchController.dispose();
    _spareFocusNode.dispose();
    _toolFocusNode.dispose();
    super.dispose();
  }

  Future<String?> _triggerNotification({
    required String action,
    required String ticketId,
    required String ticketNo,
    required String kitchenId,
    String? assignedToId,
    String? raisedById,
    String? telegramMessageId,
  }) async {
    try {
      // Delay to ensure any just-uploaded images (ticket_media) are visible to the backend
      await Future.delayed(const Duration(milliseconds: 3000));

      final url = Uri.parse(
        '${ApiConstants.pythonApiBaseUrl}/notifications/trigger',
      );
      final String apiKey = dotenv.env['NOTIFICATION_API_KEY'] ?? '';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
        body: jsonEncode({
          "action": action,
          "ticket_id": ticketId,
          "ticket_no": ticketNo,
          "kitchen_id": kitchenId,
          "assigned_to_id": assignedToId,
          "raised_by_id": raisedById ?? _supabase.auth.currentUser?.id,
          if (telegramMessageId != null)
            "telegram_message_id": telegramMessageId,
        }),
      );
      debugPrint(
        "Notification API [$action] Response (${response.statusCode}): ${response.body}",
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          if (data['telegram_message_id'] != null)
            return data['telegram_message_id'].toString();
          if (data['message_id'] != null) return data['message_id'].toString();
          if (data['data'] != null && data['data']['message_id'] != null)
            return data['data']['message_id'].toString();
          if (data['result'] != null && data['result']['message_id'] != null)
            return data['result']['message_id'].toString();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Failed to trigger notification API: $e");
    }
    return null;
  }

  String _formatToCamelCase(String text) {
    if (text.trim().isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  String _formatDateTimeLocal(DateTime? d) {
    if (d == null) return 'Select Breakdown Time *';
    final int hour12 = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final String amPm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} $hour12:${d.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDisplayDate(DateTime? d) {
    if (d == null) return 'Unknown';
    final int hour12 = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final String amPm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} $hour12:${d.minute.toString().padLeft(2, '0')} $amPm';
  }

  Future<void> _pickBreakdownTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _breakdownTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: navy),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_breakdownTime ?? DateTime.now()),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: navy),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _breakdownTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _fetchMedia() async {
    if (_localTicket == null) return;
    setState(() => _isLoadingMedia = true);
    try {
      final mediaRecords = await _supabase
          .from('ticket_media')
          .select('*')
          .eq('ticket_id', _localTicket!['id']);

      if (mounted && mediaRecords.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No media records found for this ticket in Supabase!',
            ),
          ),
        );
      }

      List<String> before = [];
      List<String> after = [];
      List<Map<String, dynamic>> beforeMedia = [];
      List<Map<String, dynamic>> afterMedia = [];

      for (var record in mediaRecords) {
        String url = record['media_url'] ?? '';
        // If the path doesn't start with http, it means it's an old Supabase storage path
        if (!url.startsWith('http')) {
          url = _supabase.storage.from('ticket-media').getPublicUrl(url);
        }

        final isVideo =
            record['media_type'] == 'video' ||
            record['content_type']?.toString().startsWith('video') == true ||
            _isVideoExtension(url) ||
            _isVideoExtension(record['file_name'] ?? '');

        final mediaItem = {
          'url': url,
          'type': isVideo ? 'video' : 'photo',
          'file_name': record['file_name'] ?? '',
          'upload_stage': record['upload_stage'] ?? '',
        };

        if (record['upload_stage'] == 'COMPLETED') {
          after.add(url);
          afterMedia.add(mediaItem);
        } else {
          before.add(url);
          beforeMedia.add(mediaItem);
        }
      }
      if (mounted) {
        setState(() {
          _beforeUrls = before;
          _afterUrls = after;
          _beforeMedia = beforeMedia;
          _afterMedia = afterMedia;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching media: $e')));
      }
      debugPrint("Error fetching media: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMedia = false);
    }
  }

  Future<void> _fetchUsedSpares() async {
    if (_localTicket == null) return;
    try {
      final records = await _supabase
          .from('spare_ticket')
          .select(
            'id, used_qty, m_spares(*, m_vendor(name), spare_tracker(current_qty))',
          )
          .eq('ticket_id', _localTicket!['id']);
      if (mounted) {
        setState(() {
          _usedSpares = records
              .map(
                (r) => {
                  'id': r['id'],
                  'qty': r['used_qty'],
                  'spare': r['m_spares'],
                  'is_existing': true,
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching used spares: $e");
    }
  }

  Future<void> _fetchUsedTools() async {
    if (_localTicket == null) return;
    try {
      final records = await _supabase
          .from('ticket_tools')
          .select('*, m_tools(*)')
          .eq('ticket_id', _localTicket!['id']);
      if (mounted) {
        setState(() {
          _usedTools = records
              .map(
                (r) => {
                  'id': r['id'],
                  'tool': r['m_tools'],
                  'is_existing': true,
                  'taken_time': r['taken_time'],
                  'return_time': r['return_time'],
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching used tools: $e");
    }
  }

  Future<void> _fetchDropdownData() async {
    try {
      final authProv = context.read<AuthProvider>();
      final ticketProv = context.read<TicketProvider>();

      String targetKitchenId = "";

      if (isEditing) {
        targetKitchenId = _localTicket!['kitchen_id']?.toString() ?? "";
      } else {
        if (authProv.assignedKitchens.isNotEmpty) {
          int index = authProv.assignedKitchens.indexWhere(
            (k) => k['id'].toString() == ticketProv.kitchenFilter,
          );
          final activeKitchen = index != -1
              ? authProv.assignedKitchens[index]
              : authProv.assignedKitchens.first;
          targetKitchenId = activeKitchen['id']?.toString() ?? "";
        }
      }

      if (targetKitchenId.isEmpty) return;

      final zonesData = await _supabase
          .from('m_zone')
          .select('id')
          .eq('kitchen_id', targetKitchenId)
          .eq('status', true);
      final List<String> validZoneIds = zonesData
          .map((z) => z['id'].toString())
          .toList();

      List<dynamic> areasData = [];
      if (validZoneIds.isNotEmpty) {
        areasData = await _supabase
            .from('m_area')
            .select()
            .eq('status', true)
            .inFilter('zone_id', validZoneIds);
      }

      final equipsData = await _supabase
          .from('m_equipment')
          .select()
          .eq('status', true);
      final testEquipsData = await _supabase
          .from('m_testing_equipment')
          .select()
          .eq('status', true);

      final staffData = await _supabase
          .from('m_user')
          .select('*, user_kitchens(kitchen_id)')
          .eq('status', true);
      final sparesData = await _supabase
          .from('m_spares')
          .select('*, m_vendor(name), spare_tracker(current_qty)')
          .eq('status', true)
          .eq('kitchen_id', targetKitchenId);
      final toolsData = await _supabase
          .from('m_tools')
          .select('*')
          .eq('status', true)
          .eq('kitchen_id', targetKitchenId);

      if (mounted) {
        setState(() {
          _allAreas = List<Map<String, dynamic>>.from(areasData);
          for (var a in _allAreas) {
            a['display_name'] = a['area_name'];
          }
          // Sort Areas Alphabetically
          _allAreas.sort(
            (a, b) => (a['display_name'] ?? '')
                .toString()
                .toLowerCase()
                .compareTo((b['display_name'] ?? '').toString().toLowerCase()),
          );

          _allEquipment = [];
          for (var e in equipsData) {
            e['display_name'] = e['name'];
            e['is_testing'] = false;
            _allEquipment.add(e);
          }
          for (var te in testEquipsData) {
            te['display_name'] = '${te['name']} (Testing)';
            te['is_testing'] = true;
            _allEquipment.add(te);
          }
          // Sort Equipment Alphabetically
          _allEquipment.sort(
            (a, b) => (a['display_name'] ?? '')
                .toString()
                .toLowerCase()
                .compareTo((b['display_name'] ?? '').toString().toLowerCase()),
          );

          _workers = List<Map<String, dynamic>>.from(staffData);
          for (var w in _workers) {
            w['display_name'] = w['name'];
          }
          // Sort Workers Alphabetically
          _workers.sort(
            (a, b) => (a['display_name'] ?? '')
                .toString()
                .toLowerCase()
                .compareTo((b['display_name'] ?? '').toString().toLowerCase()),
          );

          _availableSpares = List<Map<String, dynamic>>.from(sparesData);
          for (var s in _availableSpares) {
            String vendorName = s['m_vendor']?['name'] != null
                ? " (${s['m_vendor']['name']})"
                : "";
            s['display_name'] = "${s['spare_name']}$vendorName";
          }
          _availableSpares.sort(
            (a, b) => (a['display_name'] ?? '')
                .toString()
                .toLowerCase()
                .compareTo((b['display_name'] ?? '').toString().toLowerCase()),
          );

          _availableTools = List<Map<String, dynamic>>.from(toolsData);
          for (var t in _availableTools) {
            t['display_name'] = t['tool_name'];
          }
          _availableTools.sort(
            (a, b) => (a['display_name'] ?? '')
                .toString()
                .toLowerCase()
                .compareTo((b['display_name'] ?? '').toString().toLowerCase()),
          );

          if (isEditing && _selectedAreaId != null) {
            _fetchLinkedEquipments();
          }
        });
      }
    } catch (e) {
      debugPrint("Dropdown Fetch Error: $e");
    }
  }

  Future<void> _fetchLinkedEquipments() async {
    if (_localTicket == null) return;
    try {
      final linkedEq = await _supabase
          .from('ticket_equipments')
          .select(
            'equipment_id, testing_equipment_id, m_equipment(*), m_testing_equipment(*)',
          )
          .eq('ticket_id', _localTicket!['id']);

      if (mounted) {
        setState(() {
          _selectedEquipments = [];
          for (var e in linkedEq) {
            if (e['m_equipment'] != null) {
              var eq = e['m_equipment'];
              eq['display_name'] = eq['name'];
              eq['is_testing'] = false;
              _selectedEquipments.add(eq);
            } else if (e['m_testing_equipment'] != null) {
              var te = e['m_testing_equipment'];
              te['display_name'] = '${te['name']} (Testing)';
              te['is_testing'] = true;
              _selectedEquipments.add(te);
            }
          }
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Add Media (Photos & Videos)",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: navy.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: navy),
                ),
                title: Text(
                  'Take a Photo (Camera)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(fromCamera: true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: navy.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: navy),
                ),
                title: Text(
                  'Choose Photos from Gallery',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(fromCamera: false);
                },
              ),
              const Divider(height: 16, indent: 16, endIndent: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Color(0xFFD97706),
                  ),
                ),
                title: Text(
                  'Record a Video (Camera)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
                subtitle: Text(
                  'Record up to 3 mins (Max 50MB)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(fromCamera: true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.video_library_rounded,
                    color: Color(0xFFD97706),
                  ),
                ),
                title: Text(
                  'Choose Video from Gallery',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
                subtitle: Text(
                  'Max 50MB',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(fromCamera: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickVideo({required bool fromCamera}) async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (video == null) return;

      final length = await video.length();
      if (length > 52428800) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Video exceeds maximum limit of 50MB.',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      setState(() => _selectedImages.add(video));
    } catch (e) {
      debugPrint("Error picking video: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImages({required bool fromCamera}) async {
    final picker = ImagePicker();
    List<XFile> pickedFiles = [];

    if (fromCamera) {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (image != null) pickedFiles.add(image);
    } else {
      final images = await picker.pickMultiImage(imageQuality: 70);
      pickedFiles.addAll(images);
    }

    if (pickedFiles.isEmpty) return;
    List<XFile> validImages = [];
    bool filesDropped = false;

    for (var img in pickedFiles) {
      if ((await img.length()) <= 5242880)
        validImages.add(img);
      else
        filesDropped = true;
    }

    if (filesDropped && mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Some images skipped (exceeded 5MB).',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    setState(() => _selectedImages.addAll(validImages));
  }

  int _getSpareCurrentQty(Map<String, dynamic> spare) {
    final tracker = spare['spare_tracker'];
    if (tracker == null) return 0;
    if (tracker is List && tracker.isNotEmpty)
      return tracker[0]['current_qty'] ?? 0;
    if (tracker is Map) return tracker['current_qty'] ?? 0;
    return 0;
  }

  void _addSpareToTicket() {
    if (_currentlySelectedSpareToAdd == null) return;
    int qtyToAdd = int.tryParse(_spareQtyController.text.trim()) ?? 0;

    if (qtyToAdd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Quantity must be greater than 0"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int availableQty = _getSpareCurrentQty(_currentlySelectedSpareToAdd!);
    if (qtyToAdd > availableQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Only $availableQty available in stock!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_usedSpares.any(
      (item) => item['spare']['id'] == _currentlySelectedSpareToAdd!['id'],
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Spare already added. Remove and add again to adjust quantity.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _usedSpares.add({
        'spare': _currentlySelectedSpareToAdd,
        'qty': qtyToAdd,
        'is_existing': false,
      });
      _currentlySelectedSpareToAdd = null;
      _spareSearchController.clear();
      _spareQtyController.clear();
      _spareFocusNode.unfocus();
    });
  }

  void _addToolToTicket() {
    if (_currentlySelectedToolToAdd == null) return;
    if (_usedTools.any(
      (item) => item['tool']['id'] == _currentlySelectedToolToAdd!['id'],
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tool already added to this ticket."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _usedTools.add({
        'tool': _currentlySelectedToolToAdd,
        'is_existing': false,
      });
      _currentlySelectedToolToAdd = null;
      _toolSearchController.clear();
      _toolFocusNode.unfocus();
    });
  }

  // --- DELETE TOOLS AND SPARES FROM DRAFTS ---
  Future<void> _removeTool(Map<String, dynamic> item) async {
    final bool isExisting = item['is_existing'] == true;
    if (isExisting) {
      setState(() => _isLoading = true);
      try {
        await _supabase.from('ticket_tools').delete().eq('id', item['id']);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing tool: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
      setState(() => _isLoading = false);
    }
    setState(() => _usedTools.remove(item));
  }

  Future<void> _removeSpare(Map<String, dynamic> item) async {
    final bool isExisting = item['is_existing'] == true;
    if (isExisting) {
      setState(() => _isLoading = true);
      try {
        final spareId = item['spare']['id'];
        final int qty = item['qty'];

        await _supabase.from('spare_ticket').delete().eq('id', item['id']);

        final trackerRes = await _supabase
            .from('spare_tracker')
            .select('current_qty')
            .eq('spare_id', spareId)
            .maybeSingle();
        if (trackerRes != null) {
          int currentQty = trackerRes['current_qty'] ?? 0;
          await _supabase
              .from('spare_tracker')
              .update({'current_qty': currentQty + qty})
              .eq('spare_id', spareId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing spare: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
      setState(() => _isLoading = false);
    }
    setState(() => _usedSpares.remove(item));
  }

  // --- SUBMIT / UPDATE LOGIC ---
  Future<void> _uploadImages(
    String ticketId,
    String ticketNo,
    String stage,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    final pathStage = stage.toLowerCase() == 'completed' ? 'closed' : 'raised';

    for (var file in _selectedImages) {
      final fileExt = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final isVideo =
          _isVideoExtension(file.name) || _isVideoExtension(file.path);
      final fileName =
          '${stage.toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}.$fileExt';
      final storagePath = 'PMT_Tickets/$ticketNo/$pathStage/$fileName';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(storagePath);

      if (isVideo) {
        File uploadFile = File(file.path);
        if (!kIsWeb) {
          try {
            final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
              file.path,
              quality: VideoQuality.MediumQuality,
              deleteOrigin: false,
            );
            if (mediaInfo != null && mediaInfo.file != null) {
              uploadFile = mediaInfo.file!;
            }
          } catch (e) {
            debugPrint("Video compression error: $e, uploading original file");
          }
        }

        final fileSize = await uploadFile.length();
        final contentType = lookupMimeType(uploadFile.path) ?? 'video/$fileExt';

        await ref.putFile(
          uploadFile,
          SettableMetadata(contentType: contentType),
        );

        final downloadUrl = await ref.getDownloadURL();

        if (!kIsWeb) {
          try {
            await VideoCompress.deleteAllCache();
          } catch (_) {}
        }

        await _supabase.from('ticket_media').insert({
          'ticket_id': ticketId,
          'media_url': downloadUrl,
          'upload_stage': stage,
          'uploaded_by': userId,
          'file_name': file.name,
          'file_size': fileSize,
          'content_type': contentType,
          'media_type': 'video',
        });
      } else {
        final imageBytes = await file.readAsBytes();

        // Compress the image
        final compressedBytes = await FlutterImageCompress.compressWithList(
          imageBytes,
          minHeight: 1080,
          minWidth: 1080,
          quality: 70,
        );

        await ref.putData(
          compressedBytes,
          SettableMetadata(contentType: 'image/$fileExt'),
        );

        final downloadUrl = await ref.getDownloadURL();

        // Save the Firebase download URL in Supabase
        await _supabase.from('ticket_media').insert({
          'ticket_id': ticketId,
          'media_url': downloadUrl,
          'upload_stage': stage,
          'uploaded_by': userId,
          'file_name': file.name,
          'file_size': compressedBytes.length,
          'content_type': 'image/$fileExt',
          'media_type': 'photo',
        });
      }
    }
  }

  Future<void> _submitNewTicket() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _titleController.text = _formatToCamelCase(_titleController.text);

    if (!_formKey.currentState!.validate() ||
        _selectedAreaId == null ||
        _breakdownTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields including Area and Breakdown Time.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final availableEquipments = _allEquipment
        .where((e) => e['area_id']?.toString() == _selectedAreaId)
        .toList();
    if (availableEquipments.isNotEmpty && _selectedEquipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one Equipment.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload at least one photo or video of the issue.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProv = context.read<AuthProvider>();
      final ticketProv = context.read<TicketProvider>();
      final userId = _supabase.auth.currentUser?.id;

      dynamic exactKitchenId;
      if (authProv.assignedKitchens.isNotEmpty) {
        int index = authProv.assignedKitchens.indexWhere(
          (k) => k['id'].toString() == ticketProv.kitchenFilter,
        );
        final activeKitchen = index != -1
            ? authProv.assignedKitchens[index]
            : authProv.assignedKitchens.first;
        exactKitchenId = activeKitchen['id'];
      } else {
        final kitchenResp = await _supabase
            .from('m_kitchen')
            .select('id')
            .limit(1)
            .single();
        exactKitchenId = kitchenResp['id'];
      }

      Map<String, dynamic> insertData = {
        'title': _titleController.text,
        'custom_equipment': _isCustomEquipment
            ? _customEquipmentController.text.trim()
            : null,
        'priority': _priority,
        'category': _category,
        'area_id': _selectedAreaId,
        'kitchen_id': exactKitchenId,
        'raised_by_id': userId,
        'breakdown_time': _formatToIST(_breakdownTime!), // Indian Standard Time
      };

      final newTicket = await _supabase
          .from('tickets')
          .insert(insertData)
          .select()
          .single();

      final equipmentInserts = _selectedEquipments
          .where((eq) => eq['id'] != 'others')
          .map((eq) {
            if (eq['is_testing'] == true) {
              return {
                'ticket_id': newTicket['id'],
                'testing_equipment_id': eq['id'],
              };
            } else {
              return {'ticket_id': newTicket['id'], 'equipment_id': eq['id']};
            }
          })
          .toList();

      if (equipmentInserts.isNotEmpty) {
        await _supabase.from('ticket_equipments').insert(equipmentInserts);
      }

      if (_selectedImages.isNotEmpty)
        await _uploadImages(
          newTicket['id'],
          newTicket['ticket_no'] ?? 'UNKNOWN',
          'RAISED',
        );

      final String? returnedMessageId = await _triggerNotification(
        action: 'RAISED',
        ticketId: newTicket['id'],
        ticketNo: newTicket['ticket_no'] ?? 'NEW TICKET',
        kitchenId: exactKitchenId,
        telegramMessageId: newTicket['telegram_message_id'],
      );

      if (returnedMessageId != null) {
        await _supabase
            .from('tickets')
            .update({'telegram_message_id': returnedMessageId})
            .eq('id', newTicket['id']);
      }

      if (mounted) {
        context.read<TicketProvider>().refreshTickets();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ticket Raised successfully!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // NOTE: nextStatus = null means "Save Draft" or "Update Only"
  Future<void> _updateTicketStatus(String? nextStatus, bool isAdmin) async {
    FocusManager.instance.primaryFocus?.unfocus();
    _titleController.text = _formatToCamelCase(_titleController.text);

    // Validation
    if (nextStatus == 'VERIFIED') {
      if (_usedTools.isNotEmpty && !_toolsReturned) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please confirm that all checked-out tools have been returned.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (nextStatus == 'COMPLETED') {
      if (_usedTools.isNotEmpty && !_workerToolsReturned) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please confirm that you have returned all checked-out tools.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_causeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter the Cause of Issue.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_actionTakenController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter the Action Taken.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please upload completion photos or videos.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final nowISO = _getCurrentIST(); // ALWAYS Indian Standard Time
      final updates = <String, dynamic>{'updated_at': nowISO};

      if (nextStatus != null) {
        if (nextStatus == 'VERIFIED') {
          bool isRaiser =
              _localTicket?['raised_by_id'] == _supabase.auth.currentUser?.id;
          bool currentAdminVerified = _localTicket?['admin_verified'] ?? false;
          bool currentRaiserVerified =
              _localTicket?['raiser_verified'] ?? false;

          if (isAdmin && !isRaiser) {
            updates['admin_verified'] = true;
            updates['admin_verified_at'] = nowISO;
            currentAdminVerified = true;
          } else if (isRaiser && !isAdmin) {
            updates['raiser_verified'] = true;
            updates['raiser_verified_at'] = nowISO;
            currentRaiserVerified = true;
          } else if (isAdmin && isRaiser) {
            updates['admin_verified'] = true;
            updates['admin_verified_at'] = nowISO;
            updates['raiser_verified'] = true;
            updates['raiser_verified_at'] = nowISO;
            currentAdminVerified = true;
            currentRaiserVerified = true;
          }

          if (currentAdminVerified && currentRaiserVerified) {
            updates['status'] = nextStatus;
            updates['verified_by_id'] = _supabase.auth.currentUser?.id;
          }
        } else {
          updates['status'] = nextStatus;
          if (nextStatus == 'IN_PROGRESS')
            updates['repair_start_time'] = nowISO;
          else if (nextStatus == 'COMPLETED') {
            updates['ticket_completion_time'] = nowISO;
          }
        }
      }

      final isAssignedWorker =
          _selectedWorker != null &&
          _selectedWorker == _supabase.auth.currentUser?.id;

      if ((isAssignedWorker && currentStatus == 'IN_PROGRESS') ||
          (isAdmin && !isTicketClosed)) {
        updates['action_taken'] = _actionTakenController.text.trim();
        updates['cause_of_issue'] = _causeController.text.trim();
      }

      if (isAdmin && !isTicketClosed) {
        updates['title'] = _titleController.text;
        updates['custom_equipment'] = _isCustomEquipment
            ? _customEquipmentController.text.trim()
            : null;
        updates['priority'] = _priority;
        updates['category'] = _category;
        updates['area_id'] = _selectedAreaId;
        if (_breakdownTime != null)
          updates['breakdown_time'] = _formatToIST(_breakdownTime!);

        if (currentStatus == 'RAISED' || currentStatus == 'ASSIGNED') {
          if (_selectedWorker != null) {
            updates['assigned_to_id'] = _selectedWorker;
            if (_selectedWorker !=
                    _localTicket!['assigned_to_id']?.toString() ||
                _localTicket!['assigned_to_time'] == null) {
              updates['assigned_to_time'] = nowISO;
            }
            if (currentStatus == 'RAISED' && nextStatus == null)
              updates['status'] = 'ASSIGNED';
          }
        }

        await _supabase
            .from('ticket_equipments')
            .delete()
            .eq('ticket_id', _localTicket!['id']);

        final validEquipments = _selectedEquipments
            .where((eq) => eq['id'] != 'others')
            .toList();
        if (validEquipments.isNotEmpty) {
          final newMappings = validEquipments.map((eq) {
            if (eq['is_testing'] == true) {
              return {
                'ticket_id': _localTicket!['id'],
                'testing_equipment_id': eq['id'],
              };
            } else {
              return {
                'ticket_id': _localTicket!['id'],
                'equipment_id': eq['id'],
              };
            }
          }).toList();
          await _supabase.from('ticket_equipments').insert(newMappings);
        }
      }

      if (_usedTools.isNotEmpty) {
        for (var item in _usedTools) {
          if (item['is_existing'] == true) continue;
          await _supabase.from('ticket_tools').insert({
            'ticket_id': _localTicket!['id'],
            'tool_id': item['tool']['id'],
            'employee_id': _supabase.auth.currentUser?.id,
            'taken_time': nowISO,
            'is_vacant': false,
          });
        }
      }

      if (nextStatus == 'VERIFIED' && _usedTools.isNotEmpty) {
        await _supabase
            .from('ticket_tools')
            .update({'return_time': nowISO, 'is_vacant': true})
            .eq('ticket_id', _localTicket!['id'])
            .isFilter('return_time', null);
      }

      if (_usedSpares.isNotEmpty) {
        for (var item in _usedSpares) {
          if (item['is_existing'] == true) continue;
          final spare = item['spare'];
          final int qty = item['qty'];
          await _supabase.from('spare_ticket').insert({
            'ticket_id': _localTicket!['id'],
            'spare_id': spare['id'],
            'used_qty': qty,
            'used_qty_time': nowISO,
            'logged_by_id': _supabase.auth.currentUser?.id,
          });
          int currentStock = _getSpareCurrentQty(spare);
          await _supabase
              .from('spare_tracker')
              .update({'current_qty': currentStock - qty})
              .eq('spare_id', spare['id']);
        }
      }

      await _supabase
          .from('tickets')
          .update(updates)
          .eq('id', _localTicket!['id']);
      final String? effectiveStatus =
          nextStatus ?? updates['status']?.toString() ?? currentStatus;

      if (effectiveStatus == 'COMPLETED' && _selectedImages.isNotEmpty) {
        await _uploadImages(
          _localTicket!['id'],
          _localTicket!['ticket_no'] ?? 'UNKNOWN',
          'COMPLETED',
        );
      }

      final String? previousWorker = _localTicket!['assigned_to_id']
          ?.toString();
      final bool isAssignedEvent =
          _selectedWorker != null &&
          (_selectedWorker != previousWorker || effectiveStatus == 'ASSIGNED');

      if (isAssignedEvent) {
        await _triggerNotification(
          action: 'ASSIGNED',
          ticketId: _localTicket!['id'],
          ticketNo: _localTicket!['ticket_no'] ?? 'UNKNOWN',
          kitchenId: _localTicket!['kitchen_id'],
          assignedToId: _selectedWorker,
          raisedById: _localTicket!['raised_by_id'],
          telegramMessageId: _localTicket!['telegram_message_id'],
        );
      }

      if (effectiveStatus == 'COMPLETED') {
        await _triggerNotification(
          action: 'COMPLETED',
          ticketId: _localTicket!['id'],
          ticketNo: _localTicket!['ticket_no'] ?? 'UNKNOWN',
          kitchenId: _localTicket!['kitchen_id'],
          raisedById: _localTicket!['raised_by_id'],
          telegramMessageId: _localTicket!['telegram_message_id'],
        );
      }

      if (mounted) {
        if (_localTicket != null) {
          _localTicket!.addAll(updates);
          if (_selectedWorker != null) {
            final assignedWorkerObj = _workers.firstWhere(
              (w) => w['id']?.toString() == _selectedWorker,
              orElse: () => <String, dynamic>{},
            );
            if (assignedWorkerObj.isNotEmpty) {
              _localTicket!['assigned_to'] = {
                'name':
                    assignedWorkerObj['display_name'] ??
                    assignedWorkerObj['name'] ??
                    'Assigned Worker',
              };
            }
          }
        }
        context.read<TicketProvider>().refreshTickets();

        if (nextStatus == null)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Updates saved successfully!',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.green,
            ),
          );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW CUSTOM AUTOCOMPLETE WIDGET FOR SPARES & TOOLS ---
  Widget _buildAutocomplete({
    Key? key,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<Map<String, dynamic>> options,
    required bool isDisabled,
    required Function(Map<String, dynamic>) onSelected,
    required VoidCallback onCleared,
  }) {
    return RawAutocomplete<Map<String, dynamic>>(
      key: key,
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue val) {
        if (val.text.isEmpty) return options;
        return options.where(
          (opt) => (opt['display_name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(val.text.toLowerCase()),
        );
      },
      displayStringForOption: (opt) => (opt['display_name'] ?? '').toString(),
      onSelected: (sel) {
        onSelected(sel);
        focusNode.unfocus();
      },
      fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
        controller: ctrl,
        focusNode: fNode,
        enabled: !isDisabled,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: ctrl.text.isNotEmpty && !isDisabled
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                  onPressed: () {
                    ctrl.clear();
                    onCleared();
                    fNode.unfocus();
                  },
                )
              : const Icon(Icons.arrow_drop_down, color: Colors.grey),
          filled: true,
          fillColor: isDisabled ? Colors.grey.shade100 : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: golden),
          ),
        ),
        onTap: () {
          if (!isDisabled && ctrl.text.isEmpty) {
            ctrl.notifyListeners();
          }
        },
      ),
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 400,
              maxWidth: MediaQuery.of(context).size.width - 68,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF94A3B8), width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opts.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (ctx, idx) => ListTile(
                  title: Text(
                    (opts.elementAt(idx)['display_name'] ?? '').toString(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: navy,
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
    );
  }

  // --- UI RENDERERS FOR MEDIA / CONTEXTUAL ACTIONS ---
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF94A3B8),
                      width: 1.2,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: navy,
                        size: 28,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Add More",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: navy,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isVideo = _isVideoExtension(_selectedImages[index].path);

            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (isVideo) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            videoUrl: _selectedImages[index].path,
                            title: "Selected Video Preview",
                            subtitle: _selectedImages[index].name,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isVideo
                          ? const Color(0xFF0F172A)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF94A3B8),
                        width: 1.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: isVideo
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Color(0xFFD97706),
                                  size: 38,
                                ),
                                Positioned(
                                  bottom: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.65),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.videocam_rounded,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          "VIDEO",
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : kIsWeb
                          ? Image.network(
                              _selectedImages[index].path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 12,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedImages.removeAt(index)),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
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
          border: Border.all(
            color: isCompleting ? Colors.red.shade300 : const Color(0xFF94A3B8),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 34,
                  color: isCompleting ? Colors.red : navy,
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.videocam_rounded,
                  size: 34,
                  color: isCompleting ? Colors.red : const Color(0xFFD97706),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Tap to add photos or videos\n(Camera or Gallery)",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isCompleting ? Colors.red : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getWordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  String _getAreaDisplayName(String? areaId) {
    if (areaId == null) return 'Select Area';
    final found = _allAreas.firstWhere(
      (a) => a['id'].toString() == areaId,
      orElse: () => {},
    );
    return (found['display_name'] ?? found['area_name'] ?? 'Unknown Area')
        .toString();
  }

  void _showAddToolDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Check Out Tool",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAutocomplete(
                  hint: "Search Required Tool",
                  icon: Icons.plumbing,
                  controller: _toolSearchController,
                  focusNode: _toolFocusNode,
                  options: _availableTools,
                  isDisabled: false,
                  onSelected: (val) {
                    setModalState(() => _currentlySelectedToolToAdd = val);
                    setState(() => _currentlySelectedToolToAdd = val);
                  },
                  onCleared: () {
                    setModalState(() => _currentlySelectedToolToAdd = null);
                    setState(() => _currentlySelectedToolToAdd = null);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      _addToolToTicket();
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      "Add Tool",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddSpareDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Use Spare Part",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAutocomplete(
                  hint: "Search Spare",
                  icon: Icons.build_circle,
                  controller: _spareSearchController,
                  focusNode: _spareFocusNode,
                  options: _availableSpares,
                  isDisabled: false,
                  onSelected: (val) {
                    setModalState(() => _currentlySelectedSpareToAdd = val);
                    setState(() => _currentlySelectedSpareToAdd = val);
                  },
                  onCleared: () {
                    setModalState(() => _currentlySelectedSpareToAdd = null);
                    setState(() => _currentlySelectedSpareToAdd = null);
                  },
                ),
                if (_currentlySelectedSpareToAdd != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, left: 4),
                    child: Text(
                      "Available in Stock: ${_getSpareCurrentQty(_currentlySelectedSpareToAdd!)}",
                      style: GoogleFonts.inter(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _spareQtyController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                  decoration: InputDecoration(
                    labelText: "Quantity",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: golden,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      _addSpareToTicket();
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      "Add Spare",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
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
        ),
      ),
    );
  }

  void _openMediaViewer(BuildContext context, Map<String, dynamic> media) {
    if (media['type'] == 'video') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            videoUrl: media['url'] ?? '',
            title: _localTicket?['ticket_no'] != null
                ? "Ticket #${_localTicket!['ticket_no']}"
                : "Visual Verification",
            subtitle: "${media['upload_stage'] ?? 'Verification'} Video",
            fileName: media['file_name'],
          ),
        ),
      );
    } else {
      _openImageViewer(context, media['url'] ?? '');
    }
  }

  void _showVideoPlayerModal(
    BuildContext context,
    String videoUrl,
    String? fileName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: Color(0xFFD97706),
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Verification Video",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              if (fileName != null && fileName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse(videoUrl);
                    try {
                      final launched = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launched) {
                        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                      }
                    } catch (e) {
                      debugPrint("Error opening video: $e");
                    }
                  },
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Play Video",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse(videoUrl);
                    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                  },
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    color: navy,
                    size: 18,
                  ),
                  label: Text(
                    "Open in Browser",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: navy,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(
                      color: Color(0xFF94A3B8),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildContextualActionButton(
    bool isAdmin,
    bool isAssignedWorker,
    bool canEditWorkDetails,
  ) {
    if (currentStatus == 'VERIFIED') return null;

    String buttonText = "UPDATE TICKET";
    String? nextStatus;

    if (currentStatus == 'RAISED') {
      if (isAdmin && _selectedWorker != null) {
        buttonText = "ASSIGN WORKER";
        nextStatus = 'ASSIGNED';
      } else if (isAdmin) {
        buttonText = "UPDATE TICKET";
      } else {
        return null;
      }
    } else if (currentStatus == 'ASSIGNED') {
      if (isAssignedWorker) {
        buttonText = "START WORK";
        nextStatus = 'IN_PROGRESS';
      } else if (isAdmin) {
        buttonText = "UPDATE TICKET";
      } else {
        return null;
      }
    } else if (currentStatus == 'IN_PROGRESS') {
      if (isAssignedWorker) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _updateTicketStatus(null, isAdmin),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "SAVE DRAFT",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _updateTicketStatus('COMPLETED', isAdmin),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "MARK COMPLETE",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (isAdmin) {
        buttonText = "UPDATE TICKET";
      } else {
        return null;
      }
    } else if (currentStatus == 'COMPLETED') {
      bool isRaiser =
          _localTicket?['raised_by_id'] == _supabase.auth.currentUser?.id;
      bool currentAdminVerified = _localTicket?['admin_verified'] ?? false;
      bool currentRaiserVerified = _localTicket?['raiser_verified'] ?? false;

      bool canAdminVerify = isAdmin && !currentAdminVerified;
      bool canRaiserVerify = isRaiser && !currentRaiserVerified;

      if (canAdminVerify || canRaiserVerify || isAdmin || isAssignedWorker) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (isAdmin || isAssignedWorker)
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _updateTicketStatus(null, isAdmin),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "UPDATE ONLY",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                if ((isAdmin || isAssignedWorker) &&
                    (canAdminVerify || canRaiserVerify))
                  const SizedBox(width: 12),
                if (canAdminVerify || canRaiserVerify)
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _updateTicketStatus('VERIFIED', isAdmin),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "VERIFY TICKET",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      } else {
        return null;
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: _isLoading
                ? null
                : () => _updateTicketStatus(nextStatus, isAdmin),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    buttonText,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _submitNewTicket,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "SUBMIT TICKET",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // --- CORE BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    if (_isFetchingTicket) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: navy)),
      );
    }

    final authProv = context.watch<AuthProvider>();
    final ticketProv = context.watch<TicketProvider>();
    final currentUserId = _supabase.auth.currentUser?.id;

    final isAdmin = (authProv.activeRole == 'admin');
    final isAssignedWorker =
        _selectedWorker != null && _selectedWorker == currentUserId;

    final canEditWorkDetails =
        (isAssignedWorker &&
            (currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED')) ||
        (isAdmin && !isTicketClosed);

    final bool readOnlyFields = isTicketClosed || (isEditing && !isAdmin);
    final showCameraBox =
        (!isEditing || canEditWorkDetails) && currentStatus != 'VERIFIED';

    String activeKitchenName = "Loading Kitchen...";
    String activeKitchenId = "";

    if (!isEditing && authProv.assignedKitchens.isNotEmpty) {
      int activeIndex = authProv.assignedKitchens.indexWhere(
        (k) => k['id'].toString() == ticketProv.kitchenFilter,
      );
      final activeK = activeIndex != -1
          ? authProv.assignedKitchens[activeIndex]
          : authProv.assignedKitchens.first;
      activeKitchenName = activeK['name']?.toString() ?? 'Unknown Kitchen';
      activeKitchenId = activeK['id']?.toString() ?? "";
    } else if (isEditing) {
      activeKitchenName =
          _localTicket?['m_kitchen']?['name']?.toString() ?? 'Unknown Kitchen';
      activeKitchenId = _localTicket?['kitchen_id']?.toString() ?? "";
    }

    final List<Map<String, dynamic>> availableEquipments =
        _selectedAreaId == null
        ? []
        : [
            ..._allEquipment
                .where((e) => e['area_id']?.toString() == _selectedAreaId)
                .toList(),
            {'id': 'others', 'display_name': 'Others (Manual Entry)'},
          ];

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? (_localTicket!['ticket_no'] ?? 'Ticket Details')
                    : "Raise New Issue",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              if (activeKitchenName.isNotEmpty &&
                  activeKitchenName != "Loading Kitchen..." &&
                  activeKitchenName != "Unknown Kitchen")
                Text(
                  activeKitchenName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Form(
            key: _formKey,
            child: Builder(
              builder: (context) {
                final Widget statusAndTimelineSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing) ...[
                      TicketStatusBanner(
                        currentStatus: currentStatus,
                        raisedTime: _localTicket?['ticket_raised_time'] != null
                            ? _formatDisplayDate(
                                DateTime.tryParse(
                                  _localTicket!['ticket_raised_time'],
                                )?.toLocal(),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TicketTimeline(ticket: _localTicket!),
                    ] else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          "Status & Timeline will be tracked here once created.",
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                );

                final Widget visualVerificationSection = Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Color(0xFF475569),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "Visual Verification",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_breakdownTime != null ||
                              _localTicket?['ticket_raised_time'] != null)
                            InkWell(
                              onTap: readOnlyFields ? null : _pickBreakdownTime,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatDateTimeLocal(
                                        _breakdownTime ??
                                            DateTime.tryParse(
                                              _localTicket!['ticket_raised_time'],
                                            )?.toLocal(),
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                    if (!readOnlyFields) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.edit_calendar,
                                        size: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (_isLoadingMedia)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: golden),
                          ),
                        )
                      else ...[
                        if (_beforeUrls.isEmpty &&
                            _afterUrls.isEmpty &&
                            !showCameraBox)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "No media attached yet.",
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        // BEFORE PHOTOS & VIDEOS
                        if (_beforeUrls.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDC2626),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "BEFORE (ISSUE RAISED)",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFDC2626),
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _beforeMedia.isNotEmpty
                                    ? _formatMediaCount(_beforeMedia)
                                    : "${_beforeUrls.length} ${_beforeUrls.length == 1 ? 'Photo' : 'Photos'}",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _beforeUrls.length,
                              itemBuilder: (context, index) {
                                final mediaItem = _beforeMedia.length > index
                                    ? _beforeMedia[index]
                                    : {
                                        'url': _beforeUrls[index],
                                        'type':
                                            _isVideoExtension(
                                              _beforeUrls[index],
                                            )
                                            ? 'video'
                                            : 'photo',
                                      };
                                final isVideo = mediaItem['type'] == 'video';

                                return GestureDetector(
                                  onTap: () =>
                                      _openMediaViewer(context, mediaItem),
                                  child: Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: isVideo
                                          ? const Color(0xFF0F172A)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: isVideo
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                Color(
                                                                  0xFF1E293B,
                                                                ),
                                                                Color(
                                                                  0xFF0F172A,
                                                                ),
                                                              ],
                                                            ),
                                                      ),
                                                ),
                                                const Icon(
                                                  Icons
                                                      .play_circle_fill_rounded,
                                                  color: Color(0xFFD97706),
                                                  size: 44,
                                                ),
                                                Positioned(
                                                  bottom: 8,
                                                  left: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.65),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.white24,
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .videocam_rounded,
                                                          size: 12,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          "VIDEO",
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Image.network(
                                              mediaItem['url'] ?? '',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color: Colors.grey.shade100,
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // DIVIDER WITH CIRCULAR GREEN DOWN ARROW
                        if (_beforeUrls.isNotEmpty && _afterUrls.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Flex(
                                        direction: Axis.horizontal,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: List.generate(
                                          (constraints.constrainWidth() / 8)
                                              .floor(),
                                          (_) => const SizedBox(
                                            width: 4,
                                            height: 1,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color(0xFFCBD5E1),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Flex(
                                        direction: Axis.horizontal,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: List.generate(
                                          (constraints.constrainWidth() / 8)
                                              .floor(),
                                          (_) => const SizedBox(
                                            width: 4,
                                            height: 1,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color(0xFFCBD5E1),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // AFTER PHOTOS & VIDEOS
                        if (_afterUrls.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "AFTER (WORK COMPLETED)",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF10B981),
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _afterMedia.isNotEmpty
                                    ? _formatMediaCount(_afterMedia)
                                    : "${_afterUrls.length} ${_afterUrls.length == 1 ? 'Photo' : 'Photos'}",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _afterUrls.length,
                              itemBuilder: (context, index) {
                                final mediaItem = _afterMedia.length > index
                                    ? _afterMedia[index]
                                    : {
                                        'url': _afterUrls[index],
                                        'type':
                                            _isVideoExtension(_afterUrls[index])
                                            ? 'video'
                                            : 'photo',
                                      };
                                final isVideo = mediaItem['type'] == 'video';

                                return GestureDetector(
                                  onTap: () =>
                                      _openMediaViewer(context, mediaItem),
                                  child: Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: isVideo
                                          ? const Color(0xFF0F172A)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: isVideo
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                Color(
                                                                  0xFF1E293B,
                                                                ),
                                                                Color(
                                                                  0xFF0F172A,
                                                                ),
                                                              ],
                                                            ),
                                                      ),
                                                ),
                                                const Icon(
                                                  Icons
                                                      .play_circle_fill_rounded,
                                                  color: Color(0xFFD97706),
                                                  size: 44,
                                                ),
                                                Positioned(
                                                  bottom: 8,
                                                  left: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.65),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.white24,
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .videocam_rounded,
                                                          size: 12,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          "VIDEO",
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Image.network(
                                              mediaItem['url'] ?? '',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color: Colors.grey.shade100,
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // UPLOAD BOX IF APPLICABLE
                        if (showCameraBox) ...[
                          if (_beforeUrls.isNotEmpty || _afterUrls.isNotEmpty)
                            const SizedBox(height: 16),
                          Text(
                            (!isEditing || !canEditWorkDetails)
                                ? "Attach Issue Media (Photos / Videos) *"
                                : "Attach Completion Media (Photos / Videos) *",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildImageUploader(canEditWorkDetails),
                        ],
                      ],
                    ],
                  ),
                );

                String? currentEqId = _selectedEquipments.isNotEmpty
                    ? _selectedEquipments.first['id'].toString()
                    : null;
                if (currentEqId != null &&
                    !availableEquipments.any(
                      (e) => e['id'].toString() == currentEqId,
                    )) {
                  currentEqId = null;
                }

                final String? eqCode = _selectedEquipments.isNotEmpty
                    ? (_selectedEquipments.first['equipment_code'] ??
                              _selectedEquipments.first['code'] ??
                              _selectedEquipments.first['equipment_number'])
                          ?.toString()
                    : null;

                final Widget ticketInformationSection = Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: Color(0xFF475569),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Ticket Information",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // AREA BOX
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF94A3B8),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFDBEAFE),
                                ),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SELECT AREA *",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (readOnlyFields)
                                    Text(
                                      _getAreaDisplayName(_selectedAreaId),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  else
                                    DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedAreaId,
                                        isExpanded: true,
                                        isDense: true,
                                        menuMaxHeight: 400,
                                        borderRadius: BorderRadius.circular(12),
                                        dropdownColor: Colors.white,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        icon: const Icon(
                                          Icons.unfold_more_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 18,
                                        ),
                                        hint: Text(
                                          "Select Area",
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        items: _allAreas.map((a) {
                                          return DropdownMenuItem<String>(
                                            value: a['id'].toString(),
                                            child: Text(
                                              (a['display_name'] ??
                                                      a['area_name'] ??
                                                      '')
                                                  .toString(),
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E293B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedAreaId = val;
                                            _selectedEquipments.clear();
                                          });
                                        },
                                        validator: (v) =>
                                            v == null ? 'Required' : null,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // EQUIPMENT BOX
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF94A3B8),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: const Icon(
                                Icons.precision_manufacturing_outlined,
                                color: Color(0xFFD97706),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "EQUIPMENT NAME *",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (readOnlyFields)
                                    Text(
                                      _selectedEquipments.isNotEmpty
                                          ? (_selectedEquipments
                                                    .first['display_name'] ??
                                                _selectedEquipments
                                                    .first['name'] ??
                                                'Unknown Equipment')
                                          : 'No equipment selected',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  else
                                    DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        value: currentEqId,
                                        isExpanded: true,
                                        isDense: true,
                                        menuMaxHeight: 400,
                                        borderRadius: BorderRadius.circular(12),
                                        dropdownColor: Colors.white,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        icon:
                                            (eqCode != null &&
                                                eqCode.isNotEmpty)
                                            ? const SizedBox.shrink()
                                            : const Icon(
                                                Icons.unfold_more_rounded,
                                                color: Color(0xFF94A3B8),
                                                size: 18,
                                              ),
                                        hint: Text(
                                          _selectedAreaId == null
                                              ? "Select Area first"
                                              : "Select Equipment",
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        items: availableEquipments.map((e) {
                                          return DropdownMenuItem<String>(
                                            value: e['id'].toString(),
                                            child: Text(
                                              (e['display_name'] ?? '')
                                                  .toString(),
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E293B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged:
                                            (_selectedAreaId == null ||
                                                availableEquipments.isEmpty)
                                            ? null
                                            : (val) {
                                                if (val != null) {
                                                  final eq = availableEquipments
                                                      .firstWhere(
                                                        (e) =>
                                                            e['id']
                                                                .toString() ==
                                                            val,
                                                      );
                                                  setState(() {
                                                    _selectedEquipments = [eq];
                                                    _isCustomEquipment =
                                                        val == 'others';
                                                    if (!_isCustomEquipment) {
                                                      _customEquipmentController
                                                          .clear();
                                                    }
                                                  });
                                                }
                                              },
                                        validator: (v) =>
                                            (_selectedEquipments.isEmpty &&
                                                !_isCustomEquipment)
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (eqCode != null && eqCode.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  eqCode,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (_isCustomEquipment) ...[
                        const SizedBox(height: 10),
                        TicketFormFields.buildTextField(
                          ctrl: _customEquipmentController,
                          label: "Custom Equipment Name *",
                          icon: Icons.precision_manufacturing,
                          isReadOnly: readOnlyFields,
                          isRequired: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                      const SizedBox(height: 10),

                      // DESCRIPTION BOX
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF94A3B8),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.text_fields_rounded,
                                    color: Color(0xFF64748B),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "DESCRIPTION *",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "${_getWordCount(_titleController.text)} / 200 words",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (readOnlyFields)
                              Text(
                                _titleController.text.trim().isNotEmpty
                                    ? _titleController.text
                                    : "No description provided.",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                  height: 1.4,
                                ),
                              )
                            else
                              TextFormField(
                                controller: _titleController,
                                maxLines: 3,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                  height: 1.4,
                                ),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: "Describe the issue in detail...",
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // PRIORITY & CATEGORY ROW
                      Row(
                        children: [
                          // Priority Box
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFD97706),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "PRIORITY *",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFD97706),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (readOnlyFields)
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD97706),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _priority,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _priority,
                                        isExpanded: true,
                                        isDense: true,
                                        menuMaxHeight: 400,
                                        borderRadius: BorderRadius.circular(12),
                                        dropdownColor: Colors.white,
                                        items:
                                            [
                                              'CRITICAL',
                                              'HIGH',
                                              'MEDIUM',
                                              'LOW',
                                            ].map((p) {
                                              return DropdownMenuItem<String>(
                                                value: p,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Color(
                                                              0xFFD97706,
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      p,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: const Color(
                                                          0xFFD97706,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                        onChanged: (val) {
                                          if (val != null)
                                            setState(() => _priority = val);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Category Box
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF94A3B8),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "CATEGORY *",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (readOnlyFields)
                                    Text(
                                      _category,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  else
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _category,
                                        isExpanded: true,
                                        isDense: true,
                                        menuMaxHeight: 400,
                                        borderRadius: BorderRadius.circular(12),
                                        dropdownColor: Colors.white,
                                        items:
                                            [
                                              'In Running Condition',
                                              'In Breakdown Condition',
                                              'Running at Risk',
                                            ].map((c) {
                                              return DropdownMenuItem<String>(
                                                value: c,
                                                child: Text(
                                                  c,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF1E293B,
                                                    ),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                        onChanged: (val) {
                                          if (val != null)
                                            setState(() => _category = val);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final Widget workDetailsAndAssignmentSection = Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.engineering_outlined,
                              color: Color(0xFF475569),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Work Details & Assignment",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // CAUSE OF ISSUE BOX
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "CAUSE OF ISSUE *",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFDC2626),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (!canEditWorkDetails)
                              Text(
                                _causeController.text.trim().isNotEmpty
                                    ? _causeController.text
                                    : "No cause specified.",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              )
                            else
                              TextFormField(
                                controller: _causeController,
                                maxLines: 2,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter root cause...",
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ACTION TAKEN BOX
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.handyman_outlined,
                                  color: Color(0xFF10B981),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "ACTION TAKEN *",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF059669),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (!canEditWorkDetails)
                              Text(
                                _actionTakenController.text.trim().isNotEmpty
                                    ? _actionTakenController.text
                                    : "No action recorded yet.",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              )
                            else
                              TextFormField(
                                controller: _actionTakenController,
                                maxLines: 2,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter corrective action taken...",
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // TOOLS & SPARES 2-COLUMN ROW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tools Checked Out
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TOOLS CHECKED OUT",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (_usedTools.isEmpty)
                                    Text(
                                      "No tools logged.",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    )
                                  else
                                    ..._usedTools.map((item) {
                                      final tool = item['tool'];
                                      final bool isReturned =
                                          item['return_time'] != null;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isReturned
                                                  ? Icons.check_circle
                                                  : Icons.handyman_outlined,
                                              size: 13,
                                              color: isReturned
                                                  ? const Color(0xFF10B981)
                                                  : navy,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                tool['tool_name'] ?? 'Tool',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF1E293B,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (canEditWorkDetails)
                                              GestureDetector(
                                                onTap: () => _removeTool(item),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
                                  if (canEditWorkDetails) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: _showAddToolDialog,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.add_circle_outline,
                                            size: 13,
                                            color: Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Add Tool",
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Spares Used
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SPARES USED",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (_usedSpares.isEmpty)
                                    Text(
                                      "No spares selected.",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    )
                                  else
                                    ..._usedSpares.map((item) {
                                      final spare = item['spare'];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.settings_outlined,
                                              size: 13,
                                              color: Color(0xFFD97706),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "${spare['spare_name']} (x${item['qty']})",
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF1E293B,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (canEditWorkDetails)
                                              GestureDetector(
                                                onTap: () => _removeSpare(item),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
                                  if (canEditWorkDetails) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: _showAddSpareDialog,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.add_circle_outline,
                                            size: 13,
                                            color: Color(0xFFD97706),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Add Spare",
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFD97706),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // SIGN-OFF BANNER
                      if (currentStatus == 'VERIFIED' ||
                          _localTicket?['verified_by_id'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E3A8A),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "MK",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Maintenance Lead",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      "Verified by Plant Supervisor",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Color(0xFF15803D),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Sign-off Complete",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // WORKER ASSIGNMENT FOR ADMIN (IF EDITABLE)
                      if (isEditing &&
                          isAdmin &&
                          (currentStatus == 'RAISED' ||
                              currentStatus == 'ASSIGNED')) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF94A3B8),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.engineering_outlined,
                                  color: Color(0xFFD97706),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final eligibleWorkers = _workers.where((w) {
                                      final assignedKitchensList =
                                          w['user_kitchens']
                                              as List<dynamic>? ??
                                          [];
                                      return assignedKitchensList.any(
                                        (uk) =>
                                            uk['kitchen_id'].toString() ==
                                            activeKitchenId,
                                      );
                                    }).toList();

                                    String? currentWorkerId = _selectedWorker;
                                    if (currentWorkerId != null &&
                                        !eligibleWorkers.any(
                                          (w) =>
                                              w['id'].toString() ==
                                              currentWorkerId,
                                        )) {
                                      currentWorkerId = null;
                                    }

                                    return DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        value: currentWorkerId,
                                        isExpanded: true,
                                        isDense: true,
                                        dropdownColor: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        menuMaxHeight: 400,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        icon: const Icon(
                                          Icons.unfold_more_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 18,
                                        ),
                                        hint: Text(
                                          "Assign Worker",
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        items: eligibleWorkers.map((w) {
                                          return DropdownMenuItem<String>(
                                            value: w['id'].toString(),
                                            child: Text(
                                              w['display_name'].toString(),
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: isTicketClosed
                                            ? null
                                            : (val) {
                                                setState(() {
                                                  _selectedWorker = val;
                                                });
                                              },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // RETURNED TOOLS CHECKBOXES
                      if (currentStatus == 'IN_PROGRESS' &&
                          isAssignedWorker &&
                          _usedTools.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              "I have returned all tools",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: Colors.orange.shade800,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              "Please return all checked-out tools to the inventory before marking complete.",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            value: _workerToolsReturned,
                            activeColor: Colors.orange.shade700,
                            checkboxShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) => setState(
                              () => _workerToolsReturned = val ?? false,
                            ),
                          ),
                        ),
                      ],

                      if (currentStatus == 'COMPLETED' &&
                          isAdmin &&
                          _usedTools.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              "All Tools Returned",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade800,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              "Acknowledge that all checked-out tools have been safely returned.",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.green.shade700,
                              ),
                            ),
                            value: _toolsReturned,
                            activeColor: Colors.green.shade700,
                            checkboxShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) =>
                                setState(() => _toolsReturned = val ?? false),
                          ),
                        ),
                      ],
                    ],
                  ),
                );

                final double screenWidth = MediaQuery.of(context).size.width;

                if (screenWidth >= 1100) {
                  // 3-Column Desktop Layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column 1: Status & Timeline
                      if (isEditing) ...[
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              statusAndTimelineSection,
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      // Column 2: Visual Verification & Ticket Information
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            visualVerificationSection,
                            const SizedBox(height: 14),
                            ticketInformationSection,
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                      // Column 3: Work Details & Assignment
                      if (isEditing &&
                          (currentStatus != 'RAISED' || isAdmin)) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              workDetailsAndAssignmentSection,
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                } else if (screenWidth >= 768) {
                  // 2-Column Tablet Layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            visualVerificationSection,
                            const SizedBox(height: 14),
                            ticketInformationSection,
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              statusAndTimelineSection,
                              if (currentStatus != 'RAISED' || isAdmin) ...[
                                const SizedBox(height: 14),
                                workDetailsAndAssignmentSection,
                              ],
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                } else {
                  // 1-Column Mobile Layout (Matches mockup sequence exactly)
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEditing) ...[
                        statusAndTimelineSection,
                        const SizedBox(height: 14),
                        visualVerificationSection,
                        const SizedBox(height: 14),
                      ] else ...[
                        visualVerificationSection,
                        const SizedBox(height: 14),
                      ],
                      ticketInformationSection,
                      if (isEditing &&
                          (currentStatus != 'RAISED' || isAdmin)) ...[
                        const SizedBox(height: 14),
                        workDetailsAndAssignmentSection,
                      ],
                      const SizedBox(height: 100),
                    ],
                  );
                }
              },
            ),
          ),
        ),
        bottomNavigationBar: isEditing
            ? _buildContextualActionButton(
                isAdmin,
                isAssignedWorker,
                canEditWorkDetails,
              )
            : _buildSubmitNewButton(),
      ),
    );
  }
}
