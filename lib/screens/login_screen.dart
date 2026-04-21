import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // For setup mode

  bool _isFirstTimeSetup = false; // Toggles the UI mode

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final employeeId = _idController.text.trim();
    final password = _passwordController.text;

    if (employeeId.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    bool success = false;

    if (_isFirstTimeSetup) {
      // Setup Mode Validation
      if (password.length < 6) {
        _showError('Password must be at least 6 characters');
        return;
      }
      if (password != _confirmPasswordController.text) {
        _showError('Passwords do not match');
        return;
      }
      // Execute Setup
      success = await authProvider.setupFirstTimePassword(employeeId, password);
    } else {
      // Normal Login
      success = await authProvider.loginWithEmployeeId(employeeId, password);
    }

    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (mounted && authProvider.errorMessage != null) {
      _showError(authProvider.errorMessage!);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

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
                const SizedBox(height: 8),
                Text(
                  _isFirstTimeSetup ? "Create your password to activate your account." : "Welcome back. Please login.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 48),

                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: "Employee ID", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: _isFirstTimeSetup ? "Create New Password" : "Password", prefixIcon: const Icon(Icons.lock), border: const OutlineInputBorder()),
                  textInputAction: _isFirstTimeSetup ? TextInputAction.next : TextInputAction.done,
                  onSubmitted: _isFirstTimeSetup ? null : (_) => _handleSubmit(),
                ),

                if (_isFirstTimeSetup) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Confirm Password", prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ],
                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A56E2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isLoading ? null : _handleSubmit,
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isFirstTimeSetup ? "COMPLETE SETUP" : "LOGIN", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isFirstTimeSetup = !_isFirstTimeSetup;
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  child: Text(
                    _isFirstTimeSetup ? "Already have a password? Login here." : "First time logging in? Setup Password.",
                    style: const TextStyle(color: Color(0xFF4A56E2), fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}