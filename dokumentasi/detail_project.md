# Detail Dokumentasi Proyek: Mobile POS Flutter

Dokumen ini memberikan pemetaan mendalam mengenai struktur folder dan file di dalam proyek **Mobile POS Flutter**. Tujuannya adalah untuk memandu developer baru (maupun AI agen) memahami area mana yang merupakan tempat pengembangan utama, konfigurasi sistem, dan area terlarang yang dikelola otomatis oleh framework.

---

## 1. Konfigurasi Root (Level Teratas)

File dan folder di area ini bertanggung jawab atas konfigurasi proyek, manajemen dependensi, dan instruksi meta.

*   **`pubspec.yaml`**
    *   **Deskripsi:** Pusat manajemen proyek Flutter. Berisi metadata proyek (nama, versi), daftar dependensi (package/library), pengaturan aset (gambar, font), dan konfigurasi spesifik Flutter.
    *   **Status:** **BOLEH DIUBAH**. Anda akan sering mengedit ini untuk menambah/mengurangi dependensi atau mendaftarkan aset baru.
*   **`pubspec.lock`**
    *   **Deskripsi:** Dihasilkan otomatis oleh `flutter pub get`. Mengunci versi pasti dari dependensi yang diunduh untuk memastikan konsistensi antar developer.
    *   **Status:** **TIDAK BOLEH DIUBAH MANUAL**. Biarkan command `flutter pub` yang mengaturnya.
*   **`analysis_options.yaml`**
    *   **Deskripsi:** Aturan linting (penulisan kode) untuk proyek ini. Menentukan seberapa ketat *compiler* Dart dalam memberikan *warning* atau *error*.
    *   **Status:** **BOLEH DIUBAH**. Sering disesuaikan untuk menetapkan standar tim.
*   **`.gitignore`**
    *   **Deskripsi:** Daftar file dan folder yang tidak akan diunggah (diabaikan) ke *version control* (seperti GitHub). Misalnya file kredensial, file *build*, dan direktori `.dart_tool`.
    *   **Status:** **BOLEH DIUBAH**. Tambahkan file sensitif atau environment variable lokal di sini.
*   **`GEMINI.md` / `scaffold-feature.skill`**
    *   **Deskripsi:** Ini adalah aturan dan alur kerja (workflow) khusus proyek untuk *AI Agent* (Gemini/Claude). Memberi instruksi tentang arsitektur, standar penamaan, dan penanganan status (`Riverpod`/`Freezed`).
    *   **Status:** **BOLEH DIUBAH** jika terjadi perubahan arsitektur atau konvensi tim. Wajib dipatuhi.
*   **`README.md`**
    *   **Deskripsi:** Beranda proyek Anda di GitHub. Berisi deskripsi sistem, cara instalasi, dan panduan menjalankan aplikasi.
    *   **Status:** **BOLEH DIUBAH**. Harus selalu diupdate seiring berjalannya proyek.

---

## 2. Jantung Proyek: Direktori `lib/`

Ini adalah direktori tempat 99% penulisan kode (Dart) dilakukan. Proyek ini mengadopsi pola **Feature-First Architecture**.

### `lib/main.dart`
*   **Deskripsi:** Titik masuk (entry point) utama dari aplikasi Flutter. Biasa berisi inisialisasi awal (Firebase, Local DB) dan pembungkusan aplikasi dengan `ProviderScope` (untuk Riverpod).
*   **Status:** **BOLEH DIUBAH**. (Namun jaga agar tetap bersih, pindahkan logika kompleks ke `core/`).

### `lib/core/`
*   **Deskripsi:** Komponen lintas-fitur (global) yang dibagikan dan dapat digunakan di mana saja.
*   **Status:** **BOLEH DIUBAH (Hati-Hati)**. Perubahan di sini dapat berdampak pada seluruh aplikasi.
    *   `core/router/`: Mengatur navigasi aplikasi (`GoRouter`). Tambahkan *route* baru di sini.
    *   `core/theme/`: Definisi warna, tipografi, dan tema aplikasi (Dark/Light).
    *   `core/hardware/`: Kelas interaksi khusus (misalnya API untuk Bluetooth Printer, koneksi Cash Drawer).
    *   `core/data/`: Komponen data global seperti konfigurasi HttpClient (Dio), pengaturan Local Storage (SharedPreferences/Hive).

### `lib/features/`
*   **Deskripsi:** Kumpulan dari berbagai modul mandiri. Setiap *feature* (misal: `auth`, `products`, `transactions`) tidak boleh bergantung erat pada *feature* lain (kecuali melalui `core/`).
*   **Status:** **AREA KERJA UTAMA (BEBAS DIUBAH)**.
*   Setiap fitur memiliki subdivisi wajib:
    *   **`data/`**: Model data (`freezed`), API Services, dan Repositori.
    *   **`presentation/`**: Semua file yang berhubungan dengan *User Interface* (Screen, Widget khusus fitur tersebut).
    *   **`providers/`**: Manajemen state spesifik fitur tersebut (menggunakan Notifier/Riverpod).

---

## 3. Pengujian: Direktori `test/`

Berisi skrip untuk memastikan kode aplikasi berjalan tanpa *bug*.
*   **Deskripsi:** Strukturnya **harus** mencerminkan struktur folder `lib/`. Terdapat `widget_test.dart` dan folder per-fitur.
*   **Status:** **WAJIB DIUBAH/DITAMBAHKAN**. Saat Anda membuat fitur atau logika baru di `lib/`, Anda wajib membuat atau memperbarui pengujian yang berkorespondensi di folder `test/`.

---

## 4. Direktori Otomatis dan Native (Area Terlarang / Jarang Diubah)

Direktori-direktori di bawah ini sebaiknya tidak disentuh secara manual kecuali Anda tahu persis apa yang Anda lakukan untuk mengatur platform *native*.

*   **`android/` & `ios/`**
    *   **Deskripsi:** Berisi kode bahasa asli (Kotlin/Java untuk Android, Swift/Obj-C untuk iOS). Framework Flutter membutuhkan ini untuk mengompilasi aplikasi ke platform masing-masing.
    *   **Status:** **JARANG DIUBAH**. Hanya diubah saat perlu menambah *permission* (kamera, lokasi) di `AndroidManifest.xml` / `Info.plist`, atau mengonfigurasi rilis *build* (keystore).
*   **`build/` & `.dart_tool/`**
    *   **Deskripsi:** File sementara (*cache*) yang dihasilkan oleh proses *compiler* Flutter dan Dart. Jika Anda menghapus folder ini, Flutter akan membuatnya kembali secara otomatis.
    *   **Status:** **TIDAK BOLEH DIUBAH MANUAL**. Anda cukup menjalankan `flutter clean` untuk membersihkannya jika terjadi *error build*.
*   **`.idea/` & `mobile_pos_flutter.iml`**
    *   **Deskripsi:** Konfigurasi khusus untuk IDE Android Studio / IntelliJ.
    *   **Status:** **TIDAK BOLEH DIUBAH MANUAL**. Biarkan IDE yang mengurusnya.
*   **`.gemini/` & `.antigravitycli/`**
    *   **Deskripsi:** File sesi cache dan riwayat AI (lokal mesin Anda).
    *   **Status:** **TIDAK BOLEH DIUBAH MANUAL**. Dan **harus di-ignore** dari Git.
