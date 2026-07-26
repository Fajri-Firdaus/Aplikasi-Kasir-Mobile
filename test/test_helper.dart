import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void setupTestDatabase() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  // Initialize sqflite ffi
  sqfliteFfiInit();
  // Override database factory with ffi one
  databaseFactory = databaseFactoryFfi;
}
