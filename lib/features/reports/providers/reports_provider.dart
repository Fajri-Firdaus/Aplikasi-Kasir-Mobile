import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_local_repository.dart';

class ReportData {
  final double totalRevenue;
  final int totalTransactions;
  final double totalExpense;
  final DateTime startDate;
  final DateTime endDate;

  const ReportData({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalExpense,
    required this.startDate,
    required this.endDate,
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
    );
  }

  Future<void> loadReportData(DateTime start, DateTime end) async {
    try {
      final summary = await _repository.getFinancialSummary(start, end);
      state = ReportData(
        totalRevenue: summary.totalRevenue,
        totalTransactions: summary.totalTransactions,
        totalExpense: summary.totalHpp,
        startDate: start,
        endDate: end,
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
