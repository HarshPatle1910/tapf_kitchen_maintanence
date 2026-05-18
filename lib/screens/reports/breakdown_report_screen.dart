import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class BreakdownReportScreen extends StatefulWidget {
  const BreakdownReportScreen({super.key});

  @override
  State<BreakdownReportScreen> createState() => _BreakdownReportScreenState();
}

class _BreakdownReportScreenState extends State<BreakdownReportScreen> {
  // Unified Minimalistic Color Palette
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _completedTickets = [];
  Map<String, dynamic>? _selectedTicketData;
  bool _isLoadingTickets = true;

  String _queryMode = 'ticket'; // 'ticket' or 'monthly'
  String _selectedFormat = 'docx';

  // Monthly State Variables
  int? _selectedMonth;
  int? _selectedYear;

  // Search Controllers
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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

    // Fetch tickets after the widget tree is built so we can access providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCompletedTickets();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- GET ACTIVE KITCHEN HELPER ---
  String? _getActiveKitchenId() {
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    String targetKitchenId = ticketProv.kitchenFilter;

    if (targetKitchenId == 'ALL' || targetKitchenId.isEmpty) {
      if (authProv.assignedKitchens.isNotEmpty) {
        return authProv.assignedKitchens.first['id'].toString();
      }
      return null;
    }
    return targetKitchenId;
  }

  Future<void> _fetchCompletedTickets() async {
    setState(() => _isLoadingTickets = true);

    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId == null) {
      if (mounted) setState(() => _isLoadingTickets = false);
      return;
    }

    try {
      final response = await _supabase
          .from('tickets')
          .select('*, m_kitchen(name), raised_by:m_user!tickets_raised_by_id_fkey(name)')
          .inFilter('status', ['COMPLETED', 'VERIFIED'])
          .eq('category', 'In Breakdown Condition')
          .eq('kitchen_id', targetKitchenId) // <--- Only fetch tickets for this kitchen
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
    final targetKitchenId = _getActiveKitchenId();

    if (targetKitchenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active kitchen available!'), backgroundColor: Colors.red),
      );
      return;
    }

    Uri url;
    String finalFileName;

