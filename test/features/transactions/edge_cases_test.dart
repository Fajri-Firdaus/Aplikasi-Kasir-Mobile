import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/transactions/providers/cart_provider.dart';
import 'package:mobile_pos_flutter/features/transactions/data/transaction_local_repository.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
      ],
    );
    addTearDown(() {
      container.read(localDatabaseServiceProvider).close();
      container.dispose();
    });
    return container;
  }

  group('FASE 6: E2E Edge Cases & Robustness Tests', () {
    test('Cash payment less than total amount throws error or is prevented', () async {
      final container = createContainer();
      final repo = container.read(transactionRepositoryProvider);
      await repo.openShift('1', 500000.0);

      const prod = Product(id: '1', name: 'Nasi Goreng', price: 25000, category: 'Makanan', imageUrl: '', stock: 10, sku: 'MK001');
      container.read(cartProvider.notifier).addProduct(prod);

      // Attempt checkout with cash 10000 when total is 25000
      expect(
        () async => await container.read(cartProvider.notifier).checkout(
          paymentMethod: 'cash',
          cashReceived: 10000.0, // Insufficient cash
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Adding product with stock 0 to cart is blocked or throws warning', () {
      final container = createContainer();
      const outOfStockProd = Product(id: '99', name: 'Es Teh Habis', price: 5000, category: 'Minuman', imageUrl: '', stock: 0, sku: 'MN999');

      // Attempt adding stock 0 product
      container.read(cartProvider.notifier).addProduct(outOfStockProd);
      
      // Cart should not accept item with 0 stock
      expect(container.read(cartProvider).isEmpty, true);
    });

    test('Checkout without open shift throws active shift exception', () async {
      final container = createContainer();
      const prod = Product(id: '1', name: 'Nasi Goreng', price: 25000, category: 'Makanan', imageUrl: '', stock: 10, sku: 'MK001');
      container.read(cartProvider.notifier).addProduct(prod);

      // Shift is NOT opened
      expect(
        () async => await container.read(cartProvider.notifier).checkout(
          paymentMethod: 'cash',
          cashReceived: 50000.0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Long store name and special characters do not break store settings persistence', () async {
      final container = createContainer();
      final dbService = container.read(localDatabaseServiceProvider);
      final db = await dbService.database;

      const longStoreName = 'Toko Serba Ada 99 & Resto Cafté "Super Star" 100% Guaranteed Indonesian Heritage Brand Long Title';
      
      await db.update('stores', {'store_name': longStoreName}, where: 'id = ?', whereArgs: ['store-uuid-001']);
      
      final res = await db.query('stores', where: 'id = ?', whereArgs: ['store-uuid-001']);
      expect(res.first['store_name'], longStoreName);
    });
  });
}
