import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_interface.dart';
import '../../../core/data/local_database_service.dart';
import 'transaction.dart';
import 'transaction_detail.dart';
import 'cart_item.dart';
import '../../auth/data/shift.dart';

final transactionRepositoryProvider = Provider<TransactionLocalRepository>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return TransactionLocalRepository(dbService);
});

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
    map['createdAt'] = row['created_at'];
    return map;
  }

  // --- Transactions & Details Persistence ---
  Future<Transaction> checkout({
    required String shiftId,
    required double totalAmount,
    required String paymentMethod,
    required double cashReceived,
    String? customerId,
    required List<CartItem> items,
  }) async {
    final db = await _dbService.database;
    final intShiftId = int.parse(shiftId);
    final intCustomerId = customerId != null ? int.tryParse(customerId) : null;

    Transaction? transactionResult;

    await db.transaction((txn) async {
      // 1. Insert Transaction Header
      final transactionId = await txn.insert('transactions', {
        'shift_id': intShiftId,
        'customer_id': intCustomerId,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'cash_received': cashReceived,
        'status': 'completed',
      });

      // 2. Loop Cart Items and save details and decrement stocks
      for (final item in items) {
        final intProductId = int.parse(item.product.id);

        // Retrieve current product details (specifically buy_price and stock)
        final List<Map<String, dynamic>> productMaps = await txn.query(
          'products',
          columns: ['buy_price', 'sell_price', 'stock'],
          where: 'id = ?',
          whereArgs: [intProductId],
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

        // Insert Transaction Detail
        await txn.insert('transaction_details', {
          'transaction_id': transactionId,
          'product_id': intProductId,
          'quantity': item.quantity,
          'buy_price_at_sale': buyPrice,
          'sell_price_at_sale': sellPrice,
        });

        // Decrement Product Stock
        await txn.update(
          'products',
          {'stock': currentStock - item.quantity},
          where: 'id = ?',
          whereArgs: [intProductId],
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
    final intId = int.tryParse(id);
    if (intId == null) return;

    await db.transaction((txn) async {
      // 1. Update status to void
      await txn.update(
        'transactions',
        {'status': 'void'},
        where: 'id = ?',
        whereArgs: [intId],
      );

      // 2. Fetch transaction details to restore stock
      final List<Map<String, dynamic>> details = await txn.query(
        'transaction_details',
        where: 'transaction_id = ?',
        whereArgs: [intId],
      );

      // Restore stock for each item in details
      for (final detail in details) {
        final productId = detail['product_id'] as int;
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
    final intTxnId = int.parse(transactionId);
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_details',
      where: 'transaction_id = ?',
      whereArgs: [intTxnId],
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

  // --- Shifts Management ---
  Future<Shift> openShift(String userId, double startingCash) async {
    final db = await _dbService.database;
    final intUserId = int.parse(userId);

    // Ensure there is no open shift already
    final activeShift = await getActiveShift();
    if (activeShift != null) {
      return activeShift;
    }

    final id = await db.insert('shifts', {
      'user_id': intUserId,
      'starting_cash': startingCash,
      'ending_cash': 0.0,
      'status': 'open',
    });

    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [id],
    );

    return Shift.fromJson(_mapShiftRow(maps.first));
  }

  Future<Shift?> getActiveShift() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: "status = 'open'",
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Shift.fromJson(_mapShiftRow(maps.first));
  }

  Future<Shift> closeShift(String shiftId, double endingCash) async {
    final db = await _dbService.database;
    final intId = int.parse(shiftId);

    await db.update(
      'shifts',
      {
        'ending_cash': endingCash,
        'status': 'closed',
        'end_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [intId],
    );

    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [intId],
    );

    return Shift.fromJson(_mapShiftRow(maps.first));
  }

  Map<String, dynamic> _mapShiftRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['id'] = row['id'].toString();
    map['userId'] = row['user_id'].toString();
    map['startTime'] = row['start_time'];
    map['endTime'] = row['end_time'];
    map['startingCash'] = (row['starting_cash'] as num).toDouble();
    map['endingCash'] = (row['ending_cash'] as num).toDouble();
    map['status'] = row['status'];
    return map;
  }
}
