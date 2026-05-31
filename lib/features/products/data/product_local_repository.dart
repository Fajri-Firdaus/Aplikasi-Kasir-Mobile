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

  Future<int> _getOrInsertCategoryId(String categoryName) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [categoryName],
    );

    if (maps.isNotEmpty) {
      return maps.first['id'] as int;
    } else {
      return await db.insert('categories', {'name': categoryName});
    }
  }

  Product _mapRowToProduct(Map<String, dynamic> row) {
    return Product(
      id: row['id'].toString(),
      name: row['name'] as String,
      price: (row['sell_price'] as num).toDouble(),
      category: row['category_name']?.toString() ?? 'Lainnya',
      imageUrl: row['image_path']?.toString() ?? '',
      stock: row['stock'] as int,
      sku: row['sku']?.toString(),
      isActive: row['is_active'] == 1,
    );
  }

  @override
  Future<List<Product>> getAll() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.is_active = 1
      ORDER BY p.name ASC
    ''');
    return maps.map(_mapRowToProduct).toList();
  }

  @override
  Future<Product?> getById(String id) async {
    final db = await _dbService.database;
    final intId = int.tryParse(id);
    if (intId == null) return null;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ? AND p.is_active = 1
    ''', [intId]);

    if (maps.isEmpty) return null;
    return _mapRowToProduct(maps.first);
  }

  @override
  Future<Product> create(Product item) async {
    final db = await _dbService.database;
    final categoryId = await _getOrInsertCategoryId(item.category);

    final id = await db.insert('products', {
      'sku': item.sku?.isEmpty == true ? null : item.sku,
      'name': item.name,
      'category_id': categoryId,
      'buy_price': item.price * 0.6, // Seeding/mocking buy price as 60% of sell price
      'sell_price': item.price,
      'stock': item.stock,
      'image_path': item.imageUrl,
      'is_active': 1,
    });

    return item.copyWith(id: id.toString());
  }

  @override
  Future<Product> update(String id, Product item) async {
    final db = await _dbService.database;
    final intId = int.tryParse(id);
    if (intId == null) throw Exception('Invalid Product ID');

    final categoryId = await _getOrInsertCategoryId(item.category);

    await db.update(
      'products',
      {
        'sku': item.sku?.isEmpty == true ? null : item.sku,
        'name': item.name,
        'category_id': categoryId,
        'buy_price': item.price * 0.6, // Keep mock relation
        'sell_price': item.price,
        'stock': item.stock,
        'image_path': item.imageUrl,
        'is_active': item.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [intId],
    );

    return item;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbService.database;
    final intId = int.tryParse(id);
    if (intId == null) return;

    // Perform soft delete according to design guidelines
    await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [intId],
    );
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE (p.sku = ? OR p.name LIKE ?) AND p.is_active = 1
      LIMIT 20
    ''', [query, '%$query%']);
    return maps.map(_mapRowToProduct).toList();
  }

  Future<List<Product>> getByCategory(String categoryName) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, c.name AS category_name
      FROM products p
      JOIN categories c ON p.category_id = c.id
      WHERE c.name = ? AND p.is_active = 1
      ORDER BY p.name ASC
    ''', [categoryName]);
    return maps.map(_mapRowToProduct).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      columns: ['name'],
      orderBy: 'name ASC',
    );
    return maps.map((row) => row['name'] as String).toList();
  }
}
