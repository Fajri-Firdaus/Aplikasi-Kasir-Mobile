import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/features/transactions/providers/cart_provider.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';

void main() {
  const productA = Product(id: '1', name: 'Item A', price: 10000, category: 'Food', imageUrl: '', stock: 10);
  const productB = Product(id: '2', name: 'Item B', price: 15000, category: 'Food', imageUrl: '', stock: 5);

  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
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
    container.read(cartProvider.notifier).addProduct(productA); // 10000
    container.read(cartProvider.notifier).addProduct(productB); // 15000
    container.read(cartProvider.notifier).updateQuantity('2', 2); // 30000
    expect(container.read(cartProvider.notifier).totalAmount, 40000);
  });

  test('CartNotifier clears cart', () {
    final container = createContainer();
    container.read(cartProvider.notifier).addProduct(productA);
    container.read(cartProvider.notifier).clearCart();
    expect(container.read(cartProvider).isEmpty, true);
  });
}
