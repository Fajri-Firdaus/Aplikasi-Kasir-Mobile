# Alur Kerja Pengembangan Fitur (SOP)

Dokumen ini menjelaskan langkah-langkah standar untuk menambahkan fitur baru ke dalam proyek Mobile POS Flutter.

## Langkah 1: Persiapan & Model Data
1. Identifikasi kebutuhan data untuk fitur tersebut.
2. Buat file model di `lib/features/<nama_fitur>/data/models/<nama_model>.dart`.
3. Gunakan `freezed` untuk membuat model data yang immutable.
4. Contoh boilerplate model:
   ```dart
   import 'package:freezed_annotation/freezed_annotation.dart';

   part 'nama_model.freezed.dart';
   part 'nama_model.g.dart';

   @freezed
   class NamaModel with _$NamaModel {
     const factory NamaModel({
       required String id,
       // field lainnya
     }) = _NamaModel;

     factory NamaModel.fromJson(Map<String, dynamic> json) => _$NamaModelFromJson(json);
   }
   ```

## Langkah 2: Menjalankan Code Generator
Setiap kali ada perubahan pada file yang menggunakan `@freezed`, `@JsonSerializable`, atau `@riverpod`, jalankan perintah berikut:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Langkah 3: Logika Bisnis (Riverpod Notifier)
1. Buat file notifier di `lib/features/<nama_fitur>/providers/<nama_fitur>_notifier.dart`.
2. Gunakan `Notifier` atau `AsyncNotifier` untuk mengelola state.
3. Contoh:
   ```dart
   import 'package:riverpod_annotation/riverpod_annotation.dart';
   part 'nama_notifier.g.dart';

   @riverpod
   class NamaNotifier extends _$NamaNotifier {
     @override
     NamaState build() => const NamaState();

     void updateData() {
       state = state.copyWith(...);
     }
   }
   ```

## Langkah 4: Antarmuka Pengguna (Presentation)
1. Buat folder `lib/features/<nama_fitur>/presentation/screens/` dan `widgets/`.
2. Buat widget UI dan hubungkan dengan provider menggunakan `ConsumerWidget` atau `ConsumerStatefulWidget`.
3. Daftarkan screen baru di `lib/core/router/app_router.dart`.

## Langkah 5: Pengujian (Testing)
1. Buat file test di `test/features/<nama_fitur>/<nama_notifier>_test.dart`.
2. Pastikan logika di dalam Notifier berjalan sesuai ekspektasi.
3. Jalankan `flutter test` untuk memverifikasi.

## Perintah Penting
| Kegunaan | Perintah |
|---|---|
| Menjalankan Generator | `flutter pub run build_runner build --delete-conflicting-outputs` |
| Menjalankan Test | `flutter test` |
| Membersihkan Cache | `flutter clean && flutter pub get` |
