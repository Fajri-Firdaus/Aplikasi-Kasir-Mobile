import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/transactions/data/transaction_local_repository.dart';
import 'package:mobile_pos_flutter/features/transactions/data/cart_item.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';
import 'package:mobile_pos_flutter/features/reports/data/report_local_repository.dart';
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

  group('FASE 4: SQLite ACID & Void & Performance Tests', () {
    test('Checkout Atomic Transaction executes all 3 steps successfully', () async {
      final container = createContainer();
      final repo = container.read(transactionRepositoryProvider);

      final shift = await repo.openShift('1', 500000.0);

      const prod1 = Product(id: '1', name: 'Kopi', price: 15000, category: 'Minuman', imageUrl: '', stock: 50, sku: 'K001');
      const prod2 = Product(id: '2', name: 'Teh', price: 10000, category: 'Minuman', imageUrl: '', stock: 30, sku: 'T001');

      final db = await container.read(localDatabaseServiceProvider).database;
      await db.insert('products', {
        'id': '2',
        'store_id': 'store-uuid-001',
        'name': 'Teh',
        'sku': 'T001',
        'buy_price': 5000.0,
        'sell_price': 10000.0,
        'stock': 30,
        'is_active': 1,
      });

      final items = [
        const CartItem(product: prod1, quantity: 2),
        const CartItem(product: prod2, quantity: 3),
      ];

      final txn = await repo.checkout(
        shiftId: shift.id,
        totalAmount: 60000.0,
        paymentMethod: 'cash',
        cashReceived: 100000.0,
        items: items,
        storeId: 'store-uuid-001',
      );

      expect(txn.status, 'completed');
      expect(txn.totalAmount, 60000.0);

      // Verify stock was decremented in database
      final p1Res = await db.query('products', where: 'id = ?', whereArgs: ['1']);
      final p2Res = await db.query('products', where: 'id = ?', whereArgs: ['2']);

      expect(p1Res.first['stock'], 48); // 50 - 2
      expect(p2Res.first['stock'], 27); // 30 - 3
    });

    test('Checkout rolls back transaction completely if item stock is insufficient or invalid', () async {
      final container = createContainer();
      final repo = container.read(transactionRepositoryProvider);

      final shift = await repo.openShift('1', 500000.0);

      const prod1 = Product(id: '1', name: 'Kopi', price: 15000, category: 'Minuman', imageUrl: '', stock: 50, sku: 'K001');
      const prodOver = Product(id: '1', name: 'Kopi', price: 15000, category: 'Minuman', imageUrl: '', stock: 50, sku: 'K001');

      final items = [
        const CartItem(product: prod1, quantity: 2),
        const CartItem(product: prodOver, quantity: 999), // Will trigger exception during transaction loop
      ];

      expect(
        () async => await repo.checkout(
          shiftId: shift.id,
          totalAmount: 15000000.0,
          paymentMethod: 'cash',
          cashReceived: 15000000.0,
          items: items,
          storeId: 'store-uuid-001',
        ),
        throwsA(isA<Exception>()),
      );

      // Verify rollback: prod1 stock MUST remain 50 and no transactions created
      final db = await container.read(localDatabaseServiceProvider).database;
      final p1Res = await db.query('products', where: 'id = ?', whereArgs: ['1']);
      expect(p1Res.first['stock'], 50);

      final txns = await repo.getAll();
      expect(txns.isEmpty, true);
    });

    test('Void Transaction restores product stock and updates transaction status', () async {
      final container = createContainer();
      final repo = container.read(transactionRepositoryProvider);
      final reportRepo = container.read(reportRepositoryProvider);

      final shift = await repo.openShift('1', 500000.0);

      const prod1 = Product(id: '1', name: 'Kopi', price: 15000, category: 'Minuman', imageUrl: '', stock: 50, sku: 'K001');
      final items = [const CartItem(product: prod1, quantity: 5)];

      final txn = await repo.checkout(
        shiftId: shift.id,
        totalAmount: 75000.0,
        paymentMethod: 'cash',
        cashReceived: 100000.0,
        items: items,
        storeId: 'store-uuid-001',
      );

      final db = await container.read(localDatabaseServiceProvider).database;
      var p1Res = await db.query('products', where: 'id = ?', whereArgs: ['1']);
      expect(p1Res.first['stock'], 45); // 50 - 5

      // Void the transaction
      await repo.voidTransaction(txn.id);

      // Verify transaction status is void
      final voidedTxn = await repo.getById(txn.id);
      expect(voidedTxn?.status, 'void');

      // Verify stock was restored to 50
      p1Res = await db.query('products', where: 'id = ?', whereArgs: ['1']);
      expect(p1Res.first['stock'], 50);

      // Verify Omzet in report excludes voided transactions
      final summary = await reportRepo.getTodaySummary(storeId: 'store-uuid-001');
      expect(summary.totalRevenue, 0.0);
    });

    test('SQLite Stress & Performance: 1,000 products query completes under 100ms', () async {
      final container = createContainer();
      final db = await container.read(localDatabaseServiceProvider).database;

      final batch = db.batch();
      for (int i = 100; i < 1100; i++) {
        batch.insert('products', {
          'id': '$i',
          'store_id': 'store-uuid-001',
          'name': 'Product Stress Test $i',
          'sku': 'SKU-$i',
          'category_id': null,
          'buy_price': 10000.0,
          'sell_price': 15000.0,
          'stock': 100,
          'is_active': 1,
        });
      }
      await batch.commit(noResult: true);

      final stopwatch = Stopwatch()..start();
      final results = await db.query(
        'products',
        where: 'store_id = ? AND sku LIKE ?',
        whereArgs: ['store-uuid-001', '%SKU-55%'],
      );
      stopwatch.stop();

      expect(results.isNotEmpty, true);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
