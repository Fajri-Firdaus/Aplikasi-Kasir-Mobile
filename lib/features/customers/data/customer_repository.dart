import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/local_database_service.dart';
import 'customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return CustomerRepository(dbService);
});

class CustomerRepository {
  final LocalDatabaseService _dbService;

  CustomerRepository(this._dbService);

  Future<List<Customer>> getAll({String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'store_id = ?',
      whereArgs: [activeStoreId],
      orderBy: 'name ASC',
    );
    return maps.map((row) {
      return Customer(
        id: row['id'].toString(),
        name: row['name'] as String,
        phone: row['phone']?.toString(),
        createdAt: row['created_at']?.toString(),
      );
    }).toList();
  }

  Future<Customer> create(String name, String phone, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final newId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
    final nowStr = DateTime.now().toIso8601String();

    await db.insert('customers', {
      'id': newId,
      'store_id': activeStoreId,
      'name': name.trim(),
      'phone': phone.trim().isEmpty ? null : phone.trim(),
      'created_at': nowStr,
    });

    return Customer(
      id: newId,
      name: name.trim(),
      phone: phone.trim().isEmpty ? null : phone.trim(),
      createdAt: nowStr,
    );
  }
}
