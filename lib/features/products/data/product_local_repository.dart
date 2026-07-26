import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/repository_interface.dart';
import '../../../core/data/local_database_service.dart';
import 'product.dart';

final productRepositoryProvider = Provider<ProductLocalRepository>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return ProductLocalRepository(dbService);
});

class ProductLocalRepository implements RepositoryInterface<Product> {
  final LocalDatabaseService _dbService;

  ProductLocalRepository(this._dbService);

  Future<String> _getOrInsertCategoryId(String categoryName, {String storeId = 'store-uuid-001'}) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'categories',
      where: 'name = ? AND store_id = ?',
      whereArgs: [categoryName, storeId],
    );

    if (maps.isNotEmpty) {
      return maps.first['id'].toString();
    } else {
      final newCatId = DateTime.now().millisecondsSinceEpoch.toString();
      await db.insert('categories', {
        'id': newCatId,
        'store_id': storeId,
        'name': categoryName,
        'is_active': 1,
      });
      return newCatId;
    }
  }

  Product _mapRowToProduct(Map<String, dynamic> row) {
    return Product(
      id: row['id'].toString(),
      name: row['name'] as String,
      price: (row['sell_price'] as num).toDouble(),
      buyPrice: (row['buy_price'] as num?)?.toDouble() ?? 0.0,
      category: row['category_name']?.toString() ?? 'Lainnya',
      imageUrl: row['image_path']?.toString() ?? '',
      stock: row['stock'] as int,
      sku: row['sku']?.toString(),
      isActive: (row['is_active'] as int? ?? 1) == 1,
    );
  }

  @override
  Future<List<Product>> getAll({String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.store_id = ? AND p.is_active = 1
      ORDER BY p.name ASC
    ''', [activeStoreId]);
    return maps.map(_mapRowToProduct).toList();
  }

  @override
  Future<Product?> getById(String id) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ? AND p.is_active = 1
    ''', [id]);

    if (maps.isEmpty) return null;
    return _mapRowToProduct(maps.first);
  }

  @override
  Future<Product> create(Product item, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final categoryId = await _getOrInsertCategoryId(item.category, storeId: activeStoreId);
    final prodId = item.id.isNotEmpty ? item.id : DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('products', {
      'id': prodId,
      'store_id': activeStoreId,
      'sku': item.sku?.isEmpty == true ? null : item.sku,
      'name': item.name,
      'category_id': categoryId,
      'buy_price': item.buyPrice,
      'sell_price': item.price,
      'stock': item.stock,
      'image_path': item.imageUrl,
      'is_active': 1,
    });

    return item.copyWith(id: prodId);
  }

  @override
  Future<Product> update(String id, Product item, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final categoryId = await _getOrInsertCategoryId(item.category, storeId: activeStoreId);

    await db.update(
      'products',
      {
        'sku': item.sku?.isEmpty == true ? null : item.sku,
        'name': item.name,
        'category_id': categoryId,
        'buy_price': item.buyPrice,
        'sell_price': item.price,
        'stock': item.stock,
        'image_path': item.imageUrl,
        'is_active': item.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return item;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbService.database;

    // Perform soft delete according to design guidelines
    await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> searchProducts(String query, {String storeId = 'store-uuid-001'}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.store_id = ? AND (p.sku = ? OR p.name LIKE ?) AND p.is_active = 1
      LIMIT 20
    ''', [storeId, query, '%$query%']);
    return maps.map(_mapRowToProduct).toList();
  }

  Future<List<Product>> getByCategory(String categoryName, {String storeId = 'store-uuid-001'}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, c.name AS category_name
      FROM products p
      JOIN categories c ON p.category_id = c.id
      WHERE p.store_id = ? AND c.name = ? AND p.is_active = 1
      ORDER BY p.name ASC
    ''', [storeId, categoryName]);
    return maps.map(_mapRowToProduct).toList();
  }

  Future<List<String>> getCategories({String storeId = 'store-uuid-001'}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      columns: ['name'],
      where: 'store_id = ? AND is_active = 1',
      whereArgs: [storeId],
      orderBy: 'name ASC',
    );
    return maps.map((row) => row['name'] as String).toList();
  }
}
