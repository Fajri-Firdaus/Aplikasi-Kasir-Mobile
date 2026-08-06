# Ringkasan Proyek: Mobile POS Flutter

## 1. Deskripsi Proyek
Aplikasi Mobile Point of Sales (POS) multi-tenant yang dirancang untuk mengelola transaksi penjualan, inventaris produk, shift kasir, laporan keuangan, dan manajemen pengguna secara offline-first. Aplikasi ini menerapkan arsitektur berbasis fitur (**Feature-First Architecture**) dan pendataan terisolasi per toko (**Multi-Tenancy**) berbasis `store_id`.

## 2. Tech Stack & Dependensi
### Frontend & State Management
- **Framework:** Flutter SDK `^3.11.4` (Material 3 enabled).
- **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod: ^3.3.1`) menggunakan `NotifierProvider`, `Provider`, dan `Notifier` untuk mengelola logika bisnis secara deklaratif dan reaktif.
- **Routing:** [Go Router](https://pub.dev/packages/go_router) (`^17.2.3`) menggunakan `StatefulShellRoute.indexedStack` dengan 5 cabang navigasi utama dan sub-rute deklaratif.
- **UI & Styling:** Google Fonts (`google_fonts: ^8.1.0`), Cupertino Icons, dan Custom Theme (`AppTheme`, `AppColors`).

### Backend & Storage
- **Local Storage / Persistence:** [SQLite (`sqflite: ^2.3.0`, `sqflite_common_ffi: ^2.3.0`)](https://pub.dev/packages/sqflite) sebagai database relasional utama offline-first.
- **HTTP Client:** [Dio](https://pub.dev/packages/dio) (`^5.9.2`) siap digunakan untuk integrasi API eksternal/cloud.
- **Simple Preferences:** [Shared Preferences](https://pub.dev/packages/shared_preferences) (`^2.5.5`) untuk menyimpan status autentikasi dan ID pengguna yang sedang login.
- **Serialization & Utilities:** [Freezed](https://pub.dev/packages/freezed) (`^3.2.5`), [JSON Serializable](https://pub.dev/packages/json_serializable) (`^6.13.2`), `uuid: ^4.5.1`, dan `path_provider: ^2.1.1`.

## 3. Fitur Utama & Sistem Multi-Toko (Multi-Tenancy)
- **Sistem Multi-Toko (Multi-Tenancy):**
  - Data terisolasi penuh berbasis `store_id`.
  - Pendaftaran Admin baru secara otomatis membuat record toko (`stores`) baru.
  - Akun kasir/karyawan terikat pada `store_id` Admin pengampunya.
  - Saat login/logout, Riverpod memvalidasi dan menginvalidasikan seluruh provider domain data secara otomatis (`_invalidateAllDomainProviders()`).
- **Autentikasi & Shift Kasir:**
  - Login/Logout, Sign Up Admin (dengan input nama toko).
  - Manajemen shift (Open Shift dengan modal awal, Close Shift dengan setoran akhir, Laporan X/Z, tracking laci kasir).
- **Katalog Produk & Kategori:**
  - SKU/Barcode, nama produk, kategori per toko, harga beli (HPP), harga jual, dan stok.
  - Fitur pencarian SKU & nama, filter kategori, serta pembatalan soft delete (`is_active = 1`).
- **Transaksi POS & Keranjang:**
  - Multi-item cart dengan manajemen kuantitas dan stok real-time.
  - Checkout atomic ACID di SQLite (insert transaction header, details, dan pemotongan stok otomatis).
  - Pembatalan transaksi (*Void*) dengan pengembalian stok otomatis.
  - Generasi urutan nomor struk harian (*daily transaction sequence*) per hari.
- **Laporan & Analitik Komprehensif:**
  - **Laporan Keuangan:** Total Omzet, HPP, Laba Bersih, Grafik Penjualan (Jam, Harian/Mingguan, Bulanan).
  - **Laporan Produk:** 5 Produk Terlaris dan Halaman Performa Seluruh Produk.
  - **Laporan Inventaris:** Alert Stok Menipis (<= 10) dan Halaman Stok Seluruh Inventaris.
  - **Laporan Pelanggan:** Ringkasan Analisis Pelanggan & Halaman Detail Laporan Pelanggan.
  - **Laporan SDM / Staff:** Kinerja Kasir & Halaman Laporan Kinerja Staff.
- **Pengaturan & Manajemen User:**
  - Manajemen Pengguna/Staff (Tambah Kasir, Soft Delete Kasir).
  - Pengaturan Profil Pengguna & Pengaturan Identitas Toko (Store Settings).

## 4. Coding Standards & Arsitektur
- **Feature-First Architecture:**
  - `lib/core/`: Berisi logika bersama seperti `local_database_service.dart`, `app_router.dart`, `app_theme.dart`, `restart_widget.dart`, dan interface repositori.
  - `lib/features/`: Terbagi menjadi 8 modul fitur (`auth`, `customers`, `dashboard`, `products`, `reports`, `settings`, `transactions`, `users`). Setiap fitur memiliki struktur `data/`, `presentation/`, dan `providers/`.
- **Naming Conventions:**
  - File: `snake_case.dart`
  - Class: `PascalCase`
  - Variable/Method: `camelCase`
- **Integritas Data:**
  - Menggunakan *Soft Delete* (`is_active = 0`) untuk menjaga integritas riwayat transaksi historis.
  - Kueri SQLite memfilter `WHERE store_id = ?` untuk menjamin isolasi data multi-tenant.

## 5. Testing Workflow
- **Framework:** `flutter_test` (bawaan Flutter).
- **Struktur Tes:** Berada di `test/features/` yang mencerminkan hirarki `lib/features/`.
- **Status Pengujian:** 33 unit dan widget test lulus 100% (mencakup Auth Multi-Tenant Isolation, Multi-Tenant Restart, Cart Provider, Product Notifier, Customer Repository, Reports Provider & UI Pages, Transaction Sequence, dan Users Notifier).

