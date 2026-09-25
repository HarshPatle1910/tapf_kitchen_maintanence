# Changelog & Project Changes - Kitchen Maintenance

All notable changes, architectural milestones, and version updates to the **The Akshaya Patra Foundation (TAPF) Kitchen Maintenance System** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.10] - 2026-09-25

### Fixed
- **Undefined Identifier in Media Viewer (`_ticketData`)**:
  - Corrected reference in `_openMediaViewer` within [`ticket_detail_screen.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_detail_screen.dart) from `_ticketData` to `_localTicket` to properly display the ticket number in [`VideoPlayerScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/video_player_screen.dart).
- **Video Streaming Hardening & Diagnostics**:
  - Enhanced [`VideoPlayerScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/video_player_screen.dart) to detect un-compiled native plugins (`MissingPluginException`), display actionable restart prompts, and cleanly dispose previous controllers when retrying.
  - Added user agent headers and safe URI encoding/fallback for remote streaming.
  - Added "Open in Browser" action alongside "Open in System Player".
  - Configured missing video permissions (`READ_MEDIA_VIDEO`, `RECORD_AUDIO`) in [`AndroidManifest.xml`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/android/app/src/main/AndroidManifest.xml) and `NSAppTransportSecurity` in [`Info.plist`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/ios/Runner/Info.plist).

### Added
- **Dedicated In-App Video Player Screen (`VideoPlayerScreen`)**:
  - Implemented [`VideoPlayerScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/video_player_screen.dart) with full playback capabilities powered by `video_player` for both remote cloud media (Firebase Storage) and local camera/gallery video captures.
  - **Full Playback Controls**:
    - Central animated Play/Pause/Replay with pulsing glow.
    - Quick 10-second skip forward (`+10s`) and rewind (`-10s`) actions.
    - Smooth interactive scrubber timeline with elapsed time and total duration readouts.
    - Playback speed controller (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
    - Audio mute / unmute toggle.
    - Aspect ratio mode switch (`BoxFit.contain` vs `BoxFit.cover`).
    - Smart auto-hiding overlay after 4 seconds of inactivity.
  - **Header & Sharing**:
    - Top bar showing contextual ticket details and stage information.
    - Integrated sharing via `Share.share` / `Share.shareXFiles`.
    - Fallback button to open in native device media player.
  - **Resilient Error State**:
    - In-app error card with retry button and one-tap launch to system video player if video cannot be decoded.
  - **Routing & Integration**:
    - Added `AppRoutes.videoPlayer` in [`app_routes.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/core/routes/app_routes.dart) and registered route in [`app_router.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/core/routes/app_router.dart).
    - Connected in [`TicketDetailScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_detail_screen.dart) for both selected un-submitted videos and uploaded before/after verification media.
    - Connected in [`TicketVerificationScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_verification_screen.dart) for completion video proofs.

---

## [2.2.9] - 2026-09-25

### Added
- **Video Upload for Visual Verification**:
  - Added support for capturing and uploading diagnostic video clips for both initial issue reports (ticket raising) and completion verification proof in [`TicketDetailScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_detail_screen.dart).
  - **4-Option Media Picker**: Expanded media picker modal into "Add Media (Photos & Videos)" offering:
    1. *Take a Photo (Camera)*
    2. *Choose Photos from Gallery*
    3. *Record a Video (Camera)* (max 3 minutes duration, 50MB file size limit)
    4. *Choose Video from Gallery* (50MB file size limit)
  - **Automated Video Compression**: Integrated client-side video compression using `VideoCompress.compressVideo(quality: VideoQuality.MediumQuality)` on non-web platforms, reducing network upload payload and Firebase storage consumption while preserving diagnostic clarity.
  - **Firebase & Supabase Pipeline**: Uploads video files to Firebase Storage (`PMT_Tickets/<ticket_no>/<stage>/`) with appropriate video MIME types (`video/mp4`, `video/quicktime`), recording `media_type: 'video'` in the Supabase `ticket_media` table.
  - **Visual Verification Gallery with Video Badges**: Enhanced both `BEFORE (ISSUE RAISED)` and `AFTER (WORK COMPLETED)` galleries to show video items with a dark slate background, centered play icon (`Icons.play_circle_filled_rounded`), and uppercase `"VIDEO"` badge.
  - **Dynamic Media Counters**: Replaced static photo counters with intelligent composite labels (e.g., `2 Photos, 1 Video`, `1 Video`, `3 Photos`).
  - **Local & Remote Video Playback**:
    - Unsaved / picked videos preview directly on tap via native system player using `OpenFilex`.
    - Uploaded remote videos open a bottom-sheet playback dialog providing one-tap options to play in the device's native media player (`launchUrl` external application) or browser.
  - **Updated Form Validation Messages**: Updated snackbar prompts in `_submitNewTicket` and `_updateExistingTicket` to clearly request "photos or videos".
- **Architecture Documentation**:
  - Added [ADR-015](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/decisions.md#adr-015-video-upload--verification-pipeline-for-equipment-maintenance) to `decisions.md`.
  - Updated Section 4 of [`flow.md`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/flow.md) to reflect video verification capabilities.

---

## [2.2.8] - 2026-09-25

### Fixed
- **UI Overflow Guards**:
  - Fixed right-boundary layout overflow (`RIGHT OVERFLOWED BY 14 PIXELS`) in the Visual Verification card header on compact viewports by wrapping the title row in `Expanded` and `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))` alongside the timestamp chip.
  - Constrained title and dynamic duration pill rows in [`TicketStatusBanner`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/widgets/ticket/ticket_status_banner.dart) and [`TicketTimeline`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/widgets/ticket/ticket_timeline.dart) with `Flexible` and `TextOverflow.ellipsis`.

### Changed
- **Removed Photo Card Text Overlay**:
  - Removed "Wheel Fracture" and other placeholder tag overlays from the Visual Verification section in [`TicketDetailScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_detail_screen.dart). Photos now render cleanly within rounded bounds (`BorderRadius.circular(11)`) with full tap-to-zoom support.
