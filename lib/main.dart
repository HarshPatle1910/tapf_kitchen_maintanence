import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_maintanence/features/tickets/screens/home_screens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/themes/app_theme.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://sfjjxmdkdswothebcbbd.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamp4bWRrZHN3b3RoZWJjYmJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODg2NjIsImV4cCI6MjA5MjA2NDY2Mn0.oFdI4Azq71VjJ7q0BHacOfv88QTKt0tCLVecmngkjrU",
  );

  runApp(
    const ProviderScope(
      child: KitchenMaintenanceApp(),
    ),
  );
}

class KitchenMaintenanceApp extends StatelessWidget {
  const KitchenMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitchen Maintenance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}