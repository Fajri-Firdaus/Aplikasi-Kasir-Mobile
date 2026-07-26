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

class DailySales {
  final DateTime date;
  final String dayName;
  final double totalSales;

  DailySales({
    required this.date,
    required this.dayName,
    required this.totalSales,
  });
}

class WeeklySales {
  final String label;
  final double totalSales;

  WeeklySales({
    required this.label,
    required this.totalSales,
  });
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
  // Home Performance - Today Summary
  Future<FinancialSummary> getTodaySummary({String? storeId}) async {
    final now = DateTime.now();
    return getFinancialSummary(now, now, storeId: storeId);
  }

  Future<FinancialSummary> getFinancialSummary(DateTime start, DateTime end, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;

    final startOfDay = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.id,
        t.created_at,
        t.status,
        t.total_amount,
        COALESCE(SUM(td.quantity * td.buy_price_at_sale), 0.0) AS total_hpp
      FROM transactions t
      LEFT JOIN transaction_details td ON t.id = td.transaction_id
      WHERE t.store_id = ? AND t.status != 'void'
      GROUP BY t.id
    ''', [activeStoreId]);

    double revenue = 0.0;
    double hpp = 0.0;
    int count = 0;

    for (final row in maps) {
      final rawCreated = row['created_at']?.toString();
      if (rawCreated == null) continue;

      final parsed = (rawCreated.contains('T') || rawCreated.endsWith('Z'))
          ? DateTime.tryParse(rawCreated)?.toLocal()
          : DateTime.tryParse('${rawCreated.replaceAll(' ', 'T')}Z')?.toLocal();
      if (parsed == null) continue;

      if (parsed.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
          parsed.isBefore(endOfDay.add(const Duration(milliseconds: 1)))) {
        revenue += (row['total_amount'] as num? ?? 0.0).toDouble();
        hpp += (row['total_hpp'] as num? ?? 0.0).toDouble();
        count++;
      }
    }

    return FinancialSummary(
      totalRevenue: revenue,
      totalHpp: hpp,
      totalProfit: revenue - hpp,
      totalTransactions: count,
    );
  }

  Future<List<HourlySales>> getTodayHourlySales({String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT id, created_at, total_amount, status
      FROM transactions
      WHERE store_id = ? AND status != 'void'
    ''', [activeStoreId]);

    final Map<int, double> hourlyMap = {};

    for (final row in maps) {
      final rawCreated = row['created_at']?.toString();
      if (rawCreated == null) continue;

      final parsed = (rawCreated.contains('T') || rawCreated.endsWith('Z'))
          ? DateTime.tryParse(rawCreated)?.toLocal()
          : DateTime.tryParse('${rawCreated.replaceAll(' ', 'T')}Z')?.toLocal();
      if (parsed == null) continue;

      if (parsed.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
          parsed.isBefore(endOfDay.add(const Duration(milliseconds: 1)))) {
        final hour = parsed.hour;
        hourlyMap[hour] = (hourlyMap[hour] ?? 0.0) + (row['total_amount'] as num? ?? 0.0).toDouble();
      }
    }

