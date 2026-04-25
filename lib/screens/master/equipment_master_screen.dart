import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class EquipmentMasterScreen extends StatefulWidget {
  const EquipmentMasterScreen({super.key});

  @override
  State<EquipmentMasterScreen> createState() => _EquipmentMasterScreenState();
}

class _EquipmentMasterScreenState extends State<EquipmentMasterScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipment = [];
  bool _isLoading = true;

  // Search state & Focus
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchEquipment();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchEquipment() async {
    setState(() => _isLoading = true);
    try {
      // FIXED: Joined m_area instead of m_kitchen
      var query = _supabase
          .from('m_equipment')
          .select('*, m_area(area_name)')
          .eq('status', true);

      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);
      setState(() => _equipment = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching equipment: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _fetchEquipment();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: navy,
          title: Text(
            "Equipment Registry",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // Floating Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _searchFocusNode.hasFocus
                          ? navy.withOpacity(0.1)
                          : Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search equipment...",
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: _searchFocusNode.hasFocus ? navy : Colors.grey,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: golden, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Equipment List
            Expanded(
              child: _isLoading && _equipment.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: golden),
                    )
                  : _equipment.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.precision_manufacturing_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No equipment found",
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: navy,
                      onRefresh: _fetchEquipment,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 80,
                        ),
                        itemCount: _equipment.length,
                        itemBuilder: (context, index) {
                          final item = _equipment[index];
                          return _EquipmentCard(
                            item: item,
                            onDelete: () => _deleteEquipment(item['id']),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: golden,
          foregroundColor: navy,
          elevation: 2,
          onPressed: () {
            _searchFocusNode.unfocus();
            _showAddEquipmentDialog(context);
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(
            "Add Equipment",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEquipment(String id) async {
    await _supabase.from('m_equipment').update({'status': false}).eq('id', id);
    _fetchEquipment();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Equipment removed from registry',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showAddEquipmentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();

    // WARNING: Until this is a dropdown, you MUST paste a valid UUID from m_area here,
    // or the insert will fail due to Foreign Key constraints.
    final areaCtrl = TextEditingController();

    final modelCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    DateTime? commissionedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 12,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Text(
                    "Register Equipment",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildInputField(
                    ctrl: nameCtrl,
                    label: "Equipment Name *",
                    icon: Icons.precision_manufacturing,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          ctrl: areaCtrl,
                          label: "Area UUID (Optional)",
                          icon: Icons.place_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          ctrl: modelCtrl,
                          label: "Model No.",
                          icon: Icons.tag,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sleek Date Picker matching Driver form
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: commissionedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: navy,
                              onPrimary: Colors.white,
                              onSurface: navy,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() => commissionedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      isEmpty: commissionedDate == null,
                      decoration: InputDecoration(
                        labelText: "Date of Commission",
                        labelStyle: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: navy,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        commissionedDate == null
                            ? ""
                            : "${commissionedDate!.year}-${commissionedDate!.month.toString().padLeft(2, '0')}-${commissionedDate!.day.toString().padLeft(2, '0')}",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInputField(
                    ctrl: remarksCtrl,
                    label: "Remarks",
                    icon: Icons.notes_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        // Quick validation for Area ID to prevent crashes
                        if (areaCtrl.text.isNotEmpty &&
                            areaCtrl.text.length != 36) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Area ID must be a valid UUID or left blank.',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);

                        try {
                          await _supabase.from('m_equipment').insert({
                            'name': nameCtrl.text,
                            'area_id': areaCtrl.text.isNotEmpty
                                ? areaCtrl.text
                                : null,
                            'model': modelCtrl.text,
                            'date_of_commision': commissionedDate
                                ?.toIso8601String()
                                .split('T')[0],
                            'remarks': remarksCtrl.text,
                          });

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            _fetchEquipment();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Equipment saved successfully!',
                                  style: GoogleFonts.inter(),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error saving data: $e',
                                  style: GoogleFonts.inter(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      },
                      child: Text(
                        "SAVE EQUIPMENT",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Sleek Input Field
  Widget _buildInputField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: navy,
        fontSize: 14,
      ),
      validator: isRequired
          ? (val) => val == null || val.isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: golden, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// --- REDESIGNED EQUIPMENT CARD ---
class _EquipmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  const _EquipmentCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // FIXED: Safely extract the area name from the joined table
    final areaName = item['m_area'] != null
        ? item['m_area']['area_name']
        : 'No Area Assigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          iconColor: navy,
          collapsedIconColor: Colors.grey,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: navy.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              color: navy,
            ),
          ),
          title: Text(
            item['name'] ?? 'Unnamed',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: navy,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    areaName, // Now shows the readable Area Name instead of ID
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          title: "Model No.",
                          value: item['model'] ?? 'N/A',
                          icon: Icons.tag,
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          title: "Commissioned",
                          value: item['date_of_commision'] ?? 'N/A',
                          icon: Icons.calendar_today,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoItem(
                    title: "Remarks",
                    value:
                        item['remarks'] != null &&
                            item['remarks'].toString().isNotEmpty
                        ? item['remarks']
                        : 'No remarks added.',
                    icon: Icons.notes,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: Text(
                        "Remove Equipment",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              "Confirm Removal",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                            content: Text(
                              "Are you sure you want to remove '${item['name']}' from the registry?",
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  onDelete();
                                },
                                child: Text(
                                  "Remove",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
