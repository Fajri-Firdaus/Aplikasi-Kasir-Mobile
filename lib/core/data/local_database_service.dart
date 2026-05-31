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
      );
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'mobile_pos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys constraints support in SQLite
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Table users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT,
        email TEXT UNIQUE,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'cashier',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Table categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // 3. Table products
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT UNIQUE,
        name TEXT NOT NULL,
        category_id INTEGER,
        buy_price REAL NOT NULL DEFAULT 0.0,
        sell_price REAL NOT NULL DEFAULT 0.0,
        stock INTEGER DEFAULT 0,
        image_path TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // 4. Table customers
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 5. Table store_settings (Singleton: id must be 1)
    await db.execute('''
      CREATE TABLE store_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        store_name TEXT NOT NULL,
        store_address TEXT,
        store_phone TEXT,
        receipt_footer TEXT,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 6. Table shifts
    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        end_time TIMESTAMP,
        starting_cash REAL DEFAULT 0.0,
        ending_cash REAL DEFAULT 0.0,
        status TEXT CHECK (status IN ('open', 'closed')) DEFAULT 'open',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // 7. Table transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shift_id INTEGER NOT NULL,
        customer_id INTEGER,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        cash_received REAL DEFAULT 0.0,
        status TEXT CHECK (status IN ('completed', 'void')) DEFAULT 'completed',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (shift_id) REFERENCES shifts(id),
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    // 8. Table transaction_details
    await db.execute('''
      CREATE TABLE transaction_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        buy_price_at_sale REAL NOT NULL,
        sell_price_at_sale REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // --- Seed Initial Data ---
    // Seed default admin user (hash of '123456' using a simple base64 simulation or standard verification)
    await db.insert('users', {
      'full_name': 'Admin System',
      'email': 'admin@pos.com',
      'username': 'admin',
      'password': 'MTIzNDU2', // Base64 for '123456'
      'role': 'admin',
    });

    // Seed default store settings
    await db.insert('store_settings', {
      'id': 1,
      'store_name': 'Mobile POS Dashboard',
      'store_address': 'Jl. Merdeka No. 123',
      'store_phone': '08123456789',
      'receipt_footer': 'Terima kasih atas kunjungan Anda!',
    });
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
