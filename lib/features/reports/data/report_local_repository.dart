import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/local_database_service.dart';

final reportRepositoryProvider = Provider<ReportLocalRepository>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return ReportLocalRepository(dbService);
});

class FinancialSummary {
  final double totalRevenue;
  final double totalHpp;
  final double totalProfit;
  final int totalTransactions;

  FinancialSummary({
    required this.totalRevenue,
    required this.totalHpp,
    required this.totalProfit,
    required this.totalTransactions,
  });
}

class HourlySales {
  final String hour;
  final double totalSales;

  HourlySales({required this.hour, required this.totalSales});
}

class TopProduct {
  final String name;
  final int totalSold;
  final double revenue;

  TopProduct({required this.name, required this.totalSold, required this.revenue});
}

class CustomerReportSummary {
  final int totalCustomers;
  final int totalCustomerTransactions;
  final double totalCustomerRevenue;
  final double averageTransactionValue;
  final List<TopCustomer> topCustomers;

  CustomerReportSummary({
    required this.totalCustomers,
    required this.totalCustomerTransactions,
    required this.totalCustomerRevenue,
    required this.averageTransactionValue,
    required this.topCustomers,
  });
}

class TopCustomer {
  final String id;
  final String name;
  final String? phone;
  final int totalTransactions;
  final double totalSpent;

  TopCustomer({
    required this.id,
    required this.name,
    this.phone,
    required this.totalTransactions,
    required this.totalSpent,
  });
}

class LowStockItem {
  final String name;
  final int stock;
  final String category;

  LowStockItem({
    required this.name,
    required this.stock,
    required this.category,
  });
}

class CashierPerformance {
  final String username;
  final int totalTransactions;
  final double totalSales;

  CashierPerformance({
    required this.username,
    required this.totalTransactions,
    required this.totalSales,
  });
}

class ShiftSummary {
  final String shiftId;
  final String userId;
  final String username;
  final String startTime;
  final String? endTime;
  final double startingCash;
  final double endingCash;
  final double totalSalesCash;
  final double totalSalesNonCash;
  final double totalSalesVoid;
  final double expectedDrawerCash;
  final double discrepancy;
  final int totalTransactions;
  final String status;
  final int shiftNumber;

  const ShiftSummary({
    required this.shiftId,
    required this.userId,
    required this.username,
    required this.startTime,
    this.endTime,
    required this.startingCash,
    required this.endingCash,
    required this.totalSalesCash,
    required this.totalSalesNonCash,
    required this.totalSalesVoid,
    required this.expectedDrawerCash,
    required this.discrepancy,
    required this.totalTransactions,
    required this.status,
    required this.shiftNumber,
  });
}

class DailyReportSummary {
  final String date;
  final double totalStartingCash;
  final double totalEndingCash;
  final double totalSalesCash;
  final double totalSalesNonCash;
  final double totalSalesVoid;
  final double totalExpectedCash;
  final double totalDiscrepancy;
  final int totalTransactions;
  final int totalShiftsCount;

  DailyReportSummary({
    required this.date,
    required this.totalStartingCash,
    required this.totalEndingCash,
    required this.totalSalesCash,
    required this.totalSalesNonCash,
    required this.totalSalesVoid,
    required this.totalExpectedCash,
    required this.totalDiscrepancy,
    required this.totalTransactions,
    required this.totalShiftsCount,
  });
}

class ReportLocalRepository {
  final LocalDatabaseService _dbService;

  ReportLocalRepository(this._dbService);

  // Home Performance - Today Summary
  Future<FinancialSummary> getTodaySummary() async {
    final db = await _dbService.database;
    
    final countMaps = await db.rawQuery('''
      SELECT COUNT(id) AS count
      FROM transactions
      WHERE DATE(created_at, 'localtime') = DATE('now', 'localtime') AND status != 'void'
    ''');
    final totalTxns = countMaps.isNotEmpty ? (countMaps.first['count'] as int? ?? 0) : 0;

    final maps = await db.rawQuery('''
      SELECT 
          COALESCE(SUM(t.total_amount), 0.0) AS penjualan_hari_ini,
          COALESCE(SUM(td.quantity * td.buy_price_at_sale), 0.0) AS hpp_hari_ini
      FROM transactions t
      LEFT JOIN transaction_details td ON t.id = td.transaction_id
      WHERE DATE(t.created_at, 'localtime') = DATE('now', 'localtime') AND t.status != 'void'
    ''');

    double revenue = 0.0;
    double hpp = 0.0;

    if (maps.isNotEmpty) {
      revenue = (maps.first['penjualan_hari_ini'] as num? ?? 0.0).toDouble();
      hpp = (maps.first['hpp_hari_ini'] as num? ?? 0.0).toDouble();
    }

    return FinancialSummary(
      totalRevenue: revenue,
      totalHpp: hpp,
      totalProfit: revenue - hpp,
      totalTransactions: totalTxns,
    );
  }

