import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:kitchen_maintanence/providers/auth_provider.dart';
import 'package:kitchen_maintanence/providers/ticket_provider.dart';
import 'package:kitchen_maintanence/screens/home_screen.dart';
import 'package:kitchen_maintanence/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

// Define your Riverpod providers globally
final authControllerProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});

final ticketControllerProvider = ChangeNotifierProvider<TicketProvider>((ref) {
  return TicketProvider();
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://sfjjxmdkdswothebcbbd.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamp4bWRrZHN3b3RoZWJjYmJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODg2NjIsImV4cCI6MjA5MjA2NDY2Mn0.oFdI4Azq71VjJ7q0BHacOfv88QTKt0tCLVecmngkjrU",
  );

  runApp(
    // Wrap the app in ProviderScope for Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to changes in your AuthProvider
    final authProvider = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Kitchen Maintenance',
      theme: ThemeData(primaryColor: const Color(0xFF4A56E2)),
      // FIX: Check against the new AuthState enum
      // home: authProvider.authState == AuthState.authenticated
      //     ? const HomeScreen()
      //     : const LoginScreen(),
      home: HomeScreen(),
    );
  }
}