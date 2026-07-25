import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/transactions/data/transaction_local_repository.dart';
import 'package:mobile_pos_flutter/features/transactions/data/cart_item.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  const productA = Product(id: '1', name: 'Nasi Goreng Spesial', price: 25000, category: 'Makanan', imageUrl: '', stock: 50, sku: 'MK001');

  test('getDailyTransactionSequence correctly increments for transactions on the same day', () async {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
      ],
    );
    addTearDown(() {
      container.read(localDatabaseServiceProvider).close();
      container.dispose();
    });

    final repo = container.read(transactionRepositoryProvider);
    final shift = await repo.openShift('1', 500000.0);

    // Create 1st transaction
    final txn1 = await repo.checkout(
      shiftId: shift.id,
      totalAmount: 25000.0,
      paymentMethod: 'cash',
      cashReceived: 50000.0,
      items: [CartItem(product: productA, quantity: 1)],
    );

    // Create 2nd transaction
    final txn2 = await repo.checkout(
      shiftId: shift.id,
      totalAmount: 50000.0,
      paymentMethod: 'cash',
      cashReceived: 50000.0,
      items: [CartItem(product: productA, quantity: 2)],
    );

    // Create 3rd transaction
    final txn3 = await repo.checkout(
      shiftId: shift.id,
      totalAmount: 25000.0,
      paymentMethod: 'qris',
      cashReceived: 25000.0,
      items: [CartItem(product: productA, quantity: 1)],
    );

    final seq1 = await repo.getDailyTransactionSequence(txn1.id);
    final seq2 = await repo.getDailyTransactionSequence(txn2.id);
    final seq3 = await repo.getDailyTransactionSequence(txn3.id);

    expect(seq1, equals(1));
    expect(seq2, equals(2));
    expect(seq3, equals(3));
  });
}
