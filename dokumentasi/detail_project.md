# Detail Dokumentasi Proyek: Mobile POS Flutter

Dokumen ini memberikan pemetaan mendalam mengenai struktur folder, file, dan komponen di dalam proyek **Mobile POS Flutter**. Dokumen ini mencatat keadaan faktual codebase aplikasi POS multi-tenant berbasis **Feature-First Architecture**.

---

## 1. Konfigurasi Root (Level Teratas)

* **`pubspec.yaml`**
  * **Deskripsi:** Manajer dependensi dan metadata proyek Flutter SDK (`^3.11.4`). Berisi library utama: `flutter_riverpod`, `go_router`, `sqflite`, `dio`, `shared_preferences`, `google_fonts`, `freezed_annotation`, `json_annotation`, `uuid`, `path_provider`, dan `path`.
  * **Status:** **BOLEH DIUBAH**.
* **`pubspec.lock`**
  * **Deskripsi:** Pengunci versi pasti dependensi yang terinstal.
  * **Status:** **TIDAK BOLEH DIUBAH MANUAL**.
* **`analysis_options.yaml`**
  * **Deskripsi:** Aturan linter Dart/Flutter (`flutter_lints: ^6.0.0`).
  * **Status:** **BOLEH DIUBAH**.
* **`GEMINI.md` / `scaffold-feature.skill`**
  * **Deskripsi:** Panduan dan aturan mandatori untuk AI Agent dan pengembang.
  * **Status:** **BOLEH DIUBAH**.
* **`README.md`**
  * **Deskripsi:** Ringkasan proyek dan petunjuk menjalankan aplikasi.
  * **Status:** **BOLEH DIUBAH**.

---

## 2. Jantung Utama: Direktori `lib/`

Mengadopsi pola **Feature-First Architecture** dengan pemisahan tegas antara `core/` dan `features/`.

### `lib/main.dart`
* **Deskripsi:** Entry point aplikasi. Menginisialisasi `WidgetsFlutterBinding`, membungkus aplikasi dengan `ProviderScope` dan `RestartWidget`, lalu menjalankan `MaterialApp.router` menggunakan `routerProvider`.

### `lib/core/` (Modul Global Lintas Fitur)
* `core/data/`
  * `local_database_service.dart`: Pengelola database SQLite (`mobile_pos.db`). Bertanggung jawab atas pembuatan 8 tabel (`stores`, `users`, `categories`, `products`, `customers`, `shifts`, `transactions`, `transaction_details`), migrasi alter table, penambahan index (`idx_products_store`, `idx_transactions_store`, `idx_shifts_store`, `idx_users_store`), serta seeding data default.
  * `repository_interface.dart`: Generic interface CRUD (`getAll`, `getById`, `create`, `update`, `delete`).
* `core/presentation/widgets/`
  * `restart_widget.dart`: Widget wrapper untuk mereset seluruh pohon widget (widget tree) saat switch tenant/toko atau logout.
  * `skeleton_loader.dart`: Komponen loading placeholder animasi shimmer.