  Future<FinancialSummary> getFinancialSummary(DateTime start, DateTime end) async {
    final db = await _dbService.database;
    final startStr = '${start.toIso8601String().split('T').first} 00:00:00';
    final endStr = '${end.toIso8601String().split('T').first} 23:59:59';

    final countMaps = await db.rawQuery('''
      SELECT COUNT(id) AS count
      FROM transactions
      WHERE DATETIME(created_at, 'localtime') BETWEEN ? AND ? AND status != 'void'
    ''', [startStr, endStr]);
    final totalTxns = countMaps.isNotEmpty ? (countMaps.first['count'] as int? ?? 0) : 0;

    final maps = await db.rawQuery('''
      SELECT 
          COALESCE(SUM(t.total_amount), 0.0) AS total_pendapatan,
          COALESCE(SUM(td.quantity * td.buy_price_at_sale), 0.0) AS total_hpp
      FROM transactions t
      LEFT JOIN transaction_details td ON t.id = td.transaction_id
      WHERE DATETIME(t.created_at, 'localtime') BETWEEN ? AND ? AND t.status != 'void'
    ''', [startStr, endStr]);

    double revenue = 0.0;
    double hpp = 0.0;

    if (maps.isNotEmpty) {
      revenue = (maps.first['total_pendapatan'] as num? ?? 0.0).toDouble();
      hpp = (maps.first['total_hpp'] as num? ?? 0.0).toDouble();
    }

    return FinancialSummary(
      totalRevenue: revenue,
      totalHpp: hpp,
      totalProfit: revenue - hpp,
      totalTransactions: totalTxns,
    );
  }

