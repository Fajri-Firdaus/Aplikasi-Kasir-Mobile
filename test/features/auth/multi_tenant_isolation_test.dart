import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/products/data/product_local_repository.dart';
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

  test('Multi-tenant store isolation ensures Store A data is completely hidden from Store B', () async {
    final container = createContainer();
    final productRepo = container.read(productRepositoryProvider);

    const storeAId = 'store-uuid-a';
    const storeBId = 'store-uuid-b';

    // 0. Seed Admins and Stores A and B in database
    final dbService = container.read(localDatabaseServiceProvider);
    final db = await dbService.database;
    await db.insert('users', {'id': 'admin-a', 'username': 'admin_a', 'password': 'pass', 'role': 'admin'});
    await db.insert('users', {'id': 'admin-b', 'username': 'admin_b', 'password': 'pass', 'role': 'admin'});
    await db.insert('stores', {'id': storeAId, 'owner_id': 'admin-a', 'store_name': 'Toko A'});
    await db.insert('stores', {'id': storeBId, 'owner_id': 'admin-b', 'store_name': 'Toko B'});

    // 1. Store A adds a product
    final prodA = const Product(
      id: 'prod-a-001',
      name: 'Produk Toko A',
      price: 50000,
      category: 'Makanan',
      imageUrl: '',
      stock: 20,
    );
    await productRepo.create(prodA, storeId: storeAId);

    // 2. Store B adds a product
    final prodB = const Product(
      id: 'prod-b-001',
      name: 'Produk Toko B',
      price: 75000,
      category: 'Minuman',
      imageUrl: '',
      stock: 10,
    );
    await productRepo.create(prodB, storeId: storeBId);

    // 3. Query Store A products - should ONLY contain Store A product
    final storeAProducts = await productRepo.getAll(storeId: storeAId);
    expect(storeAProducts.any((p) => p.name == 'Produk Toko A'), true);
    expect(storeAProducts.any((p) => p.name == 'Produk Toko B'), false);

    // 4. Query Store B products - should ONLY contain Store B product
    final storeBProducts = await productRepo.getAll(storeId: storeBId);
    expect(storeBProducts.any((p) => p.name == 'Produk Toko B'), true);
    expect(storeBProducts.any((p) => p.name == 'Produk Toko A'), false);
  });
}
