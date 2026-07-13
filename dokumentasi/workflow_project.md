# Workflow Proyek: Mobile POS Flutter

Dokumen ini menjelaskan alur kerja aplikasi, keterhubungan antar file, dan tanggung jawab setiap lapisan dalam arsitektur **Feature-First** yang digunakan.

---

## BAGIAN 1: Ringkasan Workflow (The Big Picture) 

Aplikasi ini bekerja dengan aliran data satu arah yang terorganisir sebagai berikut:

1.  **Entry Point (`lib/main.dart`)**: Menginisialisasi database dan membungkus aplikasi dengan provider.
2.  **UI Layer (`presentation/`)**: Widget mendengarkan (*watch*) status dari Provider.
3.  **State Layer (`providers/`)**: Notifier mengelola logika bisnis dan memanggil Repository untuk data.
4.  **Data Layer (`data/`)**: 
    *   **Repository**: Melakukan query SQL ke SQLite.
    *   **Model (Freezed)**: Mengonversi baris tabel database menjadi objek Dart yang aman.
5.  **Core Layer (`lib/core/`)**: Menyediakan layanan global (Database, Router, Theme) yang digunakan oleh semua fitur.

**Visualisasi Sederhana:**
`User Action (UI)` -> `Notifier (Provider)` -> `Repository (SQL)` -> `LocalDatabase (SQLite)` -> `Data Return` -> `UI Rebuild`

---

## BAGIAN 2: Penjelasan Detail Komponen

### 1. Konfigurasi Root & Orchestration
*   **`pubspec.yaml`**: Pusat kendali library. Di sini kita menentukan versi SDK dan paket seperti `sqflite`, `riverpod`, dan `freezed`.
*   **`lib/main.dart`**: Inisiator aplikasi. File ini memastikan `LocalDatabaseService` siap sebelum UI pertama kali muncul.
*   **`lib/core/router/app_router.dart`**: Navigator pusat menggunakan `GoRouter`. Semua perpindahan halaman didefinisikan di sini.
*   **`lib/core/data/local_database_service.dart`**: Jantung database. Mengatur DDL (`CREATE TABLE`), migrasi versi, dan data awal (*seeding*).

### 2. Struktur Fitur (`lib/features/`)
Setiap fitur (misal: `products`, `transactions`) bersifat mandiri dan terbagi menjadi tiga lapisan:

#### A. Data Layer (`data/`)
*   **Model (`*.dart`, `*.freezed.dart`, `*.g.dart`)**:
    *   Mendefinisikan blueprint data (misal: Produk memiliki SKU, Nama, Stok).
    *   Menggunakan *code generation* untuk memastikan data tidak bisa diubah sembarangan (*immutable*) dan aman saat dikonversi dari database.
*   **Local Repository (`*_local_repository.dart`)**:
    *   Tempat penulisan query SQL asli (`db.insert`, `db.query`).
    *   Menghubungkan aplikasi dengan tabel spesifik di SQLite.

#### B. Provider Layer (`providers/`)
*   **Notifier (`*_provider.dart`)**:
    *   Otak dari setiap fitur. Ia menyimpan status data saat ini (misal: daftar produk yang sedang tampil).
    *   Jika ada perubahan di UI (misal: tombol "Tambah Stok" diklik), UI memanggil fungsi di sini, lalu Notifier memanggil Repository, dan akhirnya memperbarui tampilan secara otomatis.

#### C. Presentation Layer (`presentation/`)
*   **Pages & Widgets**:
    *   Hanya fokus pada tampilan.
    *   Menggunakan `ref.watch` untuk mendapatkan data terbaru dan `ref.read` untuk menjalankan aksi (seperti klik tombol).

### 3. Alur Komunikasi Antar File (Contoh Kasus: Checkout)
1.  **UI**: Pengguna menekan tombol "Bayar" di `transaction_page.dart`.
2.  **Provider**: `cartProvider` menjalankan fungsi `checkout()`.
3.  **Logic**: `cartProvider` menghitung total, lalu memanggil `TransactionLocalRepository`.
4.  **Database**: Repository menjalankan transaksi ACID: Simpan header, simpan detail, dan potong stok di tabel produk.
5.  **Sync**: `cartProvider` memanggil `refresh()` pada `reportsProvider` agar grafik di dashboard langsung berubah.
6.  **UI Update**: Semua widget yang mendengarkan provider tersebut akan berkedip/rebuild menampilkan data terbaru.

---

## BAGIAN 3: Konvensi Pengembangan

1.  **Modifikasi Database**: Selalu lakukan di `local_database_service.dart`.
2.  **Tambah Fitur Baru**: Gunakan struktur folder yang sama (`data`, `presentation`, `providers`).
3.  **State Management**: Selalu gunakan `Notifier` atau `AsyncNotifier` dari Riverpod.
4.  **Data Persistence**: Semua data permanen harus melalui Repository ke SQLite. Data sementara (seperti item di keranjang sebelum dibayar) cukup di simpan di memori Notifier.
