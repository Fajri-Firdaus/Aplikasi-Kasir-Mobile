import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_interface.dart';
import '../../../core/data/local_database_service.dart';
import 'transaction.dart';
import 'transaction_detail.dart';
import 'cart_item.dart';
import '../../auth/data/shift.dart';
import '../../customers/data/customer.dart';

final transactionRepositoryProvider = Provider<TransactionLocalRepository>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return TransactionLocalRepository(dbService);
});

class TransactionItemDetail {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final int quantity;
  final double buyPriceAtSale;
  final double sellPriceAtSale;

  TransactionItemDetail({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.buyPriceAtSale,
    required this.sellPriceAtSale,
  });

  double get subtotal => quantity * sellPriceAtSale;
}

class TransactionLocalRepository implements RepositoryInterface<Transaction> {
  final LocalDatabaseService _dbService;

  TransactionLocalRepository(this._dbService);

  @override
  Future<List<Transaction>> getAll() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Transaction.fromJson(_mapDbRow(map))).toList();
  }

  @override
  Future<Transaction?> getById(String id) async {
    final db = await _dbService.database;
    final intId = int.tryParse(id);
    if (intId == null) return null;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [intId],
    );

    if (maps.isEmpty) return null;
    return Transaction.fromJson(_mapDbRow(maps.first));
  }

  @override
  Future<Transaction> create(Transaction item) async {
    // This is handled via checkout. We can implement a basic create or throw.
    throw UnimplementedError('Use checkout() instead for saving transactions with cart items.');
  }

  @override
  Future<Transaction> update(String id, Transaction item) async {
    final db = await _dbService.database;
    final intId = int.tryParse(id);
    if (intId == null) throw Exception('Invalid Transaction ID');

    await db.update(
      'transactions',
      {
        'shift_id': int.parse(item.shiftId),
        'customer_id': item.customerId != null ? int.tryParse(item.customerId!) : null,
        'total_amount': item.totalAmount,
        'payment_method': item.paymentMethod,
        'cash_received': item.cashReceived,
        'status': item.status,
      },
      where: 'id = ?',
      whereArgs: [intId],
    );
    return item;
  }

  @override
  Future<void> delete(String id) async {
    // In POS, we void instead of delete.
    await voidTransaction(id);
  }

  Map<String, dynamic> _mapDbRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['id'] = row['id'].toString();
    map['shiftId'] = row['shift_id'].toString();
    map['customerId'] = row['customer_id']?.toString();
    map['totalAmount'] = (row['total_amount'] as num).toDouble();
    map['paymentMethod'] = row['payment_method'];
    map['cashReceived'] = (row['cash_received'] as num?)?.toDouble() ?? 0.0;
    map['status'] = row['status'];

    final rawCreated = row['created_at']?.toString();
    if (rawCreated != null && !rawCreated.contains('T') && !rawCreated.endsWith('Z')) {
      map['createdAt'] = '${rawCreated.replaceAll(' ', 'T')}Z';
    } else {
      map['createdAt'] = rawCreated;
    }
    return map;
  }

  // --- Transactions & Details Persistence ---
  // --- Transactions & Details Persistence ---
  Future<Transaction> checkout({
    required String shiftId,
    required double totalAmount,
    required String paymentMethod,
    required double cashReceived,
    String? customerId,
    required List<CartItem> items,
    String storeId = 'store-uuid-001',
  }) async {
    final db = await _dbService.database;

    Transaction? transactionResult;
    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

    await db.transaction((txn) async {
      // 1. Insert Transaction Header
      await txn.insert('transactions', {
        'id': transactionId,
        'store_id': storeId,
        'shift_id': shiftId,
        'customer_id': customerId,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'cash_received': cashReceived,
        'status': 'completed',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // 2. Loop Cart Items and save details and decrement stocks
      for (final item in items) {
        final productId = item.product.id;

        // Retrieve current product details (specifically buy_price and stock)
        final List<Map<String, dynamic>> productMaps = await txn.query(
          'products',
          columns: ['buy_price', 'sell_price', 'stock'],
          where: 'id = ?',
          whereArgs: [productId],
        );

        if (productMaps.isEmpty) {
          throw Exception('Product with ID ${item.product.id} not found.');
        }

        final double buyPrice = (productMaps.first['buy_price'] as num).toDouble();
        final double sellPrice = (productMaps.first['sell_price'] as num).toDouble();
        final int currentStock = productMaps.first['stock'] as int;

        // Verify stock availability
        if (currentStock < item.quantity) {
          throw Exception('Stok tidak mencukupi untuk produk: ${item.product.name}');
        }

        final detailId = '${transactionId}_$productId';

        // Insert Transaction Detail
        await txn.insert('transaction_details', {
          'id': detailId,
          'transaction_id': transactionId,
          'product_id': productId,
          'quantity': item.quantity,
          'buy_price_at_sale': buyPrice,
          'sell_price_at_sale': sellPrice,
        });

        // Decrement Product Stock
        await txn.update(
          'products',
          {'stock': currentStock - item.quantity},
          where: 'id = ?',
          whereArgs: [productId],
        );
      }

      // Fetch the created transaction to return
      final List<Map<String, dynamic>> maps = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      transactionResult = Transaction.fromJson(_mapDbRow(maps.first));
    });

    if (transactionResult == null) {
      throw Exception('Checkout gagal disimpan.');
    }
    return transactionResult!;
  }

  Future<void> voidTransaction(String id) async {
    final db = await _dbService.database;

    await db.transaction((txn) async {
      // 1. Update status to void
      await txn.update(
        'transactions',
        {'status': 'void'},
        where: 'id = ?',
        whereArgs: [id],
      );

      // 2. Fetch transaction details to restore stock
      final List<Map<String, dynamic>> details = await txn.query(
        'transaction_details',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      // Restore stock for each item in details
      for (final detail in details) {
        final productId = detail['product_id'].toString();
        final quantity = detail['quantity'] as int;

        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [quantity, productId],
        );
      }
    });
  }

  Future<List<TransactionDetail>> getTransactionDetails(String transactionId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_details',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );

    return maps.map((map) {
      return TransactionDetail(
        id: map['id'].toString(),
        transactionId: map['transaction_id'].toString(),
        productId: map['product_id'].toString(),
        quantity: map['quantity'] as int,
        buyPriceAtSale: (map['buy_price_at_sale'] as num).toDouble(),
        sellPriceAtSale: (map['sell_price_at_sale'] as num).toDouble(),
      );
    }).toList();
  }

  Future<List<TransactionItemDetail>> getTransactionItemDetails(String transactionId) async {
    final db = await _dbService.database;
    final intTxnId = int.tryParse(transactionId);
    if (intTxnId == null) return [];

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        td.id,
        td.transaction_id,
        td.product_id,
        td.quantity,
        td.buy_price_at_sale,
        td.sell_price_at_sale,
        COALESCE(p.name, 'Produk') AS product_name
      FROM transaction_details td
      LEFT JOIN products p ON td.product_id = p.id
      WHERE td.transaction_id = ?
    ''', [intTxnId]);

    return maps.map((map) {
      return TransactionItemDetail(
        id: map['id'].toString(),
        transactionId: map['transaction_id'].toString(),
        productId: map['product_id'].toString(),
        productName: map['product_name'] as String,
        quantity: map['quantity'] as int,
        buyPriceAtSale: (map['buy_price_at_sale'] as num).toDouble(),
        sellPriceAtSale: (map['sell_price_at_sale'] as num).toDouble(),
      );
    }).toList();
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 10, String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'store_id = ?',
      whereArgs: [activeStoreId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => Transaction.fromJson(_mapDbRow(map))).toList();
  }

  Future<List<Transaction>> getFilteredTransactions({DateTime? startDate, DateTime? endDate, String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'store_id = ?',
      whereArgs: [activeStoreId],
      orderBy: 'id DESC',
    );

    final allTxns = maps.map((map) => Transaction.fromJson(_mapDbRow(map))).toList();

    if (startDate == null && endDate == null) {
      return allTxns;
    }

    final startOfDay = startDate != null ? DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0) : null;
    final endOfDay = endDate != null ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999) : null;

    return allTxns.where((txn) {
      final parsed = DateTime.tryParse(txn.createdAt);
      if (parsed == null) return false;
      final localDate = parsed.toLocal();

      if (startOfDay != null && localDate.isBefore(startOfDay)) {
        return false;
      }
      if (endOfDay != null && localDate.isAfter(endOfDay)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<Customer?> getCustomerById(String customerId) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
    );

    if (maps.isEmpty) return null;
    final row = maps.first;
    return Customer(
      id: row['id'].toString(),
      name: row['name'] as String,
      phone: row['phone']?.toString(),
      createdAt: row['created_at']?.toString(),
    );
  }

  Future<int> getDailyTransactionSequence(String transactionId) async {
    final db = await _dbService.database;

    final txnRow = await db.query(
      'transactions',
      columns: ['created_at'],
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    if (txnRow.isEmpty) return 1;

    final rawCreated = txnRow.first['created_at']?.toString();
    if (rawCreated == null) return 1;

    final parsedTarget = (rawCreated.contains('T') || rawCreated.endsWith('Z'))
        ? DateTime.tryParse(rawCreated)?.toLocal()
        : DateTime.tryParse('${rawCreated.replaceAll(' ', 'T')}Z')?.toLocal();
    if (parsedTarget == null) return 1;

    final targetDateOnly = '${parsedTarget.year}-${parsedTarget.month.toString().padLeft(2, '0')}-${parsedTarget.day.toString().padLeft(2, '0')}';

    final List<Map<String, dynamic>> allPrevMaps = await db.query(
      'transactions',
      columns: ['id', 'created_at'],
      orderBy: 'created_at ASC',
    );

    int sequence = 0;
    for (final row in allPrevMaps) {
      final cStr = row['created_at']?.toString();
      if (cStr != null) {
        final rowDt = (cStr.contains('T') || cStr.endsWith('Z'))
            ? DateTime.tryParse(cStr)?.toLocal()
            : DateTime.tryParse('${cStr.replaceAll(' ', 'T')}Z')?.toLocal();
        if (rowDt != null) {
          final rDateOnly = '${rowDt.year}-${rowDt.month.toString().padLeft(2, '0')}-${rowDt.day.toString().padLeft(2, '0')}';
          if (rDateOnly == targetDateOnly) {
            sequence++;
          }
        }
      }
      if (row['id'].toString() == transactionId) {
        break;
      }
    }

    return sequence > 0 ? sequence : 1;
  }

  Future<String> getCashierNameByShiftId(String shiftId) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        COALESCE(u.full_name, u.username, 'Kasir') AS cashier_name
      FROM shifts s
      JOIN users u ON s.user_id = u.id
      WHERE s.id = ?
    ''', [shiftId]);

    if (maps.isNotEmpty && maps.first['cashier_name'] != null) {
      final name = maps.first['cashier_name'] as String;
      return name.trim().isNotEmpty ? name.trim() : 'Kasir';
    }
    return 'Kasir';
  }

  // --- Shifts Management ---
  Future<Shift> openShift(String userId, double startingCash, {String storeId = 'store-uuid-001'}) async {
    final db = await _dbService.database;

    // Ensure there is no open shift already
    final activeShift = await getActiveShift(storeId: storeId);
    if (activeShift != null) {
      return activeShift;
    }

    // Ensure valid user ID for Foreign Key constraint
    String effectiveUserId = userId;
    final userCheck = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (userCheck.isEmpty) {
      final defaultUser = await db.query('users', limit: 1);
      if (defaultUser.isNotEmpty) {
        effectiveUserId = defaultUser.first['id'].toString();
      } else {
        effectiveUserId = 'admin-uuid-001';
      }
    }

    final countMaps = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM shifts 
      WHERE store_id = ? AND DATE(start_time, 'localtime') = DATE('now', 'localtime')
    ''', [storeId]);
    final shiftCount = countMaps.isNotEmpty ? (countMaps.first['count'] as int? ?? 0) : 0;
    final nextShiftNumber = shiftCount + 1;

    final shiftId = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('shifts', {
      'id': shiftId,
      'store_id': storeId,
      'user_id': effectiveUserId,
      'starting_cash': startingCash,
      'ending_cash': 0.0,
      'status': 'open',
      'shift_number': nextShiftNumber,
    });

    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [shiftId],
    );

    return Shift.fromJson(_mapShiftRow(maps.first));
  }

  Future<Shift?> getActiveShift({String? storeId}) async {
    if (storeId == null || storeId.isEmpty) return null;
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: "store_id = ? AND status = 'open'",
      whereArgs: [storeId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Shift.fromJson(_mapShiftRow(maps.first));
  }

  Future<Shift> closeShift(String shiftId, double endingCash) async {
    final db = await _dbService.database;

    await db.update(
      'shifts',
      {
        'ending_cash': endingCash,
        'status': 'closed',
        'end_time': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );

    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [shiftId],
    );

    return Shift.fromJson(_mapShiftRow(maps.first));
  }

  Map<String, dynamic> _mapShiftRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['id'] = row['id'].toString();
    map['userId'] = row['user_id']?.toString() ?? '';
    map['startTime'] = row['start_time']?.toString() ?? DateTime.now().toIso8601String();
    map['endTime'] = row['end_time']?.toString();
    map['startingCash'] = (row['starting_cash'] as num? ?? 0.0).toDouble();
    map['endingCash'] = (row['ending_cash'] as num? ?? 0.0).toDouble();
    map['status'] = row['status'] ?? 'open';
    map['shiftNumber'] = row['shift_number'] as int? ?? 1;
    return map;
  }
}
