# Entra App

Aplikasi mobile berbasis Flutter untuk operasional penyelenggara acara (organizer) dan staf gerbang (gate staff) pada platform Entra. Aplikasi ini memfasilitasi pemantauan metrik penjualan event, validasi tiket masuk berbasis pemindai QR code, monitoring kehadiran peserta secara langsung, dan pengajuan penarikan dana pendapatan tiket.

## Fitur Utama

- Autentikasi dan Profil: Login akun penyelenggara, pembaruan profil, tampilan avatar pengguna, dan pembaruan token otomatis (auto-refresh token) di latar belakang.
- Dashboard Metrik Organizer: Visualisasi data ringkasan total pendapatan, jumlah tiket terjual, dan rasio kehadiran peserta.
- Pemindai Tiket Masuk (Gate Scanner): Pemindaian tiket via kamera dengan normalisasi format QR code, verifikasi status check-in seketika, dan pencegahan tiket ganda (anti-double check-in).
- Monitoring Kehadiran Peserta: Daftar peserta per event dengan filter status kehadiran (hadir dan belum hadir) serta fungsi pencarian nama atau kode tiket.
- Manajemen Penarikan Dana (Withdrawals): Pengecekan saldo pendapatan yang dapat ditarik, form pengajuan pencairan dana ke rekening bank tujuan, dan riwayat transaksi dengan format penanggalan lokal Indonesia.

## Prasyarat Sistem

- Flutter SDK versi 3.24.0 atau lebih baru (Dart SDK versi 3.5.0 ke atas)
- Android SDK dengan API level minimal 24 (Android 7.0)
- Perangkat fisik Android dengan kamera aktif atau Android Emulator
- Layanan backend Entra API yang aktif (auth-service, event-service, ticket-service, gate-service)

## Konfigurasi Jaringan Backend

Aplikasi berkomunikasi dengan backend microservices Entra pada port default berikut:

| Layanan | Port Default |
| --- | --- |
| `auth-service` | 8081 |
| `event-service` | 8082 |
| `ticket-service` | 8083 |
| `gate-service` | 8086 |

Secara default, konfigurasi pada `lib/config/api_config.dart` menggunakan host `10.0.2.2` untuk Android Emulator dan `localhost` untuk perangkat desktop.

### 1. Penggunaan pada Perangkat Fisik via USB (ADB Reverse)

Metode yang direkomendasikan untuk pengujian lokal dengan kabel USB adalah memetakan port komputer ke perangkat melalui ADB:

```powershell
adb reverse tcp:8081 tcp:8081
adb reverse tcp:8082 tcp:8082
adb reverse tcp:8083 tcp:8083
adb reverse tcp:8086 tcp:8086
adb reverse tcp:9000 tcp:9000
```

Dengan konfigurasi ini, aplikasi dapat dijalankan langsung tanpa parameter tambahan:

```powershell
flutter run
```

### 2. Penggunaan via Alamat IP Jaringan Lokal (Wi-Fi LAN)

Jika perangkat fisik terhubung melalui jaringan Wi-Fi lokal yang sama dengan komputer host, teruskan alamat IP komputer menggunakan argumen `--dart-define`:

```powershell
flutter run --dart-define=BACKEND_HOST=192.168.1.10
```

Ganti nilai `192.168.1.10` dengan alamat IP IPv4 komputer Anda pada jaringan lokal.

## Instalasi dan Eksekusi

### 1. Unduh Dependensi

```powershell
flutter pub get
```

### 2. Verifikasi Kesiapan Lingkungan

```powershell
flutter doctor
flutter devices
```

### 3. Menjalankan Aplikasi

```powershell
flutter run
```

## Analisis Kode dan Pengujian

### Analisis Kualitas Kode (Linter)

```powershell
flutter analyze
```

### Menjalankan Automated Test Suite

```powershell
flutter test
```

### Kompilasi Berkas APK Release

```powershell
flutter build apk --release --dart-define=BACKEND_HOST=192.168.1.10
```

Berkas keluaran biner APK akan tersedia pada direktori:
`build/app/outputs/flutter-apk/app-release.apk`

## Struktur Direktori

```text
entra-app/
├── android/                 # Konfigurasi platform Android native (manifest, gradle)
├── lib/
│   ├── config/              # Konfigurasi endpoint API dan resolusi URL media
│   ├── models/              # Data transfer objects (User, Event, Attendee, Balance, Withdrawal)
│   ├── providers/           # State management aplikasi berbasis Provider
│   ├── screens/             # Tampilan layar aplikasi (Dashboard, Events, Scanner, Withdrawals, Profile)
│   ├── services/            # Klien HTTP terpusat (ApiClient) dan service modul
│   ├── theme/               # Token desain, warna, dan tema aplikasi
│   ├── utils/               # Utilitas format mata uang, tanggal, dan normalisasi QR code
│   ├── widgets/             # Komponen antarmuka yang dapat digunakan ulang
│   ├── main.dart            # Titik masuk utama aplikasi (entry point)
│   └── router.dart          # Konfigurasi routing deklaratif (GoRouter) dan guard autentikasi
└── test/                    # Rangkaian pengujian unit test dan widget test
```
