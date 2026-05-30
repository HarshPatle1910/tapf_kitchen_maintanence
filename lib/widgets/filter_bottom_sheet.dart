import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

void showFilterBottomSheet({
  required BuildContext context,
  required TicketProvider provider,
  required AuthProvider authProv,
  required List<Map<String, dynamic>> kitchenZones,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _FilterBottomSheetWidget(
      provider: provider,
      authProv: authProv,
      kitchenZones: kitchenZones,
    ),
  );
}

// =====================================================================
// DEDICATED STATEFUL BOTTOM SHEET (Fixes the FocusNode/Overlay Crash)
// =====================================================================
class _FilterBottomSheetWidget extends StatefulWidget {
  final TicketProvider provider;
  final AuthProvider authProv;
  final List<Map<String, dynamic>> kitchenZones;

  const _FilterBottomSheetWidget({
    Key? key,
    required this.provider,
    required this.authProv,
    required this.kitchenZones,
  }) : super(key: key);

  @override
  State<_FilterBottomSheetWidget> createState() => _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<_FilterBottomSheetWidget> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  late String tempPriority;
  late String tempStatus;
  late String tempSort;
  late String tempKitchen;
  late String tempZone;
  late bool tempAssignedToMe;
  late bool tempRaisedByMe;
  DateTime? tempStart;
  DateTime? tempEnd;

  late TextEditingController zoneSearchController;
  late FocusNode zoneFocusNode;

  @override
  void initState() {
    super.initState();
    zoneSearchController = TextEditingController();
    zoneFocusNode = FocusNode();

    // Initialize states from the provider
    tempPriority = widget.provider.priorityFilter;
    tempStatus = widget.provider.statusFilter;
    tempSort = widget.provider.sortBy;
    tempKitchen = widget.provider.kitchenFilter;
    tempZone = widget.provider.zoneFilter;
    tempAssignedToMe = widget.provider.assignedToMeFilter;
    tempRaisedByMe = widget.provider.raisedByMeFilter;
    tempStart = widget.provider.startDate;
    tempEnd = widget.provider.endDate;

    if (tempZone != 'ALL') {
      final z = widget.kitchenZones.firstWhere((z) => z['id'].toString() == tempZone, orElse: () => <String, dynamic>{});
      if (z.isNotEmpty) zoneSearchController.text = z['name'].toString();
    }
  }

  @override
  void dispose() {
    zoneSearchController.dispose();
    zoneFocusNode.dispose();
    super.dispose();
  }

