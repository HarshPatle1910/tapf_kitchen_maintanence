import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kitchen_maintanence/screens/authentication/pending_approval_screen.dart';
import 'package:kitchen_maintanence/screens/authentication/register_screen.dart';
import 'package:kitchen_maintanence/screens/home_screen.dart';
import 'package:kitchen_maintanence/screens/authentication/login_screen.dart';
// Make sure to import your TicketDetailScreen!
import 'package:kitchen_maintanence/screens/ticket_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';

// 1. THIS IS REQUIRED FOR BACKGROUND NOTIFICATION ROUTING
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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

    if (auth.isInitializing) {
      homeWidget = const Scaffold(
        backgroundColor: navy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handyman_rounded, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text("Kitchen Maintenance App", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    } else {
      switch (auth.authState) {
        case AuthState.authenticated: homeWidget = const HomeScreen(); break;
        case AuthState.profileIncomplete: homeWidget = const RegisterScreen(); break;
        case AuthState.pendingApproval: homeWidget = const PendingApprovalScreen(); break;
        case AuthState.unauthenticated: homeWidget = const LoginScreen(); break;
      }
    }

    return MaterialApp(
      title: 'Plant Maintenance',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // 2. ATTACH THE KEY HERE
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: golden),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: navy, elevation: 0),
      ),
      home: homeWidget,

      // 3. HANDLE THE NOTIFICATION CLICK ROUTING HERE
      onGenerateRoute: (settings) {
        if (settings.name == '/ticket-details') {
          final args = settings.arguments as Map<String, dynamic>;
          // Since we just have the ID from the notification, we pass it to the screen
          // Make sure your TicketDetailScreen can handle fetching by ID if the full map isn't passed!
          return MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticket: {'id': args['id']}),
          );
        }
        return null;
      },
    );
  }
}