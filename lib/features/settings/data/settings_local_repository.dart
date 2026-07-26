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

  Future<AppSettings> getSettings({String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'id = ?',
      whereArgs: [activeStoreId],
    );

    if (maps.isEmpty) {
      // Return default app settings if not seeded yet
      return AppSettings(
        id: activeStoreId,
        storeName: 'Mobile POS Dashboard',
        storeAddress: 'Jl. Merdeka No. 123',
        storePhone: '08123456789',
        receiptFooter: 'Terima kasih atas kunjungan Anda!',
      );
    }

    final row = maps.first;
    return AppSettings(
      id: row['id']?.toString() ?? activeStoreId,
      ownerId: row['owner_id']?.toString(),
      storeName: row['store_name'] as String,
      storeAddress: row['store_address']?.toString() ?? '',
      storePhone: row['store_phone']?.toString() ?? '',
      receiptFooter: row['receipt_footer']?.toString() ?? 'Terima kasih atas kunjungan Anda!',
      updatedAt: row['created_at']?.toString(),
    );
  }

  Future<AppSettings> updateSettings(AppSettings settings, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final targetStoreId = settings.id ?? activeStoreId;

    await db.update(
      'stores',
      {
        'store_name': settings.storeName,
        'store_address': settings.storeAddress,
        'store_phone': settings.storePhone,
        'receipt_footer': settings.receiptFooter,
      },
      where: 'id = ?',
      whereArgs: [targetStoreId],
    );

    try {
      await db.update(
        'store_settings',
        {
          'store_name': settings.storeName,
          'store_address': settings.storeAddress,
          'store_phone': settings.storePhone,
          'receipt_footer': settings.receiptFooter,
        },
        where: 'id = 1',
      );
    } catch (_) {}

    return settings;
  }

  Future<void> createStore({
    required String id,
    required String ownerId,
    required String storeName,
    String storeAddress = '',
    String storePhone = '',
    String receiptFooter = 'Terima kasih atas kunjungan Anda!',
  }) async {
    final db = await _dbService.database;
    await db.insert('stores', {
      'id': id,
      'owner_id': ownerId,
      'store_name': storeName,
      'store_address': storeAddress,
      'store_phone': storePhone,
      'receipt_footer': receiptFooter,
    });
  }
}
