import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  String? _role; // New variable to store the user's role

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _supabase.auth.currentSession != null;
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Expose an easy boolean for UI checks
  bool get isAdmin => _role == 'admin';

  AuthProvider() {
    _checkExistingSession();
  }

  // Check if user is already logged in when the app starts
  Future<void> _checkExistingSession() async {
    if (_supabase.auth.currentSession != null) {
      await _fetchUserRole(_supabase.auth.currentUser!.id);
    }
  }

  // Helper to get role from the database
  Future<void> _fetchUserRole(String userId) async {
    try {
      final userData = await _supabase
          .from('m_user')
          .select('role')
          .eq('id', userId)
          .single();
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

      final response = await _supabase.auth.signInWithPassword(
        email: mappedEmail,
        password: password,
      );

      // If login is successful, fetch their role immediately
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

  Future<void> logout() async {
    _setLoading(true);
    await _supabase.auth.signOut();
    _role = null; // Clear role on logout
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}