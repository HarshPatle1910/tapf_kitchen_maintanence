import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthState { unauthenticated, profileIncomplete, pendingApproval, authenticated }

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isInitializing = true;
  bool _isLoading = false;

  String? _errorMessage;
  AuthState _authState = AuthState.unauthenticated;

  String? _activeRole;
  List<String> _activeKitchenIds = []; // FIX: Now a list of kitchens
  String? _userName;

  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthState get authState => _authState;

  String? get currentUserId => _supabase.auth.currentUser?.id;
  String? get activeRole => _activeRole;
  bool get isAdmin => _activeRole == 'admin';

  // Expose the list of kitchens, and a default active kitchen (the first one)
  List<String> get activeKitchenIds => _activeKitchenIds;
  String? get activeKitchenId => _activeKitchenIds.isNotEmpty ? _activeKitchenIds.first : null;

  String? get userName => _userName;

  AuthProvider() {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    _isInitializing = true;
    notifyListeners();
    if (_supabase.auth.currentSession != null) {
      await refreshUserStatus();
    } else {
      _authState = AuthState.unauthenticated;
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      await _supabase.auth.signInWithOtp(phone: formattedPhone);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      final response = await _supabase.auth.verifyOTP(phone: formattedPhone, token: otp, type: OtpType.sms);
      if (response.user != null) {
        await refreshUserStatus();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerUser({
    required String name,
    required String ampId,
    required String address,
    required String phone,
    required List<String> selectedKitchenIds, // FIX: Added selected kitchens
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final userId = _supabase.auth.currentUser!.id;

      // 1. Insert User
      await _supabase.from('m_user').insert({
        'id': userId,
        'amp_id': ampId,
        'name': name,
        'mobile_no': phone,
        'address': address,
        'role': 'worker',
        'status': false,
      });

      // 2. Insert mapped kitchens into the junction table
      if (selectedKitchenIds.isNotEmpty) {
        final kitchenInserts = selectedKitchenIds.map((kId) => {
          'user_id': userId,
          'kitchen_id': kId,
        }).toList();
        await _supabase.from('user_kitchens').insert(kitchenInserts);
      }

      await refreshUserStatus();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "Registration failed. Please try again.";
      _setLoading(false);
      return false;
    }
  }

  Future<void> refreshUserStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // FIX: Inner join to fetch the user's assigned kitchens
      final data = await _supabase
          .from('m_user')
          .select('*, user_kitchens(kitchen_id)')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        _authState = AuthState.profileIncomplete;
      } else if (data['status'] == false) {
        _userName = data['name'];
        _authState = AuthState.pendingApproval;
      } else {
        _activeRole = data['role'];
        _userName = data['name'];
        _activeKitchenIds = (data['user_kitchens'] as List<dynamic>?)
            ?.map((k) => k['kitchen_id'].toString())
            .toList() ?? [];
        _authState = AuthState.authenticated;
      }
    } catch (e) {
      debugPrint("Error fetching status: $e");
      _authState = AuthState.unauthenticated;
    }
    _setLoading(false);
  }

  Future<void> logout() async {
    _setLoading(true);
    await _supabase.auth.signOut();
    _activeRole = null;
    _activeKitchenIds = [];
    _userName = null;
    _authState = AuthState.unauthenticated;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}