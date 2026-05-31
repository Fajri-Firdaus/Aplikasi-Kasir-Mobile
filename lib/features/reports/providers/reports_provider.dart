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

  const ReportData({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalExpense,
    required this.startDate,
    required this.endDate,
    this.hourlySales = const [],
    this.topProducts = const [],
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
      totalRevenue: 0,
      totalTransactions: 0,
      totalExpense: 0,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      hourlySales: const [],
      topProducts: const [],
    );
  }

  Future<void> loadReportData(DateTime start, DateTime end) async {
    try {
      final summary = await _repository.getFinancialSummary(start, end);
      
      // Fetch hourly sales and top products for today specifically
      final hourly = await _repository.getTodayHourlySales();
      final top = await _repository.getTodayTopProducts();

      // Ensure all 24 hours are represented
      final fullHourly = List.generate(24, (index) {
        final hourStr = '${(index + 1).toString().padLeft(2, '0')}:00';
        final existing = hourly.firstWhere(
          (h) => h.hour == hourStr,
          orElse: () => HourlySales(hour: hourStr, totalSales: 0.0),
        );
        return existing;
      });

      state = ReportData(
        totalRevenue: summary.totalRevenue,
        totalTransactions: summary.totalTransactions,
        totalExpense: summary.totalHpp,
        startDate: start,
        endDate: end,
        hourlySales: fullHourly,
        topProducts: top,
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> refresh() async {
    await loadReportData(state.startDate, state.endDate);
  }

  void setFilter({required DateTime startDate, required DateTime endDate}) {
    loadReportData(startDate, endDate);
  }
}
