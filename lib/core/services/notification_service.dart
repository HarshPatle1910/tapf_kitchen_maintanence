import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Notice: No BuildContext required here anymore!
  Future<void> initNotifications() async {
    NotificationSettings settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (token != null) await _saveTokenToDatabase(token);

      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

      // Handle App Opened from Terminated State
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) _handleNotificationClick(initialMessage);

      // Handle App Opened from Background State
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // Handle App is OPEN (Foreground Alert)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          final context =  navigatorKey.currentContext;
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${message.notification!.title}: ${message.notification!.body}"),
                backgroundColor: const Color(0xFF26538D),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(label: 'VIEW', textColor: Colors.white, onPressed: () => _handleNotificationClick(message)),
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    // 1. Force a refresh of the auth session
    final session = _supabase.auth.currentSession;
    if (session == null) {
      print("❌ FAILED: No active session found.");
      return;
    }

    final userId = session.user.id;
    print("🔥 Saving FCM token for User: $userId");

    try {
      // 2. Use insert/upsert with the user ID explicitly
      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');
      print("✅ Token saved successfully!");
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final String? ticketId = message.data['ticket_id'];
    if (ticketId != null) {
      navigatorKey.currentState?.pushNamed('/ticket-details', arguments: {'id': ticketId});
    }
  }
}