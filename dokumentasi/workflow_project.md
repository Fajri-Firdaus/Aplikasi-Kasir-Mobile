# Workflow Proyek: Mobile POS Flutter

Dokumen ini menjelaskan alur kerja sistem, keterhubungan antar komponen, dan penanganan data pada arsitektur **Feature-First** dan **Multi-Tenancy** pada aplikasi **Mobile POS Flutter**.

---

## BAGIAN 1: Ringkasan Workflow (The Big Picture) 

Aplikasi bekerja dengan alur data satu arah (Unidirectional Data Flow) yang terisolasi per unit toko (`store_id`):

1. **Entry Point & Inisialisasi (`lib/main.dart`)**:
   - `WidgetsFlutterBinding.ensureInitialized()` mengeksekusi persiapan platform.
   - `ProviderScope` membungkus `RestartWidget` dan `MaterialApp.router`.
   - `LocalDatabaseService` menginisialisasi SQLite (`mobile_pos.db`), mengeksekusi DDL, migrasi tabel, dan penciptaan index.

2. **Autentikasi & Multi-Tenant Context (`authProvider`)**:
   - `AuthNotifier` memeriksa sesi login di `SharedPreferences`.
   - Jika pengguna terautentikasi (Admin atau Kasir), `authProvider` memegang data `AppUser`.
   - `activeStoreIdProvider` mengekstrak `storeId` milik user aktif (default: `'store-uuid-001'`).

3. **State Management & Domain Providers (`providers/`)**:
   - Setiap provider domain (`productNotifierProvider`, `reportsProvider`, `cartProvider`, dll) mendengarkan `activeStoreIdProvider`.
   - Repositori menerima `storeId` aktif untuk memfilter semua kueri SQL (`WHERE store_id = ? AND is_active = 1`).

4. **UI Layer (`presentation/`) & Navigasi (`app_router.dart`)**:
   - Navigation disajikan oleh `GoRouter` dengan `StatefulShellRoute.indexedStack` (5 tab utama: Dashboard, POS, Products, Reports, Settings).
   - Widget mendengarkan (*watch*) Notifier untuk rebuild UI secara reaktif saat ada data baru.

5. **Local Persistence Layer (`core/data/` & `features/*/data/`)**:
   - Repositori mengeksekusi operasi SQLite terisolasi.
   - Model data immutable mengonversi row database dari/ke objek Dart.

**Visualisasi Sederhana Workflow:**
`User Action (UI)` -> `Notifier (Provider)` -> `Repository (SQL with store_id)` -> `SQLite DB` -> `Data Return` -> `UI Rebuild`

---

## BAGIAN 2: Detail Workflow Operasional Utama

### 1. Inisialisasi & Pergantian Sesi (Auth & Multi-Tenant Switch)
- **Sign Up Admin Baru:**
  - Form Sign Up menerima `username`, `password`, `fullName`, `email`, dan `storeName`.
  - AuthNotifier memanggil `createStore()` untuk membuat record baru di tabel `stores` dengan ID `storeId`.
  - AuthNotifier membuat record admin baru di tabel `users` dengan `role = 'admin'` dan `store_id = storeId`.
- **Logout & Invalidation:**
  - Saat user logout atau berpindah akun toko, `_invalidateAllDomainProviders()` dipanggil.
  - Riverpod mereset `cartProvider`, `productNotifierProvider`, `settingsProvider`, `usersProvider`, `reportsProvider`, `customerProvider`, dan `dailyReportsProvider`.

### 2. Alur Transaksi POS (Checkout Atomic Transaction)
1. **Penyusunan Keranjang:** Kasir memilih produk dari `transaction_page.dart`. Items ditambahkan ke `cartProvider`.
2. **Shift Check:** Sistem memverifikasi ketersediaan sesi shift aktif (`activeShiftProvider`).
3. **Checkout Execution:**
   - Kasir menekan tombol "Bayar".
   - `cartProvider` memanggil `TransactionLocalRepository.checkout()`.
   - SQLite menjalankan blok `db.transaction()` atomic (ACID):
     a. Menyimpan header transaksi baru di tabel `transactions`.
     b. Untuk setiap item keranjang: memeriksa kecukupan stok, menyimpan detail di `transaction_details`, dan mengunci pemotongan stok (`products.stock = stock - qty`).
4. **Receipt & Refresh:**
   - Mengembalikan objek `Transaction` yang disimpan.
   - `cartProvider` mengosongkan keranjang dan memanggil `ref.invalidate(reportsProvider)`.
   - Dialog pratinjau struk (`TransactionReceiptWidget`) muncul.

### 3. Alur Pembatalan Transaksi (Void Transaction)
1. User membuka detail transaksi pada modal `TransactionDetailModal` di `all_transactions_page.dart`.
2. User memilih "Batalkan Transaksi (Void)".
3. `TransactionLocalRepository.voidTransaction()` mengeksekusi SQLite transaction:
   a. Memperbarui status transaksi menjadi `'void'`.
   b. Membaca detail item transaksi dari `transaction_details`.
   c. Mengembalikan stok produk (`UPDATE products SET stock = stock + quantity`).
4. Notifier merefresh tampilan laporan dan katalog produk secara otomatis.

### 4. Alur Manajemen Shift Kasir (Shift & X/Z Report)
1. **Buka Shift:** Kasir menginputkan saldo awal modal kas (`starting_cash`). Repository menyimpan record shift status `'open'` dengan nomor urut shift hari tersebut.
2. **Penjualan Shift:** Seluruh transaksi selama shift terhubung melalui `shift_id`.
3. **Tutup Shift (Report X/Z):**
   - Kasir menginput setoran fisik (`ending_cash`).
   - Repository mengkalkulasi ekspektasi saldo laci kasir (`startingCash + cashSales`) dan menghitung selisih (*discrepancy*).
   - Status shift diperbarui menjadi `'closed'`.

---

## BAGIAN 3: Konvensi Pengembangan

1. **Defensif Multi-Tenancy:** Selalu sertakan parameter `storeId` atau pastikan kueri SQL menyaring `store_id = ?`.
2. **Soft Delete Mandatori:** Untuk data master (`products`, `categories`, `users`), gunakan `is_active = 0` alih-alih `DELETE FROM` agar riwayat transaksi historis tidak terputus.
3. **State Management Standard:** Gunakan `Notifier` / `NotifierProvider` dari Riverpod untuk mengelola status UI.
4. **Penyimpanan Permanen:** Semua perubahan data permanen harus melalui Repositori ke SQLite, bukan disimpan sementara di memori widget.

