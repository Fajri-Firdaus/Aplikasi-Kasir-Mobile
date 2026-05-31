import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/transactions/providers/cart_provider.dart';
import 'package:mobile_pos_flutter/features/products/providers/product_provider.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';
import 'package:mobile_pos_flutter/features/transactions/data/transaction_local_repository.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  const productA = Product(id: '1', name: 'Nasi Goreng Spesial', price: 25000, category: 'Makanan', imageUrl: '', stock: 50, sku: 'MK001');
  const productB = Product(id: '2', name: 'Mie Goreng Seafood', price: 30000, category: 'Makanan', imageUrl: '', stock: 30, sku: 'MK002');

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

  test('CartNotifier adds product', () {
    final container = createContainer();
    container.read(cartProvider.notifier).addProduct(productA);
    expect(container.read(cartProvider).length, 1);
    expect(container.read(cartProvider).first.product.id, '1');
    expect(container.read(cartProvider).first.quantity, 1);
  });

  test('CartNotifier increments quantity for existing product', () {
    final container = createContainer();
    container.read(cartProvider.notifier).addProduct(productA);
    container.read(cartProvider.notifier).addProduct(productA);
    expect(container.read(cartProvider).length, 1);
    expect(container.read(cartProvider).first.quantity, 2);
  });

  test('CartNotifier updates quantity correctly', () {
    final container = createContainer();
    container.read(cartProvider.notifier).addProduct(productA);
    container.read(cartProvider.notifier).updateQuantity('1', 5);
    expect(container.read(cartProvider).first.quantity, 5);
  });

  test('CartNotifier removes product when quantity is 0', () {
    final container = createContainer();
    container.read(cartProvider.notifier).addProduct(productA);
    container.read(cartProvider.notifier).updateQuantity('1', 0);
    expect(container.read(cartProvider).isEmpty, true);
  });

  test('CartNotifier calculates total correctly', () {
    final container = createContainer();
    container.read(cartProvider.notifier).addProduct(productA); // 25000
    container.read(cartProvider.notifier).addProduct(productB); // 30000
    container.read(cartProvider.notifier).updateQuantity('2', 2); // 60000
    expect(container.read(cartProvider.notifier).totalAmount, 85000);
  });

  test('CartNotifier clears cart', () {
    final container = createContainer();
    container.read(cartProvider.notifier).addProduct(productA);
    container.read(cartProvider.notifier).clearCart();
    expect(container.read(cartProvider).isEmpty, true);
  });

  test('CartNotifier executes checkout and decrements database stock', () async {
    final container = createContainer();
    
    // Inisialisasi data produk dari database agar tersinkronisasi
    final productNotifier = container.read(productNotifierProvider.notifier);
    await productNotifier.loadProducts();
    
    // Get product from notifier (which matches SQLite seeded product with ID 1, stock 50)
    final initialProducts = container.read(productNotifierProvider);
    final initialProduct1 = initialProducts.firstWhere((p) => p.id == '1');
    expect(initialProduct1.stock, 50);

    // Add to cart
    container.read(cartProvider.notifier).addProduct(initialProduct1);
    container.read(cartProvider.notifier).updateQuantity('1', 5); // Buy 5

    // Run checkout
    await container.read(cartProvider.notifier).checkout(
      paymentMethod: 'cash',
      cashReceived: 150000.0,
    );

    // Cart should be cleared
    expect(container.read(cartProvider).isEmpty, true);

    // Product state stock should be updated (50 - 5 = 45)
    final updatedProducts = container.read(productNotifierProvider);
    final updatedProduct1 = updatedProducts.firstWhere((p) => p.id == '1');
    expect(updatedProduct1.stock, 45);

    // Database check (fetch transactions history)
    final txns = await container.read(transactionRepositoryProvider).getAll();
    expect(txns.length, 1);
    expect(txns.first.paymentMethod, 'cash');
    expect(txns.first.totalAmount, 125000.0); // 25000 * 5
  });
}
