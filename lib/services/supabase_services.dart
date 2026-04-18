import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  // Helper to get current user ID [cite: 459]
  static String? get currentUserId => client.auth.currentUser?.id;
}