  Future<List<HourlySales>> getTodayHourlySales() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
          STRFTIME('%H:00', created_at, 'localtime') AS jam,
          COALESCE(SUM(total_amount), 0.0) AS total_omzet
      FROM transactions
      WHERE DATE(created_at, 'localtime') = DATE('now', 'localtime') AND status != 'void'
      GROUP BY jam
      ORDER BY jam ASC
    ''');

    return maps.map((row) {
      return HourlySales(
        hour: (row['jam'] ?? '00:00') as String,
        totalSales: (row['total_omzet'] as num? ?? 0.0).toDouble(),
      );
    }).toList();
  }

  Future<List<TopProduct>> getTopProducts(DateTime start, DateTime end) async {
    final db = await _dbService.database;
    final startStr = '${start.toIso8601String().split('T').first} 00:00:00';
    final endStr = '${end.toIso8601String().split('T').first} 23:59:59';
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
          p.name,
          COALESCE(sales.total_terjual, 0) AS total_terjual,
          COALESCE(sales.total_revenue, 0.0) AS total_revenue
      FROM products p
      LEFT JOIN (
          SELECT 
              td.product_id,
              SUM(td.quantity) AS total_terjual,
              SUM(td.quantity * td.sell_price_at_sale) AS total_revenue
          FROM transaction_details td
          JOIN transactions t ON td.transaction_id = t.id
          WHERE t.status != 'void' AND DATETIME(t.created_at, 'localtime') BETWEEN ? AND ?
          GROUP BY td.product_id
      ) sales ON p.id = sales.product_id
      WHERE p.is_active = 1
      ORDER BY total_terjual DESC, p.name ASC
    ''', [startStr, endStr]);

    return maps.map((row) {
      return TopProduct(
        name: (row['name'] ?? 'Unknown') as String,
        totalSold: (row['total_terjual'] as int? ?? 0),
        revenue: (row['total_revenue'] as num? ?? 0.0).toDouble(),
      );
    }).toList();
  }

  Future<List<LowStockItem>> getLowStockProducts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.name, p.stock, COALESCE(c.name, 'Tanpa Kategori') as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.is_active = 1 AND p.stock <= 10
      ORDER BY p.stock ASC 
      LIMIT 3
    ''');

    return maps.map((row) {
      return LowStockItem(
        name: (row['name'] ?? 'Unknown') as String,
        stock: (row['stock'] as int? ?? 0),
        category: (row['category_name'] ?? 'Umum') as String,
      );
    }).toList();
  }

  Future<List<CashierPerformance>> getCashierPerformance() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
          u.full_name AS username,
          COUNT(DISTINCT t.id) AS total_transaksi_ditangani,
          SUM(t.total_amount) AS total_nominal_penjualan
      FROM transactions t
      JOIN shifts s ON t.shift_id = s.id
      JOIN users u ON s.user_id = u.id
      WHERE t.status != 'void'
      GROUP BY u.id
      ORDER BY total_nominal_penjualan DESC
    ''');

    return maps.map((row) {
      return CashierPerformance(
        username: (row['username'] ?? 'User') as String,
        totalTransactions: (row['total_transaksi_ditangani'] as int? ?? 0),
        totalSales: (row['total_nominal_penjualan'] as num? ?? 0.0).toDouble(),
      );
    }).toList();
  }

  // --- X/Z Report Specific Queries ---
  Future<ShiftSummary?> getShiftSummary(int shiftId) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> shiftMaps = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [shiftId],
    );

    if (shiftMaps.isEmpty) return null;
    final shiftMap = shiftMaps.first;

    final List<Map<String, dynamic>> userMaps = await db.query(
      'users',
      columns: ['full_name'],
      where: 'id = ?',
      whereArgs: [shiftMap['user_id']],
    );
    final username = userMaps.isNotEmpty ? (userMaps.first['full_name'] as String? ?? 'Unknown') : 'Unknown';

    final List<Map<String, dynamic>> cashSalesMaps = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount), 0.0) AS total
      FROM transactions
      WHERE shift_id = ? AND payment_method = 'cash' AND status != 'void'
    ''', [shiftId]);
    final double cashSales = cashSalesMaps.isNotEmpty ? (cashSalesMaps.first['total'] as num? ?? 0.0).toDouble() : 0.0;

    final List<Map<String, dynamic>> nonCashSalesMaps = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount), 0.0) AS total
      FROM transactions
      WHERE shift_id = ? AND payment_method != 'cash' AND status != 'void'
    ''', [shiftId]);
    final double nonCashSales = nonCashSalesMaps.isNotEmpty ? (nonCashSalesMaps.first['total'] as num? ?? 0.0).toDouble() : 0.0;

    final List<Map<String, dynamic>> voidSalesMaps = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount), 0.0) AS total
      FROM transactions
      WHERE shift_id = ? AND status = 'void'
    ''', [shiftId]);
    final double voidSales = voidSalesMaps.isNotEmpty ? (voidSalesMaps.first['total'] as num? ?? 0.0).toDouble() : 0.0;

    final List<Map<String, dynamic>> txnsMaps = await db.rawQuery('''
      SELECT COUNT(id) AS count
      FROM transactions
      WHERE shift_id = ? AND status != 'void'
    ''', [shiftId]);
    final int totalTxns = txnsMaps.isNotEmpty ? (txnsMaps.first['count'] as int? ?? 0) : 0;

    final startingCash = (shiftMap['starting_cash'] as num? ?? 0.0).toDouble();
    final endingCash = (shiftMap['ending_cash'] as num? ?? 0.0).toDouble();
    final expectedCash = startingCash + cashSales;
    final discrepancy = shiftMap['status'] == 'closed' ? endingCash - expectedCash : 0.0;
    final shiftNumber = shiftMap['shift_number'] as int? ?? 1;

    return ShiftSummary(
      shiftId: shiftId.toString(),
      userId: shiftMap['user_id'].toString(),
      username: username,
      startTime: shiftMap['start_time'] as String,
      endTime: shiftMap['end_time'] as String?,
      startingCash: startingCash,
      endingCash: endingCash,
      totalSalesCash: cashSales,
      totalSalesNonCash: nonCashSales,
      totalSalesVoid: voidSales,
      expectedDrawerCash: expectedCash,
      discrepancy: discrepancy,
      totalTransactions: totalTxns,
      status: shiftMap['status'] as String? ?? 'open',
      shiftNumber: shiftNumber,
    );
  }

  Future<ShiftSummary?> getActiveShiftSummary() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      columns: ['id'],
      where: "status = 'open'",
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final activeShiftId = maps.first['id'] as int;
    return getShiftSummary(activeShiftId);
  }

  Future<List<ShiftSummary>> getClosedShifts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: "status = 'closed'",
      orderBy: 'end_time DESC',
    );

    final List<ShiftSummary> list = [];
    for (final map in maps) {
      final summary = await getShiftSummary(map['id'] as int);
      if (summary != null) {
        list.add(summary);
      }
    }
    return list;
  }

  Future<DailyReportSummary?> getDailyReportSummary(String dateStr) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> shifts = await db.rawQuery('''
      SELECT id
      FROM shifts
      WHERE DATE(start_time, 'localtime') = ?
    ''', [dateStr]);

    if (shifts.isEmpty) return null;

    double totalStartingCash = 0.0;
    double totalEndingCash = 0.0;
    double totalSalesCash = 0.0;
    double totalSalesNonCash = 0.0;
    double totalSalesVoid = 0.0;
    int totalTransactions = 0;

    for (final s in shifts) {
      final shiftId = s['id'] as int;
      final summary = await getShiftSummary(shiftId);
      if (summary != null) {
        totalStartingCash += summary.startingCash;
        totalEndingCash += summary.endingCash;
        totalSalesCash += summary.totalSalesCash;
        totalSalesNonCash += summary.totalSalesNonCash;
        totalSalesVoid += summary.totalSalesVoid;
        totalTransactions += summary.totalTransactions;
      }
    }

    final totalExpectedCash = totalStartingCash + totalSalesCash;
    
    double totalDiscrepancy = 0.0;
    for (final s in shifts) {
      final shiftId = s['id'] as int;
      final summary = await getShiftSummary(shiftId);
      if (summary != null && summary.status == 'closed') {
        totalDiscrepancy += summary.discrepancy;
      }
    }

    return DailyReportSummary(
      date: dateStr,
      totalStartingCash: totalStartingCash,
      totalEndingCash: totalEndingCash,
      totalSalesCash: totalSalesCash,
      totalSalesNonCash: totalSalesNonCash,
      totalSalesVoid: totalSalesVoid,
      totalExpectedCash: totalExpectedCash,
      totalDiscrepancy: totalDiscrepancy,
      totalTransactions: totalTransactions,
      totalShiftsCount: shifts.length,
    );
  }

  Future<List<DailyReportSummary>> getDailyReportsHistory() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> datesMaps = await db.rawQuery('''
      SELECT DISTINCT DATE(start_time, 'localtime') as date_str
      FROM shifts
      ORDER BY date_str DESC
    ''');

    final List<DailyReportSummary> list = [];
    for (final row in datesMaps) {
      final dateStr = row['date_str'] as String?;
      if (dateStr != null) {
        final summary = await getDailyReportSummary(dateStr);
        if (summary != null) {
          list.add(summary);
        }
      }
    }
    return list;
  }

  Future<CustomerReportSummary> getCustomerReportSummary({DateTime? startDate, DateTime? endDate}) async {
    final db = await _dbService.database;

    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    final totalCustomers = countResult.isNotEmpty ? ((countResult.first['count'] as int?) ?? 0) : 0;

    String dateFilter = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      final startStr = '${startDate.toIso8601String().split('T').first} 00:00:00';
      final endStr = '${endDate.toIso8601String().split('T').first} 23:59:59';
      dateFilter = " AND DATETIME(t.created_at, 'localtime') BETWEEN ? AND ? ";
      whereArgs = [startStr, endStr];
    }

    final transResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as trans_count, COALESCE(SUM(t.total_amount), 0.0) as total_revenue
      FROM transactions t
      WHERE t.customer_id IS NOT NULL AND t.customer_id != '' AND t.customer_id != '0' AND t.customer_id != 0 AND t.status != 'void' $dateFilter
      ''',
      whereArgs,
    );

    final totalCustomerTransactions = transResult.isNotEmpty ? ((transResult.first['trans_count'] as int?) ?? 0) : 0;
    final totalCustomerRevenue = transResult.isNotEmpty ? ((transResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0) : 0.0;
    final avgValue = totalCustomerTransactions > 0 ? totalCustomerRevenue / totalCustomerTransactions : 0.0;

    final topResult = await db.rawQuery(
      '''
      SELECT c.id, c.name, c.phone, COUNT(t.id) as trans_count, COALESCE(SUM(t.total_amount), 0.0) as total_spent
      FROM customers c
      JOIN transactions t ON CAST(c.id AS TEXT) = CAST(t.customer_id AS TEXT)
      WHERE t.status != 'void' $dateFilter
      GROUP BY c.id, c.name, c.phone
      ORDER BY total_spent DESC
      LIMIT 10
      ''',
      whereArgs,
    );

    final topCustomers = topResult.map((row) {
      return TopCustomer(
        id: (row['id'] ?? '').toString(),
        name: (row['name'] as String?) ?? 'Pelanggan',
        phone: row['phone'] as String?,
        totalTransactions: (row['trans_count'] as int?) ?? 0,
        totalSpent: (row['total_spent'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return CustomerReportSummary(
      totalCustomers: totalCustomers,
      totalCustomerTransactions: totalCustomerTransactions,
      totalCustomerRevenue: totalCustomerRevenue,
      averageTransactionValue: avgValue,
      topCustomers: topCustomers,
    );
  }
}
