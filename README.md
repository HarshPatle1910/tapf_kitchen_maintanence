# Kitchen Maintenance App

A comprehensive mobile and web application built with Flutter to streamline kitchen maintenance ticket lifecycle tracking, task assignments, worker reporting, and notification management.

---

## 🚀 Features

### 🎫 Ticket Lifecycle Management
- **Raise Tickets:** Quick issue creation specifying category, urgency level, descriptions, and media attachments.
- **Detailed Timelines & Status Tracking:** Real-time visibility into the progression of tickets (e.g., Open, In Progress, Completed, Verified).
- **Media Uploads:** Seamless image/video attachment upload handling via Supabase Storage.
- **Worker Update Permissions:** Workers can edit and append details, logs, and images directly to tickets.

### 👥 User & Role Management
- **Dashboard Auditing:** Multi-parameter search and filtration controls on the User Management Screen.
- **Dynamic Sorting:** Sort users by Name, APM ID, or Join Date.
- **Granular Role Controls:** Easily toggle roles (Admins, Workers, etc.) and manage statuses.
- **Secure Kitchen Assignments:** Admins can allocate users only to specific kitchens they themselves have permission to access.
- **Global Kitchen Context:** Synchronized kitchen filters throughout the application, automatically resetting user filters on context changes.

### 🔔 Smart Notification System
- **In-App Alerts:** Interactive banners notifying users of state transitions. Features quick view navigations, auto-dismiss timers, and placement tweaks.
- **Telegram Integration:** Integrates notifications straight to Telegram groups. Completion messages are threaded as direct replies to the original ticket-raised alert messages for clear communication.

---

## 🛠️ Technology Stack

- **Frontend:** Flutter & Dart
- **Backend & Database:** Supabase (Database, Auth, Storage)
- **Notification Services:** Firebase Cloud Messaging (FCM) & Telegram API
- **State Management:** Provider
- **Design Framework:** Material Design with Google Fonts (Inter)

---

## ⚙️ Getting Started

### Prerequisites

Before starting, ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (matching version requirements in `pubspec.yaml`)
- Android Studio / VS Code (configured for Flutter development)
- Dart SDK

### Installation

1. **Clone the Repository:**
   ```bash
   git clone <repository-url>
   cd kitchen_maintanence
   ```

2. **Retrieve Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the root directory (using `.env.example` as a template) and add your keys:
   ```env
   SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL
   SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   # Additional services as needed
   ```

4. **Run the Application:**
   ```bash
   flutter run
   ```

### Building the Release App (Android APK)

To build a production-ready release APK:
```bash
flutter build apk --release
```
The output APK will be saved under: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📁 Directory Structure Overview

- `lib/`
  - `providers/`: App-wide states and controllers (e.g. `ticket_provider.dart`, `auth_provider.dart`)
  - `screens/`: UI Views grouped by flow (Home, Ticket Details, User Management)
  - `services/`: API integration and communication layer (Supabase, Firebase, Notifications)
  - `widgets/`: Reusable interface components and cards
- `android/` / `ios/`: Native configuration folders for platform integration (Firebase configs, Permissions)
