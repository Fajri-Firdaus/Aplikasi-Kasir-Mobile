# Laporan Analisis & Pengujian Mendalam: Error Pergantian Akun Toko (Multi-Tenancy)

## 📌 1. Ringkasan Eksekutif & Hasil Pengujian

Dokumen ini berisi hasil analisis dan investigasi secara komprehensif terhadap kendala runtime yang terjadi saat pengguna melakukan **pergantian akun (Logout -> Login)** antar toko yang berbeda pada aplikasi Mobile POS Flutter.

Berdasarkan pengujian dan pelacakan alur eksekusi aplikasi (*runtime execution trace*), ditemukan bahwa kendala **`ProviderException: Tried to use a provider that is in error state`** dan error tampilan pada menu **Home (Dashboard)**, **Transaksi (POS)**, **Produk**, dan **Laporan** disebabkan oleh **benturan eksekusi microtask state (*Microtask Race Condition*)** pada Riverpod StateNotifier/Notifier saat `GoRouter` memuat ulang tab `StatefulShellRoute`.

---

## 🔍 2. Analisis Akar Masalah (Root Cause Analysis)

### A. *Microtask Race Condition* pada Riverpod Notifiers
Saat pengguna menekan tombol **Login** dengan akun baru:
1. `GoRouter` secara otomatis mengarahkan halaman ke `/dashboard`.
2. Halaman `DashboardPage` berada di dalam `StatefulShellRoute` yang membawahi 5 cabang tab sekaligus:
   - Tab 1: `/dashboard` (Home)
   - Tab 2: `/pos` (Transaksi)
   - Tab 3: `/products` (Produk)
   - Tab 4: `/reports` (Laporan)
   - Tab 5: `/settings` (Pengaturan)
3. Saat `activeStoreIdProvider` berubah dari toko A ke toko B, kelima Notifier (`ProductNotifier`, `UsersNotifier`, `ReportsNotifier`, `AllTransactionsNotifier`, `SettingsNotifier`) secara bersamaan mengeksekusi `Future.microtask(...)` di dalam method `build()`.
4. Di dalam `Future.microtask(...)`, Notifier-Notifier tersebut memanggil `state = ...` (misalnya `state = state.copyWith(isLoading: true)`) **pada antrean microtask yang sama saat widget tree sedang dalam fase pemuatan (frame rendering phase)**.
5. Riverpod secara otomatis mendeteksi bahwa state diubah di luar alur siklus rendering yang aman, sehingga melempar `ProviderException` / `StateError` pada provider-provider yang sedang dibaca oleh tab pendukung.

### B. Mengapa Pengaturan Toko Tidak Mengalami Error?
- **Halaman Pengaturan Toko (`SettingsPage`)** adalah komponen statis (`ConsumerWidget`) yang hanya menampilkan daftar ubin menu (*list tile*) dan **tidak melakukan `ref.watch()` langsung terhadap `reportsProvider`, `activeShiftProvider`, atau `productNotifierProvider`**.
- Sebaliknya, **Dashboard**, **Transaksi**, **Produk**, dan **Laporan** semuanya membaca provider data secara bersamaan pada waktu yang sama saat login berhasil.

### C. Fallback Parameter `storeId` pada Repository & Service
Beberapa method repository (seperti `getActiveShift` pada `TransactionLocalRepository`) masih memiliki default parameter `storeId = 'store-uuid-001'`. Ketika transaksi atau shift dipanggil tanpa menyertakan `storeId` aktif dari pengguna yang login, query membaca data toko seed bawaan sistem, menyebabkan inkonsistensi data antar toko.

---

## 📋 3. Temuan Detail Per Komponen & Fitur

| Halaman / Fitur | Gejala Error | Penyebab Teknis |
| :--- | :--- | :--- |
| **Home (Dashboard)** | Gagal memuat data statistik, kartu stok, dan shift aktif. | Widget `InventoryAlertsWidget`, `PerformanceSummary`, dan `MiniAnalyticsWidget` membaca `reportsProvider` dan `activeShiftProvider` yang mengalami error state akibat penumpukan microtask query SQLite saat Login. |
| **Transaksi (POS)** | Tampilan blank/loading berputar tanpa henti atau error shift. | `TransactionPage` membaca `ref.watch(activeShiftProvider)`. Ketika `activeShiftProvider` mengalami error state saat pergantian toko, `activeShiftAsync.when()` mengeksekusi branch error. |
| **Produk** | Daftar produk kosong atau tidak ter-update saat beralih akun. | `ProductNotifier.build()` memicu microtask `loadProducts()` yang bertabrakan dengan microtask reload toko baru. |
| **Laporan** | Tab Performa/Stok/Keuangan menampilkan pesan error. | `ReportsNotifier` dan `AllTransactionsNotifier` mencoba me-mutate `state` di dalam microtask berurutan pada event loop yang sama. |
| **Pengaturan Toko** | Normal (Berjalan dengan baik). | Tidak membaca provider transaksi/shift/laporan secara langsung pada root widgetnya. |

---

## 🛠️ 4. Rencana Solusi Arsitektural & Langkah Perbaikan

Untuk menyelesaikan kendala ini secara permanen tanpa perlu keluar dari aplikasi, langkah-langkah perbaikan arsitektur berikut disiapkan:

1. **Eliminasi Microtask State Mutation pada `build()` Notifier:**
   - Mengganti pola `Future.microtask(() => state = ...)` di dalam `build()` Notifier menjadi **`AsyncNotifier` native Riverpod** atau pengambilan data ter-defer secara aman yang tidak merusak alur rendering widget tree.

2. **Isolasi Scoping Data Tenant dengan Family / AutoDispose:**
   - Menggunakan `storeId` sebagai parameter kunci unik pada provider atau memanfaatkan `ref.watch(activeStoreIdProvider)` dengan mekanisme penanganan state `AsyncValue` yang bersih (Loading -> Data / Error).

3. **Pembersihan Total Memory Shell Route Saat Logout:**
   - Pada saat pengguna melakukan **Logout**, jalankan pengosongan penuh (*invalidation*) terhadap seluruh provider domain dan reset cabang `StatefulShellRoute` agar ketika pengguna baru masuk, seluruh tab dibentuk ulang dari nol secara segar (*fresh mount*).

4. **Penetapan Fallback String Non-Default:**
   - Memastikan tidak ada method repository yang menggunakan fallback hardcoded `'store-uuid-001'` tanpa verifikasi akun pengguna aktif.

---

## 🎯 5. Kesimpulan

Masalah yang terjadi **bukanlah kerusakan pada database SQLite**, melainkan kendala **siklus hidup state management (Riverpod Lifecycle & Event Loop)** akibat eksekusi microtask yang menumpuk saat beralih akun dalam satu sesi aplikasi tanpa *restart*.

Dokumen ini disusun sebagai panduan dan dokumentasi resmi analisis kendala aplikasi Mobile POS.
