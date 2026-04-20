import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_maintanence/providers/auth_provider.dart';
import 'package:kitchen_maintanence/providers/ticket_provider.dart';
import 'package:kitchen_maintanence/screens/home_screen.dart';
import 'package:kitchen_maintanence/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/themes/app_theme.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://sfjjxmdkdswothebcbbd.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamp4bWRrZHN3b3RoZWJjYmJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODg2NjIsImV4cCI6MjA5MjA2NDY2Mn0.oFdI4Azq71VjJ7q0BHacOfv88QTKt0tCLVecmngkjrU",
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitchen Maintenance',
      theme: ThemeData(primaryColor: const Color(0xFF4A56E2)),
      // Simple routing based on auth state
      home:
      // HomeScreen()
      context.watch<AuthProvider>().isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}