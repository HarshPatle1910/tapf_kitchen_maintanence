import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _isLoginMode = true; // Toggle for Login / Register UI

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSendOtp() async {
    if (_phoneCtrl.text.trim().length < 10) {
      _showError("Enter a valid mobile number");
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(_phoneCtrl.text.trim());

    if (ok) {
      setState(() => _otpSent = true);
    } else {
      if (mounted) _showError(auth.errorMessage ?? "Failed to send OTP");
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpCtrl.text.trim().isEmpty) {
      _showError("Enter the 6-digit OTP");
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(
      _phoneCtrl.text.trim(),
      _otpCtrl.text.trim(),
    );

    if (!ok && mounted) {
      _showError(auth.errorMessage ?? "Invalid OTP");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Header
                const Icon(Icons.handyman_rounded, size: 80, color: navy),
                const SizedBox(height: 16),
                Text(
                  "Plant Maintenance",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: navy,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 48),

                // Dynamic Context Header
                Text(
                  _otpSent
                      ? "Verify your number"
                      : (_isLoginMode
                            ? "Login to your account"
                            : "Create an account"),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _otpSent
                      ? "Enter the OTP sent to ${_phoneCtrl.text}"
                      : "Enter your mobile number to receive an OTP.",
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Phone Input (Disabled if OTP is sent)
                _buildTextField(
                  ctrl: _phoneCtrl,
                  label: "Mobile Number",
                  icon: Icons.phone_outlined,
                  isEnabled: !_otpSent,
                ),

                // OTP Input (Only shows if OTP is sent)
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    ctrl: _otpCtrl,
                    label: "6-Digit OTP",
                    icon: Icons.lock_clock_outlined,
                  ),
                ],

                const SizedBox(height: 32),

                // Primary Action Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : (_otpSent ? _handleVerifyOtp : _handleSendOtp),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _otpSent
                                ? "VERIFY OTP"
                                : (_isLoginMode
                                      ? "LOGIN WITH OTP"
                                      : "REGISTER WITH OTP"),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Toggle Login/Register OR Change Number
                if (!_otpSent)
                  TextButton(
                    onPressed: () =>
                        setState(() => _isLoginMode = !_isLoginMode),
                    child: Text(
                      _isLoginMode
                          ? "Don't have an account? Register"
                          : "Already have an account? Login",
                      style: GoogleFonts.inter(
                        color: golden,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => setState(() {
                      _otpSent = false;
                      _otpCtrl.clear();
                    }),
                    child: Text(
                      "Change Mobile Number",
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
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

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool isEnabled = true,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: isEnabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: isEnabled ? navy : Colors.grey.shade600,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: isEnabled ? navy : Colors.grey.shade400,
          size: 22,
        ),
        filled: true,
        fillColor: isEnabled ? Colors.grey.shade50 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: golden, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
