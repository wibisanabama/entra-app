# Entra App

Aplikasi Android untuk operasional organizer Entra, termasuk pemantauan event, daftar peserta, check-in tiket, dan pengajuan withdrawal.

## Fitur

- Login dan pengelolaan profil.
- Dashboard penjualan dan daftar event organizer.
- Daftar peserta, pencarian, dan filter status kehadiran.
- Check-in melalui kamera QR, input kode, atau daftar peserta.
- Ringkasan saldo, pengajuan withdrawal, dan riwayatnya.

## Teknologi

Flutter, Dart, Provider, GoRouter, mobile_scanner, http, dan shared_preferences.

## Prasyarat

- Flutter SDK dengan Dart yang memenuhi `^3.12.0` (`>=3.12.0 <4.0.0`).
- Android SDK dan toolchain yang lolos pemeriksaan `flutter doctor`.
- Emulator Android atau perangkat Android.
- Layanan auth, event, ticket, dan gate dari [Entra API](https://github.com/wibisanabama/entra-api).

Repositori saat ini hanya menyertakan konfigurasi platform Android.

## Instalasi

```bash
git clone https://github.com/wibisanabama/entra-app.git
cd entra-app
flutter pub get
flutter doctor
flutter devices
```

## Konfigurasi backend

Host backend ditentukan melalui `BACKEND_HOST`. Nilainya berupa hostname atau alamat IP, tanpa protokol, port, atau path.

| Layanan | Port |
| --- | --- |
| Auth | 8081 |
| Event | 8082 |
| Ticket | 8083 |
| Gate | 8086 |

Konfigurasi berada di `lib/config/api_config.dart` dan menggunakan HTTP. Tanpa override, Android menggunakan `10.0.2.2` untuk mengakses komputer host dari Android Emulator.

## Menjalankan aplikasi

Pada Android Emulator:

```bash
flutter run
```

Pada perangkat fisik, gunakan IP LAN komputer backend. Contoh berikut memakai `192.168.1.10`; ganti dengan alamat komputer Anda:

```bash
flutter run --dart-define=BACKEND_HOST=192.168.1.10
```

Perangkat harus dapat menjangkau seluruh port API tersebut. Izinkan akses pada firewall dan berikan izin kamera untuk scanner. Gunakan akun organizer yang telah dibuat melalui Entra Web/API; aplikasi tidak menyediakan registrasi.

## Pemeriksaan dan build

```bash
flutter analyze
flutter test
flutter build apk --release --dart-define=BACKEND_HOST=192.168.1.10
```

Ganti IP pada perintah build dengan host backend tujuan. APK tersedia di `build/app/outputs/flutter-apk/app-release.apk`.

Build release saat ini masih menggunakan debug signing. Konfigurasikan signing produksi sebelum mendistribusikan aplikasi. Penggunaan HTTPS memerlukan penyesuaian konfigurasi URL API.

## Struktur

- `lib/config/`: konfigurasi endpoint backend.
- `lib/models/`: model data.
- `lib/providers/`: state aplikasi.
- `lib/screens/`: halaman aplikasi.
- `lib/services/`: komunikasi HTTP.
- `lib/widgets/`: komponen UI.
- `lib/utils/`: utilitas, termasuk normalisasi kode QR.
- `lib/router.dart`: rute dan pengalihan autentikasi.
- `test/`: pengujian.
- `android/`: konfigurasi Android.

Pemindaian QR dan check-in manual memerlukan koneksi ke backend; aplikasi tidak menyediakan mode check-in offline.
