import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

class BreakdownReportScreen extends StatefulWidget {
  const BreakdownReportScreen({super.key});

  @override
  State<BreakdownReportScreen> createState() => _BreakdownReportScreenState();
}

class _BreakdownReportScreenState extends State<BreakdownReportScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  String get _pythonApiBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (Platform.isAndroid) return 'http://192.168.0.45:8000/api';
    if (Platform.isIOS) return 'http://127.0.0.1:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _completedTickets = [];
  Map<String, dynamic>? _selectedTicketData;
  bool _isLoadingTickets = true;

  String _queryMode = 'ticket'; // 'ticket' or 'monthly'
  String _selectedFormat = 'docx';

  // Monthly State Variables
  int? _selectedMonth;
  int? _selectedYear;

  var _searchCtrl;
  var _focusNode;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<int> _years = List.generate(
      (DateTime.now().year - 2020) + 2,
          (index) => 2020 + index
  );

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
    _fetchCompletedTickets();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCompletedTickets() async {
    try {
      final response = await _supabase
          .from('tickets')
          .select('*, m_kitchen(name), raised_by:m_user!tickets_raised_by_id_fkey(name)')
          .inFilter('status', ['COMPLETED', 'VERIFIED'])
          .eq('category', 'In Breakdown Condition')
          .order('updated_at', ascending: false);

      if (mounted) {
        setState(() {
          _completedTickets = List<Map<String, dynamic>>.from(response);
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching tickets: $e");
      if (mounted) setState(() => _isLoadingTickets = false);
    }
  }

  Future<void> _processReport(String action) async {
    Uri url;
    String finalFileName;

    if (_queryMode == 'ticket') {
      if (_selectedTicketData == null) return;
      final ticketNo = _selectedTicketData!['ticket_no'];
      url = Uri.parse('$_pythonApiBaseUrl/reports/breakdown/$ticketNo?format=$_selectedFormat');
      finalFileName = 'Breakdown_$ticketNo.$_selectedFormat';
    } else {
      if (_selectedMonth == null || _selectedYear == null) return;
      url = Uri.parse('$_pythonApiBaseUrl/reports/breakdowns/monthly?month=$_selectedMonth&year=$_selectedYear&format=$_selectedFormat');

      final monthAbbr = _months[_selectedMonth! - 1].substring(0, 3);
      // NEW: Now requests a single merged docx/pdf file
      finalFileName = 'Breakdown_Reports_${monthAbbr}_$_selectedYear.$_selectedFormat';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: golden)),
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        File? file;

        try {
          Directory? saveDir;
          if (Platform.isAndroid) {
            saveDir = Directory('/storage/emulated/0/Download/Breakdown Intimation Forms');
          } else {
            final docDir = await getApplicationDocumentsDirectory();
            saveDir = Directory('${docDir.path}/Breakdown Intimation Forms');
          }

          if (!await saveDir.exists()) {
            await saveDir.create(recursive: true);
          }

          file = File('${saveDir.path}/$finalFileName');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted && action == 'preview') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to Downloads/Breakdown Intimation Forms/'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          final tempDir = await getTemporaryDirectory();
          file = File('${tempDir.path}/$finalFileName');
          await file.writeAsBytes(response.bodyBytes);
        }

        if (mounted) Navigator.pop(context);

        if (action == 'share') {
          await Share.shareXFiles(
              [XFile(file.path)],
              text: 'Attached is the Breakdown Report(s).'
          );
        } else if (action == 'preview') {
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open file. Do you have a file viewer installed?'), backgroundColor: Colors.orange)
            );
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

  @override
  Widget build(BuildContext context) {
    final bool isReadyToExport = (_queryMode == 'ticket' && _selectedTicketData != null) ||
        (_queryMode == 'monthly' && _selectedMonth != null && _selectedYear != null);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0, foregroundColor: navy,
          title: Text("Breakdown Report", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
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
                        onTap: () => setState(() => _queryMode = 'monthly'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _queryMode == 'monthly' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _queryMode == 'monthly' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
                          ),
                          child: Center(child: Text("Monthly", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _queryMode == 'monthly' ? navy : Colors.grey.shade600))),
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
                    Text(_queryMode == 'ticket' ? "Select Ticket Data" : "Select Timeframe", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                    const SizedBox(height: 16),

                    if (_queryMode == 'ticket') ...[
                      RawAutocomplete<Map<String, dynamic>>(
                        textEditingController: _searchCtrl, focusNode: _focusNode,
                        optionsBuilder: (val) {
                          if (val.text.isEmpty) return _completedTickets;
                          return _completedTickets.where((opt) => opt['ticket_no'].toString().toLowerCase().contains(val.text.toLowerCase()));
                        },
                        displayStringForOption: (opt) => opt['ticket_no'].toString(),
                        onSelected: (sel) { setState(() => _selectedTicketData = sel); _focusNode.unfocus(); },
                        fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
                          controller: ctrl, focusNode: fNode,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: navy),
                          decoration: InputDecoration(
                            hintText: "Search Ticket No...", hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true, fillColor: Colors.grey.shade50,
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
                      // MONTH/YEAR DROPDOWNS
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedMonth, isExpanded: true,
                                  hint: Text("Month", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: navy),
                                  items: List.generate(_months.length, (index) {
                                    return DropdownMenuItem(value: index + 1, child: Text(_months[index], style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy, fontSize: 14)));
                                  }),
                                  onChanged: (val) => setState(() => _selectedMonth = val),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedYear, isExpanded: true,
                                  hint: Text("Year", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: navy),
                                  items: _years.map((year) {
                                    return DropdownMenuItem(value: year, child: Text(year.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy, fontSize: 14)));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedYear = val),
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

              // EXPORT SETTINGS SECTION
              Text("Export Settings", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade500, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              Container(
                width: double.infinity, padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFormat = 'docx'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedFormat == 'docx' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedFormat == 'docx' ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description, size: 18, color: _selectedFormat == 'docx' ? Colors.blue.shade700 : Colors.grey), const SizedBox(width: 8),
                              Text("Word (.docx)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _selectedFormat == 'docx' ? navy : Colors.grey)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
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
                      style: ElevatedButton.styleFrom(backgroundColor: golden, foregroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
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