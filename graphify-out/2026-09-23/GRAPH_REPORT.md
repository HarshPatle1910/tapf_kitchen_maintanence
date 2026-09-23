# Graph Report - kitchen_maintanence  (2026-09-23)

## Corpus Check
- 108 files · ~248,763 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 59 file(s) not represented in the graph (top: (none) 10, .plist 9, .xcconfig 8)

## Summary
- 1793 nodes · 2655 edges · 108 communities (83 shown, 25 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `66198de7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- ticket_detail_screen.dart
- boiler_log_screen.dart
- electrical_log_screen.dart
- equipment_master_screen.dart
- testing_equipment_screen.dart
- more_screen.dart
- dg_log_screen.dart
- spare_screen.dart
- ro_checklist_screen.dart
- ticket_provider.dart
- auth_provider.dart
- zone_screen.dart
- pm_schedule_screen.dart
- ticket_verification_screen.dart
- reports_screen.dart
- pm_checklist_screen.dart
- home_screen.dart
- filter_bottom_sheet.dart
- my_application.cc
- critical_spares_report_screen.dart
- home_screen_backup.dart
- area_screen.dart
- tools_screen.dart
- vendor_screen.dart
- user_management.dart
- breakdown_report_screen.dart
- complaint_report_screen.dart
- List
- web_ticket_table.dart
- Application Flow & Architecture Map - Kitchen Maintenance
- StatefulWidget
- tools_tackles_screen.dart
- user_management_backup.dart
- win32_window.cpp
- master_equipment_report_screen.dart
- Win32Window
- ../providers/ticket_provider.dart
- AuthProvider
- login_screen.dart
- ADR-002: Dual Backend Architecture — Supabase (Data/Auth) + Firebase (Storage & FCM)
- State
- GeneratedPluginRegistrant.swift
- ADR-003: State Management Architecture via Provider
- package:supabase_flutter/supabase_flutter.dart
- ticket_card.dart
- ADR-001: Mobile & Web Platform Selection (Flutter & Dart)
- utils.cpp
- web_ticket_card.dart
- windows/flutter/generated_plugin_registrant.cc
- string
- MessageHandler
- supabase_types.ts
- manifest.json
- firebase_media_service.dart
- package:flutter/material.dart
- firebase_options.dart
- StatelessWidget
- MessageHandler
- dart:io
- AppDelegate
- ios/RunnerTests/RunnerTests.swift
- static const Color
- Point
- FlutterMacOS
- AppDelegate
- Changelog & Project Changes - Kitchen Maintenance
- RegisterGeneratedPlugins
- telegram-notify/index.ts
- MainActivity.java
- RunnerTests
- app_update_wrapper.dart
- imports
- imports
- Runner-Bridging-Header.h
- Kitchen Maintenance App
- responsive_sidebar.dart
- BoilerLogFormScreen
- _AnimatedTicketCardState
- rules/graphify.md
- _DGLogListScreenState
- _PMScheduleScreenState
- workflows/graphify.md
- _TestingEquipmentScreenState
- GEMINI.md
- LaunchImage.imageset/README.md
- firebase-messaging-sw.js
- String?
- python_backend_snippet.md
- package:provider/provider.dart
- ../providers/auth_provider.dart
- ADR-004: Ticket Lifecycle & Zone-Based Verification Model
- ADR-005: Telegram Bot Notification Threading & Railway Webhooks
- ADR-006: Responsive Hybrid Architecture for Desktop/Web and Mobile
- ADR-007: App Update Enforcement & Versioning Mechanism
- ADR-008: Official TAPF Brand Identity & Header Standardization
- ADR-009: Dynamic Ticket Swapping & Staggered Transition Animations
- ADR-010: Asynchronous Query Concurrency Guards & Atomic State Resets
- Architecture Decision Records (ADRs) - Kitchen Maintenance
- widget_test.dart
- spare_inventory_screen.dart
- ticket_form_fields.dart

## God Nodes (most connected - your core abstractions)
1. `AuthProvider` - 115 edges
2. `TicketProvider` - 93 edges
3. `Win32Window` - 24 edges
4. `MessageHandler` - 12 edges
5. `Architecture Decision Records (ADRs) - Kitchen Maintenance` - 12 edges
6. `Application Flow & Architecture Map - Kitchen Maintenance` - 11 edges
7. `FlutterWindow` - 10 edges
8. `Create` - 10 edges
9. `WndProc` - 10 edges
10. `MessageHandler` - 9 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `AuthProvider`  [EXTRACTED]
  lib/main.dart → lib/providers/auth_provider.dart
- `build` --references--> `AuthProvider`  [EXTRACTED]
  lib/screens/authentication/login_screen.dart → lib/providers/auth_provider.dart
- `_handleSendOtp` --references--> `AuthProvider`  [EXTRACTED]
  lib/screens/authentication/login_screen.dart → lib/providers/auth_provider.dart
- `_handleVerifyOtp` --references--> `AuthProvider`  [EXTRACTED]
  lib/screens/authentication/login_screen.dart → lib/providers/auth_provider.dart
- `build` --references--> `AuthProvider`  [EXTRACTED]
  lib/screens/authentication/pending_approval_screen.dart → lib/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (108 total, 25 thin omitted)

### Community 0 - "ticket_detail_screen.dart"
Cohesion: 0.03
Nodes (76): _actionTakenController, _addSpareToTicket, _addToolToTicket, _afterUrls, _allAreas, _allEquipment, _availableSpares, _availableTools (+68 more)

### Community 1 - "boiler_log_screen.dart"
Cohesion: 0.03
Nodes (64): _addOperatorUI, _addReadingUI, _airPressCtrl, background, _boilerEndCtrl, _boilerStartCtrl, _bq1ClCtrl, _bq1ConCtrl (+56 more)

### Community 2 - "electrical_log_screen.dart"
Cohesion: 0.04
Nodes (53): background, _buildMetricRow, _buildTimeSlotCard, createState, _dailyLogId, date, _decor, dispose (+45 more)

### Community 3 - "equipment_master_screen.dart"
Cohesion: 0.04
Nodes (47): _activeZones, _allAreas, areaCtrl, areaFocusNode, build, _buildActiveFilterBadge, _buildChip, _buildInputField (+39 more)

### Community 4 - "testing_equipment_screen.dart"
Cohesion: 0.04
Nodes (47): _areaFocusNode, _areas, _areaSearchController, background, build, _calculateNextDueDate, _commissionDate, createState (+39 more)

### Community 5 - "more_screen.dart"
Cohesion: 0.06
Nodes (31): BuildContext, background, badgeColor, badgeText, build, _buildDetailRow, _buildEditTextField, _buildMenuCard (+23 more)

### Community 6 - "dg_log_screen.dart"
Cohesion: 0.04
Nodes (45): dart:typed_data, background, _batteryVoltageCtrl, _buildMetricRow, _buildSectionCard, _coolantTempCtrl, createState, _decor (+37 more)

### Community 7 - "spare_screen.dart"
Cohesion: 0.07
Nodes (29): background, _buildChip, _buildInputField, _buildSleekAutocomplete, _buildStatCard, createState, _criticalOnlyFilter, dispose (+21 more)

### Community 8 - "ro_checklist_screen.dart"
Cohesion: 0.05
Nodes (42): background, _checkIfAllAreChecked, _checklistDetails, createState, date, dispose, _executeDailyExport, _executeExport (+34 more)

### Community 9 - "ticket_provider.dart"
Cohesion: 0.04
Nodes (44): ../core/services/firebase_media_service.dart, dart:convert, DateTime? get, int get, _allowedKitchenIds, _areaFilter, _assignedToMeFilter, _completed (+36 more)

### Community 10 - "auth_provider.dart"
Cohesion: 0.08
Nodes (25): AuthState get, bool get, activeKitchenId, activeKitchenIds, _activeRole, _address, _assignedKitchens, AuthState (+17 more)

### Community 11 - "zone_screen.dart"
Cohesion: 0.05
Nodes (38): background, build, _buildChip, _buildStatCard, createState, dispose, existingZone, _fetchData (+30 more)

### Community 12 - "pm_schedule_screen.dart"
Cohesion: 0.06
Nodes (36): class, _achievedDate, background, CreateEditPMScheduleScreen, _CreateEditPMScheduleScreenState, createState, _currentUserId, _currentUserName (+28 more)

### Community 13 - "ticket_verification_screen.dart"
Cohesion: 0.04
Nodes (47): build, build, build, build, build, build, _buildReportTile, build (+39 more)

### Community 14 - "reports_screen.dart"
Cohesion: 0.06
Nodes (34): boiler_log_screen.dart, breakdown_report_screen.dart, critical_spares_report_screen.dart, dg_log_screen.dart, electrical_log_screen.dart, _allCategories, allowedReportCodes, background (+26 more)

### Community 15 - "pm_checklist_screen.dart"
Cohesion: 0.06
Nodes (32): _activities, _addEmptyActivityRow, background, _checklists, createState, dispose, _equipments, _executeExport (+24 more)

### Community 16 - "home_screen.dart"
Cohesion: 0.04
Nodes (47): _allowedReportCodes, _animation, _animationGeneration, _areListsEqual, _buildActionButton, _buildCollapsedActionRow, _buildCompactIconButton, _buildExpandedSearchRow (+39 more)

### Community 17 - "filter_bottom_sheet.dart"
Cohesion: 0.06
Nodes (32): DateTime?, _applyFilters, areaFocusNode, areaSearchController, authProv, build, buildChip, createState (+24 more)

### Community 18 - "my_application.cc"
Cohesion: 0.08
Nodes (28): file_selector_plugin, FlPluginRegistry, flutter_linux, FlView, GApplication, gboolean, gchar, gdkx (+20 more)

### Community 19 - "critical_spares_report_screen.dart"
Cohesion: 0.07
Nodes (27): _allRecords, _applyFilters, background, build, createState, CriticalSparesReportScreen, dispose, _executeExport (+19 more)

### Community 20 - "home_screen_backup.dart"
Cohesion: 0.07
Nodes (26): ../core/services/notification_service.dart, _allowedReportCodes, _buildStatCard, _checkAndFetchPermissions, createState, dispose, golden, HomeScreen (+18 more)

### Community 21 - "area_screen.dart"
Cohesion: 0.08
Nodes (25): _activeZones, AreaMasterScreen, _areas, background, build, _buildChip, _buildSleekAutocomplete, _buildStatCard (+17 more)

### Community 22 - "tools_screen.dart"
Cohesion: 0.08
Nodes (24): background, build, _buildChip, _buildDatePill, _buildInputField, _buildStatCard, createState, dispose (+16 more)

### Community 23 - "vendor_screen.dart"
Cohesion: 0.08
Nodes (24): background, build, _buildChip, _buildInputField, _buildStatCard, createState, dispose, _fetchData (+16 more)

### Community 24 - "user_management.dart"
Cohesion: 0.07
Nodes (27): _allKitchens, _availableReports, background, build, _buildUserCard, _buildUserList, _buildWebLayout, createState (+19 more)

### Community 25 - "breakdown_report_screen.dart"
Cohesion: 0.08
Nodes (23): background, BreakdownReportScreen, build, _completedTickets, createState, dispose, _fetchCompletedTickets, _focusNode (+15 more)

### Community 26 - "complaint_report_screen.dart"
Cohesion: 0.08
Nodes (23): _allTickets, background, build, ComplaintReportScreen, createState, dispose, _endDate, _fetchTickets (+15 more)

### Community 27 - "List"
Cohesion: 0.13
Nodes (15): background, build, createState, _fetchKitchens, golden, initState, _isLoading, KitchenMasterScreen (+7 more)

### Community 28 - "web_ticket_table.dart"
Cohesion: 0.05
Nodes (40): Animation, AnimationController, _AnimatedTableRow, _AnimatedTableRowState, _animation, animationGeneration, _buildDataCell, _buildHeaderCell (+32 more)

### Community 29 - "Application Flow & Architecture Map - Kitchen Maintenance"
Cohesion: 0.13
Nodes (14): 1. App Initialization & Remote Version Enforcement, 2. Authentication & Authorization State Machine, 3. Main Workspace & Kitchen Switching Flow, 4. Ticket Lifecycle & State Transitions, 5. Search, Filter, Sorting & Concurrency Sequencing, 6. Ticket Verification Flow (Zone-Based), 7. Media Upload & Storage Pipeline, 8. External Integrations & Push Notifications (+6 more)

### Community 30 - "StatefulWidget"
Cohesion: 0.09
Nodes (23): HomeScreen, _HomeTicketView, EquipmentMasterScreen, _EquipmentMasterScreenState, ZoneMasterScreen, _ZoneMasterScreenState, BoilerLogListScreen, _BoilerLogListScreenState (+15 more)

### Community 31 - "tools_tackles_screen.dart"
Cohesion: 0.10
Nodes (20): background, build, createState, dispose, _executeExport, _fetchData, initState, _isLoading (+12 more)

### Community 32 - "user_management_backup.dart"
Cohesion: 0.10
Nodes (20): FocusNode, _allKitchens, _availableReports, background, build, createState, dispose, _fetchData (+12 more)

### Community 33 - "win32_window.cpp"
Cohesion: 0.16
Nodes (15): dwmapi, wchar_t, Scale(), Create, Destroy, SetQuitOnClose, Show, UpdateTheme (+7 more)

### Community 34 - "master_equipment_report_screen.dart"
Cohesion: 0.11
Nodes (17): ../core/constants/api_constants.dart, int?, background, build, createState, EquipmentReportScreen, initState, _minimalDecor (+9 more)

### Community 35 - "Win32Window"
Cohesion: 0.16
Nodes (18): FlutterViewController, RECT, unique_ptr, FlutterWindow, flutter_controller_, OnCreate, OnDestroy, project_ (+10 more)

### Community 36 - "../providers/ticket_provider.dart"
Cohesion: 0.12
Nodes (15): firebase_options.dart, GlobalKey, build, initialize, initializeApp, load, main, navigatorKey (+7 more)

### Community 37 - "AuthProvider"
Cohesion: 0.11
Nodes (36): ChangeNotifier, AuthProvider, TicketProvider, build, _fetchKitchenZones, initState, build, _fetchKitchenZones (+28 more)

### Community 38 - "login_screen.dart"
Cohesion: 0.12
Nodes (16): build, _buildTextField, createState, dispose, golden, _handleSendOtp, _handleVerifyOtp, _isLoginMode (+8 more)

### Community 39 - "ADR-002: Dual Backend Architecture — Supabase (Data/Auth) + Firebase (Storage & FCM)"
Cohesion: 0.40
Nodes (5): ADR-002: Dual Backend Architecture — Supabase (Data/Auth) + Firebase (Storage & FCM), Consequences, Context, Decision, Status

### Community 40 - "State"
Cohesion: 0.10
Nodes (23): HomeScreen, _HomeTicketView, _HomeScreenState, _HomeTicketViewState, _HomeScreenState, _HomeTicketViewState, _AreaMasterScreenState, _SparesMasterScreenState (+15 more)

### Community 41 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.14
Nodes (13): app_links, file_selector_macos, firebase_core, firebase_messaging, firebase_storage, flutter_image_compress_macos, Foundation, package_info_plus (+5 more)

### Community 42 - "ADR-003: State Management Architecture via Provider"
Cohesion: 0.40
Nodes (5): ADR-003: State Management Architecture via Provider, Consequences, Context, Decision, Status

### Community 43 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.07
Nodes (28): FirebaseMessaging, _fcm, _handleNotificationClick, initNotifications, NotificationService, _saveTokenToDatabase, _supabase, _address (+20 more)

### Community 44 - "ticket_card.dart"
Cohesion: 0.15
Nodes (12): Color, build, color, _formatDate, _getPriorityInfo, _getStatusColor, isRight, label (+4 more)

### Community 45 - "ADR-001: Mobile & Web Platform Selection (Flutter & Dart)"
Cohesion: 0.40
Nodes (5): ADR-001: Mobile & Web Platform Selection (Flutter & Dart), Consequences, Context, Decision, Status

### Community 46 - "utils.cpp"
Cohesion: 0.19
Nodes (12): flutter_windows, _In_, _In_opt_, io, iostream, stdio, wWinMain(), string (+4 more)

### Community 47 - "web_ticket_card.dart"
Cohesion: 0.15
Nodes (12): build, color, _formatDate, _getInitials, _getPriorityInfo, _getStatusColor, label, name (+4 more)

### Community 48 - "windows/flutter/generated_plugin_registrant.cc"
Cohesion: 0.18
Nodes (9): app_links_plugin_c_api, file_selector_windows, firebase_core_plugin_c_api, firebase_storage_plugin_c_api, plugin_registry, PluginRegistry, share_plus_windows_plugin_c_api, url_launcher_windows (+1 more)

### Community 49 - "string"
Cohesion: 0.27
Nodes (7): dart_project, flutter_view_controller, functional, memory, string, vector, windows

### Community 50 - "MessageHandler"
Cohesion: 0.18
Nodes (10): generated_plugin_registrant, optional, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM (+2 more)

### Community 51 - "supabase_types.ts"
Cohesion: 0.18
Nodes (10): CompositeTypes, Constants, Database, DatabaseWithoutInternals, DefaultSchema, Enums, Json, Tables (+2 more)

### Community 52 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 53 - "firebase_media_service.dart"
Cohesion: 0.20
Nodes (9): FirebaseStorage, compressAndUpload, FirebaseMediaService, _storage, package:firebase_storage/firebase_storage.dart, package:flutter_image_compress/flutter_image_compress.dart, package:mime/mime.dart, package:path/path.dart (+1 more)

### Community 54 - "package:flutter/material.dart"
Cohesion: 0.20
Nodes (8): AppTheme, primaryBlue, build, currentStatus, TicketStatusBanner, package:flutter/material.dart, package:google_fonts/google_fonts.dart, static const

### Community 55 - "firebase_options.dart"
Cohesion: 0.20
Nodes (9): android, DefaultFirebaseOptions, ios, macos, web, windows, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart (+1 more)

### Community 56 - "StatelessWidget"
Cohesion: 0.17
Nodes (12): MyApp, PendingApprovalScreen, _EquipmentCard, _InfoItem, ForceUpdateScreen, ResponsiveSidebar, TicketCard, _UserDisplay (+4 more)

### Community 57 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 58 - "dart:io"
Cohesion: 0.22
Nodes (8): dart:io, ApiConstants, isProduction, _localIp, _railwayUrl, package:flutter_dotenv/flutter_dotenv.dart, static bool get, static String get

### Community 59 - "AppDelegate"
Cohesion: 0.25
Nodes (6): Any, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, AppDelegate, Bool, UIApplication

### Community 60 - "ios/RunnerTests/RunnerTests.swift"
Cohesion: 0.32
Nodes (5): Flutter, FlutterSceneDelegate, SceneDelegate, UIKit, XCTest

### Community 61 - "static const Color"
Cohesion: 0.22
Nodes (8): build, _buildTimeRow, _formatDate, navy, ticket, TicketTimeline, Map, static const Color

### Community 62 - "Point"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

### Community 63 - "FlutterMacOS"
Cohesion: 0.38
Nodes (3): Cocoa, FlutterMacOS, RunnerTests

### Community 64 - "AppDelegate"
Cohesion: 0.47
Nodes (4): FlutterAppDelegate, AppDelegate, Bool, NSApplication

### Community 65 - "Changelog & Project Changes - Kitchen Maintenance"
Cohesion: 0.12
Nodes (16): [2.0.0] - 2026-05-10, [2.1.2] - 2026-07-15, [2.2.0] - 2026-07-25, [2.2.1] - 2026-07-28, [2.2.3+9] - 2026-09-23, Added, Added, Added (+8 more)

### Community 66 - "RegisterGeneratedPlugins"
Cohesion: 0.40
Nodes (4): FlutterPluginRegistry, RegisterGeneratedPlugins(), MainFlutterWindow, NSWindow

### Community 70 - "app_update_wrapper.dart"
Cohesion: 0.14
Nodes (14): AppUpdateWrapper, _AppUpdateWrapperState, build, _checkForUpdates, child, createState, initState, _isLoading (+6 more)

### Community 74 - "Kitchen Maintenance App"
Cohesion: 0.17
Nodes (11): Building the Release App (Android APK), 📁 Directory Structure Overview, 🚀 Features, ⚙️ Getting Started, Installation, Kitchen Maintenance App, Prerequisites, 🔔 Smart Notification System (+3 more)

### Community 75 - "responsive_sidebar.dart"
Cohesion: 0.15
Nodes (12): IconData, activeIcon, build, icon, isFixed, items, label, navy (+4 more)

### Community 77 - "_AnimatedTicketCardState"
Cohesion: 0.67
Nodes (3): _AnimatedTicketCard, _AnimatedTicketCardState, SingleTickerProviderStateMixin

### Community 95 - "package:provider/provider.dart"
Cohesion: 0.15
Nodes (12): package:kitchen_maintanence/providers/auth_provider.dart, package:kitchen_maintanence/providers/ticket_provider.dart, package:kitchen_maintanence/screens/ticket_detail_screen.dart, package:provider/provider.dart, package:shared_preferences/shared_preferences.dart, activeRole, assignedKitchens, currentUserId (+4 more)

### Community 96 - "../providers/auth_provider.dart"
Cohesion: 0.40
Nodes (4): build, golden, navy, ../providers/auth_provider.dart

### Community 97 - "ADR-004: Ticket Lifecycle & Zone-Based Verification Model"
Cohesion: 0.40
Nodes (5): ADR-004: Ticket Lifecycle & Zone-Based Verification Model, Consequences, Context, Decision, Status

### Community 98 - "ADR-005: Telegram Bot Notification Threading & Railway Webhooks"
Cohesion: 0.40
Nodes (5): ADR-005: Telegram Bot Notification Threading & Railway Webhooks, Consequences, Context, Decision, Status

### Community 99 - "ADR-006: Responsive Hybrid Architecture for Desktop/Web and Mobile"
Cohesion: 0.40
Nodes (5): ADR-006: Responsive Hybrid Architecture for Desktop/Web and Mobile, Consequences, Context, Decision, Status

### Community 100 - "ADR-007: App Update Enforcement & Versioning Mechanism"
Cohesion: 0.40
Nodes (5): ADR-007: App Update Enforcement & Versioning Mechanism, Consequences, Context, Decision, Status

### Community 101 - "ADR-008: Official TAPF Brand Identity & Header Standardization"
Cohesion: 0.40
Nodes (5): ADR-008: Official TAPF Brand Identity & Header Standardization, Consequences, Context, Decision, Status

### Community 102 - "ADR-009: Dynamic Ticket Swapping & Staggered Transition Animations"
Cohesion: 0.40
Nodes (5): ADR-009: Dynamic Ticket Swapping & Staggered Transition Animations, Consequences, Context, Decision, Status

### Community 103 - "ADR-010: Asynchronous Query Concurrency Guards & Atomic State Resets"
Cohesion: 0.40
Nodes (5): ADR-010: Asynchronous Query Concurrency Guards & Atomic State Resets, Consequences, Context, Decision, Status

### Community 105 - "widget_test.dart"
Cohesion: 0.50
Nodes (3): package:flutter_test/flutter_test.dart, package:kitchen_maintanence/main.dart, main

### Community 106 - "spare_inventory_screen.dart"
Cohesion: 0.09
Nodes (23): FormState, _addQtyController, background, build, createState, _currentQty, dispose, _fetchInventoryData (+15 more)

### Community 107 - "ticket_form_fields.dart"
Cohesion: 0.09
Nodes (23): build, buildDescriptionField, buildDropdown, buildSleekAutocomplete, buildTextField, createState, ctrl, _DescriptionFieldWidget (+15 more)

## Knowledge Gaps
- **1228 isolated node(s):** `ApiConstants`, `isProduction`, `_railwayUrl`, `_localIp`, `FirebaseMediaService` (+1223 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1375 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **25 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthProvider` connect `AuthProvider` to `ticket_detail_screen.dart`, `boiler_log_screen.dart`, `electrical_log_screen.dart`, `equipment_master_screen.dart`, `testing_equipment_screen.dart`, `more_screen.dart`, `dg_log_screen.dart`, `spare_screen.dart`, `ro_checklist_screen.dart`, `auth_provider.dart`, `zone_screen.dart`, `pm_schedule_screen.dart`, `ticket_verification_screen.dart`, `reports_screen.dart`, `pm_checklist_screen.dart`, `home_screen.dart`, `filter_bottom_sheet.dart`, `critical_spares_report_screen.dart`, `home_screen_backup.dart`, `area_screen.dart`, `tools_screen.dart`, `vendor_screen.dart`, `user_management.dart`, `breakdown_report_screen.dart`, `complaint_report_screen.dart`, `StatefulWidget`, `tools_tackles_screen.dart`, `user_management_backup.dart`, `master_equipment_report_screen.dart`, `../providers/ticket_provider.dart`, `login_screen.dart`, `State`, `package:supabase_flutter/supabase_flutter.dart`, `StatelessWidget`, `_DGLogListScreenState`, `_PMScheduleScreenState`, `_TestingEquipmentScreenState`, `package:provider/provider.dart`, `../providers/auth_provider.dart`?**
  _High betweenness centrality (0.083) - this node is a cross-community bridge._
- **Why does `TicketProvider` connect `AuthProvider` to `ticket_detail_screen.dart`, `boiler_log_screen.dart`, `electrical_log_screen.dart`, `equipment_master_screen.dart`, `testing_equipment_screen.dart`, `more_screen.dart`, `dg_log_screen.dart`, `spare_screen.dart`, `ro_checklist_screen.dart`, `ticket_provider.dart`, `zone_screen.dart`, `pm_schedule_screen.dart`, `ticket_verification_screen.dart`, `reports_screen.dart`, `pm_checklist_screen.dart`, `home_screen.dart`, `filter_bottom_sheet.dart`, `critical_spares_report_screen.dart`, `home_screen_backup.dart`, `area_screen.dart`, `tools_screen.dart`, `vendor_screen.dart`, `user_management.dart`, `breakdown_report_screen.dart`, `complaint_report_screen.dart`, `StatefulWidget`, `tools_tackles_screen.dart`, `master_equipment_report_screen.dart`, `../providers/ticket_provider.dart`, `State`, `_DGLogListScreenState`, `_PMScheduleScreenState`, `_TestingEquipmentScreenState`, `package:provider/provider.dart`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **Why does `Win32Window` connect `Win32Window` to `win32_window.cpp`, `string`, `MessageHandler`, `MessageHandler`, `Point`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **What connects `ApiConstants`, `isProduction`, `_railwayUrl` to the rest of the system?**
  _1228 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `ticket_detail_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.025974025974025976 - nodes in this community are weakly interconnected._
- **Should `boiler_log_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03076923076923077 - nodes in this community are weakly interconnected._
- **Should `electrical_log_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._