  Widget buildChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? navy : Colors.black87)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: golden.withOpacity(0.3),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: isSelected ? golden : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _applyFilters() {
    // Dismiss keyboard before applying
    FocusScope.of(context).unfocus();

    widget.provider.setFilters(
        status: tempStatus,
        priority: tempPriority,
        kitchenId: tempKitchen,
        zoneId: tempZone,
        assignedToMe: tempAssignedToMe,
        raisedByMe: tempRaisedByMe,
        start: tempStart,
        end: tempEnd,
        sort: tempSort,
        clearDates: tempStart == null // Passes true to clear the dates dynamically
    );
    Navigator.pop(context);
  }

  void _resetAllFilters() {
    setState(() {
      tempStatus = 'ALL';
      tempPriority = 'ALL';
      tempZone = 'ALL';
      zoneSearchController.clear();
      tempAssignedToMe = false;
      tempRaisedByMe = false;
      tempStart = null;
      tempEnd = null;
      tempSort = 'DATE_DESC';
    });
  }

  @override
  Widget build(BuildContext context) {
    String dateText = "Select Date Range";
    if (tempStart != null && tempEnd != null) {
      dateText = "${tempStart!.day}/${tempStart!.month}/${tempStart!.year}  -  ${tempEnd!.day}/${tempEnd!.month}/${tempEnd!.year}";
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Sort & Filter", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
                  TextButton(
                    onPressed: _resetAllFilters,
                    child: Text("Reset All", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Toggles
                      Container(
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text("My Tasks Only", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy)),
                              subtitle: Text("Show tickets assigned to me", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                              activeColor: golden,
                              value: tempAssignedToMe,
                              onChanged: (val) => setState(() => tempAssignedToMe = val),
                            ),
                            Divider(height: 1, color: Colors.grey.shade200),
                            SwitchListTile(
                              title: Text("Raised By Me", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy)),
                              subtitle: Text("Show tickets I have raised", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                              activeColor: golden,
                              value: tempRaisedByMe,
                              onChanged: (val) => setState(() => tempRaisedByMe = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Zone Filter Autocomplete
                      if (widget.kitchenZones.isNotEmpty) ...[
                        Text("Filter by Zone", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        RawAutocomplete<Map<String, dynamic>>(
                          textEditingController: zoneSearchController, focusNode: zoneFocusNode,
                          optionsBuilder: (val) {
                            if (val.text.isEmpty) return widget.kitchenZones;
                            return widget.kitchenZones.where((opt) => opt['display_name'].toString().toLowerCase().contains(val.text.toLowerCase()));
                          },
                          displayStringForOption: (opt) => opt['display_name'].toString(),
                          onSelected: (sel) { setState(() { tempZone = sel['id'].toString(); }); zoneFocusNode.unfocus(); },
                          fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
                            controller: ctrl, focusNode: fNode,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: navy),
                            decoration: InputDecoration(
                              labelText: "Search Zone (Clear for All)", labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                              prefixIcon: const Icon(Icons.layers_outlined, color: Colors.grey, size: 20),
                              filled: true, fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                              suffixIcon: ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16, color: Colors.grey), onPressed: () { ctrl.clear(); setState(() => tempZone = 'ALL'); }) : null,
                            ),
                          ),
                          optionsViewBuilder: (ctx, onSel, opts) => Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0, borderRadius: BorderRadius.circular(12),
                              child: Container(
                                constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 48),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                  itemBuilder: (ctx, idx) => ListTile(title: Text(opts.elementAt(idx)['display_name'], style: GoogleFonts.inter(fontSize: 13, color: navy, fontWeight: FontWeight.w500)), onTap: () => onSel(opts.elementAt(idx))),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Text("Sort By", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          buildChip("Newest First", tempSort == 'DATE_DESC', () => setState(() => tempSort = 'DATE_DESC')),
                          buildChip("Oldest First", tempSort == 'DATE_ASC', () => setState(() => tempSort = 'DATE_ASC')),
                          buildChip("Highest Priority", tempSort == 'PRIORITY_DESC', () => setState(() => tempSort = 'PRIORITY_DESC')),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text("Date Raised", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          FocusScope.of(context).unfocus(); // Ensure inputs lose focus before picker opens
                          final DateTimeRange? picked = await showDateRangePicker(
                            context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)),
                            initialDateRange: tempStart != null && tempEnd != null ? DateTimeRange(start: tempStart!, end: tempEnd!) : null,
                            builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: navy, onPrimary: Colors.white, onSurface: navy)), child: child!),
                          );
                          if (picked != null) {
                            setState(() { tempStart = picked.start; tempEnd = picked.end; });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dateText, style: GoogleFonts.inter(color: tempStart == null ? Colors.grey.shade500 : navy, fontWeight: FontWeight.w600)),
                              if (tempStart != null)
                                GestureDetector(
                                  onTap: () => setState(() { tempStart = null; tempEnd = null; }),
                                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                                )
                              else
                                const Icon(Icons.calendar_today, size: 18, color: navy),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text("Priority", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((prio) => buildChip(prio, tempPriority == prio, () => setState(() => tempPriority = prio))).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24, top: 16),
                child: SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                    onPressed: _applyFilters,
                    child: Text("APPLY FILTERS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}