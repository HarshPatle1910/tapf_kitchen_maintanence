class AppRoutes {
  // Auth & System Routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String pendingApproval = '/pending-approval';

  // Core Workspace
  static const String home = '/';

  // Tickets
  static const String ticketNew = '/tickets/new';
  static const String ticketDetail = '/tickets/:id';
  static const String ticketVerification = '/verification';

  // Facility Configuration & Master
  static const String areaMaster = '/master/area';
  static const String zoneMaster = '/master/zone';
  static const String equipmentMaster = '/master/equipment';
  static const String sparesMaster = '/master/spares';
  static const String spareInventory = '/master/spares/inventory';
  static const String toolsMaster = '/master/tools';
  static const String vendorMaster = '/master/vendors';
  static const String userManagement = '/master/users';

  // Plant Maintenance Reports & Logs
  static const String reports = '/reports';
  static const String pmSchedule = '/reports/pm-schedule';
  static const String pmChecklist = '/reports/pm-checklist';
  static const String pmChecklistCreate = '/reports/pm-checklist/new';
  static const String electricalLog = '/reports/electrical-log';
  static const String boilerLog = '/reports/boiler-log';
  static const String roChecklist = '/reports/ro-checklist';
  static const String roTemplate = '/reports/ro-checklist/template';
  static const String dgLog = '/reports/dg-log';
  static const String breakdownReport = '/reports/breakdown';
  static const String complaintReport = '/reports/complaint';
  static const String testingEquipment = '/reports/testing-equipment';
  static const String criticalSpares = '/reports/critical-spares';
  static const String toolsTackles = '/reports/tools-tackles';
  static const String masterEquipment = '/reports/master-equipment';

  // Media & Video Playback
  static const String videoPlayer = '/video-player';

  // Helper Path Generators
  static String ticketDetailPath(dynamic id) => '/tickets/$id';
}
