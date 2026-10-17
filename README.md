# Mann Plus Payroll (Mobile)

Aplikasi Flutter untuk karyawan dan pengelola bengkel **Mann Plus Advertising**:
melihat slip gaji, menerima notifikasi slip, serta mengelola SPK, kasbon, dan penggajian
langsung dari ponsel.

> Skripsi: *Analisis dan Optimalisasi Fitur Penggajian Karyawan Menggunakan Pendekatan DevOps*
> Backend: repositori `app_advertising` (Laravel 12 + Sanctum)

<!-- Ganti <USERNAME> dengan akun GitHub kamu setelah repo di-push -->
![Mobile CI](https://github.com/<USERNAME>/app-advertising-mobile/actions/workflows/ci.yml/badge.svg)

## Teknologi

| Bagian | Teknologi |
|---|---|
| Framework | Flutter 3.41 (Dart 3) |
| State management | `provider` + `ChangeNotifier` |
| HTTP | `http` + `ApiClient` sendiri (timeout, error terpusat) |
| Notifikasi | `firebase_messaging` + `flutter_local_notifications` |
| Slip | `qr_flutter`, `share_plus`, `path_provider` |
| Font | Instrument Sans (lokal, `assets/fonts`) |

## Tampilan per peran

| Peran | Isi |
|---|---|
| **Karyawan** | Beranda (gaji diterima/tertunda/sisa kasbon), daftar slip, detail slip (struk + QR + unduh PDF), tugas, profil |
| **Admin** | Beranda ringkasan + "perlu tindakan", kelola SPK, buat slip (dengan pratinjau hitung), kasbon, data master karyawan & toko |
| **Owner** | Ringkasan seluruh bengkel (gaji, SPK, kasbon) |

## Menjalankan

```bash
flutter pub get
flutter run          # emulator Android otomatis memakai 10.0.2.2:8000
```

Untuk HP fisik, arahkan ke IP LAN komputer yang menjalankan backend:

```bash
php artisan serve --host=0.0.0.0        # di repo backend
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

## Pengujian

```bash
flutter analyze     # 0 issue
flutter test        # 8 test widget/unit
```

Uji integrasi ke API nyata (butuh backend hidup):

```bash
flutter test test/admin_crud_integration_test.dart --run-skipped
```

## Struktur

```
lib/
├── core/        # tema, formatter rupiah/tanggal, ApiClient
├── models/      # User, Payroll, Spk, CashAdvance, Shop, Employee
├── services/    # ApiServices (pemetaan endpoint) + PushService (FCM)
├── state/       # AuthState, NotificationState
├── screens/     # login, shell, home (per peran), payroll, spk, kasbon, notifikasi, profil, master
└── widgets/     # komponen UI bersama (StatTile, StatusBadge, EmptyState, ...)
```

`DESIGN.md` berisi panduan visual; `design/preview.html` berisi pratinjau desain.

## Catatan

- `android/app/google-services.json` sudah disertakan agar build APK langsung jalan.
- APK rilis dibangun otomatis lewat pipeline CI/CD (lihat `../CI-CD.md`).
