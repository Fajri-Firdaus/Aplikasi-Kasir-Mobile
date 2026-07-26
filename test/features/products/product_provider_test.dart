import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/products/providers/product_provider.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';
import '../../test_helper.dart';

void main() {
  // Initialize test SQLite factory
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

  test('ProductNotifier adds new product', () async {
    final container = createContainer();
    final notifier = container.read(productNotifierProvider.notifier);
    
    // Wait for initial load
    await notifier.loadProducts();

    final newProduct = const Product(
      id: '', // Will be assigned by database
      name: 'Nasi Liwet Special',
      price: 22000,
      buyPrice: 15000,
      category: 'Makanan',
      imageUrl: '',
      stock: 15,
      sku: 'NL001',
    );
    
    await notifier.addProduct(newProduct);
    
    final state = container.read(productNotifierProvider);
    final added = state.firstWhere((p) => p.name == 'Nasi Liwet Special');
    expect(added.buyPrice, 15000);
    expect(added.sku, 'NL001');
  });

  test('ProductNotifier deletes product', () async {
    final container = createContainer();
    final notifier = container.read(productNotifierProvider.notifier);
    
    // Wait for initial load
    await notifier.loadProducts();
    
    // Seed data initial has seeded product (Nasi Goreng Spesial)
    final stateBefore = container.read(productNotifierProvider);
    final targetProduct = stateBefore.firstWhere((p) => p.name == 'Nasi Goreng Spesial');
    
    await notifier.deleteProduct(targetProduct.id);
    
    final stateAfter = container.read(productNotifierProvider);
    expect(stateAfter.any((p) => p.id == targetProduct.id), false);
  });

  test('ProductNotifier updates product', () async {
    final container = createContainer();
    final notifier = container.read(productNotifierProvider.notifier);
    
    await notifier.loadProducts();
    
    final stateBefore = container.read(productNotifierProvider);
    final targetProduct = stateBefore.firstWhere((p) => p.name == 'Nasi Goreng Spesial');
    
    final updatedProduct = targetProduct.copyWith(
      name: 'Nasi Goreng Super Pedas',
      price: 27000,
      buyPrice: 18000,
      sku: 'MK001-NEW',
    );
    
    await notifier.updateProduct(targetProduct.id, updatedProduct);
    
    final state = container.read(productNotifierProvider);
    final product = state.firstWhere((p) => p.id == targetProduct.id);
    expect(product.name, 'Nasi Goreng Super Pedas');
    expect(product.price, 27000);
    expect(product.buyPrice, 18000);
    expect(product.sku, 'MK001-NEW');
  });
}