    final List<HourlySales> result = [];
    hourlyMap.forEach((hour, sales) {
      final hourStr = '${hour.toString().padLeft(2, '0')}:00';
      result.add(HourlySales(hour: hourStr, totalSales: sales));
    });
    return result;
  }

  Future<List<DailySales>> getWeeklyDailySales(DateTime monday, DateTime sunday, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final startOfDay = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
    final endOfDay = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT id, created_at, total_amount, status
      FROM transactions
      WHERE store_id = ? AND status != 'void'
    ''', [activeStoreId]);

    final Map<String, double> salesMap = {};

    for (final row in maps) {
      final rawCreated = row['created_at']?.toString();
      if (rawCreated == null) continue;

      final parsed = (rawCreated.contains('T') || rawCreated.endsWith('Z'))
          ? DateTime.tryParse(rawCreated)?.toLocal()
          : DateTime.tryParse('${rawCreated.replaceAll(' ', 'T')}Z')?.toLocal();
      if (parsed == null) continue;

      if (parsed.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
          parsed.isBefore(endOfDay.add(const Duration(milliseconds: 1)))) {
        final dateKey = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
        salesMap[dateKey] = (salesMap[dateKey] ?? 0.0) + (row['total_amount'] as num? ?? 0.0).toDouble();
      }
    }

    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return List.generate(7, (index) {
      final dayDate = monday.add(Duration(days: index));
      final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
      return DailySales(
        date: dayDate,
        dayName: dayNames[index],
        totalSales: salesMap[dateStr] ?? 0.0,
      );
    });
  }

  Future<List<WeeklySales>> getMonthlyWeeklySales(DateTime monthStart, DateTime monthEnd, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final startOfDay = DateTime(monthStart.year, monthStart.month, monthStart.day, 0, 0, 0);
    final endOfDay = DateTime(monthEnd.year, monthEnd.month, monthEnd.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT id, created_at, total_amount, status
      FROM transactions
      WHERE store_id = ? AND status != 'void'
    ''', [activeStoreId]);

    final Map<int, double> daySalesMap = {};

    for (final row in maps) {
      final rawCreated = row['created_at']?.toString();
      if (rawCreated == null) continue;

      final parsed = (rawCreated.contains('T') || rawCreated.endsWith('Z'))
          ? DateTime.tryParse(rawCreated)?.toLocal()
          : DateTime.tryParse('${rawCreated.replaceAll(' ', 'T')}Z')?.toLocal();
      if (parsed == null) continue;

      if (parsed.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
          parsed.isBefore(endOfDay.add(const Duration(milliseconds: 1)))) {
        final day = parsed.day;
        daySalesMap[day] = (daySalesMap[day] ?? 0.0) + (row['total_amount'] as num? ?? 0.0).toDouble();
      }
    }

    final totalDaysInMonth = monthEnd.day;
    final List<WeeklySales> buckets = [];

    double w1 = 0.0;
    for (int d = 1; d <= 7 && d <= totalDaysInMonth; d++) {
      w1 += daySalesMap[d] ?? 0.0;
    }
    buckets.add(WeeklySales(label: 'Mgg 1 (1-7)', totalSales: w1));

    double w2 = 0.0;
    for (int d = 8; d <= 14 && d <= totalDaysInMonth; d++) {
      w2 += daySalesMap[d] ?? 0.0;
    }
    buckets.add(WeeklySales(label: 'Mgg 2 (8-14)', totalSales: w2));

    double w3 = 0.0;
    for (int d = 15; d <= 21 && d <= totalDaysInMonth; d++) {
      w3 += daySalesMap[d] ?? 0.0;
    }
    buckets.add(WeeklySales(label: 'Mgg 3 (15-21)', totalSales: w3));

    double w4 = 0.0;
    for (int d = 22; d <= 28 && d <= totalDaysInMonth; d++) {
      w4 += daySalesMap[d] ?? 0.0;
    }
    buckets.add(WeeklySales(label: 'Mgg 4 (22-28)', totalSales: w4));

    if (totalDaysInMonth > 28) {
      double w5 = 0.0;
      for (int d = 29; d <= totalDaysInMonth; d++) {
        w5 += daySalesMap[d] ?? 0.0;
      }
      buckets.add(WeeklySales(label: 'Mgg 5 (29-$totalDaysInMonth)', totalSales: w5));
    }

    return buckets;
  }

  Future<List<TopProduct>> getTopProducts(DateTime start, DateTime end, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final startOfDay = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        p.id AS product_id,
        p.name,
        td.quantity,
        td.sell_price_at_sale,
        t.created_at,
        t.status
      FROM products p
      LEFT JOIN transaction_details td ON p.id = td.product_id
      LEFT JOIN transactions t ON td.transaction_id = t.id
      WHERE p.store_id = ? AND p.is_active = 1
    ''', [activeStoreId]);

    final Map<String, Map<String, dynamic>> productStats = {};

    for (final row in maps) {
      final name = (row['name'] ?? 'Unknown') as String;

      if (!productStats.containsKey(name)) {
        productStats[name] = {'name': name, 'totalSold': 0, 'revenue': 0.0};
      }

      final status = row['status'] as String?;
      if (status == 'void') continue;

      final rawCreated = row['created_at']?.toString();
      if (rawCreated == null) continue;

      final parsed = (rawCreated.contains('T') || rawCreated.endsWith('Z'))
          ? DateTime.tryParse(rawCreated)?.toLocal()
          : DateTime.tryParse('${rawCreated.replaceAll(' ', 'T')}Z')?.toLocal();
      if (parsed == null) continue;

      if (parsed.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
          parsed.isBefore(endOfDay.add(const Duration(milliseconds: 1)))) {
        final qty = row['quantity'] as int? ?? 0;
        final price = (row['sell_price_at_sale'] as num? ?? 0.0).toDouble();
        productStats[name]!['totalSold'] = (productStats[name]!['totalSold'] as int) + qty;
        productStats[name]!['revenue'] = (productStats[name]!['revenue'] as double) + (qty * price);
      }
    }

    final List<TopProduct> list = productStats.values.map((map) {
      return TopProduct(
        name: map['name'] as String,
        totalSold: map['totalSold'] as int,
        revenue: map['revenue'] as double,
      );
    }).toList();

    list.sort((a, b) {
      final cmp = b.totalSold.compareTo(a.totalSold);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });

    return list;
  }

  Future<List<LowStockItem>> getLowStockProducts({String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.name, p.stock, COALESCE(c.name, 'Tanpa Kategori') as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.store_id = ? AND p.is_active = 1 AND p.stock <= 10
      ORDER BY p.stock ASC 
      LIMIT 10
    ''', [activeStoreId]);

    return maps.map((row) {
      return LowStockItem(
        name: (row['name'] ?? 'Unknown') as String,
        stock: (row['stock'] as int? ?? 0),
        category: (row['category_name'] ?? 'Umum') as String,
      );
    }).toList();
  }

  Future<List<CashierPerformance>> getCashierPerformance({String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        COALESCE(u.full_name, u.username, 'Kasir') as username,
        COUNT(DISTINCT t.id) as total_txns,
        COALESCE(SUM(t.total_amount), 0.0) as total_sales
      FROM transactions t
      JOIN shifts s ON t.shift_id = s.id
      JOIN users u ON s.user_id = u.id
      WHERE t.store_id = ? AND t.status != 'void'
      GROUP BY u.id
      ORDER BY total_sales DESC
    ''', [activeStoreId]);

    return maps.map((row) {
      return CashierPerformance(
        username: (row['username'] ?? 'User') as String,
        totalTransactions: (row['total_txns'] as int? ?? 0),
        totalSales: (row['total_sales'] as num? ?? 0.0).toDouble(),
      );
    }).toList();
  }

  // --- X/Z Report Specific Queries ---
  // --- X/Z Report Specific Queries ---
  Future<ShiftSummary?> getShiftSummary(dynamic rawShiftId) async {
    final db = await _dbService.database;
    final shiftId = rawShiftId.toString();

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
      whereArgs: [shiftMap['user_id'].toString()],
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
      shiftId: shiftId,
      userId: shiftMap['user_id']?.toString() ?? '',
      username: username,
      startTime: shiftMap['start_time']?.toString() ?? DateTime.now().toIso8601String(),
      endTime: shiftMap['end_time']?.toString(),
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

  Future<ShiftSummary?> getActiveShiftSummary({String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      columns: ['id'],
      where: "store_id = ? AND status = 'open'",
      whereArgs: [activeStoreId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final activeShiftId = maps.first['id'].toString();
    return getShiftSummary(activeShiftId);
  }

  Future<List<ShiftSummary>> getClosedShifts({String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: "store_id = ? AND status = 'closed'",
      whereArgs: [activeStoreId],
      orderBy: 'end_time DESC',
    );

    final List<ShiftSummary> list = [];
    for (final map in maps) {
      final summary = await getShiftSummary(map['id'].toString());
      if (summary != null) {
        list.add(summary);
      }
    }
    return list;
  }

  Future<DailyReportSummary?> getDailyReportSummary(String dateStr, {String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;

    final List<Map<String, dynamic>> shifts = await db.rawQuery('''
      SELECT id 
      FROM shifts
      WHERE store_id = ? AND DATE(start_time, 'localtime') = ?
    ''', [activeStoreId, dateStr]);

    if (shifts.isEmpty) return null;

    double totalStartingCash = 0.0;
    double totalEndingCash = 0.0;
    double totalSalesCash = 0.0;
    double totalSalesNonCash = 0.0;
    double totalSalesVoid = 0.0;
    int totalTransactions = 0;

    for (final s in shifts) {
      final shiftId = s['id'].toString();
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
      final shiftId = s['id'].toString();
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

  Future<List<DailyReportSummary>> getDailyReportsHistory({String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;

    final List<Map<String, dynamic>> datesMaps = await db.rawQuery('''
      SELECT DISTINCT DATE(start_time, 'localtime') as date_str
      FROM shifts
      WHERE store_id = ?
      ORDER BY date_str DESC
    ''', [activeStoreId]);

    final List<DailyReportSummary> list = [];
    for (final row in datesMaps) {
      final dateStr = row['date_str'] as String?;
      if (dateStr != null) {
        final summary = await getDailyReportSummary(dateStr, storeId: activeStoreId);
        if (summary != null) {
          list.add(summary);
        }
      }
    }
    return list;
  }

  Future<CustomerReportSummary> getCustomerReportSummary({DateTime? startDate, DateTime? endDate, String? storeId}) async {
    final activeStoreId = (storeId != null && storeId.isNotEmpty) ? storeId : 'store-uuid-001';
    final db = await _dbService.database;

    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM customers WHERE store_id = ?', [activeStoreId]);
    final totalCustomers = countResult.isNotEmpty ? ((countResult.first['count'] as int?) ?? 0) : 0;

    String dateFilter = '';
    List<dynamic> whereArgs = [activeStoreId];

    if (startDate != null && endDate != null) {
      final startStr = '${startDate.toIso8601String().split('T').first} 00:00:00';
      final endStr = '${endDate.toIso8601String().split('T').first} 23:59:59';
      dateFilter = " AND DATETIME(t.created_at, 'localtime') BETWEEN ? AND ? ";
      whereArgs = [activeStoreId, startStr, endStr];
    }

    final transResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as trans_count, COALESCE(SUM(t.total_amount), 0.0) as total_revenue
      FROM transactions t
      WHERE t.store_id = ? AND t.customer_id IS NOT NULL AND t.customer_id != '' AND t.customer_id != '0' AND t.customer_id != 0 AND t.status != 'void' $dateFilter
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
      WHERE c.store_id = ? AND t.status != 'void' $dateFilter
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
