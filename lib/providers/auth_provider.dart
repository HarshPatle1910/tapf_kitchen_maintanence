import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthState { unauthenticated, profileIncomplete, pendingApproval, authenticated }

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  String? _role;
  AuthState _authState = AuthState.unauthenticated;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  bool get isAdmin => _role == 'admin';
  AuthState get authState => _authState;

  AuthProvider() {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    if (_supabase.auth.currentSession != null) {
      await _fetchUserAndCheckStatus(_supabase.auth.currentUser!.id);
    }
  }

  // 1. SEND OTP
  Future<bool> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // Ensure phone number has country code. Assuming +91 for India as default if missing.
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

      await _supabase.auth.signInWithOtp(phone: formattedPhone);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred.";
      _setLoading(false);
      return false;
    }
  }

  // 2. VERIFY OTP
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

      final response = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user != null) {
        await _fetchUserAndCheckStatus(response.user!.id);
        _setLoading(false);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred.";
      _setLoading(false);
      return false;
    }
  }

  // 3. COMPLETE PROFILE (First Time Registration)
  Future<bool> completeProfile(String name, String ampId, String phoneNumber) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase.from('m_user').insert({
        'id': userId,
        'amp_id': ampId,
        'name': name,
        'mobile_no': phoneNumber,
        'role': 'worker', // Default role
        'status': false,  // Needs Admin Approval
      });

      _authState = AuthState.pendingApproval;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Failed to save profile. AMP ID might be taken.";
      _setLoading(false);
      return false;
    }
  }

  // 4. CHECK STATUS & ROLE
  Future<void> _fetchUserAndCheckStatus(String userId) async {
    try {
      final response = await _supabase.from('m_user').select().eq('id', userId).maybeSingle();

      if (response == null) {
        // User authenticated but hasn't created their m_user profile yet
        _authState = AuthState.profileIncomplete;
      } else {
        if (response['status'] == true) {
          _role = response['role'];
          _authState = AuthState.authenticated;
        } else {
          _authState = AuthState.pendingApproval;
        }
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _setLoading(true);
    await _supabase.auth.signOut();
    _role = null;
    _authState = AuthState.unauthenticated;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}