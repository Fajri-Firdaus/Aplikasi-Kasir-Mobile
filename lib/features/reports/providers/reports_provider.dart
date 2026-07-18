import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_local_repository.dart';

class ReportData {
  final double totalRevenue;
  final int totalTransactions;
  final double totalExpense;
  final DateTime startDate;
  final DateTime endDate;
  final List<HourlySales> hourlySales;
  final List<TopProduct> topProducts;
  final List<LowStockItem> lowStockProducts;

  const ReportData({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalExpense,
    required this.startDate,
    required this.endDate,
    required this.hourlySales,
    required this.topProducts,
    required this.lowStockProducts,
  });

  double get netProfit => totalRevenue - totalExpense;
}

final reportsProvider = NotifierProvider<ReportsNotifier, ReportData>(ReportsNotifier.new);

class ReportsNotifier extends Notifier<ReportData> {
  late final ReportLocalRepository _repository;

  @override
  ReportData build() {
    _repository = ref.watch(reportRepositoryProvider);
    // Initial fetch for today
    Future.microtask(() => loadReportData(DateTime.now(), DateTime.now()));
    
    return ReportData(
      totalRevenue: 0.0,
      totalTransactions: 0,
      totalExpense: 0.0,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      hourlySales: const [],
      topProducts: const [],
      lowStockProducts: const [],
    );
  }

  Future<void> loadReportData(DateTime start, DateTime end) async {
    try {
      final summary = await _repository.getFinancialSummary(start, end);

      // Fetch hourly sales, top products, and low stock for today specifically
      final List<HourlySales> hourly = await _repository.getTodayHourlySales();
      final List<TopProduct> top = await _repository.getTopProducts(start, end);
      final List<LowStockItem> lowStock = await _repository.getLowStockProducts();

      // Ensure all 24 hours are represented, mapping DB's 00:00 to 24:00 if needed
      final List<HourlySales> fullHourly = List.generate(24, (index) {
        // We want display hours 01:00 to 24:00
        final displayHour = index + 1;
        final hourStr = '${displayHour.toString().padLeft(2, '0')}:00';
        
        // SQLite STRFTIME %H returns 00-23. Map 24:00 back to 00:00 for lookup.
        final lookupHour = displayHour == 24 ? '00:00' : hourStr;
        
        final existing = hourly.firstWhere(
          (h) => h.hour == lookupHour,
          orElse: () => HourlySales(hour: hourStr, totalSales: 0.0),
        );
        
        // Return with the display hour string
        return HourlySales(hour: hourStr, totalSales: existing.totalSales);
      });

      state = ReportData(
        totalRevenue: summary.totalRevenue,
        totalTransactions: summary.totalTransactions,
        totalExpense: summary.totalHpp,
        startDate: start,
        endDate: end,
        hourlySales: fullHourly,
        topProducts: top,
        lowStockProducts: lowStock,
      );
    } catch (e) {
      // Handle error safely if needed
    }
  }

  Future<void> refresh() async {
    await loadReportData(state.startDate, state.endDate);
  }

  void setFilter({required DateTime startDate, required DateTime endDate}) {
    loadReportData(startDate, endDate);
  }
}
