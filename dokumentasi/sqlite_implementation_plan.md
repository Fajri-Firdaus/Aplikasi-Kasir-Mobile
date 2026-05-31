# Rencana Implementasi SQLite (SQLite Implementation Plan)

## 1. Pendahuluan & Tujuan
Dokumen ini disusun sebagai panduan teknis untuk mengimplementasikan sistem penyimpanan lokal yang permanen (*local persistence storage*) pada aplikasi **Mobile POS Flutter**. Seluruh implementasi didasarkan pada spesifikasi skema relasional yang didefinisikan dalam [sqlite_schema.md](file:///D:/FAJRI/INFORMATIKA/TUGAS%20KULIAH/Mobile%20Programming/mobile_pos_flutter/dokumentasi/sqlite_schema.md).

Dengan implementasi ini, data transaksi, produk, kategori, pelanggan, shift, dan pengaturan toko akan tersimpan secara aman di perangkat lokal pengguna, bahkan setelah aplikasi ditutup atau perangkat dijalankan ulang. Implementasi ini tetap mempertahankan prinsip **Feature-First Architecture**, imutabilitas state dengan **Freezed & Riverpod**, serta pola desain **Repository**.

---

## 2. Dependensi Tambahan
Untuk mendukung database SQLite dan pengujian lokal, kita perlu menambahkan dependensi berikut ke dalam [pubspec.yaml](file:///D:/FAJRI/INFORMATIKA/TUGAS%20KULIAH/Mobile%20Programming/mobile_pos_flutter/pubspec.yaml):

```yaml
dependencies:
  # SQLite Database untuk Flutter
  sqflite: ^2.3.0
  # Utility untuk mencari folder penyimpanan lokal yang aman di Android/iOS
  path_provider: ^2.1.1
  # Untuk manipulasi path file
  path: ^1.9.0

dev_dependencies:
  # SQLite FFI untuk menjalankan unit test di terminal desktop (Windows/macOS/Linux)
  sqflite_common_ffi: ^2.3.0
```

Setelah mengubah file `pubspec.yaml`, jalankan perintah berikut untuk mengunduh dependensi:
```bash
flutter pub get
```

---

## 3. Tahapan Implementasi

### FASE 1: Core Database Service
Membuat layanan database pusat yang bertanggung jawab mengelola daur hidup database (*lifecycle*), skema tabel, dan seeding data awal.

- **Lokasi File:** `lib/core/data/local_database_service.dart` (Baru)
- **Detail Implementasi:**
  - Membuat class `LocalDatabaseService`.
  - Mengaktifkan fitur *Foreign Key* pada SQLite (`PRAGMA foreign_keys = ON;`).
  - Menginisialisasi file database dengan nama `mobile_pos.db` versi `1`.
  - Membuat tabel-tabel berikut saat pertama kali database dibuat (`onCreate`):
    - `users`
    - `categories`
    - `products`
    - `customers`
    - `store_settings`
    - `shifts`
    - `transactions`
    - `transaction_details`
  - Melakukan **Data Seeding** awal jika database baru dibuat:
    - User Admin Sistem (`username: admin`, `password: hashing_123456`, `role: admin`).
    - Kategori default (`Makanan`, `Minuman`).
    - Pengaturan toko default (`store_name: Mobile POS`, `store_address: Jl. Merdeka No. 123`).
  - Menyediakan Riverpod Provider `localDatabaseServiceProvider` untuk membagikan instance database secara bersih di seluruh aplikasi.

---

### FASE 2: Migrasi Model Data ke Freezed & JSON Serializable
Semua model data harus dimigrasikan menggunakan `@freezed` dan `@JsonSerializable` agar mendukung serialisasi map SQLite secara otomatis.

1. **Fitur Users (`lib/features/users/data/`)**:
   - `app_user.dart`: Migrasi ke Freezed. Sesuaikan kolom: `id`, `full_name`, `email`, `username`, `role`, `created_at`.
2. **Fitur Products (`lib/features/products/data/`)**:
   - `product.dart`: Migrasi ke Freezed. Sesuaikan kolom: `id`, `sku`, `name`, `category_id`, `buy_price`, `sell_price`, `stock`, `image_path`, `is_active`.
   - `category.dart` (Baru): Model Freezed untuk data kategori produk. Kolom: `id`, `name`.
3. **Fitur Settings (`lib/features/settings/data/`)**:
   - `app_settings.dart` (Baru): Dipindahkan dari inline provider ke file model khusus. Kolom: `id` (Constraint CHECK id=1), `store_name`, `store_address`, `store_phone`, `receipt_footer`, `updated_at`.
4. **Fitur Transactions (`lib/features/transactions/data/`)**:
   - `cart_item.dart`: Migrasi ke Freezed.
   - `transaction.dart` (Baru): Model Freezed untuk mencatat header transaksi. Kolom: `id`, `shift_id`, `customer_id`, `total_amount`, `payment_method`, `cash_received`, `status`, `created_at`.
   - `transaction_detail.dart` (Baru): Model Freezed untuk detail item yang terjual. Kolom: `id`, `transaction_id`, `product_id`, `quantity`, `buy_price_at_sale`, `sell_price_at_sale`.
   - `customer.dart` (Baru): Model Freezed untuk loyalitas pelanggan. Kolom: `id`, `name`, `phone`, `created_at`.
5. **Fitur Auth/Session (`lib/features/auth/data/`)**:
   - `shift.dart` (Baru): Model Freezed untuk sesi kasir. Kolom: `id`, `user_id`, `start_time`, `end_time`, `starting_cash`, `ending_cash`, `status`.

Setelah modifikasi model selesai, jalankan generator build runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### FASE 3: Implementasi Local Repositories
Membuat repositori konkret yang mengimplementasikan `RepositoryInterface` dengan menggunakan SQLite query.

#### 1. `ProductLocalRepository` (`lib/features/products/data/product_local_repository.dart`)
- **Fungsi Utama:**
  - Mengambil semua produk aktif (`is_active = 1`).
  - Mendukung pencarian berbasis teks dan SKU (`sku = ? OR name LIKE ?`).
  - Menyaring produk berdasarkan kategori (`JOIN categories c ON category_id = c.id`).
  - Menghapus produk secara *Soft Delete* (mengubah `is_active = 0`).

#### 2. `TransactionLocalRepository` (`lib/features/transactions/data/transaction_local_repository.dart`)
- **Fungsi Utama:**
  - **Checkout Transactional (ACID):**
    Menjalankan proses checkout di dalam SQLite transaction (`db.transaction((txn) async { ... })`) untuk menjaga konsistensi:
    1. Menyimpan data transaksi ke tabel `transactions`.
    2. Menyimpan daftar produk belanja ke tabel `transaction_details`.
    3. Mengurangi stok produk yang bersangkutan di tabel `products` secara otomatis.
  - **Sesi Shift:**
    - Membuka sesi kasir baru (menambah baris di tabel `shifts` dengan status `open`).
    - Menutup sesi kasir (mengisi `ending_cash`, `end_time`, dan mengubah status ke `closed`).
    - Query audit saldo laci (X/Z Report) untuk mencocokkan total kas fisik dengan kalkulasi sistem.
  - **Void Transaction:** Mengubah status transaksi menjadi `void` tanpa menghapus data secara fisik untuk keperluan audit.

#### 3. `UserLocalRepository` (`lib/features/users/data/user_local_repository.dart`)
- **Fungsi Utama:**
  - Operasi CRUD staf admin & kasir.
  - Melakukan hashing password dan validasi saat login.

#### 4. `SettingsLocalRepository` (`lib/features/settings/data/settings_local_repository.dart`)
- **Fungsi Utama:**
  - Mengambil satu baris pengaturan (`id = 1`) dari tabel `store_settings`.
  - Memperbarui informasi toko pada struk dan dashboard.

#### 5. `ReportLocalRepository` (`lib/features/reports/data/report_local_repository.dart`)
- **Fungsi Utama:**
  - Menjalankan kueri analitik kompleks yang tercantum pada berkas `sqlite_schema.md`:
    - Ringkasan performa harian (Transaksi, Omzet, Laba Bersih berdasarkan selisih harga jual/beli historis).
    - Tren penjualan per jam (untuk visualisasi grafik batang).
    - Daftar 5 produk terlaris hari ini.
    - Peringatan stok menipis (3 produk dengan stok paling sedikit).
    - Performa kinerja keuangan kasir per periode tertentu.

---

### FASE 4: Refaktor State Management (Riverpod Providers)
Karena pengambilan data dari SQLite bersifat asinkron, provider state management perlu diubah untuk menangani operasi asinkron menggunakan `AsyncNotifier`.

1. **`productNotifierProvider` (`lib/features/products/providers/product_provider.dart`)**
   - Mengubah `ProductNotifier` menjadi `AsyncNotifier<List<Product>>`.
   - Mengambil data awal secara asinkron dari `ProductLocalRepository` pada method `build()`.
   - Menghapus in-memory dummy list `_initialProducts`.
   - Method `addProduct`, `updateProduct`, `deleteProduct` akan memanggil repositori terlebih dahulu baru memperbarui state.

2. **`cartProvider` (`lib/features/transactions/providers/cart_provider.dart`)**
   - Saat checkout berhasil, panggil `TransactionLocalRepository` untuk menyimpan transaksi.
   - Bersihkan keranjang (`state = []`).
   - Memicu pembaruan stok di `productNotifierProvider` dengan memanggil refresh.

3. **`reportsProvider` (`lib/features/reports/providers/reports_provider.dart`)**
   - Mengubah `ReportsNotifier` menjadi `AsyncNotifier<ReportData>`.
   - Mengambil metrik performa toko secara dinamis dari `ReportLocalRepository` menggunakan filter tanggal.

4. **`settingsProvider` (`lib/features/settings/providers/settings_provider.dart`)**
   - Mengubah `SettingsNotifier` menjadi `AsyncNotifier<AppSettings>`.
   - Mengambil konfigurasi dari `SettingsLocalRepository` saat inisialisasi.

5. **`usersProvider` (`lib/features/users/providers/users_provider.dart`)**
   - Mengubah `UsersNotifier` menjadi `AsyncNotifier<List<AppUser>>`.
   - Mengambil data dari `UserLocalRepository`.

6. **`authProvider` (`lib/features/auth/providers/auth_provider.dart`)**
   - Mengintegrasikan repositori user untuk memvalidasi username dan password terdaftar.

---

## 4. Rencana Verifikasi & Pengujian

### A. Pengujian Otomatis (Unit Testing)
Karena unit test Flutter berjalan di komputer lokal (bukan device/emulator), pemanggilan database `sqflite` bawaan akan memicu `MissingPluginException`. Untuk itu kita wajib menyiapkan mock atau menggunakan SQLite FFI di lingkungan testing.

- **Langkah Setup di Lingkungan Test:**
  Membuat berkas bantuan inisialisasi SQLite FFI untuk test, misalnya `test/test_helper.dart`:
  ```dart
  import 'package:sqflite_common_ffi/sqflite_ffi.dart';

  void setupTestDatabase() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  ```
- **Membuat Berkas Pengujian:**
  1. `test/features/products/product_local_repository_test.dart`
     - Menguji apakah operasi CRUD pada database in-memory berjalan dengan baik.
     - Menguji pencarian teks dan SKU produk.
  2. `test/features/transactions/transaction_local_repository_test.dart`
     - Menguji integritas transaksi (ACID) saat checkout (transaksi disimpan, detail tersimpan, dan stok produk berkurang serentak).
     - Menguji validitas saldo laci kasir (X/Z Report).
  3. `test/features/reports/report_local_repository_test.dart`
     - Menguji query analitik laba bersih, tren omzet per jam, dan 5 produk terlaris terhadap data transaksi mock.
- **Menjalankan Tes:**
  ```bash
  flutter test
  ```

### B. Pengujian Manual
1. **Persistensi Produk:**
   - Tambahkan produk baru via UI -> Restart aplikasi -> Pastikan produk baru tersebut masih terdaftar dengan stok yang tepat.
2. **Uji Coba Transaksi & Stok:**
   - Tambahkan beberapa produk ke keranjang -> Selesaikan pembayaran -> Periksa stok produk tersebut di menu produk, pastikan stok berkurang sesuai jumlah pembelian.
3. **Uji Coba Laporan:**
   - Buka halaman Dashboard / Laporan -> Pastikan nominal omzet, laba bersih, dan grafik tren jam langsung berubah setelah transaksi checkout diselesaikan.
4. **Persistensi Pengaturan:**
   - Ubah nama toko di Pengaturan -> Restart aplikasi -> Pastikan nama toko baru tersimpan dan tercermin pada struk belanja kasir.
