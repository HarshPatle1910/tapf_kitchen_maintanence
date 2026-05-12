import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

class ComplaintReportScreen extends StatefulWidget {
  const ComplaintReportScreen({super.key});

  @override
  State<ComplaintReportScreen> createState() => _ComplaintReportScreenState();
}

class _ComplaintReportScreenState extends State<ComplaintReportScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  String get _pythonApiBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (Platform.isAndroid) return 'http://192.168.0.45:8000/api'; // Make sure IP matches your PC
    if (Platform.isIOS) return 'http://127.0.0.1:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allTickets = [];
  bool _isLoadingTickets = true;

  // Mode Selection
  String _queryMode = 'ticket'; // 'ticket' or 'dateRange'
  String _selectedFormat = 'xlsx'; // Excel by default for Register

  // Single Ticket State
  Map<String, dynamic>? _selectedTicketData;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Date Range State
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchTickets() async {
    try {
      final response = await _supabase
          .from('tickets')
          .select('*, m_kitchen(name), raised_by:m_user!tickets_raised_by_id_fkey(name)')
          .order('updated_at', ascending: false);

      if (mounted) {
        setState(() {
          _allTickets = List<Map<String, dynamic>>.from(response);
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching tickets: $e");
      if (mounted) setState(() => _isLoadingTickets = false);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: navy)),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _processReport(String action) async {
    Uri url;
    String finalFileName;

    if (_queryMode == 'ticket') {
      if (_selectedTicketData == null) return;
      final ticketNo = _selectedTicketData!['ticket_no'];
      url = Uri.parse('$_pythonApiBaseUrl/reports/complaint/$ticketNo?format=$_selectedFormat');
      finalFileName = 'Complaint_Register_$ticketNo.$_selectedFormat';
    } else {
      if (_startDate == null || _endDate == null) return;
      final startIso = _startDate!.toIso8601String().split('T')[0];
      final endIso = _endDate!.toIso8601String().split('T')[0];

      url = Uri.parse('$_pythonApiBaseUrl/reports/complaints/range?start=$startIso&end=$endIso&format=$_selectedFormat');
      finalFileName = 'Complaint_Register_${startIso}_to_$endIso.$_selectedFormat';
    }

    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: golden)),
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        File? file;

        // --------------------------------------------------------------------
        // NEW DIRECTORY LOGIC: Save to Public Downloads Folder
        // --------------------------------------------------------------------
        try {
          Directory? saveDir;
          if (Platform.isAndroid) {
            // Standard path to Android Downloads folder
            saveDir = Directory('/storage/emulated/0/Download/Complaint Register');
          } else {
            // iOS visible documents folder
            final docDir = await getApplicationDocumentsDirectory();
            saveDir = Directory('${docDir.path}/Complaint Register');
          }

          // Create the folder if it doesn't exist
          if (!await saveDir.exists()) {
            await saveDir.create(recursive: true);
          }

          file = File('${saveDir.path}/$finalFileName');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved to Downloads/Complaint Register/'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          // FALLBACK: If storage permission fails, fall back to temporary directory
          final tempDir = await getTemporaryDirectory();
          file = File('${tempDir.path}/$finalFileName');
          await file.writeAsBytes(response.bodyBytes);
          print("Saved to temp directory due to error: $e");
        }
        // --------------------------------------------------------------------

        if (mounted) Navigator.pop(context); // Close loading dialog

        if (action == 'share') {
          await Share.shareXFiles([XFile(file.path)], text: 'Attached is the Complaint Register Report.');
        } else if (action == 'preview') {
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file. Viewer app missing?'), backgroundColor: Colors.orange));
          }
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process report: $e'), backgroundColor: Colors.red));
    }
  }

  String _formatDateLocal(DateTime? d) {
    if (d == null) return 'Select Date';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isReadyToExport = (_queryMode == 'ticket' && _selectedTicketData != null) ||
        (_queryMode == 'dateRange' && _startDate != null && _endDate != null);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0, foregroundColor: navy,
          title: Text("Complaint Register", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ),
        body: _isLoadingTickets
            ? const Center(child: CircularProgressIndicator(color: golden))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 1. MODE TOGGLE
              Container(
                width: double.infinity, padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _queryMode = 'ticket'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _queryMode == 'ticket' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _queryMode == 'ticket' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
                          ),
                          child: Center(child: Text("Single Ticket", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _queryMode == 'ticket' ? navy : Colors.grey.shade600))),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _queryMode = 'dateRange'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _queryMode == 'dateRange' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _queryMode == 'dateRange' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
                          ),
                          child: Center(child: Text("Date Range", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _queryMode == 'dateRange' ? navy : Colors.grey.shade600))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. INPUT SECTION
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Query Parameters", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                    const SizedBox(height: 16),

                    if (_queryMode == 'ticket') ...[
                      RawAutocomplete<Map<String, dynamic>>(
                        textEditingController: _searchCtrl, focusNode: _focusNode,
                        optionsBuilder: (val) {
                          if (val.text.isEmpty) return _allTickets;
                          return _allTickets.where((opt) => opt['ticket_no'].toString().toLowerCase().contains(val.text.toLowerCase()));
                        },
                        displayStringForOption: (opt) => opt['ticket_no'].toString(),
                        onSelected: (sel) { setState(() => _selectedTicketData = sel); _focusNode.unfocus(); },
                        fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
                          controller: ctrl, focusNode: fNode, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: navy),
                          decoration: InputDecoration(
                            hintText: "Search Ticket No...", hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey), filled: true, fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                            suffixIcon: ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { ctrl.clear(); setState(() => _selectedTicketData = null); }) : null,
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
                                  title: Text(opts.elementAt(idx)['ticket_no'], style: GoogleFonts.inter(fontSize: 14, color: navy, fontWeight: FontWeight.bold)),
                                  subtitle: Text(opts.elementAt(idx)['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12)),
                                  onTap: () => onSel(opts.elementAt(idx)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // DATE RANGE PICKERS
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Start Date", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: _startDate == null ? Colors.grey : navy),
                                        const SizedBox(width: 8),
                                        Text(_formatDateLocal(_startDate), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _startDate == null ? Colors.grey : navy, fontSize: 13)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _startDate == null ? null : () => _pickDate(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(color: _startDate == null ? Colors.grey.shade100 : Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("End Date", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: _endDate == null ? Colors.grey : navy),
                                        const SizedBox(width: 8),
                                        Text(_formatDateLocal(_endDate), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _endDate == null ? Colors.grey : navy, fontSize: 13)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. EXPORT SETTINGS SECTION
              Text("Export Settings", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade500, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              Container(
                width: double.infinity, padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFormat = 'xlsx'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedFormat == 'xlsx' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedFormat == 'xlsx' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.table_chart, size: 18, color: _selectedFormat == 'xlsx' ? Colors.green.shade700 : Colors.grey), const SizedBox(width: 8),
                              Text("Excel (.xlsx)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _selectedFormat == 'xlsx' ? navy : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFormat = 'pdf'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedFormat == 'pdf' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedFormat == 'pdf' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 18, color: _selectedFormat == 'pdf' ? Colors.red.shade700 : Colors.grey), const SizedBox(width: 8),
                              Text("PDF (.pdf)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _selectedFormat == 'pdf' ? navy : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // BOTTOM ACTION BUTTONS
        bottomNavigationBar: !isReadyToExport ? null : SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100, foregroundColor: navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0
                      ),
                      onPressed: () => _processReport("preview"),
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text("PREVIEW", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: golden, foregroundColor: navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0
                      ),
                      onPressed: () => _processReport("share"),
                      icon: const Icon(Icons.share),
                      label: Text("SHARE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}