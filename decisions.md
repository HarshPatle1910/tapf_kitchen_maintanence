# Architecture Decision Records (ADRs) - Kitchen Maintenance

This document tracks key architectural, technical, and structural decisions made in the development and evolution of the **The Akshaya Patra Foundation (TAPF) Kitchen Maintenance System**.

---

## Index of Decisions

- [ADR-001: Mobile & Web Platform Selection (Flutter & Dart)](#adr-001-mobile--web-platform-selection-flutter--dart)
- [ADR-002: Dual Backend Architecture — Supabase (Data/Auth) + Firebase (Storage & FCM)](#adr-002-dual-backend-architecture--supabase-dataauth--firebase-storage--fcm)
- [ADR-003: State Management Architecture via Provider](#adr-003-state-management-architecture-via-provider)
- [ADR-004: Ticket Lifecycle & Zone-Based Verification Model](#adr-004-ticket-lifecycle--zone-based-verification-model)
- [ADR-005: Telegram Bot Notification Threading & Railway Webhooks](#adr-005-telegram-bot-notification-threading--railway-webhooks)
- [ADR-006: Responsive Hybrid Architecture for Desktop/Web and Mobile](#adr-006-responsive-hybrid-architecture-for-desktopweb-and-mobile)
- [ADR-007: App Update Enforcement & Versioning Mechanism](#adr-007-app-update-enforcement--versioning-mechanism)
- [ADR-008: Official TAPF Brand Identity & Header Standardization](#adr-008-official-tapf-brand-identity--header-standardization)

---

## ADR-001: Mobile & Web Platform Selection (Flutter & Dart)

### Status
**Accepted**

### Context
Kitchen maintenance supervisors, technicians, and central plant administrators need access to real-time maintenance logs across diverse devices:
- Floor technicians use low-to-mid tier Android mobile phones in kitchen environments.
- Plant supervisors and kitchen directors access the portal via desktop web browsers and tablets.
- Maintaining separate web and native mobile codebases would significantly increase development, testing, and maintenance costs.

### Decision
Adopt **Flutter (Dart)** as the single multi-platform framework targeting Android, iOS, and Web.

### Consequences
- **Positive:**
  - Unified business logic, models, and state controllers shared between mobile and web.
  - Consistent visual design language and theme across all devices.
  - Native performance on mobile devices with hardware camera and gallery access for media capture.
- **Negative:**
  - Web initial bundle size is larger than vanilla web frameworks.
  - Requires responsive layout branching (`isWeb`) to accommodate desktop data density alongside mobile tactile card interfaces.

---

## ADR-002: Dual Backend Architecture — Supabase (Data/Auth) + Firebase (Storage & FCM)

### Status
**Accepted** (Supabase Storage migrated to Firebase Cloud Storage in v2.1.2)

### Context
The application requires:
1. Relational data modeling (kitchens, zones, areas, equipment, tools, tickets, status logs, users).
2. Strong row-level security (RLS) ensuring users only access kitchens they are assigned to.
3. High-throughput media uploading (photos/videos of equipment breakdowns and repair proofs).
4. Reliable push notification delivery to Android and iOS mobile devices.

### Decision
1. **Supabase (PostgreSQL + PostgREST + GoTrue Auth):**
   - Hosts all relational tables (`tickets`, `m_kitchen`, `m_zone`, `m_area`, `m_equipment`, `users`, etc.).
   - Enforces database-level Row Level Security (RLS).
   - Manages user sessions, authentication, and custom RPC functions.
2. **Firebase Cloud Storage:**
   - Handles ticket media attachments (images/videos) instead of Supabase Storage buckets to ensure high availability, automatic scaling, and fast CDN delivery for field technicians.
3. **Firebase Cloud Messaging (FCM):**
   - Handles native mobile push notifications.

### Consequences
- **Positive:**
  - Relational consistency with PostgreSQL integrity, constraints, and joins.
  - Dedicated storage bandwidth and media pipelines that do not burden database connections.
  - Industry-standard FCM push notifications on Android/iOS.
- **Negative:**
  - Requires dual SDK initialization and credentials (`SupabaseConfig` and `firebase_options.dart`).

---

## ADR-003: State Management Architecture via Provider

### Status
**Accepted**

### Context
State needs to be shared across many screens:
- Current active kitchen selection and kitchen switching.
- Filter and search parameters (status, priority, zone, area, sort order).
- Paginated ticket data, loading states, and live ticket counters (Total, To Do, WIP, Done, Verified).
- User profile, assigned kitchens, and permission roles.

### Decision
Use **Provider** (`ChangeNotifierProvider`) with domain-scoped providers:
- `AuthProvider`: Manages auth state, current profile, role capabilities, and assigned kitchens.
- `TicketProvider`: Manages ticket querying, pagination, metric counters, live filtering, and status updates.

### Consequences
- **Positive:**
  - Minimal boilerplate compared to BLoC or Redux.
  - Seamless lifecycle integration with Flutter's widget tree.
  - Clear separation of UI presentation from backend API requests.
- **Negative:**
  - Providers must be carefully notified to avoid excessive full-tree widget rebuilds.

---

## ADR-004: Ticket Lifecycle & Zone-Based Verification Model

### Status
**Accepted** (Refactored in v2.2.3 from blanket admin verification to zone-based sign-off)

### Context
Previously, any admin could verify any completed ticket across any area. In large central kitchens, this caused accountability issues where plant engineers signed off on specialized electrical or boiler maintenance without domain or zone authority.

### Decision
Implement a multi-tier lifecycle:
$$\text{TO DO} \longrightarrow \text{IN PROGRESS (WIP)} \longrightarrow \text{COMPLETED} \longrightarrow \text{VERIFIED}$$
- **Verification Logic:** Refactored from global admin privileges to **zone-based verification**. A user can sign off on tickets only within zones they are specifically assigned or authorized to oversee.
- **Pending Verification Queue:** Dedicated `TicketVerificationScreen` and dynamic badge counters on the Home AppBar and More tab highlight tickets awaiting sign-off.

### Consequences
- **Positive:**
  - True operational accountability for plant maintenance.
  - Streamlined supervisor workflow dedicated to closing out finished tasks.
- **Negative:**
  - Requires assigning users to specific zones/kitchens during user provisioning.

---

## ADR-005: Telegram Bot Notification Threading & Railway Webhooks

### Status
**Accepted**

### Context
Field maintenance and plant managers rely on Telegram groups for real-time alerts. When tickets are raised, updated, completed, and verified, disconnected Telegram messages flooded group chats, making it difficult to trace a ticket's complete history.

### Decision
1. When a ticket is created (`RAISED`), store the Telegram message ID returned by the bot in the `tickets` table as `telegram_message_id`.
2. For subsequent updates (`IN PROGRESS`, `COMPLETED`, `VERIFIED`), send the notification as a **threaded reply** using `reply_parameters: { "message_id": telegram_message_id }`.
3. Orchestrate notification dispatch via a FastAPI service hosted on Railway, interfacing between Supabase and Telegram Bot API.

### Consequences
- **Positive:**
  - All status updates, photos, and verification notes for a ticket remain neatly nested under the original ticket alert in Telegram.
  - Easy audit trail directly in the operations chat room.
- **Negative:**
  - If the initial message fails to post or record an ID, subsequent updates fall back to standalone messages.

---

## ADR-006: Responsive Hybrid Architecture for Desktop/Web and Mobile

### Status
**Accepted**

### Context
Floor workers operate handheld mobile devices where large tabular data is difficult to navigate. Conversely, maintenance heads in corporate or plant offices review hundreds of tickets daily on 1080p+ widescreen monitors.

### Decision
Implement adaptive conditional rendering based on platform and screen width:
- **Mobile (`!isWeb`):**
  - Sliver-based `CustomScrollView` with swipe-to-refresh.
  - Vertical `TicketCard` items optimized for touch targets.
  - Bottom sheets for complex filtering (`FilterBottomSheet`) and sorting.
- **Web / Desktop (`isWeb`):**
  - Full-width `WebTicketTable` data grid with inline status pills.
  - Horizontal metric cards in the AppBar (`_buildStatCard`).
  - Inline search, sorting, and filter bars.

### Consequences
- **Positive:**
  - Native feel on smartphones without sacrificing desktop productivity.
  - Single codebase and shared business logic.
- **Negative:**
  - Requires testing UI changes across multiple screen resolutions.

---

## ADR-007: App Update Enforcement & Versioning Mechanism

### Status
**Accepted**

### Context
When database schemas or API contracts change in production, technicians with outdated installed APKs can experience app crashes or corrupt ticket records.

### Decision
Implement `AppUpdateWrapper` that checks client build number against the remote minimum supported version:
- If an update is required, present a scrollable `AppUpdateScreen` preventing user interaction until updated.
- Provide direct download links / OTA APK installation links.

### Consequences
- **Positive:**
  - Zero downtime caused by deprecated client schema mismatches.
  - Clean upgrade path for plant personnel.
- **Negative:**
  - Requires updating remote version thresholds upon releasing major schema migrations.

---

## ADR-008: Official TAPF Brand Identity & Header Standardization

### Status
**Accepted**

### Context
The Home screen AppBar previously displayed a small generic launcher icon inside a tinted square container. For official organizational presentation and user clarity, the official Akshaya Patra Foundation mark was required.

### Decision
Standardize the Home screen AppBar header with the official Akshaya Patra Foundation logo (`assets/icon/akshaya_patra_logo.png`):
- Render using `BoxFit.contain` with a proportional height of `42px` directly against the clean white AppBar.
- Wrap the adjacent kitchen selection dropdown in a `Flexible` container to prevent any `RenderFlex` overflow on compact devices.

### Consequences
- **Positive:**
  - Professional, organization-aligned branding.
  - Responsive alignment with kitchen selector on mobile and web viewports.
