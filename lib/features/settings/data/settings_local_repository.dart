import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/local_database_service.dart';
import 'app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsLocalRepository>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return SettingsLocalRepository(dbService);
});

class SettingsLocalRepository {
  final LocalDatabaseService _dbService;

  SettingsLocalRepository(this._dbService);

  Future<AppSettings> getSettings() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'store_settings',
      where: 'id = 1',
    );

    if (maps.isEmpty) {
      // Return default app settings if not seeded yet
      return const AppSettings(
        storeName: 'Mobile POS Dashboard',
        storeAddress: 'Jl. Merdeka No. 123',
        storePhone: '08123456789',
        receiptFooter: 'Terima kasih atas kunjungan Anda!',
      );
    }

    final row = maps.first;
    return AppSettings(
      storeName: row['store_name'] as String,
      storeAddress: row['store_address']?.toString() ?? '',
      storePhone: row['store_phone']?.toString() ?? '',
      receiptFooter: row['receipt_footer']?.toString() ?? 'Terima kasih atas kunjungan Anda!',
      updatedAt: row['updated_at']?.toString(),
    );
  }

  Future<AppSettings> updateSettings(AppSettings settings) async {
    final db = await _dbService.database;
    await db.update(
      'store_settings',
      {
        'store_name': settings.storeName,
        'store_address': settings.storeAddress,
        'store_phone': settings.storePhone,
        'receipt_footer': settings.receiptFooter,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = 1',
    );
    return settings;
  }
}
