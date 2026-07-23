import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class SpareInventoryScreen extends StatefulWidget {
  final Map<String, dynamic> spare;

  const SpareInventoryScreen({super.key, required this.spare});

  @override
  State<SpareInventoryScreen> createState() => _SpareInventoryScreenState();
}

class _SpareInventoryScreenState extends State<SpareInventoryScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8F9FA);

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  int _currentQty = 0;
  int _totalQty = 0;
  int _minAlert = 5;

  final TextEditingController _addQtyController = TextEditingController();
  final TextEditingController _minAlertController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchInventoryData();
  }

  @override
  void dispose() {
    _addQtyController.dispose();
    _minAlertController.dispose();
    super.dispose();
  }

  Future<void> _fetchInventoryData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('spare_tracker')
          .select()
          .eq('spare_id', widget.spare['id'])
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _currentQty = response['current_qty'] ?? 0;
          _totalQty = response['total_qty'] ?? 0;
          _minAlert = response['min_qty_alert'] ?? 5;
          _minAlertController.text = _minAlert.toString();
        });
      } else {
        setState(() {
          _minAlertController.text = '5';
        });
      }
    } catch (e) {
      debugPrint("Error fetching tracker: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateInventory() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    int addedQty = int.tryParse(_addQtyController.text.trim()) ?? 0;
    int newMin = int.tryParse(_minAlertController.text.trim()) ?? 5;

    if (addedQty <= 0 && newMin == _minAlert) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes detected.', style: GoogleFonts.inter()), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final int newCurrent = _currentQty + addedQty;
      final int newTotal = _totalQty + addedQty;

      await _supabase.from('spare_tracker').upsert({
        'spare_id': widget.spare['id'],
        'current_qty': newCurrent,
        'total_qty': newTotal,
        'min_qty_alert': newMin,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'spare_id').select();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory Updated Successfully!', style: GoogleFonts.inter()), backgroundColor: Colors.green),
        );
        _addQtyController.clear();
        await _fetchInventoryData();
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _getStatusColor() {
    if (_currentQty == 0) return Colors.red;
    if (_currentQty <= _minAlert) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final String uom = widget.spare['uom'] ?? 'Nos';

    String statusText = "Healthy Stock";
    if (_currentQty == 0) {
      statusText = "Out of Stock";
    } else if (_currentQty <= _minAlert) {
      statusText = "Low Stock";
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: navy,
          title: Text("Manage Inventory", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: golden))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: navy.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(widget.spare['spare_name'], style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                        if (widget.spare['is_critical'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                            child: Text("CRITICAL", style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Code: ${widget.spare['spare_code'] ?? 'N/A'}  •  Type: ${widget.spare['spare_type']}", style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          Text("Current Stock", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(_currentQty.toString(), style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: statusColor)),
                              const SizedBox(width: 4),
                              Text(uom, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                            ],
                          ),
                          Text(statusText, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          Text("Lifetime Added", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(_totalQty.toString(), style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: navy)),
                              const SizedBox(width: 4),
                              Text(uom, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                            ],
                          ),
                          Text("Total Units", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text("Update Quantities", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _addQtyController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.green.shade700, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: "Receive New Stock (in $uom)",
                          labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                          prefixIcon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                          filled: true, fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _minAlertController,
                        keyboardType: TextInputType.number,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                        decoration: InputDecoration(
                          labelText: "Minimum Alert Threshold (in $uom) *",
                          labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                          prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          filled: true, fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: golden, width: 2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: golden,
                  foregroundColor: navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: _isSaving ? null : _updateInventory,
                child: _isSaving
                    ? const CircularProgressIndicator(color: navy)
                    : Text("SAVE INVENTORY", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}