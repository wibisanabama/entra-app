# Entra App

Mobile operational application built with Flutter and Dart for event organizers and gate access validation staff on the Entra platform.

---

## 1. System Overview

Entra App streamlines on-ground event operations. It equips organizers and gate staff with high-throughput ticket QR scanning, real-time attendee check-in tracking, gate admission audit logs, and financial withdrawal processing with transparent platform commission deductions.

---

## 2. Technology Stack

- Framework: Flutter SDK (Version 3.24.0 or higher)
- Language: Dart (Version 3.5.0 or higher)
- Architecture & State Management: Provider Pattern
- Declarative Navigation: GoRouter with route-level authentication guards
- Barcode / QR Scanning: `mobile_scanner`
- HTTP & Networking: Native `http` with centralized `ApiClient` (token lifecycle & auto-refresh)
- Persistence: `shared_preferences`
- Internationalization & Formatting: `intl`

---

## 3. Core Operational Capabilities

### 3.1 High-Speed Gate Ticket Scanner (`ScannerScreen`)
- Real-Time Camera Detection: Continuous QR scanning with automatic payload normalization.
- Instant Status Verification: Real-time validation against `gate-service` with distinct states:
  - `VALID` — First-time admission granted.
  - `ALREADY USED` — Duplicate entry rejected; displays previous check-in timestamp and gate name.
  - `INVALID` — Unrecognized code or signature mismatch.
  - `WRONG EVENT` — Ticket belongs to a different event.
- Zero-Truncation Display: Scanned codes and error feedback are displayed in full without ellipsis (`...`) clipping, utilizing zero-width space wrapping (`\u200B`) and auto-scrolling modal containers to prevent RenderFlex overflow.
- Auditory and Haptic Feedback: Distinct audio cues and vibration patterns for valid and rejected scans.
- Strict Anti-Double Check-In: Concurrency guards prevent duplicate submissions during scan processing.

### 3.2 Attendee Management (`AttendeeListScreen`)
- Live Attendee Manifest: Paginated, searchable attendee records with filter tabs (`Semua`, `Hadir`, `Belum Hadir`).
- Manual Check-In Override: Direct manual check-in capability for damaged or unreadable physical QR passes.
- Complete Ticket Codes: Renders complete 36-character UUID ticket codes in monospace format without truncation.

### 3.3 Organizer Financials & Payouts (`WithdrawalsScreen`)
- Transparent 5% Fee Breakdown: Visualizes Gross Sales, 5% Platform Fee, Net Organizer Revenue, and Available Withdrawable Balance.
- Idempotent Payout Requests: Withdrawal submissions include an `Idempotency-Key` HTTP header, preventing duplicate payouts caused by unstable mobile network connectivity.
- Localized Settlement History: Transaction records formatted with Indonesian Rupiah (`formatCurrency`) and natural localized timestamps (`formatDate`).

### 3.4 Design System Standards
- Transparent Elevations: Buttons, bottom sheets, and dialogs enforce `elevation: 0`, `shadowColor: Colors.transparent`, and `splashFactory: NoSplash.splashFactory`.
- Responsive Text Scaling: User IDs and UUID strings utilize `FittedBox(fit: BoxFit.scaleDown)` to ensure full 36-character strings display without horizontal layout overflow across varying device form factors.

---

## 4. Prerequisites

- Flutter SDK: Version 3.24.0 or higher
- Android SDK: API Level 24 (Android 7.0) or higher
- Java Development Kit (JDK): Version 17
- Physical Android device with camera support or Android Virtual Device (AVD)
- Active Entra API backend services

---

## 5. Network Configuration & Device Connectivity

The mobile application communicates with Entra microservices across default backend ports:

| Service | Port | Endpoint Scope |
| --- | --- | --- |
| `auth-service` | 8081 | Authentication, profile credentials, token refresh |
| `event-service` | 8082 | Event catalog and ticket tier metadata |
| `ticket-service` | 8083 | Financial balances and withdrawal requests |
| `gate-service` | 8086 | Gate check-in scan validation and attendee lists |
| `storage-service` | 9000 | MinIO / S3 public media asset resolution |

### 5.1 Option A: USB Debugging via ADB Reverse (Recommended for Physical Devices)

When running the app on a physical device connected via USB, forward localhost ports directly to the device:

```powershell
adb reverse tcp:8081 tcp:8081
adb reverse tcp:8082 tcp:8082
adb reverse tcp:8083 tcp:8083
adb reverse tcp:8086 tcp:8086
adb reverse tcp:9000 tcp:9000
```

Verify port forwarding:

```powershell
adb reverse --list
```

Run the application:

```powershell
flutter run
```

### 5.2 Option B: Local Area Network (Wi-Fi LAN)

If testing wirelessly over the same Wi-Fi network as the host machine, specify the host machine IP address via `--dart-define`:

```powershell
flutter run --dart-define=BACKEND_HOST=192.168.1.10
```

Replace `192.168.1.10` with your machine's local IPv4 address.

### 5.3 Option C: Android Emulator

Android emulators automatically route host connections via `10.0.2.2`. Run directly:

```powershell
flutter run
```

---

## 6. Installation and Execution

### 6.1 Retrieve Dependencies

```powershell
flutter pub get
```

### 6.2 Verify Environment Health

```powershell
flutter doctor
flutter devices
```

### 6.3 Execute in Debug Mode

```powershell
flutter run
```

---

## 7. Testing and Code Quality

### 7.1 Static Code Analysis

Run the Flutter linter to verify compliance with analysis options:

```powershell
flutter analyze
```

### 7.2 Automated Test Suite

Execute all unit and widget tests:

```powershell
flutter test
```

---

## 8. Release Compilation

Generate an optimized Android release APK:

```powershell
# With USB localhost port forwarding
flutter build apk --release

# With LAN network host configuration
flutter build apk --release --dart-define=BACKEND_HOST=192.168.1.10
```

The compiled binary will be output to:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 9. Directory Structure

```text
entra-app/
├── android/                 # Android native project configuration, manifests, and gradle scripts
├── lib/
│   ├── config/              # Centralized backend URL configuration and environment parsing
│   ├── models/              # Immutable domain models (User, Event, Attendee, Balance, Withdrawal)
│   ├── providers/           # Provider state management controllers (Auth, Event, Attendee, Balance)
│   ├── screens/             # Application views (Dashboard, Events, Scanner, Attendees, Withdrawals, Profile)
│   ├── services/            # HTTP network clients, interceptors, and error mappers
│   ├── theme/               # Material 3 tokens, color schemes, and no-splash component themes
│   ├── utils/               # Currency parsers, date helpers, and QR normalization utilities
│   ├── widgets/             # Reusable UI components (AttendeeTile, ScanResultDialog, MetricsCard)
│   ├── main.dart            # Application entrypoint and dependency initialization
│   └── router.dart          # GoRouter route declarations, redirects, and navigation hierarchy
├── test/                    # Unit, widget, and provider integration tests
└── pubspec.yaml             # Flutter project manifest and dependency constraints
```