- **Select Button Visual Affordance & Identifiers**:
  - Enhanced all select dropdown buttons (Area, Equipment, Category, Priority, and Worker Assignment) and text input fields with a prominent, distinct border (`Color(0xFF94A3B8)`, `1.2px` stroke) and clean white fill so users can immediately distinguish interactive select areas from background cards.
- **Dropdown List Menus & Autocomplete Standardization**:
  - Standardized all dropdown and autocomplete popup lists across [`TicketDetailScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_detail_screen.dart), [`TicketFormFields`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/widgets/ticket/ticket_form_fields.dart), and [`TicketVerificationScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_verification_screen.dart) to feature smooth rounded corners (`borderRadius: BorderRadius.circular(12)`) and a bounded maximum height of `400px` (`menuMaxHeight: 400`, `constraints: BoxConstraints(maxHeight: 400)`).

---

## [2.2.7] - 2026-09-25

### Changed
- **Ticket Details & Raise Issue Screen UI Overhaul**:
  - Revamped [`TicketDetailScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_detail_screen.dart) and its components to match the modern enterprise mobile card mockup with 100% preservation of existing business logic, validation, state machines, and API interactions.
  - **Card 1: Status & Raised On**: Updated [`TicketStatusBanner`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/widgets/ticket/ticket_status_banner.dart) with amber squircle checkmark icon, "CURRENT STATUS" uppercase caption, bold status with accent dot, status pill badge (e.g. "Resolved"), divider, and integrated "Raised On:" timestamp row.
  - **Card 2: Activity Timeline**: Overhauled [`TicketTimeline`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/widgets/ticket/ticket_timeline.dart) to feature a connected vertical line layout, clock header with dynamic "Total duration: Xh Ym" calculation, circular step nodes (Worker Assigned, Work Started, Work Completed, Admin Verified, Raiser Verified, Verified & Closed), and right-aligned timestamp pill chips.
  - **Card 3: Visual Verification**: Restructured media gallery into a dedicated card with squircle camera icon, header timestamp pill, uppercase `• BEFORE (ISSUE RAISED)` and `• AFTER (WORK COMPLETED)` photo sections with dark semi-transparent pill tags ("Wheel Fracture", "Track Assembly", "Replaced Wheel", "Operational Test"), centered circular green down arrow (`↓`) on a dashed divider, and integrated completion photo uploader.
  - **Card 4: Ticket Information**: Redesigned form fields into clean rounded containers with dedicated squircle icons:
    - Area container with blue squircle location icon, "SELECT AREA *" caption, and up-down dropdown indicator.
    - Equipment container with amber squircle cog icon, "EQUIPMENT NAME *" caption, and right-aligned equipment code pill badge (e.g. `EQ-CH-C9`).
    - Description container with `T` icon, "DESCRIPTION *" caption, live word counter (`X / 200 words`), and multiline text.
    - 2-Column row with `PRIORITY *` (amber border `#FDE68A`, colored status dot) and `CATEGORY *` container.
  - **Card 5: Work Details & Assignment**:
    - Cause of issue in a soft crimson container (`#FEF2F2`, border `#FECACA`, warning icon).
    - Action taken in a soft emerald container (`#F0FDF4`, border `#BBF7D0`, handyman icon).
    - 2-Column dashed cards for "TOOLS CHECKED OUT" and "SPARES USED" with interactive bottom-sheet addition dialogs (`_showAddToolDialog`, `_showAddSpareDialog`) for technicians.
    - Verification sign-off container with verifier avatar initials circle, "Maintenance Lead", "Verified by Plant Supervisor", and green pill "✓ Sign-off Complete".
    - Admin worker assignment dropdown with engineering squircle badge.

---

## [2.2.6] - 2026-09-25

### Added
- **Worker Assignment Tracking (`assigned_to_time`)**:
  - Added `assigned_to_time TIMESTAMPTZ` column to the `tickets` table in Supabase via migration `20260925104000_add_assigned_to_time.sql`.
  - Backfilled historical assignment timestamps for 100% of existing assigned tickets in Supabase using `ticket_status_history` (`to_status = 'ASSIGNED'`), falling back to `repair_start_time` and `ticket_raised_time`.
  - Configured PostgreSQL trigger `trg_set_ticket_assigned_to_time` to automatically record `assigned_to_time = NOW()` whenever a worker is assigned or changed.
- **Worker Assignment in Activity Timeline**:
  - Updated [`TicketTimeline`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/widgets/ticket/ticket_timeline.dart) to show "Worker Assigned" as the primary stage in the ticket details Activity Timeline with an amber engineering badge (`Icons.engineering_rounded`, `Color(0xFFD97706)`).
  - Enhanced `_buildTimeRow` with subtitle support to display the assigned technician's name directly beneath "Worker Assigned" with zero layout overflow.
  - Updated [`TicketDetailScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/ticket_detail_screen.dart) to synchronously persist `assigned_to_time` and update the in-memory ticket map upon worker selection.
- **Architecture Documentation**:
  - Added [ADR-013](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/decisions.md#adr-013-worker-assignment-tracking--activity-timeline-integration) to `decisions.md`.
  - Updated Section 4 of [`flow.md`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/flow.md) with technician assignment tracking requirements.

---

## [2.2.5] - 2026-09-24

### Added
- **Product Requirements Document (`PRD.md`)**:
  - Authored comprehensive Product Requirements Document defining TAPF kitchen maintenance operations, system objectives, personas, RBAC matrix, architecture, module specifications, NFRs, ER diagram, and release roadmap.
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
