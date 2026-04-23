import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Using Riverpod
import '../main.dart'; // Access to your global authControllerProvider
import '../providers/auth_provider.dart';
import 'home_screen.dart';

enum LoginStep { phone, otp, profile, pending }

// 1. Change to ConsumerStatefulWidget
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

// 2. Change to ConsumerState
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _ampIdController = TextEditingController();

  LoginStep _currentStep = LoginStep.phone;

  @override
  void initState() {
    super.initState();
    // Auto-redirect if session exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingSession();
    });
  }

  void _checkExistingSession() {
    // FIX: Replaced context.read with ref.read
    final auth = ref.read(authControllerProvider);
    _handleAuthState(auth.authState);
  }

  void _handleAuthState(AuthState state) {
    if (state == AuthState.authenticated) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (state == AuthState.pendingApproval) {
      setState(() => _currentStep = LoginStep.pending);
    } else if (state == AuthState.profileIncomplete) {
      setState(() => _currentStep = LoginStep.profile);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _ampIdController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().length < 10) {
      _showError("Enter a valid mobile number");
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    // FIX: Replaced context.read with ref.read
    final success = await ref.read(authControllerProvider).sendOtp(_phoneController.text.trim());
    if (success && mounted) {
      setState(() => _currentStep = LoginStep.otp);
    } else if (mounted) {
      _showError(ref.read(authControllerProvider).errorMessage ?? "Failed to send OTP");
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showError("Enter OTP");
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    // FIX: Replaced context.read with ref.read
    final auth = ref.read(authControllerProvider);
    final success = await auth.verifyOtp(_phoneController.text.trim(), _otpController.text.trim());

    if (success && mounted) {
      _handleAuthState(auth.authState);
    } else if (mounted) {
      _showError(auth.errorMessage ?? "Invalid OTP");
    }
  }

  Future<void> _submitProfile() async {
    if (_nameController.text.trim().isEmpty || _ampIdController.text.trim().isEmpty) {
      _showError("All fields are required");
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    // FIX: Replaced context.read with ref.read
    final auth = ref.read(authControllerProvider);
    final success = await auth.completeProfile(
      _nameController.text.trim(),
      _ampIdController.text.trim(),
      _phoneController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _currentStep = LoginStep.pending);
    } else if (mounted) {
      _showError(auth.errorMessage ?? "Failed to save profile");
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Replaced context.watch with ref.watch
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.handyman, size: 80, color: Color(0xFF4A56E2)),
                const SizedBox(height: 16),
                const Text("Plant Maintenance", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4A56E2))),
                const SizedBox(height: 48),

                if (_currentStep == LoginStep.phone) ...[
                  const Text("Login or Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Enter your mobile number to receive an OTP.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Mobile Number", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(isLoading, "SEND OTP", _sendOtp),
                ],

                if (_currentStep == LoginStep.otp) ...[
                  const Text("Verify Phone", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Enter the OTP sent to ${_phoneController.text}", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "6-Digit OTP", prefixIcon: Icon(Icons.lock_clock), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(isLoading, "VERIFY OTP", _verifyOtp),
                  TextButton(
                    onPressed: () => setState(() => _currentStep = LoginStep.phone),
                    child: const Text("Change Phone Number"),
                  )
                ],

                if (_currentStep == LoginStep.profile) ...[
                  const Text("Complete Registration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Please provide your details for admin approval.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ampIdController,
                    decoration: const InputDecoration(labelText: "AMP ID", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(isLoading, "SUBMIT FOR APPROVAL", _submitProfile),
                ],

                if (_currentStep == LoginStep.pending) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
                    child: Column(
                      children: [
                        const Icon(Icons.pending_actions, size: 48, color: Colors.orange),
                        const SizedBox(height: 16),
                        const Text("Approval Pending", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                        const SizedBox(height: 8),
                        const Text("Your account has been registered successfully. Please wait for an Admin to approve your access.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black87)),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          // FIX: Replaced context.read with ref.read
                          onPressed: () => ref.read(authControllerProvider).logout().then((_) => setState(()=> _currentStep = LoginStep.phone)),
                          child: const Text("LOGOUT"),
                        )
                      ],
                    ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool isLoading, String text, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A56E2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}