import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_maintanence/screens/ticket_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:kitchen_maintanence/providers/auth_provider.dart';
import 'package:kitchen_maintanence/providers/ticket_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  String? get activeRole => 'admin';
  
  @override
  String? get currentUserId => 'test-user-id';

  @override
  List<Map<String, dynamic>> get assignedKitchens => [{'id': 'kitchen1', 'name': 'Test Kitchen'}];

  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTicketProvider extends ChangeNotifier implements TicketProvider {
  @override
  String get kitchenFilter => 'kitchen1';

  @override
  bool get isLoading => false;

  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // Initialize Supabase for testing to prevent "You must initialize..." error
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('TicketDetailScreen renders without crashing on Web/Tablet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ChangeNotifierProvider<TicketProvider>(create: (_) => MockTicketProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TicketDetailScreen(ticket: null),
          ),
        ),
      ),
    );

    // Wait for animations
    await tester.pumpAndSettle();

    // Verify it rendered successfully with the three distinct cards
    expect(find.text('Ticket Information'), findsOneWidget);
    expect(find.text('Work & Assignment'), findsOneWidget);
    expect(find.text('Status & Timeline'), findsOneWidget);
    
    // Reset view
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

