import 'package:flutter/material.dart';
import 'package:kitchen_maintanence/screens/authentication/pending_approval_screen.dart';
import 'package:kitchen_maintanence/screens/authentication/register_screen.dart';
import 'package:kitchen_maintanence/screens/home_screen.dart';
import 'package:kitchen_maintanence/screens/authentication/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: "https://sfjjxmdkdswothebcbbd.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamp4bWRrZHN3b3RoZWJjYmJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODg2NjIsImV4cCI6MjA5MjA2NDY2Mn0.oFdI4Azq71VjJ7q0BHacOfv88QTKt0tCLVecmngkjrU",
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<TicketProvider>(create: (_) => TicketProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF26538D);
    const Color golden = Color(0xFFD4AF37);

    final auth = context.watch<AuthProvider>();

    Widget homeWidget;

    // NEW: Show Splash Screen while checking DB
    if (auth.isInitializing) {
      homeWidget = const Scaffold(
        backgroundColor: navy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handyman_rounded, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Center(
                child: Text(
                  "Kitchen Maintanence App",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Normal Routing
      switch (auth.authState) {
        case AuthState.authenticated:
          homeWidget = const HomeScreen();
          break;
        case AuthState.profileIncomplete:
          homeWidget = const RegisterScreen();
          break;
        case AuthState.pendingApproval:
          homeWidget = const PendingApprovalScreen();
          break;
        case AuthState.unauthenticated:
        default:
          homeWidget = const LoginScreen();
          break;
      }
    }

    return MaterialApp(
      title: 'Plant Maintenance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: golden,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: navy,
          elevation: 0,
        ),
      ),
      home: homeWidget,
    );
  }
}
