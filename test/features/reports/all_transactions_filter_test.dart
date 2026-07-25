import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/transactions/data/transaction_local_repository.dart';
import 'package:mobile_pos_flutter/features/reports/providers/transactions_report_provider.dart';
import 'package:mobile_pos_flutter/features/transactions/data/cart_item.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  const productA = Product(id: '1', name: 'Es Teh Manis', price: 5000, category: 'Minuman', imageUrl: '', stock: 100, sku: 'MN001');

  test('AllTransactionsNotifier filters transactions created today accurately', () async {
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
    final shift = await repo.openShift('1', 200000.0);

    // Create 2 transactions today
    await repo.checkout(
      shiftId: shift.id,
      totalAmount: 10000.0,
      paymentMethod: 'cash',
      cashReceived: 10000.0,
      items: [CartItem(product: productA, quantity: 2)],
    );

    await repo.checkout(
      shiftId: shift.id,
      totalAmount: 5000.0,
      paymentMethod: 'qris',
      cashReceived: 5000.0,
      items: [CartItem(product: productA, quantity: 1)],
    );

    final notifier = container.read(allTransactionsNotifierProvider.notifier);
    await notifier.filterBy(TransactionFilterPeriod.today);

    final state = container.read(allTransactionsNotifierProvider);
    expect(state.transactions.length, equals(2));
    expect(state.totalRevenue, equals(15000.0));
    expect(state.totalCount, equals(2));
  });
}
