import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _amp = TextEditingController();
  final _address = TextEditingController();

  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  List<Map<String, dynamic>> _availableKitchens = [];
  final List<String> _selectedKitchenIds = [];
  bool _isLoadingKitchens = true;

  @override
  void initState() {
    super.initState();
    _fetchKitchens();
  }

  Future<void> _fetchKitchens() async {
    try {
      final response = await Supabase.instance.client
          .from('m_kitchen')
          .select('id, name')
          .eq('status', true);
      if (mounted) {
        setState(() {
          _availableKitchens = List<Map<String, dynamic>>.from(response);
          _isLoadingKitchens = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading kitchens: $e");
      if (mounted) setState(() => _isLoadingKitchens = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amp.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isLoading = context.watch<AuthProvider>().isLoading;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0,
          title: Text("Complete Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: navy)),
          centerTitle: true,
          actions: [
            IconButton(onPressed: () => auth.logout(), icon: const Icon(Icons.logout_rounded, color: Colors.redAccent)),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Almost there!", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: navy)),
              const SizedBox(height: 8),
              Text("Please provide your details and select the kitchens you work at.", style: GoogleFonts.inter(color: Colors.grey.shade600, height: 1.5)),
              const SizedBox(height: 32),

              _buildTextField(ctrl: _name, label: "Full Name", icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(ctrl: _amp, label: "AMP ID", icon: Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildTextField(ctrl: _address, label: "Address", icon: Icons.home_outlined, maxLines: 3),
              const SizedBox(height: 24),

              Text("Select Kitchens (Required)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: navy, fontSize: 14)),
              const SizedBox(height: 12),
              _isLoadingKitchens
                  ? const Center(child: CircularProgressIndicator(color: golden))
                  : Wrap(
                spacing: 8, runSpacing: 8,
                children: _availableKitchens.map((k) {
                  final isSelected = _selectedKitchenIds.contains(k['id']);
                  return FilterChip(
                    label: Text(k['name'], style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? navy : Colors.grey.shade700)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedKitchenIds.add(k['id']);
                        } else {
                          _selectedKitchenIds.remove(k['id']);
                        }
                      });
                    },
                    selectedColor: navy.withValues(alpha: 0.08),
                    backgroundColor: Colors.white,
                    checkmarkColor: navy,
                    side: BorderSide(color: isSelected ? navy : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: navy, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isLoading ? null : () async {
                    if (_name.text.isEmpty || _amp.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Name and AMP ID are required", style: GoogleFonts.inter()), backgroundColor: Colors.red.shade600));
                      return;
                    }
                    if (_selectedKitchenIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select at least one Kitchen", style: GoogleFonts.inter()), backgroundColor: Colors.red.shade600));
                      return;
                    }

                    final phone = Supabase.instance.client.auth.currentUser?.phone;
                    if (phone == null) return;

                    final ok = await auth.registerUser(
                      name: _name.text.trim(),
                      ampId: _amp.text.trim(),
                      address: _address.text.trim(),
                      phone: phone,
                      selectedKitchenIds: _selectedKitchenIds,
                    );

                    if (!ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? "Error", style: GoogleFonts.inter()), backgroundColor: Colors.red.shade600));
                    }
                  },
                  child: isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text("SUBMIT FOR APPROVAL", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController ctrl, required String label, required IconData icon, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.inter(color: Colors.grey.shade500),
        prefixIcon: Padding(padding: EdgeInsets.only(bottom: maxLines > 1 ? 48.0 : 0), child: Icon(icon, color: Colors.grey.shade400)),
        filled: true, fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
      ),
    );
  }
}