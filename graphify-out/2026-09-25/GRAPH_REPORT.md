# Graph Report - kitchen_maintanence  (2026-09-25)

## Corpus Check
- 113 files · ~266,787 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 59 file(s) not represented in the graph (top: (none) 10, .plist 9, .xcconfig 8)

## Summary
- 2008 nodes · 2911 edges · 120 communities (95 shown, 25 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4ac48538`
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
- package:supabase_flutter/supabase_flutter.dart
- web_ticket_table.dart
- Application Flow & Architecture Map - Kitchen Maintenance
- State
- tools_tackles_screen.dart
- ticket_detail_white_screen_test.dart
- win32_window.cpp
- master_equipment_report_screen.dart
- Win32Window
- app_router.dart
- spare_inventory_screen.dart
- login_screen.dart
- ADR-002: Dual Backend Architecture — Supabase (Data/Auth) + Firebase (Storage & FCM)
- AuthProvider
- GeneratedPluginRegistrant.swift
- ADR-003: State Management Architecture via Provider
- app_routes.dart
- ticket_card.dart
- ADR-001: Mobile & Web Platform Selection (Flutter & Dart)
- utils.cpp
- web_ticket_card.dart
- windows/flutter/generated_plugin_registrant.cc
- video_player_screen.dart
- MessageHandler
- supabase_types.ts
- manifest.json
- firebase_media_service.dart
- package:google_fonts/google_fonts.dart
- string
- StatelessWidget
- MessageHandler
- dart:io
- AppDelegate
- ios/RunnerTests/RunnerTests.swift
- ADR-013: Worker Assignment Tracking & Activity Timeline Integration
- Point
- FlutterMacOS
- AppDelegate
- Changelog & Project Changes - Kitchen Maintenance
- RegisterGeneratedPlugins
- telegram-notify/index.ts
- MainActivity.java
- RunnerTests
- package:provider/provider.dart
- imports
- imports
- Runner-Bridging-Header.h
- Kitchen Maintenance App
- List
- BoilerLogFormScreen
- _AnimatedTicketCardState
- rules/graphify.md
- The Akshaya Patra Foundation (TAPF) — Kitchen Maintenance System
- app_update_wrapper.dart
- workflows/graphify.md
- ADR-012: Desktop Web Layout & In-Line Completion Proof Inspection for Ticket Verification
- GEMINI.md
- LaunchImage.imageset/README.md
- firebase-messaging-sw.js
- String?
- python_backend_snippet.md
- AppRoutes.ticketDetailPath
- build
- ADR-004: Ticket Lifecycle & Zone-Based Verification Model
- ADR-005: Telegram Bot Notification Threading & Railway Webhooks
- ADR-006: Responsive Hybrid Architecture for Desktop/Web and Mobile
- ADR-007: App Update Enforcement & Versioning Mechanism
- ADR-008: Official TAPF Brand Identity & Header Standardization
- ADR-009: Dynamic Ticket Swapping & Staggered Transition Animations
- ADR-010: Asynchronous Query Concurrency Guards & Atomic State Resets
- Architecture Decision Records (ADRs) - Kitchen Maintenance
- ADR-011: Declarative URL Routing & Reactive Navigation Guard Architecture (go_router)
- user_management_backup.dart
- main.dart
- static const Color
- widget_test.dart
- _AnimatedTableRowState
- _TicketVerificationScreenState
- firebase_options.dart
- ADR-014: Modular Card-Based UI Overhaul for Ticket Details & Defect Lifecycle
- ticket_form_fields.dart
- _WebVerificationTableRow
- package:flutter/material.dart
- MaterialPageRoute
- ADR-015: Video Upload & Verification Pipeline for Equipment Maintenance
- _ExpandableTableRow

## God Nodes (most connected - your core abstractions)
1. `AuthProvider` - 117 edges
2. `TicketProvider` - 94 edges
3. `Win32Window` - 24 edges
4. `Architecture Decision Records (ADRs) - Kitchen Maintenance` - 17 edges
5. `Changelog & Project Changes - Kitchen Maintenance` - 13 edges
6. `MessageHandler` - 12 edges
7. `Application Flow & Architecture Map - Kitchen Maintenance` - 11 edges
8. `FlutterWindow` - 10 edges
9. `Create` - 10 edges
10. `WndProc` - 10 edges

## Surprising Connections (you probably didn't know these)
- `initState` --references--> `AuthProvider`  [EXTRACTED]
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

## Communities (120 total, 25 thin omitted)

### Community 0 - "ticket_detail_screen.dart"
Cohesion: 0.02
Nodes (83): _actionTakenController, _addSpareToTicket, _addToolToTicket, _afterMedia, _afterUrls, _allAreas, _allEquipment, _availableSpares (+75 more)

### Community 1 - "boiler_log_screen.dart"
Cohesion: 0.03
Nodes (65): _addOperatorUI, _addReadingUI, _airPressCtrl, background, _boilerEndCtrl, _boilerStartCtrl, _bq1ClCtrl, _bq1ConCtrl (+57 more)

### Community 2 - "electrical_log_screen.dart"
Cohesion: 0.04
Nodes (54): background, _buildMetricRow, _buildTimeSlotCard, createState, _dailyLogId, date, _decor, dispose (+46 more)

### Community 3 - "equipment_master_screen.dart"
Cohesion: 0.04
Nodes (48): _activeZones, _allAreas, areaCtrl, areaFocusNode, build, _buildActiveFilterBadge, _buildChip, _buildInputField (+40 more)

### Community 4 - "testing_equipment_screen.dart"
Cohesion: 0.04
Nodes (48): _areaFocusNode, _areas, _areaSearchController, background, build, _calculateNextDueDate, _commissionDate, createState (+40 more)

### Community 5 - "more_screen.dart"
Cohesion: 0.09
Nodes (22): background, badgeColor, badgeText, build, _buildDetailRow, _buildEditTextField, _buildMenuCard, _buildSectionTitle (+14 more)

### Community 6 - "dg_log_screen.dart"
Cohesion: 0.04
Nodes (46): dart:typed_data, background, _batteryVoltageCtrl, _buildMetricRow, _buildSectionCard, _coolantTempCtrl, createState, _decor (+38 more)

### Community 7 - "spare_screen.dart"
Cohesion: 0.06
Nodes (30): background, build, _buildChip, _buildInputField, _buildSleekAutocomplete, _buildStatCard, createState, _criticalOnlyFilter (+22 more)

### Community 8 - "ro_checklist_screen.dart"
Cohesion: 0.05
Nodes (43): background, _checkIfAllAreChecked, _checklistDetails, createState, date, dispose, _executeDailyExport, _executeExport (+35 more)

### Community 9 - "ticket_provider.dart"
Cohesion: 0.04
Nodes (44): ../core/services/firebase_media_service.dart, dart:convert, DateTime? get, int get, _allowedKitchenIds, _areaFilter, _assignedToMeFilter, _completed (+36 more)

### Community 10 - "auth_provider.dart"
Cohesion: 0.08
Nodes (23): AuthState get, activeKitchenId, activeKitchenIds, _activeRole, _address, _assignedKitchens, AuthState, _checkExistingSession (+15 more)

### Community 11 - "zone_screen.dart"
Cohesion: 0.05
Nodes (39): background, build, _buildChip, _buildStatCard, createState, dispose, existingZone, _fetchData (+31 more)

### Community 12 - "pm_schedule_screen.dart"
Cohesion: 0.05
Nodes (37): class, _achievedDate, background, CreateEditPMScheduleScreen, _CreateEditPMScheduleScreenState, createState, _currentUserId, _currentUserName (+29 more)

### Community 13 - "ticket_verification_screen.dart"
Cohesion: 0.04
Nodes (49): adminColor, _allocatedZones, background, _buildCountBadge, _buildTicketList, _buildWebBody, _buildWebEmptyState, _buildWebHeaderCell (+41 more)

### Community 14 - "reports_screen.dart"
Cohesion: 0.08
Nodes (23): _allCategories, allowedReportCodes, background, build, _buildReportTile, _CategoryData, code, createState (+15 more)

### Community 15 - "pm_checklist_screen.dart"
Cohesion: 0.06
Nodes (36): _activities, _addEmptyActivityRow, background, _checklists, CreatePMChecklistScreen, _CreatePMChecklistScreenState, createState, dispose (+28 more)

### Community 16 - "home_screen.dart"
Cohesion: 0.04
Nodes (49): _allowedReportCodes, _animation, _animationGeneration, _areListsEqual, _buildActionButton, _buildCollapsedActionRow, _buildCompactIconButton, _buildExpandedSearchRow (+41 more)

### Community 17 - "filter_bottom_sheet.dart"
Cohesion: 0.06
Nodes (31): _applyFilters, areaFocusNode, areaSearchController, authProv, build, buildChip, createState, dispose (+23 more)

### Community 18 - "my_application.cc"
Cohesion: 0.08
Nodes (28): file_selector_plugin, FlPluginRegistry, flutter_linux, FlView, GApplication, gboolean, gchar, gdkx (+20 more)

### Community 19 - "critical_spares_report_screen.dart"
Cohesion: 0.07
Nodes (27): _allRecords, _applyFilters, background, build, createState, dispose, _executeExport, _fetchData (+19 more)

### Community 20 - "home_screen_backup.dart"
Cohesion: 0.07
Nodes (26): ../core/services/notification_service.dart, _allowedReportCodes, _buildStatCard, _checkAndFetchPermissions, createState, dispose, _fetchKitchenZones, golden (+18 more)

### Community 21 - "area_screen.dart"
Cohesion: 0.05
Nodes (40): FormState, _activeZones, _areas, background, build, _buildChip, _buildSleekAutocomplete, _buildStatCard (+32 more)

### Community 22 - "tools_screen.dart"
Cohesion: 0.08
Nodes (24): background, build, _buildChip, _buildDatePill, _buildInputField, _buildStatCard, createState, dispose (+16 more)

### Community 23 - "vendor_screen.dart"
Cohesion: 0.08
Nodes (24): background, build, _buildChip, _buildInputField, _buildStatCard, createState, dispose, _fetchData (+16 more)

### Community 24 - "user_management.dart"
Cohesion: 0.07
Nodes (26): _allKitchens, _availableReports, background, build, _buildUserCard, _buildUserList, _buildWebLayout, createState (+18 more)

### Community 25 - "breakdown_report_screen.dart"
Cohesion: 0.08
Nodes (23): background, build, _completedTickets, createState, dispose, _fetchCompletedTickets, _focusNode, _getActiveKitchenId (+15 more)

### Community 26 - "complaint_report_screen.dart"
Cohesion: 0.08
Nodes (24): DateTime?, _allTickets, background, build, createState, dispose, _endDate, _fetchTickets (+16 more)

### Community 27 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.17
Nodes (11): FirebaseMessaging, _fcm, initNotifications, NotificationService, _saveTokenToDatabase, _supabase, ../../main.dart, package:firebase_messaging/firebase_messaging.dart (+3 more)

### Community 28 - "web_ticket_table.dart"
Cohesion: 0.05
Nodes (36): Animation, AnimationController, _animation, animationGeneration, _buildDataCell, _buildHeaderCell, _buildHeaderRow, _buildPriorityCell (+28 more)

### Community 29 - "Application Flow & Architecture Map - Kitchen Maintenance"
Cohesion: 0.11
Nodes (17): 1. App Initialization, Declarative Routing & Remote Version Enforcement, 2. Authentication & Authorization State Machine (Reactive Navigation Guards), 3. Main Workspace & Kitchen Switching Flow, 4. Ticket Lifecycle & State Transitions, 5. Search, Filter, Sorting & Concurrency Sequencing, 6. Ticket Verification Flow & Dual-Auditor Lifecycle, 7. Media Upload & Storage Pipeline, 8. External Integrations & Push Notifications (+9 more)

### Community 30 - "State"
Cohesion: 0.06
Nodes (45): MyApp, _MyAppState, RegisterScreen, _RegisterScreenState, HomeScreen, _HomeTicketView, HomeScreen, _HomeTicketView (+37 more)

### Community 31 - "tools_tackles_screen.dart"
Cohesion: 0.10
Nodes (20): background, build, createState, dispose, _executeExport, _fetchData, _getActiveKitchenId, initState (+12 more)

### Community 32 - "ticket_detail_white_screen_test.dart"
Cohesion: 0.14
Nodes (13): bool get, package:kitchen_maintanence/providers/auth_provider.dart, package:kitchen_maintanence/providers/ticket_provider.dart, package:kitchen_maintanence/screens/ticket_detail_screen.dart, package:shared_preferences/shared_preferences.dart, String? get, activeRole, assignedKitchens (+5 more)

### Community 33 - "win32_window.cpp"
Cohesion: 0.16
Nodes (15): dwmapi, wchar_t, Scale(), Create, Destroy, SetQuitOnClose, Show, UpdateTheme (+7 more)

### Community 34 - "master_equipment_report_screen.dart"
Cohesion: 0.11
Nodes (17): ../core/constants/api_constants.dart, int?, background, build, createState, initState, _minimalDecor, _months (+9 more)

### Community 35 - "Win32Window"
Cohesion: 0.16
Nodes (18): FlutterViewController, RECT, unique_ptr, FlutterWindow, flutter_controller_, OnCreate, OnDestroy, project_ (+10 more)

### Community 36 - "app_router.dart"
Cohesion: 0.06
Nodes (32): app_routes.dart, build, rootNavigatorKey, NavigatorState, ../../screens/authentication/login_screen.dart, ../../screens/authentication/pending_approval_screen.dart, ../../screens/authentication/register_screen.dart, ../../screens/home_screen.dart (+24 more)

### Community 37 - "spare_inventory_screen.dart"
Cohesion: 0.09
Nodes (22): _addQtyController, background, build, createState, _currentQty, dispose, _fetchInventoryData, _formKey (+14 more)

### Community 38 - "login_screen.dart"
Cohesion: 0.13
Nodes (15): build, _buildTextField, createState, dispose, golden, _handleSendOtp, _handleVerifyOtp, _isLoginMode (+7 more)

### Community 39 - "ADR-002: Dual Backend Architecture — Supabase (Data/Auth) + Firebase (Storage & FCM)"
Cohesion: 0.40
Nodes (5): ADR-002: Dual Backend Architecture — Supabase (Data/Auth) + Firebase (Storage & FCM), Consequences, Context, Decision, Status

### Community 40 - "AuthProvider"
Cohesion: 0.10
Nodes (33): ChangeNotifier, HomeScreen, _HomeTicketView, createAppRouter, AuthProvider, TicketProvider, _HomeScreenState, _HomeTicketViewState (+25 more)

### Community 41 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.13
Nodes (14): app_links, file_selector_macos, firebase_core, firebase_messaging, firebase_storage, flutter_image_compress_macos, Foundation, package_info_plus (+6 more)

### Community 42 - "ADR-003: State Management Architecture via Provider"
Cohesion: 0.40
Nodes (5): ADR-003: State Management Architecture via Provider, Consequences, Context, Decision, Status

### Community 43 - "app_routes.dart"
Cohesion: 0.06
Nodes (35): AppRoutes, areaMaster, boilerLog, breakdownReport, complaintReport, criticalSpares, dgLog, electricalLog (+27 more)

### Community 44 - "ticket_card.dart"
Cohesion: 0.17
Nodes (11): ../core/routes/app_routes.dart, color, _formatDate, _getPriorityInfo, _getStatusColor, isRight, label, name (+3 more)

### Community 45 - "ADR-001: Mobile & Web Platform Selection (Flutter & Dart)"
Cohesion: 0.40
Nodes (5): ADR-001: Mobile & Web Platform Selection (Flutter & Dart), Consequences, Context, Decision, Status

### Community 46 - "utils.cpp"
Cohesion: 0.19
Nodes (12): flutter_windows, _In_, _In_opt_, io, iostream, stdio, wWinMain(), string (+4 more)

### Community 47 - "web_ticket_card.dart"
Cohesion: 0.15
Nodes (12): Color, color, _formatDate, _getInitials, _getPriorityInfo, _getStatusColor, label, name (+4 more)

### Community 48 - "windows/flutter/generated_plugin_registrant.cc"
Cohesion: 0.18
Nodes (9): app_links_plugin_c_api, file_selector_windows, firebase_core_plugin_c_api, firebase_storage_plugin_c_api, plugin_registry, PluginRegistry, share_plus_windows_plugin_c_api, url_launcher_windows (+1 more)

### Community 49 - "video_player_screen.dart"
Cohesion: 0.05
Nodes (44): BoxFit, dart:async, build, _buildBottomControls, _buildCenterControls, _buildErrorView, _buildTopBar, _buildVideoContent (+36 more)

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

### Community 54 - "package:google_fonts/google_fonts.dart"
Cohesion: 0.18
Nodes (10): build, currentStatus, _getPillBgColor, _getPillText, _getPillTextColor, _getStatusColor, _getStatusIcon, raisedTime (+2 more)

### Community 55 - "string"
Cohesion: 0.27
Nodes (7): dart_project, flutter_view_controller, functional, memory, string, vector, windows

### Community 56 - "StatelessWidget"
Cohesion: 0.18
Nodes (11): _SplashScreen, _EquipmentCard, _InfoItem, ForceUpdateScreen, ResponsiveSidebar, TicketCard, _UserDisplay, _UserColumn (+3 more)

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

### Community 61 - "ADR-013: Worker Assignment Tracking & Activity Timeline Integration"
Cohesion: 0.40
Nodes (5): ADR-013: Worker Assignment Tracking & Activity Timeline Integration, Consequences, Context, Decision, Status

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
Cohesion: 0.06
Nodes (33): [2.0.0] - 2026-05-10, [2.1.2] - 2026-07-15, [2.2.0] - 2026-07-25, [2.2.10] - 2026-09-25, [2.2.1] - 2026-07-28, [2.2.3+9] - 2026-09-23, [2.2.4] - 2026-09-23, [2.2.5] - 2026-09-24 (+25 more)

### Community 66 - "RegisterGeneratedPlugins"
Cohesion: 0.40
Nodes (4): FlutterPluginRegistry, RegisterGeneratedPlugins(), MainFlutterWindow, NSWindow

### Community 70 - "package:provider/provider.dart"
Cohesion: 0.10
Nodes (20): build, golden, navy, PendingApprovalScreen, _address, _amp, _availableKitchens, build (+12 more)

### Community 74 - "Kitchen Maintenance App"
Cohesion: 0.17
Nodes (11): Building the Release App (Android APK), 📁 Directory Structure Overview, 🚀 Features, ⚙️ Getting Started, Installation, Kitchen Maintenance App, Prerequisites, 🔔 Smart Notification System (+3 more)

### Community 75 - "List"
Cohesion: 0.15
Nodes (12): activeIcon, build, icon, isFixed, items, label, navy, onToggleFixed (+4 more)

### Community 79 - "The Akshaya Patra Foundation (TAPF) — Kitchen Maintenance System"
Cohesion: 0.06
Nodes (32): 1.1 Vision Statement, 1.2 Core Business Objectives (KPIs & OKRs), 1. Product Vision & Strategic Objectives, 2.1 Persona Specifications, 2.2 Granular Permissions Matrix, 2. User Personas & Role-Based Access Control (RBAC), 3.1 Technology Selection Breakdown, 3. System Architecture & Technology Stack (+24 more)

### Community 80 - "app_update_wrapper.dart"
Cohesion: 0.14
Nodes (14): AppUpdateWrapper, _AppUpdateWrapperState, build, _checkForUpdates, child, createState, initState, _isLoading (+6 more)

### Community 82 - "ADR-012: Desktop Web Layout & In-Line Completion Proof Inspection for Ticket Verification"
Cohesion: 0.40
Nodes (5): ADR-012: Desktop Web Layout & In-Line Completion Proof Inspection for Ticket Verification, Consequences, Context, Decision, Status

### Community 95 - "AppRoutes.ticketDetailPath"
Cohesion: 0.25
Nodes (8): _handleNotificationClick, build, _buildRaiserCard, _buildZoneCard, build, build, build, AppRoutes.ticketDetailPath

### Community 96 - "build"
Cohesion: 0.67
Nodes (3): build, AppRoutes.ticketNew, AppRoutes.ticketVerification

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

### Community 105 - "ADR-011: Declarative URL Routing & Reactive Navigation Guard Architecture (go_router)"
Cohesion: 0.40
Nodes (5): ADR-011: Declarative URL Routing & Reactive Navigation Guard Architecture (go_router), Consequences, Context, Decision, Status

### Community 106 - "user_management_backup.dart"
Cohesion: 0.10
Nodes (20): FocusNode, _allKitchens, _availableReports, background, build, createState, dispose, _fetchData (+12 more)

### Community 107 - "main.dart"
Cohesion: 0.12
Nodes (16): core/routes/app_router.dart, firebase_options.dart, GlobalKey, GoRouter, build, createState, initialize, initializeApp (+8 more)

### Community 108 - "static const Color"
Cohesion: 0.22
Nodes (8): build, _calculateDuration, _formatDate, navy, ticket, TicketTimeline, Map, static const Color

### Community 109 - "widget_test.dart"
Cohesion: 0.50
Nodes (3): package:flutter_test/flutter_test.dart, package:kitchen_maintanence/main.dart, main

### Community 110 - "_AnimatedTableRowState"
Cohesion: 0.67
Nodes (3): _AnimatedTableRow, _AnimatedTableRowState, SingleTickerProviderStateMixin

### Community 111 - "_TicketVerificationScreenState"
Cohesion: 0.67
Nodes (3): TicketVerificationScreen, _TicketVerificationScreenState, TickerProviderStateMixin

### Community 112 - "firebase_options.dart"
Cohesion: 0.20
Nodes (9): android, DefaultFirebaseOptions, ios, macos, web, windows, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart (+1 more)

### Community 113 - "ADR-014: Modular Card-Based UI Overhaul for Ticket Details & Defect Lifecycle"
Cohesion: 0.40
Nodes (5): ADR-014: Modular Card-Based UI Overhaul for Ticket Details & Defect Lifecycle, Consequences, Context, Decision, Status

### Community 114 - "ticket_form_fields.dart"
Cohesion: 0.09
Nodes (23): IconData, build, buildDescriptionField, buildDropdown, buildSleekAutocomplete, buildTextField, createState, ctrl (+15 more)

### Community 116 - "package:flutter/material.dart"
Cohesion: 0.40
Nodes (4): AppTheme, primaryBlue, package:flutter/material.dart, static const

### Community 117 - "MaterialPageRoute"
Cohesion: 0.17
Nodes (12): build, build, build, build, build, build, build, _buildImageUploader (+4 more)

### Community 118 - "ADR-015: Video Upload & Verification Pipeline for Equipment Maintenance"
Cohesion: 0.40
Nodes (5): ADR-015: Video Upload & Verification Pipeline for Equipment Maintenance, Consequences, Context, Decision, Status

## Knowledge Gaps
- **1386 isolated node(s):** `ApiConstants`, `isProduction`, `_railwayUrl`, `_localIp`, `rootNavigatorKey` (+1381 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1549 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **25 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthProvider` connect `AuthProvider` to `ticket_detail_screen.dart`, `boiler_log_screen.dart`, `electrical_log_screen.dart`, `equipment_master_screen.dart`, `testing_equipment_screen.dart`, `more_screen.dart`, `dg_log_screen.dart`, `spare_screen.dart`, `ro_checklist_screen.dart`, `auth_provider.dart`, `zone_screen.dart`, `pm_schedule_screen.dart`, `ticket_verification_screen.dart`, `reports_screen.dart`, `pm_checklist_screen.dart`, `home_screen.dart`, `filter_bottom_sheet.dart`, `critical_spares_report_screen.dart`, `home_screen_backup.dart`, `area_screen.dart`, `tools_screen.dart`, `vendor_screen.dart`, `user_management.dart`, `breakdown_report_screen.dart`, `complaint_report_screen.dart`, `State`, `tools_tackles_screen.dart`, `ticket_detail_white_screen_test.dart`, `master_equipment_report_screen.dart`, `app_router.dart`, `login_screen.dart`, `package:provider/provider.dart`, `AppRoutes.ticketDetailPath`, `build`, `user_management_backup.dart`, `main.dart`, `_TicketVerificationScreenState`, `MaterialPageRoute`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **Why does `TicketProvider` connect `AuthProvider` to `ticket_detail_screen.dart`, `boiler_log_screen.dart`, `electrical_log_screen.dart`, `equipment_master_screen.dart`, `testing_equipment_screen.dart`, `more_screen.dart`, `dg_log_screen.dart`, `spare_screen.dart`, `ro_checklist_screen.dart`, `ticket_provider.dart`, `zone_screen.dart`, `pm_schedule_screen.dart`, `ticket_verification_screen.dart`, `reports_screen.dart`, `pm_checklist_screen.dart`, `home_screen.dart`, `filter_bottom_sheet.dart`, `critical_spares_report_screen.dart`, `home_screen_backup.dart`, `area_screen.dart`, `tools_screen.dart`, `vendor_screen.dart`, `user_management.dart`, `breakdown_report_screen.dart`, `complaint_report_screen.dart`, `State`, `tools_tackles_screen.dart`, `ticket_detail_white_screen_test.dart`, `master_equipment_report_screen.dart`, `AppRoutes.ticketDetailPath`, `build`, `main.dart`, `_TicketVerificationScreenState`, `MaterialPageRoute`?**
  _High betweenness centrality (0.043) - this node is a cross-community bridge._
- **Why does `Win32Window` connect `Win32Window` to `win32_window.cpp`, `MessageHandler`, `string`, `MessageHandler`, `Point`?**
  _High betweenness centrality (0.043) - this node is a cross-community bridge._
- **What connects `ApiConstants`, `isProduction`, `_railwayUrl` to the rest of the system?**
  _1386 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `ticket_detail_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.023809523809523808 - nodes in this community are weakly interconnected._
- **Should `boiler_log_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.030303030303030304 - nodes in this community are weakly interconnected._
- **Should `electrical_log_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03636363636363636 - nodes in this community are weakly interconnected._