    if (_queryMode == 'ticket') {
      if (_selectedTicketData == null) return;
      final ticketNo = _selectedTicketData!['ticket_no'];
      // --- ADDED KITCHEN_ID TO SINGLE TICKET API ---
      url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/breakdown/$ticketNo?kitchen_id=$targetKitchenId&format=$_selectedFormat');
      finalFileName = 'Breakdown_$ticketNo.$_selectedFormat';
    } else {
      if (_selectedMonth == null || _selectedYear == null) return;
      // --- ADDED KITCHEN_ID TO MONTHLY API ---
      url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/breakdowns/monthly?kitchen_id=$targetKitchenId&month=$_selectedMonth&year=$_selectedYear&format=$_selectedFormat');
      final monthAbbr = _months[_selectedMonth! - 1].substring(0, 3);
      finalFileName = 'Breakdown_Reports_${monthAbbr}_$_selectedYear.$_selectedFormat';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: primary)),
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
      } else if (response.statusCode == 404) {
        throw Exception("No breakdown reports found for this selection.");
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process report: $e'), backgroundColor: Colors.red));
    }
  }

  // Minimalist Input Decoration
  InputDecoration _minimalDecor() {
    return InputDecoration(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary)),
    );
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
          backgroundColor: background, elevation: 0, foregroundColor: primary,
          title: Text("Breakdown Report", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        ),
        body: _isLoadingTickets
            ? const Center(child: CircularProgressIndicator(color: primary))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Generate Report", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text("Configure the timeframe and format for your MT-07 export.", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14)),
              const SizedBox(height: 32),

              // 1. REPORT TYPE SECTION
              Text("REPORT TYPE", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey.shade400, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: Text("Single Ticket", style: GoogleFonts.inter(fontWeight: _queryMode == 'ticket' ? FontWeight.w600 : FontWeight.normal)),
                    selected: _queryMode == 'ticket',
                    selectedColor: primary.withOpacity(0.1),
                    backgroundColor: surface,
                    side: BorderSide.none,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onSelected: (v) {
                      setState(() => _queryMode = 'ticket');
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: Text("Monthly Bulk", style: GoogleFonts.inter(fontWeight: _queryMode == 'monthly' ? FontWeight.w600 : FontWeight.normal)),
                    selected: _queryMode == 'monthly',
                    selectedColor: primary.withOpacity(0.1),
                    backgroundColor: surface,
                    side: BorderSide.none,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onSelected: (v) {
                      setState(() => _queryMode = 'monthly');
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. INPUT CONFIGURATION SECTION
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_queryMode == 'ticket' ? "Select Ticket" : "Select Timeframe", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: primary)),
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
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                          decoration: _minimalDecor().copyWith(
                            hintText: "Search Ticket No...",
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                            suffixIcon: ctrl.text.isNotEmpty
                                ? IconButton(
                                icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                                onPressed: () {
                                  ctrl.clear();
                                  setState(() => _selectedTicketData = null);
                                  _focusNode.requestFocus(); // Keeps keyboard open after clearing
                                }
                            )
                                : null,
                          ),
                          onChanged: (val) { if (val.isEmpty) setState(() => _selectedTicketData = null); },
                        ),
                        optionsViewBuilder: (ctx, onSel, opts) => Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 2.0, borderRadius: BorderRadius.circular(10),
                            child: Container(
                              constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 80),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
                              child: ListView.separated(
                                padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                                itemBuilder: (ctx, idx) => ListTile(
                                  dense: true,
                                  title: Text(opts.elementAt(idx)['ticket_no'], style: GoogleFonts.inter(fontSize: 14, color: primary, fontWeight: FontWeight.w600)),
                                  subtitle: Text(opts.elementAt(idx)['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                                  onTap: () => onSel(opts.elementAt(idx)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_completedTickets.isEmpty && _queryMode == 'ticket')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("No completed breakdown tickets found for this kitchen.", style: GoogleFonts.inter(color: Colors.red.shade400, fontSize: 12)),
                        )
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              decoration: _minimalDecor(),
                              value: _selectedMonth,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16), dropdownColor: Colors.white,
                              hint: Text("Month", style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14)),
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              items: List.generate(_months.length, (index) {
                                return DropdownMenuItem(value: index + 1, child: Text(_months[index], style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: primary, fontSize: 14)));
                              }),
                              onChanged: (val) => setState(() => _selectedMonth = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              decoration: _minimalDecor(),
                              value: _selectedYear,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16), dropdownColor: Colors.white,
                              hint: Text("Year", style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14)),
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              items: _years.map((year) {
                                return DropdownMenuItem(value: year, child: Text(year.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: primary, fontSize: 14)));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedYear = val),
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
              Text("FORMAT", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey.shade400, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              Row(
                children: [
                  ChoiceChip(
                    label: Text("Word (.docx)", style: GoogleFonts.inter(fontWeight: _selectedFormat == 'docx' ? FontWeight.w600 : FontWeight.normal)),
                    selected: _selectedFormat == 'docx',
                    selectedColor: primary.withOpacity(0.1),
                    backgroundColor: surface,
                    side: BorderSide.none,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onSelected: (v) => setState(() => _selectedFormat = 'docx'),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: Text("PDF (.pdf)", style: GoogleFonts.inter(fontWeight: _selectedFormat == 'pdf' ? FontWeight.w600 : FontWeight.normal)),
                    selected: _selectedFormat == 'pdf',
                    selectedColor: primary.withOpacity(0.1),
                    backgroundColor: surface,
                    side: BorderSide.none,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onSelected: (v) => setState(() => _selectedFormat = 'pdf'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // BOTTOM ACTION BUTTONS
        bottomNavigationBar: !isReadyToExport ? null : SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surface,
                        foregroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => _processReport("preview"),
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      label: Text("PREVIEW", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => _processReport("share"),
                      icon: const Icon(Icons.share_outlined, size: 20),
                      label: Text("SHARE", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
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