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

  TopProduct({required this.name, required this.totalSold});
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

class ReportLocalRepository {
  final LocalDatabaseService _dbService;

  ReportLocalRepository(this._dbService);

  // Home Performance - Today Summary
  Future<FinancialSummary> getTodaySummary() async {
    final db = await _dbService.database;
    
    final countMaps = await db.rawQuery('''
      SELECT COUNT(id) AS count
      FROM transactions
      WHERE DATE(created_at) = DATE('now', 'localtime') AND status != 'void'
    ''');
    final totalTxns = countMaps.isNotEmpty ? (countMaps.first['count'] as int? ?? 0) : 0;

    final maps = await db.rawQuery('''
      SELECT 
          COALESCE(SUM(t.total_amount), 0.0) AS penjualan_hari_ini,
          COALESCE(SUM(td.quantity * td.buy_price_at_sale), 0.0) AS hpp_hari_ini
      FROM transactions t
      LEFT JOIN transaction_details td ON t.id = td.transaction_id
      WHERE DATE(t.created_at) = DATE('now', 'localtime') AND t.status != 'void'
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
      WHERE created_at BETWEEN ? AND ? AND status != 'void'
    ''', [startStr, endStr]);
    final totalTxns = countMaps.isNotEmpty ? (countMaps.first['count'] as int? ?? 0) : 0;

    final maps = await db.rawQuery('''
      SELECT 
          COALESCE(SUM(t.total_amount), 0.0) AS total_pendapatan,
          COALESCE(SUM(td.quantity * td.buy_price_at_sale), 0.0) AS total_hpp
      FROM transactions t
      LEFT JOIN transaction_details td ON t.id = td.transaction_id
      WHERE t.created_at BETWEEN ? AND ? AND t.status != 'void'
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
          STRFTIME('%H:00', created_at) AS jam,
          COALESCE(SUM(total_amount), 0.0) AS total_omzet
      FROM transactions
      WHERE DATE(created_at) = DATE('now', 'localtime') AND status != 'void'
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

  Future<List<TopProduct>> getTodayTopProducts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
          p.name,
          COALESCE(SUM(td.quantity), 0) AS total_terjual
      FROM transaction_details td
      JOIN products p ON td.product_id = p.id
      JOIN transactions t ON td.transaction_id = t.id
      WHERE DATE(t.created_at) = DATE('now', 'localtime') AND t.status != 'void'
      GROUP BY p.id
      ORDER BY total_terjual DESC
      LIMIT 5
    ''');

    return maps.map((row) {
      return TopProduct(
        name: (row['name'] ?? 'Unknown') as String,
        totalSold: (row['total_terjual'] as int? ?? 0),
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
          u.username,
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
}
