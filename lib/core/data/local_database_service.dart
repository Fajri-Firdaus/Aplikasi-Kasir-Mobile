import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

class LocalDatabaseService {
  Database? _db;
  final bool isTesting;

  LocalDatabaseService({this.isTesting = false});

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (isTesting) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
        onOpen: _onOpen,
      );
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'mobile_pos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    // Migration helper for existing DBs
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stores (
          id TEXT PRIMARY KEY,
          owner_id TEXT NOT NULL,
          store_name TEXT NOT NULL,
          store_address TEXT,
          store_phone TEXT,
          receipt_footer TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    } catch (_) {}

    try { await db.execute('ALTER TABLE users ADD COLUMN admin_id TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE users ADD COLUMN store_id TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1'); } catch (_) {}
    try { await db.execute('ALTER TABLE categories ADD COLUMN store_id TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE categories ADD COLUMN is_active INTEGER DEFAULT 1'); } catch (_) {}
    try { await db.execute('ALTER TABLE products ADD COLUMN store_id TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE products ADD COLUMN is_active INTEGER DEFAULT 1'); } catch (_) {}
    try { await db.execute('ALTER TABLE customers ADD COLUMN store_id TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE shifts ADD COLUMN store_id TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE shifts ADD COLUMN shift_number INTEGER DEFAULT 1'); } catch (_) {}
    try { await db.execute('ALTER TABLE transactions ADD COLUMN store_id TEXT'); } catch (_) {}

    // Backfill default store for existing data if store_id is null
    const defaultStoreId = 'store-uuid-001';
    const defaultAdminId = '1';

    final storeCheck = await db.rawQuery("SELECT id FROM stores WHERE id = ?", [defaultStoreId]);
    if (storeCheck.isEmpty) {
      await db.insert('stores', {
        'id': defaultStoreId,
        'owner_id': defaultAdminId,
        'store_name': 'Mobile POS Dashboard',
        'store_address': 'Jl. Merdeka No. 123',
        'store_phone': '08123456789',
        'receipt_footer': 'Terima kasih atas kunjungan Anda!',
      });
    }

    await db.execute("UPDATE users SET store_id = '$defaultStoreId' WHERE store_id IS NULL");
    await db.execute("UPDATE categories SET store_id = '$defaultStoreId' WHERE store_id IS NULL");
    await db.execute("UPDATE products SET store_id = '$defaultStoreId' WHERE store_id IS NULL");
    await db.execute("UPDATE customers SET store_id = '$defaultStoreId' WHERE store_id IS NULL");
    await db.execute("UPDATE shifts SET store_id = '$defaultStoreId' WHERE store_id IS NULL");
    await db.execute("UPDATE transactions SET store_id = '$defaultStoreId' WHERE store_id IS NULL");

    // Indexes
    try { await db.execute('CREATE INDEX IF NOT EXISTS idx_products_store ON products(store_id)'); } catch (_) {}
    try { await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_store ON transactions(store_id)'); } catch (_) {}
    try { await db.execute('CREATE INDEX IF NOT EXISTS idx_shifts_store ON shifts(store_id)'); } catch (_) {}
    try { await db.execute('CREATE INDEX IF NOT EXISTS idx_users_store ON users(store_id)'); } catch (_) {}
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys constraints support in SQLite
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    const defaultAdminId = '1';
    const defaultStoreId = 'store-uuid-001';
    const defaultCategoryId = 'cat-uuid-001';
    const defaultProductId = '1';

    // 1. Table stores
    await db.execute('''
      CREATE TABLE stores (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        store_name TEXT NOT NULL,
        store_address TEXT,
        store_phone TEXT,
        receipt_footer TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Table users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT,
        email TEXT UNIQUE,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'cashier',
        admin_id TEXT,
        store_id TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (store_id) REFERENCES stores(id)
      )
    ''');

    // 3. Table categories
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        name TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (store_id) REFERENCES stores(id),
        UNIQUE(store_id, name)
      )
    ''');

    // 4. Table products
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        sku TEXT,
        name TEXT NOT NULL,
        category_id TEXT,
        buy_price REAL NOT NULL DEFAULT 0.0,
        sell_price REAL NOT NULL DEFAULT 0.0,
        stock INTEGER DEFAULT 0,
        image_path TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (store_id) REFERENCES stores(id),
        FOREIGN KEY (category_id) REFERENCES categories(id),
        UNIQUE(store_id, sku)
      )
    ''');

    // 5. Table customers
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (store_id) REFERENCES stores(id)
      )
    ''');

    // 6. Table shifts
    await db.execute('''
      CREATE TABLE shifts (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        end_time TIMESTAMP,
        starting_cash REAL DEFAULT 0.0,
        ending_cash REAL DEFAULT 0.0,
        status TEXT CHECK (status IN ('open', 'closed')) DEFAULT 'open',
        shift_number INTEGER DEFAULT 1,
        FOREIGN KEY (store_id) REFERENCES stores(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // 7. Table transactions
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        shift_id TEXT NOT NULL,
        customer_id TEXT,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        cash_received REAL DEFAULT 0.0,
        status TEXT CHECK (status IN ('completed', 'void')) DEFAULT 'completed',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (store_id) REFERENCES stores(id),
        FOREIGN KEY (shift_id) REFERENCES shifts(id),
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    // 8. Table transaction_details
    await db.execute('''
      CREATE TABLE transaction_details (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        buy_price_at_sale REAL NOT NULL,
        sell_price_at_sale REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_products_store ON products(store_id)');
    await db.execute('CREATE INDEX idx_transactions_store ON transactions(store_id)');
    await db.execute('CREATE INDEX idx_shifts_store ON shifts(store_id)');
    await db.execute('CREATE INDEX idx_users_store ON users(store_id)');

    // --- Seed Initial Data ---
    // Seed default store first (required by users.store_id Foreign Key)
    await db.insert('stores', {
      'id': defaultStoreId,
      'owner_id': defaultAdminId,
      'store_name': 'Mobile POS Dashboard',
      'store_address': 'Jl. Merdeka No. 123',
      'store_phone': '08123456789',
      'receipt_footer': 'Terima kasih atas kunjungan Anda!',
    });

    // Seed default admin user
    await db.insert('users', {
      'id': defaultAdminId,
      'full_name': 'Admin System',
      'email': 'admin@pos.com',
      'username': 'admin',
      'password': 'MTIzNDU2', // Base64 for '123456'
      'role': 'admin',
      'store_id': defaultStoreId,
      'admin_id': defaultAdminId,
      'is_active': 1,
    });

    // Seed default category
    await db.insert('categories', {
      'id': defaultCategoryId,
      'store_id': defaultStoreId,
      'name': 'Makanan',
      'is_active': 1,
    });

    // Seed default product
    await db.insert('products', {
      'id': defaultProductId,
      'store_id': defaultStoreId,
      'sku': 'MK001',
      'name': 'Nasi Goreng Spesial',
      'category_id': defaultCategoryId,
      'buy_price': 15000.0,
      'sell_price': 25000.0,
      'stock': 50,
      'image_path': '',
      'is_active': 1,
    });
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
