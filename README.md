# Entra Mobile Application Specification and Architecture Document

The official mobile application for event organizers on the Entra White-Label Event Ticketing Platform. Built with Flutter, Dart, Provider state management, and GoRouter.

---

## Overview

Entra Mobile is a cross-platform application designed for event organizers and gate staff. It provides real-time sales and revenue dashboards, event detail views, attendee roster inspection with buyer profile enrichment, and high-performance camera-based QR code ticket scanning for event access control.

---

## Technology Stack

| Component | Technology Choice | Specification / Version |
|---|---|---|
| SDK / Framework | Flutter | SDK 3.12+ (Material 3 Dark Theme) |
| Programming Language | Dart | Dart 3.0+ |
| State Management | Provider | ^6.1.5 |
| Navigation & Routing | GoRouter | ^17.5.0 |
| Camera / Barcode Scanner | mobile_scanner | ^7.4.0 |
| HTTP Client | http | ^1.6.0 |
| Local Storage | shared_preferences | ^2.5.5 |
| Date Utilities | intl | ^0.20.3 |
| Target Platform | Android / iOS | Android App ID: `com.wibisanabama.entra` |

---

## Directory Structure

```
entra-app/
├── android/                # Native Android application configuration and gradle files
├── lib/
│   ├── config/             # Environment and API network configuration
│   │   └── api_config.dart # Base URLs and host IP settings for backend services
│   ├── models/             # Data model definitions
│   │   ├── attendee.dart   # Attendee record and check-in status model
│   │   ├── event.dart      # Event catalog and details model
│   │   └── user.dart       # Authenticated user profile model
│   ├── providers/          # ChangeNotifier state providers
│   │   ├── attendee_provider.dart # Attendee list state and search filtering
│   │   ├── auth_provider.dart     # Authentication state and token lifecycle
│   │   └── event_provider.dart    # Organizer event list and dashboard stats
│   ├── screens/            # UI Screen views
│   │   ├── attendee_list_screen.dart # Attendee roster and check-in status
│   │   ├── dashboard_screen.dart     # Real-time revenue and sales stats
│   │   ├── event_detail_screen.dart  # Detailed event overview
│   │   ├── login_screen.dart         # User login screen
│   │   └── scanner_screen.dart       # QR scanner and gate entry validation
│   ├── services/           # HTTP API service implementations
│   │   ├── auth_service.dart     # Authentication & profile endpoints
│   │   ├── event_service.dart    # Organizer events endpoints
│   │   ├── gate_service.dart     # Gate check-in scan endpoint
│   │   └── ticket_service.dart   # Dashboard stats & attendee list endpoints
│   ├── widgets/            # Reusable UI widgets and dialogs
│   │   └── scan_result_dialog.dart # Gate check-in scan result modal
│   ├── main.dart           # Application entrypoint & Material theme configuration
│   └── router.dart         # GoRouter path declarations & auth redirect guards
├── pubspec.yaml            # Package dependencies and Flutter settings
└── README.md               # Application documentation
```

---

## Backend API Configuration

Backend microservices base URLs are configured in `lib/config/api_config.dart`. Update the `host` IP address to match your host machine's Wi-Fi IP address when testing on physical devices:

```dart
class ApiConfig {
  // Update host IP address for local network device access
  static String host = '192.168.0.106';

  static String get authBaseUrl => 'http://$host:8081';
  static String get eventBaseUrl => 'http://$host:8082';
  static String get ticketBaseUrl => 'http://$host:8083';
  static String get gateBaseUrl => 'http://$host:8080';
}
```

---

## Installation and Execution Guide

### Prerequisites

Ensure the following development dependencies are installed:
- Flutter SDK 3.12.0 or higher
- Android Studio / VS Code with Flutter extension
- Android SDK (API Level 21+) or connected physical Android device

### Setup Procedure

1. **Clone the repository**:
   ```bash
   git clone https://github.com/wibisanabama/entra-app.git
   cd entra-app
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify environment and connected devices**:
   ```bash
   flutter doctor
   flutter devices
   ```

### Running the Application

To run the application in debug mode on a connected device:

```bash
flutter run
```

---

## Application Screens and Navigation Routes

### Declarative Routes (`lib/router.dart`)

| Route Path | Screen Class | Access | Description |
|---|---|---|---|
| `/login` | `LoginScreen` | Public | User authentication screen with email and password input. |
| `/dashboard` | `DashboardScreen` | Protected | Organizer dashboard displaying sales metrics and owned events. |
| `/events/:id` | `EventDetailScreen` | Protected | Detailed event overview with navigation to scanner and attendee list. |
| `/events/:id/scan` | `ScannerScreen` | Protected | Real-time QR camera scanner with strict event ID validation. |
| `/events/:id/attendees` | `AttendeeListScreen` | Protected | Attendee roster with buyer name enrichment and search filter. |
| `/withdrawals` | `WithdrawalsScreen` | Protected | Organizer revenue balance overview, bank payout requests, and withdrawal history ledger. |

---

## Key Features Specification

### 1. Authentication and Session Persistence (`AuthProvider`)
- Authenticates against `auth-service` (`:8081`).
- Persists JWT access tokens locally using `shared_preferences`.
- Automatically redirects unauthenticated users to `/login`.

### 2. Dashboard Analytics (`EventProvider` & `WithdrawalProvider`)
- Fetches real-time organizer statistics (`Total Revenue`, `Tickets Sold`, `Total Orders`) and net available balance from `ticket-service` (`:8083`).
- Displays interactive balance summary cards with quick withdrawal triggers.
- Displays a clean list of events owned by the authenticated organizer.
- Handles token expiration (401 Unauthorized) gracefully with clear user prompts.

### 3. QR Code Gate Check-In (`ScannerScreen` & `GateService`)
- Real-time camera viewfinder powered by `mobile_scanner`.
- Camera flip and manual code input support.
- Performs dual-lookup validation by Ticket ID or Ticket Code.
- Strictly validates ticket `event_id` against current gate `event_id` to prevent cross-event fraud.

### 4. Enriched Attendee List & Manual 1-Tap Check-In (`AttendeeListScreen` & `AttendeeProvider`)
- Retrieves event attendees with buyer full name and email pre-enriched by `ticket-service`.
- Live search filter by attendee name, email, or ticket code.
- Interactive status filter chips (`Semua`, `Hadir`, `Belum Hadir`).
- **1-Tap Manual Check-In**: Instant check-in button directly on attendee cards with confirmation dialog, fallback handling, and real-time status update without camera scanner.
- Attendee detail bottom sheet with single-click ticket code copying.

### 5. Organizer Finance and Payout Management (`WithdrawalsScreen` & `WithdrawalProvider`)
- Live available balance calculation (`Total Revenue` minus pending/paid deductions).
- Modal bottom sheet form for requesting bank payouts (amount, bank choice, account number, beneficiary name, optional notes).
- Quick percentage chips (25%, 50%, 100% full payout) and fixed amount shortcuts.
- Status tracking (`PENDING`, `APPROVED`, `PAID`, `REJECTED`) with detailed modal receipts and rejection reasons.

---

## Building Release Binaries

To build an optimized Android APK for release:

```bash
# Build APK
flutter build apk --release

# Output path
# build/app/outputs/flutter-apk/app-release.apk
```

---

## Code Quality and Analysis

To verify code formatting and static analysis rules:

```bash
flutter analyze
```

---

## License

Proprietary Software. All rights reserved. Unauthorized copying, distribution, or modification of this software is strictly prohibited.
