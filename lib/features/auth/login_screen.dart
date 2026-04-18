import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.handyman, size: 80, color: Color(0xFF4A56E2)),
            const SizedBox(height: 16),
            const Text("Plant Maintenance", textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A56E2))),
            const SizedBox(height: 48),

            // Step 1: Enter User ID
            TextField(
              controller: _idController,
              enabled: !_otpSent,
              decoration: const InputDecoration(
                labelText: "Employee ID",
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),

            // Step 2: Enter OTP (Visible only after sending)
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: "Enter 6-Digit OTP",
                  prefixIcon: Icon(Icons.lock_clock),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A56E2),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _otpSent ? _verifyOtp : _sendOtp,
              child: Text(_otpSent ? "VERIFY & LOGIN" : "GET OTP",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

            if (_otpSent)
              TextButton(
                onPressed: () => setState(() => _otpSent = false),
                child: const Text("Change Employee ID"),
              ),
          ],
        ),
      ),
    );
  }

  void _sendOtp() {
    // Logic:
    // 1. Call Edge Function to look up phone number for _idController.text[cite: 70, 74].
    // 2. Trigger Supabase Auth signInWithOtp[cite: 52].
    setState(() => _otpSent = true);
  }

  void _verifyOtp() {
    // Logic: Call Supabase auth.verifyOTP[cite: 56].
  }
}