import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  ReportData build() {
    return ReportData(
      totalRevenue: 10260000,
      totalTransactions: 48,
      totalExpense: 890000,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
    );
  }

  void setFilter({required DateTime startDate, required DateTime endDate}) {
    // In a real app, this would fetch data from a repository
    state = ReportData(
      totalRevenue: state.totalRevenue, // Dummy keep
      totalTransactions: state.totalTransactions,
      totalExpense: state.totalExpense,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
