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

  Future<List<Customer>> getAll() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
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

  Future<Customer> create(String name, String phone) async {
    final db = await _dbService.database;
    final id = await db.insert('customers', {
      'name': name.trim(),
      'phone': phone.trim().isEmpty ? null : phone.trim(),
    });
    return Customer(
      id: id.toString(),
      name: name.trim(),
      phone: phone.trim().isEmpty ? null : phone.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}
