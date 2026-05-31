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
      category: 'Makanan',
      imageUrl: '',
      stock: 15,
      sku: 'NL001',
    );
    
    await notifier.addProduct(newProduct);
    
    final state = container.read(productNotifierProvider);
    expect(state.any((p) => p.name == 'Nasi Liwet Special'), true);
  });

  test('ProductNotifier deletes product', () async {
    final container = createContainer();
    final notifier = container.read(productNotifierProvider.notifier);
    
    // Wait for initial load
    await notifier.loadProducts();
    
    // Seed data initial has ID 1 (Nasi Goreng Spesial)
    final stateBefore = container.read(productNotifierProvider);
    final hasId1 = stateBefore.any((p) => p.id == '1');
    expect(hasId1, true);

    await notifier.deleteProduct('1');
    
    final stateAfter = container.read(productNotifierProvider);
    expect(stateAfter.any((p) => p.id == '1'), false);
  });

  test('ProductNotifier updates product', () async {
    final container = createContainer();
    final notifier = container.read(productNotifierProvider.notifier);
    
    await notifier.loadProducts();
    
    final updatedProduct = const Product(
      id: '1',
      name: 'Nasi Goreng Super Pedas',
      price: 27000,
      category: 'Makanan',
      imageUrl: '',
      stock: 45,
      sku: 'MK001',
    );
    
    await notifier.updateProduct('1', updatedProduct);
    
    final state = container.read(productNotifierProvider);
    final product = state.firstWhere((p) => p.id == '1');
    expect(product.name, 'Nasi Goreng Super Pedas');
    expect(product.price, 27000);
  });
}
