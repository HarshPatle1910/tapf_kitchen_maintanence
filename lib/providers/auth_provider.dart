import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  String? _role;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _supabase.auth.currentSession != null;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  bool get isAdmin => _role == 'admin';

  // The secret key used ONLY for the few seconds between account creation and first login.
  static const String _secretSetupKey = 'SETUP_KEY_2026!@#';

  AuthProvider() {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    if (_supabase.auth.currentSession != null) {
      await _fetchUserRole(_supabase.auth.currentUser!.id);
    }
  }

  Future<void> _fetchUserRole(String userId) async {
    try {
      final userData = await _supabase.from('m_user').select('role').eq('id', userId).single();
      _role = userData['role'];
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching role: $e");
    }
  }

  Future<bool> loginWithEmployeeId(String employeeId, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final String mappedEmail = '$employeeId@yourkitchen.local'.toLowerCase().trim();
      final response = await _supabase.auth.signInWithPassword(email: mappedEmail, password: password);

      if (response.user != null) {
        await _fetchUserRole(response.user!.id);
      }
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

  // --- NEW: First Time Setup Logic ---
  Future<bool> setupFirstTimePassword(String employeeId, String newPassword) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final String mappedEmail = '$employeeId@yourkitchen.local'.toLowerCase().trim();

      // 1. Attempt to log in using the secret setup key
      final response = await _supabase.auth.signInWithPassword(
        email: mappedEmail,
        password: _secretSetupKey,
      );

      if (response.user != null) {
        // 2. Login successful! Immediately update to the user's chosen password
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));
        await _fetchUserRole(response.user!.id);

        _setLoading(false);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      // If the login fails, it means the key is wrong (already set up) or ID doesn't exist
      if (e.message.toLowerCase().contains('invalid login')) {
        _errorMessage = "Setup already completed or Employee ID not found.";
      } else {
        _errorMessage = e.message;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred during setup.";
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _supabase.auth.signOut();
    _role = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}