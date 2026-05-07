import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/auth_provider.dart';
import '../../../providers/ticket_provider.dart';

class ToolsMasterScreen extends StatefulWidget {
  const ToolsMasterScreen({super.key});

  @override
  State<ToolsMasterScreen> createState() => _ToolsMasterScreenState();
}

class _ToolsMasterScreenState extends State<ToolsMasterScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tools = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String? _getActiveKitchenId() {
    final authProv = context.read<AuthProvider>();
    final ticketProv = context.read<TicketProvider>();
    String activeKitchenId = ticketProv.kitchenFilter;

    if (activeKitchenId == 'ALL' || !authProv.assignedKitchens.any((k) => k['id'].toString() == activeKitchenId)) {
      if (authProv.assignedKitchens.isNotEmpty) {
        return authProv.assignedKitchens.first['id'].toString();
      }
      return null;
    }
    return activeKitchenId;
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final activeKitchenId = _getActiveKitchenId();
      if (activeKitchenId == null) {
        if (mounted) setState(() => _tools = []);
        return;
      }

      final response = await _supabase
          .from('m_tools')
          .select('*')
          .eq('kitchen_id', activeKitchenId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _tools = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Error fetching tools: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTools {
    var list = List<Map<String, dynamic>>.from(_tools);

    if (_searchQuery.isNotEmpty) {
      list = list.where((t) => t['tool_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_statusFilter == 'ACTIVE') {
      list = list.where((t) => t['status'] == true).toList();
    } else if (_statusFilter == 'INACTIVE') {
      list = list.where((t) => t['status'] == false).toList();
    }

    return list;
  }

  String _formatDateOnly(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final d = DateTime.parse(isoString).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (e) {
      return '';
    }
  }

  // FIX: Custom Date Picker Logic for smooth state updating
  Future<void> _pickDateStr(BuildContext context, String? currentIso, Function(String) onPicked) async {
    final DateTime? initial = (currentIso != null && currentIso.isNotEmpty) ? DateTime.tryParse(currentIso) : DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: navy, onPrimary: Colors.white, onSurface: navy),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      onPicked(picked.toIso8601String());
    }
  }

  void _showFilterBottomSheet() {
    String tempStatus = _statusFilter;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filter Tools", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                      TextButton(
                        onPressed: () => setModalState(() => tempStatus = 'ALL'),
                        child: Text("Reset", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  Text("Status", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _buildChip("All", tempStatus == 'ALL', () => setModalState(() => tempStatus = 'ALL')),
                      _buildChip("Active", tempStatus == 'ACTIVE', () => setModalState(() => tempStatus = 'ACTIVE')),
                      _buildChip("Inactive / Destroyed", tempStatus == 'INACTIVE', () => setModalState(() => tempStatus = 'INACTIVE')),
                    ],
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () {
                        setState(() => _statusFilter = tempStatus);
                        Navigator.pop(ctx);
                      },
                      child: Text("APPLY FILTERS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showToolsForm({Map<String, dynamic>? existingTool}) {
    final nameController = TextEditingController(text: existingTool?['tool_name'] ?? '');

    // Separate State variables for DB vs UI display
    String? commIso = existingTool?['date_of_commision'];
    String? destIso = existingTool?['date_of_destroy'];

    final commDisplayCtrl = TextEditingController(text: _formatDateOnly(commIso));
    final destDisplayCtrl = TextEditingController(text: _formatDateOnly(destIso));

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final targetKitchenId = existingTool?['kitchen_id']?.toString() ?? _getActiveKitchenId();

    if (targetKitchenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active kitchen selected.'), backgroundColor: Colors.red));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                    Text(existingTool == null ? "Add New Tool" : "Edit Tool Details", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                    const SizedBox(height: 24),

                    _buildInputField(ctrl: nameController, label: "Tool Name *", icon: Icons.handyman, isRequired: true),
                    const SizedBox(height: 16),

                    // Commission Date Picker (Clean State Updating)
                    TextFormField(
                      controller: commDisplayCtrl,
                      readOnly: true,
                      onTap: () => _pickDateStr(context, commIso, (iso) {
                        setModalState(() {
                          commIso = iso;
                          commDisplayCtrl.text = _formatDateOnly(iso);
                        });
                      }),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                      decoration: InputDecoration(
                        labelText: "Date of Commissioning", labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                        prefixIcon: const Icon(Icons.event_available, color: Colors.green),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FIX 1: Only show Destruction Date if editing an existing tool
                    if (existingTool != null) ...[
                      TextFormField(
                        controller: destDisplayCtrl,
                        readOnly: true,
                        onTap: () => _pickDateStr(context, destIso, (iso) {
                          setModalState(() {
                            destIso = iso;
                            destDisplayCtrl.text = _formatDateOnly(iso);
                          });
                        }),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.red),
                        decoration: InputDecoration(
                          labelText: "Date of Destruction (Optional)", labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                          prefixIcon: const Icon(Icons.event_busy, color: Colors.redAccent),
                          filled: true, fillColor: Colors.red.withOpacity(0.05), // Subtle red tint to warn user
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                          suffixIcon: destIso != null ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setModalState(() {
                            destIso = null;
                            destDisplayCtrl.clear();
                          })) : null,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: isSaving
                            ? null
                            : () async {
                          if (!formKey.currentState!.validate()) return;

                          // FIX 4: Destruction Confirmation Dialog
                          bool proceed = true;
                          if (destIso != null && existingTool?['status'] != false) {
                            proceed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text("Confirm Destruction", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: navy, fontSize: 18)),
                                  ],
                                ),
                                content: Text("Marking a date of destruction will permanently lock this tool and set it as Inactive. Do you wish to proceed?", style: GoogleFonts.inter(color: Colors.grey.shade700)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text("Yes, Destroy", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ) ?? false;
                          }

                          if (!proceed) return;

                          setModalState(() => isSaving = true);

                          final Map<String, dynamic> payload = {
                            'tool_name': nameController.text.trim(),
                            'date_of_commision': commIso,
                            'date_of_destroy': destIso,
                            'kitchen_id': targetKitchenId,
                          };

                          // Automatically mark inactive if a destroy date is confirmed
                          if (destIso != null) {
                            payload['status'] = false;
                          }

                          try {
                            if (existingTool == null) {
                              await _supabase.from('m_tools').insert(payload).select();
                            } else {
                              await _supabase.from('m_tools').update(payload).eq('id', existingTool['id']).select();
                            }
                            if (mounted) {
                              Navigator.pop(ctx);
                              _fetchData();
                            }
                          } catch (e) {
                            debugPrint("Insert Error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                            setModalState(() => isSaving = false);
                          }
                        },
                        child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text("SAVE TOOL", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({required TextEditingController ctrl, required String label, required IconData icon, bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, textCapitalization: TextCapitalization.words,
      validator: isRequired ? (val) => val == null || val.trim().isEmpty ? 'Required' : null : null,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? navy : Colors.grey.shade700)),
      selected: isSelected, onSelected: (_) => onTap(),
      selectedColor: navy.withOpacity(0.08), backgroundColor: Colors.white, showCheckmark: false,
      side: BorderSide(color: isSelected ? navy : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _buildStatCard(String label, int count, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count.toString(), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: baseColor)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: baseColor.withOpacity(0.8), fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // Custom UI pill for displaying dates cleanly on the card
  Widget _buildDatePill(String label, String? isoDate, Color color) {
    if (isoDate == null || isoDate.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 12, color: color),
          const SizedBox(width: 4),
          Text("$label: ${_formatDateOnly(isoDate)}", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = _tools.length;
    int activeItems = _tools.where((t) => t['status'] == true).length;
    int destroyedItems = totalItems - activeItems;

    final displayList = _filteredTools;
    final bool hasActiveFilters = _statusFilter != 'ALL';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background, elevation: 0, foregroundColor: navy,
          title: Text("Tools Master", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: golden))
            : CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: background, elevation: 0, floating: true, snap: true, automaticallyImplyLeading: false, toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(160),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(child: _buildStatCard("Total Tools", totalItems, navy)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard("Active", activeItems, Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard("Destroyed", destroyedItems, Colors.red)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                              child: TextField(
                                controller: _searchController, focusNode: _searchFocusNode, onChanged: (value) => setState(() => _searchQuery = value),
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                                decoration: InputDecoration(
                                  hintText: "Search tools...", hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 20), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); _searchFocusNode.unfocus(); }) : null,
                                  filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () { _searchFocusNode.unfocus(); _showFilterBottomSheet(); },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: hasActiveFilters ? navy : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hasActiveFilters ? navy : Colors.white),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Icon(Icons.tune, color: hasActiveFilters ? Colors.white : navy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (displayList.isEmpty)
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40.0), child: Center(child: Text("No tools match your filters.", style: GoogleFonts.inter(color: Colors.grey)))))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final tool = displayList[i];
                      final bool isActive = tool['status'] == true;

                      // FIX 3: Premium UI Card implementation
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey.shade100)
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: isActive ? Colors.green : Colors.red, width: 5))
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: navy.withOpacity(0.05), shape: BoxShape.circle),
                                            child: const Icon(Icons.handyman, color: navy, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(tool['tool_name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? navy : Colors.grey.shade600)),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                            child: Text(isActive ? "ACTIVE" : "DESTROYED", style: GoogleFonts.inter(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                if (isActive)
                                                  TextButton.icon(
                                                    onPressed: () => _showToolsForm(existingTool: tool),
                                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                                    label: Text("Edit", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                                    style: TextButton.styleFrom(foregroundColor: navy),
                                                  )
                                                else
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                                                        const SizedBox(width: 4),
                                                        Text("Locked", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                                      ],
                                                    ),
                                                  )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        children: [
                                          _buildDatePill("Commissioned", tool['date_of_commision'], Colors.green.shade700),
                                          _buildDatePill("Destroyed", tool['date_of_destroy'], Colors.red.shade700),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: displayList.length,
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: golden, foregroundColor: navy,
          onPressed: _showToolsForm,
          icon: const Icon(Icons.add), label: Text("Add Tool", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}