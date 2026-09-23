# Changelog & Project Changes - Kitchen Maintenance

All notable changes, architectural milestones, and version updates to the **The Akshaya Patra Foundation (TAPF) Kitchen Maintenance System** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.2.3] - 2026-09-23

### Added
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
- **Knowledge Graph Integration**:
  - Integrated `graphify` knowledge graph tooling and agent rules for automated architectural mapping and navigation.

### Changed
- **Zone-Based Ticket Verification**:
  - Refactored ticket verification logic from blanket admin privileges to zone-based sign-off: supervisors can now verify tickets only for zones under their authority.
- **Scrollable App Update Screen**:
  - Refactored `AppUpdateScreen` layout with a scrollable container to prevent UI overflow on smaller handheld devices.

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
