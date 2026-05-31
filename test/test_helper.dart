import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void setupTestDatabase() {
  // Initialize sqflite ffi
  sqfliteFfiInit();
  // Override database factory with ffi one
  databaseFactory = databaseFactoryFfi;
}
