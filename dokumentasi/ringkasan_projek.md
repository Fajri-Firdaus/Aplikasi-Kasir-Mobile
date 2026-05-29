# Ringkasan Proyek: Mobile POS Flutter

## 1. Deskripsi Proyek
Aplikasi Mobile Point of Sales (POS) yang dirancang untuk membantu pengelolaan transaksi penjualan, inventaris produk, dan laporan keuangan secara mobile. Aplikasi ini menggunakan arsitektur berbasis fitur (feature-driven) untuk memudahkan skalabilitas dan pemeliharaan kode.

## 2. Tech Stack
### Frontend
- **Framework:** Flutter SDK ^3.11.4
- **State Management:** [Riverpod](https://riverpod.dev/) (menggunakan `NotifierProvider` untuk logika bisnis).
- **Routing:** [Go Router](https://pub.dev/packages/go_router) untuk navigasi deklaratif.
- **UI & Styling:** Material Design 3, Google Fonts, dan Custom Theme.

### Backend & API
- **HTTP Client:** [Dio](https://pub.dev/packages/dio) (sudah terkonfigurasi di `pubspec.yaml`, siap digunakan untuk integrasi API).
- **Status Saat Ini:** Prototype menggunakan data lokal/dummy (In-memory storage).

### Database & Persistence
- **Local Storage:** [Shared Preferences](https://pub.dev/packages/shared_preferences) digunakan untuk penyimpanan data persisten sederhana (seperti setting aplikasi atau sesi user).
- **Data Serialization:** [Freezed](https://pub.dev/packages/freezed) dan [JSON Serializable](https://pub.dev/packages/json_serializable) tersedia untuk menangani model data kompleks dan konversi JSON.

## 3. Coding Standards
### Arsitektur
Menggunakan pola **Feature-First Architecture**:
- `lib/core/`: Berisi logika bersama seperti routing, tema, antarmuka hardware (printer/scanner), dan konfigurasi global.
- `lib/features/`: Modul-modul fitur (auth, products, transactions, dll) yang masing-masing memiliki folder `data`, `presentation`, dan `providers`.

### Naming & Style
- **File Naming:** Menggunakan `snake_case` (contoh: `app_router.dart`).
- **Class Naming:** Menggunakan `PascalCase` (contoh: `ProductNotifier`).
- **Variable/Method:** Menggunakan `camelCase`.
- **Linting:** Mengikuti standar `flutter_lints` untuk memastikan kualitas dan konsistensi kode.

### Types
- Mengutamakan **Strong Typing** pada Dart.
- Penggunaan objek **Immutable** dengan pola `copyWith` untuk pembaruan state yang aman.

## 4. Testing Workflow
### Framework
- **Primary:** `flutter_test` (bawaan Flutter).

### Aturan & Struktur
- Folder tes berada di `test/` dan mengikuti struktur folder `lib/features/` untuk kemudahan pelacakan.
- **Unit Testing:** Difokuskan pada pengujian logika bisnis di dalam `Notifier` menggunakan `ProviderContainer`.
- **Widget Testing:** Tersedia untuk memvalidasi komponen UI (contoh: `widget_test.dart`).

### Cakupan (Coverage)
- Saat ini pengujian mencakup logika CRUD pada provider utama (seperti `ProductNotifier`) untuk memastikan integritas data sebelum ditampilkan di UI.
