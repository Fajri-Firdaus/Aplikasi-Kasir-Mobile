import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/customers/data/customer_repository.dart';
import 'package:mobile_pos_flutter/features/customers/providers/customer_provider.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  test('CustomerRepository creates customer with valid id and store_id without NOT NULL error', () async {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
      ],
    );
    addTearDown(() {
      container.read(localDatabaseServiceProvider).close();
      container.dispose();
    });

    final repo = container.read(customerRepositoryProvider);
    final customer = await repo.create('Budi Santoso', '081299998888', storeId: 'store-uuid-001');

    expect(customer.id, startsWith('cust_'));
    expect(customer.name, 'Budi Santoso');
    expect(customer.phone, '081299998888');

    final list = await repo.getAll(storeId: 'store-uuid-001');
    expect(list.any((c) => c.name == 'Budi Santoso'), true);
  });

  test('CustomerNotifier addCustomer successfully registers customer', () async {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
      ],
    );
    addTearDown(() {
      container.read(localDatabaseServiceProvider).close();
      container.dispose();
    });

    final notifier = container.read(customerProvider.notifier);
    final cust = await notifier.addCustomer('Siti Aminah', '085711112222');

    expect(cust.name, 'Siti Aminah');
    expect(cust.id, isNotEmpty);
  });
}
