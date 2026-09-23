# Application Flow & Architecture Map - Kitchen Maintenance

This document provides a comprehensive end-to-end breakdown of the user flows, data lifecycles, and architectural component interactions for the **The Akshaya Patra Foundation (TAPF) Kitchen Maintenance System**.

---

## Table of Contents
1. [App Initialization & Remote Version Enforcement](#1-app-initialization--remote-version-enforcement)
2. [Authentication & Authorization State Machine](#2-authentication--authorization-state-machine)
3. [Main Workspace & Kitchen Switching Flow](#3-main-workspace--kitchen-switching-flow)
4. [Ticket Lifecycle & State Transitions](#4-ticket-lifecycle--state-transitions)
5. [Search, Filter, Sorting & Concurrency Sequencing](#5-search-filter-sorting--concurrency-sequencing)
6. [Ticket Verification Flow (Zone-Based)](#6-ticket-verification-flow-zone-based)
7. [Media Upload & Storage Pipeline](#7-media-upload--storage-pipeline)
8. [External Integrations & Push Notifications](#8-external-integrations--push-notifications)
9. [Master Data & Plant Maintenance Modules](#9-master-data--plant-maintenance-modules)

---

## 1. App Initialization & Remote Version Enforcement

Every app launch executes a synchronous bootstrap sequence wrapped with version enforcement:

```mermaid
graph TD
    A[main.dart] --> B[dotenv.load .env]
    B --> C[Supabase.initialize]
    C --> D[Firebase.initializeApp]
    D --> E[MultiProvider: AuthProvider + TicketProvider]
    E --> F[AppUpdateWrapper]
    F --> G{Remote Version Check}
    G -- "Current < Min Supported" --> H[AppUpdateScreen - Hard Block Force Update]
    G -- "Current < Latest" --> I[Soft Update Alert Banner - Dismissible]
    G -- "Version Valid" --> J[Render Authenticated / Login Hierarchy]
```

- **Entry Point**: [`lib/main.dart`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/main.dart)
- **Version Guard**: [`AppUpdateWrapper`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/updates/app_update_wrapper.dart) reads version boundaries from remote configuration (`m_app_versions` or Firebase Remote Config).

---

## 2. Authentication & Authorization State Machine

User sessions transition through four deterministic states managed by [`AuthProvider`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/providers/auth_provider.dart):

```mermaid
stateDiagram-v2
    [*] --> Initializing: App Boot
    Initializing --> Unauthenticated: No Active Session
    Initializing --> FetchProfile: Active Supabase Token
    
    Unauthenticated --> LoginScreen: User provides credentials
    LoginScreen --> FetchProfile: Successful Auth
    
    FetchProfile --> ProfileIncomplete: Profile Record Missing
    ProfileIncomplete --> RegisterScreen: User Completes Profile
    RegisterScreen --> FetchProfile: Profile Saved
    
    FetchProfile --> PendingApproval: status == 'PENDING'
    PendingApproval --> PendingApprovalScreen: Block access until admin activates
    
    FetchProfile --> Authenticated: status == 'ACTIVE'
    Authenticated --> HomeScreen: Load assigned kitchens & tickets
```

### Roles & Access Scopes
- **Technician**: Can view tickets for assigned kitchens, change status to `IN_PROGRESS` / `COMPLETED`, attach tools and proof media.
- **Supervisor**: Can create tickets, assign technicians, approve/verify completed tickets for supervised zones.
- **Admin**: Full authority across all kitchens, user approvals, master data, and analytics.

---

## 3. Main Workspace & Kitchen Switching Flow

Upon reaching `HomeScreen`, the app determines the device viewport (`isWeb` vs. mobile) and binds to the active kitchen:

```mermaid
graph TD
    A[HomeScreen Init] --> B[Fetch AuthProfile & Assigned Kitchens]
    B --> C{Number of Kitchens}
    C -- "Single Kitchen" --> D[Static Kitchen Title in Header]
    C -- "Multiple Kitchens" --> E[DropdownButton with isExpanded & Ellipsis]
    
    D --> F[TicketProvider.setFilters kitchenId]
    E --> F
    
    F --> G[Load Zones & Areas for Selected Kitchen]
    G --> H[Fetch Tickets & Compute Dashboard Counters]
    
    H --> I{Device Form Factor}
    I -- "Desktop / Web" --> J[Render WebTicketTable + Metric Stats in AppBar + Header Refresh Controls]
    I -- "Mobile Phone" --> K[Render CustomScrollView + Stat Cards + SliverList + Pull-to-Refresh]
```

### Data Refresh Capabilities
- **Web / Desktop**: Dedicated AppBar refresh icon button, table header column refresh button, and empty-state "Refresh Data" action trigger `ticketProvider.refreshTickets()`.
- **Mobile**: Touch-driven `RefreshIndicator` (pull-to-refresh) and AppBar refresh action.


---

## 4. Ticket Lifecycle & State Transitions

Tickets move through strict status gates with dual-verification requirements:

```mermaid
stateDiagram-v2
    [*] --> RAISED: Created by User/Supervisor
    RAISED --> ASSIGNED: Supervisor assigns Technician
    ASSIGNED --> IN_PROGRESS: Technician begins work
    IN_PROGRESS --> COMPLETED: Repair finished + Mandatory Proof Uploaded
    COMPLETED --> VERIFIED: Zone Supervisor audit passed
    COMPLETED --> REOPENED: Verification rejected / issue persists
    REOPENED --> IN_PROGRESS: Further repair required
    VERIFIED --> [*]: Ticket Closed
```

### Mandatory Requirements per Step
1. **Creation**: Title, description, kitchen, zone, area, equipment ID, priority (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`), initial media.
2. **Completion**: Tools used selection, resolution notes, after-repair photo/video proof.
3. **Verification**: Zone supervisor sign-off (`is_verified = true`, `verified_by`, `verified_at`).

---

## 5. Search, Filter, Sorting & Concurrency Sequencing

To guarantee fluid 60fps UX without race conditions:

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as HomeScreen / WebTicketTable
    participant Prov as TicketProvider
    participant DB as Supabase DB

    User->>UI: Selects Filter / Search / Reset
    UI->>Prov: resetAllFilters() or setFilters() [Atomic]
    Note over Prov: Increments _fetchRequestId = N
    Prov->>DB: Asynchronous Query (Request #N)
    
    alt Slower previous request resolves late (Request #N-1)
        DB-->>Prov: Stale Response #N-1
        Note over Prov: #N-1 != currentRequestId (Ignored & Dropped)
    end
    
    DB-->>Prov: Authoritative Response #N
    Prov->>Prov: Update _tickets & stats
    Prov->>UI: notifyListeners()
    UI->>UI: Calculate deltaIndex per item
    UI->>UI: Trigger _AnimatedTicketCard / _AnimatedTableRow (650ms easeOutCubic glide)
```

- **Delta Tracking**: Relative offset glide `deltaIndex * 122.0` (mobile) or `deltaIndex * 48.0` (web).
- **Scale Elevation Lift**: Items in motion scale up `+2.5%` (mobile) or `+1.5%` (web).
- **Staggered Fade-in**: New items entrance from `+20px` / `+16px` with opacity ramp `0.2 -> 1.0`.

---

## 6. Ticket Verification Flow (Zone-Based)

```mermaid
graph TD
    A[Supervisor clicks Verification Badge in AppBar] --> B[TicketVerificationScreen]
    B --> C[Fetch COMPLETED tickets for Supervisor Assigned Kitchens]
    C --> D[Filter tickets by Supervisor Assigned Zones]
    D --> E[Review Before vs After Media & Resolution Notes]
    E --> F{Audit Decision}
    F -- "Approved" --> G[Call verifyTicket RPC -> Status: VERIFIED]
    F -- "Rejected" --> H[Enter Rejection Reason -> Status: REOPENED]
    G --> I[Telegram Notification Sent to Thread]
    H --> I
    I --> J[Return to HomeScreen & Auto-Refresh Counters]
```

---

## 7. Media Upload & Storage Pipeline

All visual proofs and attachments are routed through Firebase Cloud Storage for resilience and CDN distribution:

```mermaid
graph LR
    A[User Selects Image/Video] --> B[Compress & Optimize Client-Side]
    B --> C[FirebaseMediaService]
    C --> D[Firebase Cloud Storage Bucket]
    D --> E[Obtain Permanent Download URL]
    E --> F[Persist URL in Supabase ticket_media Table]
```

---

## 8. External Integrations & Push Notifications

```mermaid
graph TD
    A[Ticket Created or Status Changed] --> B[Supabase Database Webhook]
    B --> C[Railway Python Webhook Handler]
    C --> D[Telegram Bot API]
    D --> E[Threaded Reply in Operations Channel under telegram_message_id]
    
    A --> F[Firebase Cloud Messaging Service]
    F --> G[Android / iOS Push Notification to Assigned Technician]
```

---

## 9. Master Data & Plant Maintenance Modules

Accessible via [`MoreScreen`](file:///Users/harsh/Documents/TAPF%20Projects/flutter%20projects/kitchen_maintanence/lib/screens/more_screen.dart):

- **Master Configuration**:
  - `EquipmentMasterScreen`: Equipment categorization, QR code binding, critical spares tagging, zone filtering.
  - `ZoneMasterScreen` & `AreaMasterScreen`: Hierarchical kitchen mapping.
  - `UserManagementScreen`: Supervisor zone assignments and role capabilities.
- **Plant Maintenance Reports & Logs**:
  - `PMScheduleScreen`: Preventive maintenance calendar and task checklists.
  - `ElectricalLogScreen`, `BoilerLogScreen`, `ROChecklistScreen`, `DGLogScreen`: Specialized plant utility daily shift logs.
  - `BreakdownReportScreen` & `CriticalSparesReportScreen`: Operational uptime analysis.
