# Changelog & Project Changes - Kitchen Maintenance

All notable changes, architectural milestones, and version updates to the **The Akshaya Patra Foundation (TAPF) Kitchen Maintenance System** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.2.5] - 2026-09-23

### Added
- **Desktop Web Layout for Ticket Verification Screen (`width > 800`)**:
  - Implemented desktop web interface for [`TicketVerificationScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_verification_screen.dart) matching the TAPF Web design system.
  - **75px Desktop Web Header**: Features official Akshaya Patra Foundation logo, interactive kitchen/facility dropdown selector, metric stat cards ("Total Pending", "Raised by Me", "Zone Sign-Off"), and asynchronous refresh controls.
  - **Verification Control Bar**: Integrated full-text search field, segmented tab switcher pills ("Raised by Me" and "Zone Sign-Off"), and horizontal zone filter chips.
  - **Desktop Verification Data Grid**: Fixed header row with 9 columns (`Ticket #`, `Title & Description`, `Zone & Area`, `Priority`, `Assigned Tech`, `Proof Media`, `Resolution Info`, `Audit Status`, `Action`), hover row state, left priority accent stripe, and inline action buttons ("Verify" and "Sign-Off").
- **In-Line Completion Proof Media Inspection**:
  - Query attached `ticket_media` using PostgREST `inFilter` to avoid join limitations.
  - Extracted resolution proof image (`upload_stage == 'COMPLETED'`) with fallback to any attached ticket media.
  - Rendered 44x44 (web table) and 54x54 (mobile cards) thumbnail previews with rounded borders and zoom badges.
  - Built interactive lightbox viewer dialog (`_openImageViewer`) featuring `InteractiveViewer` with pinch-to-zoom, pan, and 0.5x–4.0x zoom boundaries.
- **Mobile Verification Card Enhancements**:
  - Added completion proof photo thumbnail cards to `_buildRaiserCard` and `_buildZoneCard` with tap-to-enlarge inspection.
- **Architecture & System Documentation**:
  - Added [ADR-012](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/decisions.md#adr-012-desktop-web-layout--in-line-completion-proof-inspection-for-ticket-verification) to `decisions.md`.
  - Updated Section 6 of [`flow.md`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/flow.md) with desktop verification sequence diagram and table specification.

---

## [2.2.4] - 2026-09-23

### Added
- **Declarative URL Routing Architecture (`go_router`)**:
  - Replaced legacy imperative `Navigator.push` navigation throughout the entire application with declarative routing via `go_router` (v17.2.1).
  - Created [`AppRoutes`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/core/routes/app_routes.dart) containing canonical path constants and parameterized path generators (`AppRoutes.ticketDetailPath(id)`).
  - Built comprehensive router in [`AppRouter`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/core/routes/app_router.dart) with clean URL path strategy (`usePathUrlStrategy()`), removing hash `#` fragments for modern web browsing.
  - Implemented reactive redirect authentication guard listening to `AuthProvider` via `refreshListenable`, seamlessly handling splash loading, unauthenticated access redirects, pending approval lock screens, and authenticated home navigation.
  - Built parametric ticket detail route (`/tickets/:id`) supporting deep links, browser reloads, and `extra` state passing for zero-latency card-to-detail transitions.
  - Implemented custom 404 error page (`_ErrorScreen`) with direct return-home action.
  - Registered all Master Data routes (`/master/area`, `/master/zone`, `/master/equipment`, `/master/spares`, `/master/spares/inventory`, `/master/tools`, `/master/vendors`, `/master/users`) and Plant Maintenance log routes (`/reports/*`).
- **Architecture Documentation**:
  - Added [ADR-011](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/decisions.md#adr-011-declarative-url-routing--reactive-navigation-guard-architecture-go_router) to `decisions.md`.
  - Updated [`flow.md`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/flow.md) with initialization diagrams, URL route map table, and reactive redirect guard state machine.

### Changed
- **Root Application Configuration**:
  - Migrated `MaterialApp` in [`main.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/main.dart) to `MaterialApp.router`.
  - Integrated `AppUpdateWrapper` seamlessly via `MaterialApp.router(builder: (context, child) => AppUpdateWrapper(child: child!))`, ensuring remote version checks and force-update screens wrap all routes without breaking router state.
  - Updated notification click handler in `NotificationService` to push parameterized ticket detail routes.
  - Migrated card taps in `TicketCard`, `WebTicketCard`, and `WebTicketTable` to `context.push(AppRoutes.ticketDetailPath(ticketId), extra: ticket)`.
  - Migrated verification actions in `HomeScreen` and `TicketVerificationScreen` to `context.push(...)`.
  - Migrated More screen menu cards and Spares inventory buttons to declarative route navigation.
  - Migrated `ReportsScreen` to navigate all maintenance log screens via declarative `AppRoutes`.

---

## [2.2.3+9] - 2026-09-23

### Added
- **Ticket Swapping & State Transition Animations**:
  - Implemented physical position-swapping animations in [`HomeScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/home_screen.dart) via `_AnimatedTicketCard` (mobile) and [`WebTicketTable`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/widgets/web_ticket_table.dart) via `_AnimatedTableRow` (desktop/web view).
  - Added relative delta-index calculation tracking previous item positions across search, sort, and filter state changes.
  - Added physical elevation/scale lift (`+2.5%` mobile, `+1.5%` web) during swap glide to visually elevate moving cards/rows over/under other elements.
  - Tuned animation duration to `650ms` with `Curves.easeOutCubic` for a smooth, natural transition across both platforms.
  - Added dynamic golden loading indicator (`LinearProgressIndicator`) below the filter bar on mobile and below table headers on web during data fetching.
- **Web & Desktop Refresh Controls**:
  - Added dedicated refresh button in the Home AppBar actions next to verification with in-flight spinner state.
  - Added interactive refresh button in the [`WebTicketTable`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/widgets/web_ticket_table.dart) header column action slot.
  - Added "Refresh Data" action in the empty-state container when no tickets match active filters.
- **Official TAPF Branding**:
  - Integrated official Akshaya Patra Foundation corporate logo (`assets/icon/akshaya_patra_logo.png`) into the Home screen AppBar.
  - Sized cleanly with `BoxFit.contain` and wrapped adjacent kitchen selector in `Flexible` to eliminate mobile layout overflow.
- **Dedicated Ticket Verification Screen**:
  - Added [`TicketVerificationScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_verification_screen.dart) for quick sign-off and auditing of completed maintenance tasks.
  - Added pending verification count badge on the Home AppBar (`Icons.verified_outlined`) with live counter.
  - Added pending verification indicator to More screen navigation.
- **Equipment Master Enhancements**:
  - Implemented multi-criteria filtering, search, and zone-based sorting in [`EquipmentMasterScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/master/equipment_master_screen.dart).
  - Added zone selection modal and state binding.
- **User Profile Management**:
  - Added user profile edit functionality and responsive UI for updating user details.
- **Comprehensive Application Flow Documentation**:
  - Created [`flow.md`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/flow.md) documenting complete end-to-end architecture, user journeys, authentication state machine, ticket lifecycle states, search/filter concurrency sequencing diagrams, and master data hierarchies.
- **Knowledge Graph Integration**:
  - Integrated `graphify` knowledge graph tooling and agent rules for automated architectural mapping and navigation.

### Changed
- **Zone-Based Ticket Verification**:
  - Refactored ticket verification logic from blanket admin privileges to zone-based sign-off: supervisors can now verify tickets only for zones under their authority.
- **Scrollable App Update Screen**:
  - Refactored `AppUpdateScreen` layout with a scrollable container to prevent UI overflow on smaller handheld devices.
- **App Version Bump**:
  - Updated application build version to `2.2.3+9` in [`pubspec.yaml`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/pubspec.yaml).

### Fixed
- **Filter Reset Concurrency & Race Condition**:
  - Added atomic [`resetAllFilters()`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/providers/ticket_provider.dart) in `TicketProvider` and implemented `_fetchRequestId` concurrency guards.
  - Eliminated the race condition where `setSearchQuery` followed by `setFilters` silently dropped the query because `_isLoading` was true, leaving the screen stuck on "No Tickets Found" until a manual pull-to-refresh.
  - Enhanced empty state reset button to cleanly reset filters and reload tickets instantly with animated entrance.

---

## [2.2.1] - 2026-07-28

### Changed
- Bumped application build version to `2.2.1+8`.
- Cleaned up root directory by pruning legacy scripts and testing utilities.
- Improved error handling across Supabase client queries.

---

## [2.2.0] - 2026-07-25

### Added
- **Telegram Threaded Replies**:
  - Captured `telegram_message_id` on ticket creation in Supabase.
  - Subsequent ticket status changes (Work In Progress, Completed, Verified) are sent as threaded replies under the original alert in Telegram operations channels.
  - Created supporting Python backend webhook handler (`python_backend_snippet.md`).
- **Responsive Web & Tablet Layout**:
  - Added [`WebTicketTable`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/widgets/web_ticket_table.dart) for high-density desktop data management.
  - Added metric stat cards in the Home AppBar on web viewports.
  - Added responsive sidebar and web ticket cards.
- **Deployment & Caching Configurations**:
  - Configured Dockerfile to inject Railway environment variables directly.
  - Updated `nginx.conf` caching policy to disable caching for core Flutter web bundles (`main.dart.js`, `flutter.js`) to prevent stale assets after deployments.
  - Added Firebase Hosting configurations for web builds.

### Security
- Added `.env` to `.gitignore` to prevent secret leakage in version control.

---

## [2.1.2] - 2026-07-15

### Added
- **Firebase Cloud Messaging (FCM)**:
  - Integrated FCM for mobile push notifications on Android and iOS.
  - Added background and foreground push handlers in `NotificationService`.
- **Plant Maintenance Reporting Modules**:
  - Added Preventive Maintenance (PM) Schedule Screen ([`pm_schedule_screen.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/reports/pm_schedule_screen.dart)).
  - Added Electrical Log Screen ([`electrical_log_screen.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/reports/electrical_log_screen.dart)).
  - Added Boiler Log Screen ([`boiler_log_screen.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/reports/boiler_log_screen.dart)).
  - Added Reverse Osmosis (RO) Checklist Screen ([`ro_checklist_screen.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/reports/ro_checklist_screen.dart)).
  - Added Diesel Generator (DG) Log Screen ([`dg_log_screen.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/reports/dg_log_screen.dart)).
  - Added Breakdown Report Screen ([`breakdown_report_screen.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/reports/breakdown_report_screen.dart)).
  - Added Testing Equipment Screen ([`testing_equipment_screen.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/reports/testing_equipment_screen.dart)).
  - Added Critical Spares Report Screen ([`critical_spares_report_screen.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/reports/critical_spares_report_screen.dart)).
- **Tools & Spares Tracking**:
  - Implemented tools and tackles assignment system for ongoing tickets.
  - Added critical spare part tagging in asset management.

### Changed
- **Media Storage Migration**:
  - Migrated image and video upload pipeline from Supabase Storage buckets to **Firebase Cloud Storage** via [`FirebaseMediaService`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/core/services/firebase_media_service.dart) for enhanced upload resilience.

### Fixed
- Fixed date and time dropdown UI alignment.
- Fixed real-time reading reflection in equipment checklists.
- Nullified default values to prevent erroneous form submissions.

---

## [2.0.0] - 2026-05-10

### Added
- **Core Architecture & Role-Based Access Control (RBAC)**:
  - Multi-kitchen provisioning allowing users to be assigned to one or multiple central kitchens.
  - Role hierarchy: Admins, Technicians/Workers, and Supervisors.
  - Supabase database schema with Row Level Security (RLS).
- **Ticket Lifecycle Engine**:
  - Ticket creation with urgency levels, fault categories, and photo uploads.
  - Ticket status workflow: Open -> In Progress -> Completed -> Verified.
  - Interactive ticket timeline component.
- **Master Data Management**:
  - Kitchens, Zones, Areas, Equipment, Tools, and Vendors screens.
