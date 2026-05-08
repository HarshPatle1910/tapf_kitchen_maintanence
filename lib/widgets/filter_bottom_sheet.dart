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
  const Color navy = Color(0xFF26538D);
  const Color golden = Color(0xFFD4AF37);

  String tempPriority = provider.priorityFilter;
  String tempStatus = provider.statusFilter;
  String tempSort = provider.sortBy;
  String tempKitchen = provider.kitchenFilter;
  String tempZone = provider.zoneFilter;
  bool tempAssignedToMe = provider.assignedToMeFilter;
  DateTime? tempStart = provider.startDate;
  DateTime? tempEnd = provider.endDate;

  final zoneSearchController = TextEditingController();
  final zoneFocusNode = FocusNode();

  if (tempZone != 'ALL') {
    final z = kitchenZones.firstWhere((z) => z['id'].toString() == tempZone, orElse: () => <String, dynamic>{});
    if (z.isNotEmpty) zoneSearchController.text = z['name'].toString();
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

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          String dateText = "Select Date Range";
          if (tempStart != null && tempEnd != null) {
            dateText = "${tempStart!.day}/${tempStart!.month}/${tempStart!.year}  -  ${tempEnd!.day}/${tempEnd!.month}/${tempEnd!.year}";
          }

          return FractionallySizedBox(
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
                        onPressed: () {
                          // FIX: Instantly applies the reset to the Provider and closes the sheet
                          final defaultKitchen = authProv.assignedKitchens.isNotEmpty ? authProv.assignedKitchens.first['id'].toString() : 'ALL';
                          provider.setFilters(
                            status: 'ALL', priority: 'ALL', zoneId: 'ALL', assignedToMe: false,
                            sort: 'DATE_DESC', kitchenId: defaultKitchen, start: null, end: null,
                          );
                          Navigator.pop(ctx);
                        },
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
                          Container(
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                            child: SwitchListTile(
                              title: Text("My Tasks Only", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy)),
                              subtitle: Text("Show tickets assigned to me", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                              activeColor: golden,
                              value: tempAssignedToMe,
                              onChanged: (val) => setModalState(() => tempAssignedToMe = val),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (kitchenZones.isNotEmpty) ...[
                            Text("Filter by Zone", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                            const SizedBox(height: 12),
                            RawAutocomplete<Map<String, dynamic>>(
                              textEditingController: zoneSearchController, focusNode: zoneFocusNode,
                              optionsBuilder: (val) {
                                if (val.text.isEmpty) return kitchenZones;
                                return kitchenZones.where((opt) => opt['display_name'].toString().toLowerCase().contains(val.text.toLowerCase()));
                              },
                              displayStringForOption: (opt) => opt['display_name'].toString(),
                              onSelected: (sel) { setModalState(() { tempZone = sel['id'].toString(); }); zoneFocusNode.unfocus(); },
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
                                  suffixIcon: ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16, color: Colors.grey), onPressed: () { ctrl.clear(); setModalState(() => tempZone = 'ALL'); }) : null,
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
                              buildChip("Newest First", tempSort == 'DATE_DESC', () => setModalState(() => tempSort = 'DATE_DESC')),
                              buildChip("Oldest First", tempSort == 'DATE_ASC', () => setModalState(() => tempSort = 'DATE_ASC')),
                              buildChip("Highest Priority", tempSort == 'PRIORITY_DESC', () => setModalState(() => tempSort = 'PRIORITY_DESC')),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Text("Date Raised", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final DateTimeRange? picked = await showDateRangePicker(
                                context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)),
                                initialDateRange: tempStart != null && tempEnd != null ? DateTimeRange(start: tempStart!, end: tempEnd!) : null,
                                builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: navy, onPrimary: Colors.white, onSurface: navy)), child: child!),
                              );
                              if (picked != null) setModalState(() { tempStart = picked.start; tempEnd = picked.end; });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dateText, style: GoogleFonts.inter(color: tempStart == null ? Colors.grey.shade500 : navy, fontWeight: FontWeight.w600)),
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
                            children: ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((prio) => buildChip(prio, tempPriority == prio, () => setModalState(() => tempPriority = prio))).toList(),
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
                        onPressed: () {
                          provider.setFilters(status: tempStatus, priority: tempPriority, kitchenId: tempKitchen, zoneId: tempZone, assignedToMe: tempAssignedToMe, start: tempStart, end: tempEnd, sort: tempSort);
                          Navigator.pop(ctx);
                        },
                        child: Text("APPLY FILTERS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    zoneSearchController.dispose();
    zoneFocusNode.dispose();
  });
}