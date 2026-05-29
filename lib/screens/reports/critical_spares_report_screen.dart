import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class CriticalSparesReportScreen extends StatefulWidget {
  const CriticalSparesReportScreen({super.key});

  @override
  State<CriticalSparesReportScreen> createState() => _CriticalSparesReportScreenState();
}

class _CriticalSparesReportScreenState extends State<CriticalSparesReportScreen> {
  static const Color primary = Color(0xFF26538D);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  final _supabase = Supabase.instance.client;

  // Data States
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;

  // Search, Filter, Sort States
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'All';
  String _sortOption = 'Name (A-Z)';

  final List<String> _spareTypes = ['All', 'MECHANICAL', 'ELECTRICAL', 'CHEMICAL', 'OTHER'];
  final List<String> _sortOptions = ['Name (A-Z)', 'Name (Z-A)', 'Stock (Low-High)', 'Stock (High-Low)'];

  // Timeline States
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    // Ensure the year defaults to at least 2026
    if (_selectedYear < 2026) {
      _selectedYear = 2026;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final targetKitchenId = _getActiveKitchenId();

    if (targetKitchenId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final now = DateTime.now();
      final isCurrentMonth = (_selectedMonth == now.month && _selectedYear == now.year);

      List<Map<String, dynamic>> res = [];

      // SMART ROUTING: Fetch live data for current month, history for past months
      if (isCurrentMonth) {
        final response = await _supabase
            .from('v_critical_spare_parts_report')
            .select()
            .eq('kitchen_id', targetKitchenId);
        res = List<Map<String, dynamic>>.from(response);
      } else {
        final response = await _supabase
            .from('v_critical_spare_parts_monthly_report')
            .select()
            .eq('kitchen_id', targetKitchenId)
            .eq('history_month', _selectedMonth)
            .eq('history_year', _selectedYear);
        res = List<Map<String, dynamic>>.from(response);
      }

      if (mounted) {
        setState(() {
          _allRecords = res;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = List.from(_allRecords);

    // 1. Apply Search Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((item) {
        final name = (item['spare_name'] ?? '').toString().toLowerCase();
        final code = (item['spare_code'] ?? '').toString().toLowerCase();
        return name.contains(query) || code.contains(query);
      }).toList();
    }

    // 2. Apply Type Filter
    if (_selectedType != 'All') {
      temp = temp.where((item) => (item['spare_type'] ?? '').toString().toUpperCase() == _selectedType).toList();
    }

    // 3. Apply Sorting
    temp.sort((a, b) {
      if (_sortOption == 'Name (A-Z)') {
        return (a['spare_name'] ?? '').toString().compareTo((b['spare_name'] ?? '').toString());
      } else if (_sortOption == 'Name (Z-A)') {
        return (b['spare_name'] ?? '').toString().compareTo((a['spare_name'] ?? '').toString());
      } else if (_sortOption == 'Stock (Low-High)') {
        final stockA = (a['on_stock'] as num?) ?? 0;
        final stockB = (b['on_stock'] as num?) ?? 0;
        return stockA.compareTo(stockB);
      } else if (_sortOption == 'Stock (High-Low)') {
        final stockA = (a['on_stock'] as num?) ?? 0;
        final stockB = (b['on_stock'] as num?) ?? 0;
        return stockB.compareTo(stockA);
      }
      return 0;
    });

    setState(() {
      _filteredRecords = temp;
    });
  }

  void _showExportFormatDialog() {
    String format = 'docx';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Export MT-15 Report", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: primary.withOpacity(0.1))),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          "Generating report for ${_months[_selectedMonth - 1]} $_selectedYear.",
                          style: GoogleFonts.inter(fontSize: 13, color: primary, fontWeight: FontWeight.w600)
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("Select Format", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(
                      label: Text("Word (.docx)", style: GoogleFonts.inter(fontWeight: format == 'docx' ? FontWeight.bold : FontWeight.normal)),
                      selected: format == 'docx',
                      selectedColor: primary.withOpacity(0.1),
                      side: BorderSide(color: format == 'docx' ? primary : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (v) => setDialogState(() => format = 'docx')
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                      label: Text("PDF", style: GoogleFonts.inter(fontWeight: format == 'pdf' ? FontWeight.bold : FontWeight.normal)),
                      selected: format == 'pdf',
                      selectedColor: primary.withOpacity(0.1),
                      side: BorderSide(color: format == 'pdf' ? primary : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (v) => setDialogState(() => format = 'pdf')
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), elevation: 0),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExport(_selectedMonth, _selectedYear, format);
              },
              child: Text("DOWNLOAD", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeExport(int month, int year, String format) async {
    final targetKitchenId = _getActiveKitchenId();
    if (targetKitchenId == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primary)));

    try {
      final monthString = "${_months[month - 1].substring(0, 3)}_$year"; // Formats to "Jan_2026"
      final url = Uri.parse('${ApiConstants.pythonApiBaseUrl}/reports/critical-spares/$monthString?kitchen_id=$targetKitchenId&format=$format');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Directory? saveDir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download/Maintenance Reports')
            : Directory('${(await getApplicationDocumentsDirectory()).path}/Maintenance Reports');

        if (!await saveDir.exists()) await saveDir.create(recursive: true);

        final expectedFilename = 'MT15_Critical_Spares_$monthString.$format';
        final file = File('${saveDir.path}/$expectedFilename');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context); // Close loading dialog
        OpenFilex.open(file.path);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
    }
  }

  IconData _getSpareIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'MECHANICAL': return Icons.settings;
      case 'ELECTRICAL': return Icons.electric_bolt;
      case 'CHEMICAL': return Icons.science;
      default: return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface, foregroundColor: primary, elevation: 0,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
              hintText: "Search spare name or code...",
              border: InputBorder.none,
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400)
          ),
          style: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w500),
          onChanged: (val) {
            _searchQuery = val;
            _applyFilters();
          },
        )
            : Text("MT-15 Critical Spares", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: primary),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _applyFilters();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          if (!_isSearching)
            IconButton(icon: const Icon(Icons.download_outlined, color: primary), onPressed: _showExportFormatDialog),
        ],
      ),
      body: Column(
        children: [
          // 1. ROUNDED TIMELINE FILTER ROW (Main Screen)
          Container(
            color: surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    borderRadius: BorderRadius.circular(24), // Ensures the dropdown list menu is rounded
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    value: _selectedMonth,
                    icon: const Icon(Icons.arrow_drop_down, color: primary),
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i], style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))))),
                    onChanged: (v) {
                      setState(() => _selectedMonth = v!);
                      _fetchData();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    borderRadius: BorderRadius.circular(24), // Ensures the dropdown list menu is rounded
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    value: _selectedYear,
                    icon: const Icon(Icons.arrow_drop_down, color: primary),
                    items: List.generate(10, (index) => 2026 + index).map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedYear = v!);
                      _fetchData();
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. TYPES FILTER ROW & SORT
          Container(
            color: surface,
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _spareTypes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final type = _spareTypes[index];
                      final isSelected = type == _selectedType;
                      return ChoiceChip(
                        label: Text(type == 'All' ? 'All Types' : type, style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 13)),
                        selected: isSelected,
                        selectedColor: primary,
                        backgroundColor: const Color(0xFFF8FAFC),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? primary : Colors.grey.shade300)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedType = type);
                            _applyFilters();
                          }
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_filteredRecords.length} Spares Found", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                      DropdownButton<String>(
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: Colors.white,
                        value: _sortOption,
                        icon: const Icon(Icons.sort, size: 16, color: primary),
                        underline: const SizedBox(),
                        style: GoogleFonts.inter(color: primary, fontSize: 13, fontWeight: FontWeight.w600),
                        items: _sortOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) {
                          setState(() => _sortOption = v!);
                          _applyFilters();
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          // 3. LIST VIEW
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _filteredRecords.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No matching spares found.", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 15)),
                ],
              ),
            )
                : RefreshIndicator(
              color: primary,
              onRefresh: _fetchData,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredRecords.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final item = _filteredRecords[i];
                  final num onStock = item['on_stock'] ?? 0;
                  final num maintainedStock = item['maintained_stock'] ?? 0;
                  final bool isLowStock = onStock < maintainedStock;

                  return Material(
                    color: surface, borderRadius: BorderRadius.circular(16),
                    elevation: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: isLowStock ? Colors.red.shade200 : Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                            child: Icon(_getSpareIcon(item['spare_type']), color: primary, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${item['spare_name']}", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text("Code: ${item['spare_code'] ?? 'N/A'}", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                                    SizedBox(width: 8,),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                                      child: Text("${item['spare_type'] ?? 'N/A'}", style: GoogleFonts.inter(color: primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Stock Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isLowStock ? Colors.red.shade200 : Colors.green.shade200)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("$onStock / $maintainedStock", style: GoogleFonts.inter(color: isLowStock ? Colors.red.shade700 : Colors.green.shade700, fontWeight: FontWeight.w800, fontSize: 14)),
                                Text(item['uom'] ?? 'Nos', style: GoogleFonts.inter(color: isLowStock ? Colors.red.shade500 : Colors.green.shade600, fontSize: 10, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}