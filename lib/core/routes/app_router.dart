import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/authentication/login_screen.dart';
import '../../screens/authentication/pending_approval_screen.dart';
import '../../screens/authentication/register_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/master/area_screen.dart';
import '../../screens/master/equipment_master_screen.dart';
import '../../screens/master/spares/spare_inventory_screen.dart';
import '../../screens/master/spares/spare_screen.dart';
import '../../screens/master/tools_screen.dart';
import '../../screens/master/user_management.dart';
import '../../screens/master/vendor_screen.dart';
import '../../screens/master/zone_screen.dart';
import '../../screens/reports/boiler_log_screen.dart';
import '../../screens/reports/breakdown_report_screen.dart';
import '../../screens/reports/complaint_report_screen.dart';
import '../../screens/reports/critical_spares_report_screen.dart';
import '../../screens/reports/dg_log_screen.dart';
import '../../screens/reports/electrical_log_screen.dart';
import '../../screens/reports/master_equipment_report_screen.dart';
import '../../screens/reports/pm_checklist_screen.dart';
import '../../screens/reports/pm_schedule_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/reports/ro_checklist_screen.dart';
import '../../screens/reports/testing_equipment_screen.dart';
import '../../screens/reports/tools_tackles_screen.dart';
import '../../screens/ticket_detail_screen.dart';
import '../../screens/ticket_verification_screen.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final location = state.uri.path;

      if (authProvider.isInitializing) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final authState = authProvider.authState;
      final isLoggingIn = location == AppRoutes.login;
      final isRegistering = location == AppRoutes.register;
      final isPending = location == AppRoutes.pendingApproval;
      final isSplash = location == AppRoutes.splash;

      if (authState == AuthState.unauthenticated) {
        return isLoggingIn ? null : AppRoutes.login;
      }

      if (authState == AuthState.profileIncomplete) {
        return isRegistering ? null : AppRoutes.register;
      }

      if (authState == AuthState.pendingApproval) {
        return isPending ? null : AppRoutes.pendingApproval;
      }

      if (authState == AuthState.authenticated) {
        if (isLoggingIn || isRegistering || isPending || isSplash) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.ticketNew,
        builder: (context, state) => const TicketDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.ticketDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final ticket = state.extra as Map<String, dynamic>? ?? {'id': id};
          return TicketDetailScreen(ticket: ticket);
        },
      ),
      GoRoute(
        path: AppRoutes.ticketVerification,
        builder: (context, state) => const TicketVerificationScreen(),
      ),
      // Master Data Routes
      GoRoute(
        path: AppRoutes.areaMaster,
        builder: (context, state) => const AreaMasterScreen(),
      ),
      GoRoute(
        path: AppRoutes.zoneMaster,
        builder: (context, state) => const ZoneMasterScreen(),
      ),
      GoRoute(
        path: AppRoutes.equipmentMaster,
        builder: (context, state) => const EquipmentMasterScreen(),
      ),
      GoRoute(
        path: AppRoutes.sparesMaster,
        builder: (context, state) => const SparesMasterScreen(),
      ),
      GoRoute(
        path: AppRoutes.spareInventory,
        builder: (context, state) {
          final spare = state.extra as Map<String, dynamic>? ?? {};
          return SpareInventoryScreen(spare: spare);
        },
      ),
      GoRoute(
        path: AppRoutes.toolsMaster,
        builder: (context, state) => const ToolsMasterScreen(),
      ),
      GoRoute(
        path: AppRoutes.vendorMaster,
        builder: (context, state) => const VendorMasterScreen(),
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        builder: (context, state) => const UserManagementScreen(),
      ),
      // Reports & Plant Maintenance
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) {
          final auth = context.read<AuthProvider>();
          final extra = state.extra as Map<String, dynamic>?;
          final allowedCodes = extra?['allowedReportCodes'] as List<String>? ?? [];
          final isAdmin = extra?['isAdmin'] as bool? ?? auth.isAdmin;
          return ReportsScreen(
            allowedReportCodes: allowedCodes,
            isAdmin: isAdmin,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.pmSchedule,
        builder: (context, state) => const PMScheduleScreen(),
      ),
      GoRoute(
        path: AppRoutes.pmChecklist,
        builder: (context, state) => const PMChecklistScreen(),
      ),
      GoRoute(
        path: AppRoutes.pmChecklistCreate,
        builder: (context, state) {
          final existing = state.extra as Map<String, dynamic>?;
          return CreatePMChecklistScreen(existingChecklist: existing);
        },
      ),
      GoRoute(
        path: AppRoutes.electricalLog,
        builder: (context, state) => const ElectricalLogListScreen(),
      ),
      GoRoute(
        path: AppRoutes.boilerLog,
        builder: (context, state) => const BoilerLogListScreen(),
      ),
      GoRoute(
        path: AppRoutes.roChecklist,
        builder: (context, state) => const ROChecklistListScreen(),
      ),
      GoRoute(
        path: AppRoutes.roTemplate,
        builder: (context, state) => const ROMasterTemplateScreen(),
      ),
      GoRoute(
        path: AppRoutes.dgLog,
        builder: (context, state) => const DGLogListScreen(),
      ),
      GoRoute(
        path: AppRoutes.breakdownReport,
        builder: (context, state) => const BreakdownReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.complaintReport,
        builder: (context, state) => const ComplaintReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.testingEquipment,
        builder: (context, state) => const TestingEquipmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.criticalSpares,
        builder: (context, state) => const CriticalSparesReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.toolsTackles,
        builder: (context, state) => const ToolsTacklesScreen(),
      ),
      GoRoute(
        path: AppRoutes.masterEquipment,
        builder: (context, state) => const EquipmentReportScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'No route defined for: ${state.uri.path}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF26538D);
    return const Scaffold(
      backgroundColor: navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman_rounded, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              "Kitchen Maintenance App",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