* `core/router/`
  * `app_router.dart`: Definisi navigasi [GoRouter](https://pub.dev/packages/go_router) dengan `StatefulShellRoute.indexedStack` (5 cabang utama) dan `RouterNotifier` yang mendengarkan perubahan `authProvider` untuk auto-redirect `/login` vs `/dashboard`.
* `core/theme/`
  * `app_colors.dart`: Palet warna aplikasi (Primary Navy, Accent Blue, Success, Warning, Error, Dark Mode tokens).
  * `app_theme.dart`: Definisi `ThemeData` Material 3 (Typography Google Fonts Inter, ColorScheme, CardTheme, InputDecorationTheme, NavigationBarTheme).
* `core/hardware/`
  * Folder disiapkan untuk antarmuka perangkat keras (printer kasir thermal / bluetooth / barcode scanner).

### `lib/features/` (Modul Fitur Berorientasi Domain)

Setiap fitur wajib mengikuti sub-struktur: `data/`, `presentation/`, `providers/`.

1. **`features/auth/`** (Autentikasi & Sesi Shift)
   * `data/shift.dart`: Model immutable (`freezed`) untuk sesi shift kasir.
   * `presentation/login_page.dart`: Layar Login dan tab Sign Up Admin (dengan input nama toko).
   * `providers/auth_provider.dart`: `AuthNotifier` yang mengelola login, logout, sign up, reload user, serta menginvalidasi seluruh provider domain saat ganti user/toko (`_invalidateAllDomainProviders()`). Menyediakan `activeStoreIdProvider`.

2. **`features/customers/`** (Manajemen Pelanggan)
   * `data/customer.dart`: Model data pelanggan.
   * `data/customer_repository.dart`: Repositori SQLite untuk CRUD pelanggan terisolasi per `store_id`.
   * `providers/customer_provider.dart`: Riverpod Notifier untuk state daftar pelanggan.

3. **`features/dashboard/`** (Beranda & Ringkasan Performa)
   * `presentation/dashboard_page.dart`: Layar utama dashboard admin/kasir.
   * `presentation/main_layout.dart`: Shell layout utama dengan `NavigationBar` 5 tab.
   * `widgets/`:
     * `profile_header.dart`: Header profil user & identitas toko aktif.
     * `performance_summary.dart`: Card ringkasan omzet, laba bersih, dan total transaksi hari ini.
     * `quick_actions_widget.dart`: Tombol pintas aksi (POS, Tambah Produk, Laporan, Pengaturan).
     * `inventory_alerts_widget.dart`: Widget peringatan stok menipis (<= 10).
     * `mini_analytics_widget.dart`: Widget grafik dan 5 produk terlaris.
     * `start_transaction_card.dart`: Card pembuka transaksi / kelola shift.

4. **`features/products/`** (Katalog Produk & Kategori)
   * `data/product.dart` & `category.dart`: Model immutable (`freezed`) produk dan kategori.
   * `data/product_local_repository.dart`: Repositori SQLite untuk produk & kategori terisolasi per `store_id` (termasuk soft delete `is_active = 1`).
   * `providers/product_provider.dart`: State notifier katalog produk, filter kategori, pencarian, dan dialog CRUD.
   * `presentation/products_page.dart`: Layar manajemen produk dan kategori.

5. **`features/reports/`** (Laporan & Analitik Business Intelligence)
   * `data/report_local_repository.dart`: Repositori kueri agregat SQLite (Financial summary, Top products, Hourly/Daily/Weekly sales, Low stock, Cashier performance, Customer report, Shift X/Z summary).
   * `providers/reports_provider.dart` & `transactions_report_provider.dart`: State Notifiers untuk tab Keuangan, Produk, Stok, Pelanggan, Staff, dan Riwayat Transaksi.
   * `presentation/`:
     * `reports_page.dart`: Halaman laporan utama dengan TabBar 5 modul.
     * `all_transactions_page.dart`: Sub-halaman riwayat seluruh transaksi dengan filter tanggal & status void.
     * `all_product_performance_page.dart`: Sub-halaman analisis performa seluruh produk.
     * `all_inventory_stock_page.dart`: Sub-halaman stok inventaris lengkap.
     * `all_customers_report_page.dart`: Sub-halaman laporan statistik seluruh pelanggan.
     * `all_staff_report_page.dart`: Sub-halaman laporan kinerja seluruh staff kasir.
     * `widgets/transaction_detail_modal.dart`: Modal dialog detail transaksi & opsi void.

6. **`features/settings/`** (Pengaturan Sistem & Identitas Toko)
   * `data/app_settings.dart` & `settings_local_repository.dart`: Model & Repositori untuk pengaturan toko (`stores` / `store_settings`).
   * `providers/settings_provider.dart`: State management identitas toko.
   * `presentation/`:
     * `settings_page.dart`: Halaman menu pengaturan.
     * `profile_page.dart`: Halaman edit profil pengguna yang sedang login.
     * `store_settings_page.dart`: Halaman edit nama toko, alamat, telepon, dan footer struk.

7. **`features/transactions/`** (POS & Kasir Transaksi)
   * `data/`: `cart_item.dart`, `customer.dart`, `transaction.dart`, `transaction_detail.dart`, `transaction_local_repository.dart`.
   * `providers/cart_provider.dart`: State Notifier keranjang belanja, perhitungan subtotal/tax/discount, dan proses `checkout()`.
   * `presentation/`:
     * `transaction_page.dart`: Layar POS Kasir untuk memilih produk, mengatur keranjang, dan melakukan pembayaran.
     * `widgets/transaction_receipt_widget.dart`: Widget pratinjau struk belanja yang dapat dicetak/dibagikan.

8. **`features/users/`** (Manajemen Pengguna / Staff Kasir)
   * `data/app_user.dart` & `user_local_repository.dart`: Model & Repositori pengguna (`users` table) dengan dukungan soft delete `is_active`.
   * `providers/users_provider.dart`: State Notifier daftar staff kasir di bawah toko terpilih.
   * `presentation/users_page.dart`: Layar kelola pengguna (tambah akun kasir, nonaktifkan kasir).

---

## 3. Pengujian: Direktori `test/`

Direktori pengujian mengikuti struktur `lib/features/`:

- `test/features/auth/`
  - `auth_provider_test.dart`: Pengujian login, logout, dan pendaftaran user baru.
  - `multi_tenant_isolation_test.dart`: Pengujian bahwa data Toko A tidak bocor ke Toko B.
  - `multi_tenant_restart_test.dart`: Pengujian pembersihan state dan pembetulan widget tree saat restart.
- `test/features/customers/`
  - `customer_repository_test.dart`: Pengujian CRUD pelanggan di SQLite.
- `test/features/products/`
  - `product_provider_test.dart`: Pengujian CRUD produk dan filter kategori di Provider.
- `test/features/reports/`
  - `reports_provider_test.dart`: Pengujian kueri keuangan & agregasi laporan.
  - `reports_page_test.dart`: Widget test halaman laporan utama.
  - `all_transactions_filter_test.dart`: Widget test filter tanggal & pencarian transaksi.
  - `all_product_performance_test.dart`: Widget test performa produk.
  - `all_customers_report_test.dart`: Widget test statistik pelanggan.
  - `all_staff_report_test.dart`: Widget test laporan kinerja staff.
- `test/features/transactions/`
  - `cart_provider_test.dart`: Pengujian logika tambah/kurang item dan total belanja.
  - `transaction_sequence_test.dart`: Pengujian penomoran nomor urut struk harian.
  - `transaction_page_test.dart`: Widget test halaman POS Kasir.
- `test/features/users/`
  - `users_provider_test.dart`: Pengujian manajemen staff kasir.
- `test/widget_test.dart`: Smoke test dasar UI.

---

## 4. Direktori Platform & Cache (Native / Auto-Generated)

- `android/` & `ios/`: Kode platform native (Kotlin/Swift) untuk kompilasi rilis.
- `build/` & `.dart_tool/`: Cache kompilasi otomatis dari Flutter & build_runner.
- `.idea/` & `mobile_pos_flutter.iml`: Konfigurasi IDE.
- `.gemini/` & `.antigravitycli/`: Cache internal lingkungan AI agent.

