import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_local_repository.dart';
import 'transactions_report_provider.dart';
import '../../transactions/data/transaction_local_repository.dart';
import '../../auth/providers/auth_provider.dart';

class ReportData {
  final double totalRevenue;
  final int totalTransactions;
  final double totalExpense;
  final DateTime startDate;
  final DateTime endDate;
  final List<HourlySales> hourlySales;
  final List<DailySales> weeklyDailySales;
  final double weeklyTotalRevenue;
  final List<WeeklySales> monthlyWeeklySales;
  final double monthlyTotalRevenue;
  final List<TopProduct> topProducts;
  final List<LowStockItem> lowStockProducts;
  final CustomerReportSummary? customerSummary;

  const ReportData({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalExpense,
    required this.startDate,
    required this.endDate,
    required this.hourlySales,
    required this.weeklyDailySales,
    required this.weeklyTotalRevenue,
    required this.monthlyWeeklySales,
    required this.monthlyTotalRevenue,
    required this.topProducts,
    required this.lowStockProducts,
    this.customerSummary,
  });

  double get totalHpp => totalExpense;
  double get netProfit => totalRevenue - totalExpense;
}

final reportsProvider = NotifierProvider<ReportsNotifier, ReportData>(ReportsNotifier.new);

class ReportsNotifier extends Notifier<ReportData> {
  late final ReportLocalRepository _repository;

  @override
  ReportData build() {
    _repository = ref.watch(reportRepositoryProvider);
    final storeId = ref.watch(activeStoreIdProvider);

    // Initial fetch for today
    Future.microtask(() => loadReportData(DateTime.now(), DateTime.now(), storeId: storeId));
    
    return ReportData(
      totalRevenue: 0.0,
      totalTransactions: 0,
      totalExpense: 0.0,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      hourlySales: const [],
      weeklyDailySales: const [],
      weeklyTotalRevenue: 0.0,
      monthlyWeeklySales: const [],
      monthlyTotalRevenue: 0.0,
      topProducts: const [],
      lowStockProducts: const [],
    );
  }

  Future<void> loadReportData(DateTime start, DateTime end, {String? storeId}) async {
    try {
      final activeStoreId = storeId ?? ref.read(activeStoreIdProvider);
      final now = DateTime.now();

      // Calculate Monday to Sunday for current week
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));

      // Calculate Month Start to Month End for current month
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final summary = await _repository.getFinancialSummary(start, end, storeId: activeStoreId);

      // Fetch hourly sales, weekly sales (Mon-Sun), monthly sales, top products, low stock, and customer summary
      final List<HourlySales> hourly = await _repository.getTodayHourlySales(storeId: activeStoreId);
      final List<DailySales> weeklyDaily = await _repository.getWeeklyDailySales(monday, sunday, storeId: activeStoreId);
      final List<WeeklySales> monthlyWeekly = await _repository.getMonthlyWeeklySales(monthStart, monthEnd, storeId: activeStoreId);
      final List<TopProduct> top = await _repository.getTopProducts(start, end, storeId: activeStoreId);
      final List<LowStockItem> lowStock = await _repository.getLowStockProducts(storeId: activeStoreId);
      final CustomerReportSummary customerSum = await _repository.getCustomerReportSummary(startDate: start, endDate: end, storeId: activeStoreId);

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

      final double weeklyTotal = weeklyDaily.fold(0.0, (sum, item) => sum + item.totalSales);
      final double monthlyTotal = monthlyWeekly.fold(0.0, (sum, item) => sum + item.totalSales);

      if (ref.mounted) {
        state = ReportData(
          totalRevenue: summary.totalRevenue,
          totalTransactions: summary.totalTransactions,
          totalExpense: summary.totalHpp,
          startDate: start,
          endDate: end,
          hourlySales: fullHourly,
          weeklyDailySales: weeklyDaily,
          weeklyTotalRevenue: weeklyTotal,
          monthlyWeeklySales: monthlyWeekly,
          monthlyTotalRevenue: monthlyTotal,
          topProducts: top,
          lowStockProducts: lowStock,
          customerSummary: customerSum,
        );
      }
    } catch (e) {
      // Handle error safely if needed
    }
  }

  Future<void> refresh() async {
    ref.invalidate(recentTransactionsProvider);
    final storeId = ref.read(activeStoreIdProvider);
    await loadReportData(state.startDate, state.endDate, storeId: storeId);
  }

  void setFilter({required DateTime startDate, required DateTime endDate}) {
    final storeId = ref.read(activeStoreIdProvider);
    loadReportData(startDate, endDate, storeId: storeId);
  }
}

final activeShiftProvider = AsyncNotifierProvider<ActiveShiftNotifier, ShiftSummary?>(ActiveShiftNotifier.new);

class ActiveShiftNotifier extends AsyncNotifier<ShiftSummary?> {
  late final ReportLocalRepository _reportRepository;
  late final TransactionLocalRepository _transactionRepository;

  @override
  FutureOr<ShiftSummary?> build() async {
    _reportRepository = ref.watch(reportRepositoryProvider);
    _transactionRepository = ref.watch(transactionRepositoryProvider);
    final storeId = ref.watch(activeStoreIdProvider);
    try {
      return await _reportRepository.getActiveShiftSummary(storeId: storeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshShift() async {
    final storeId = ref.read(activeStoreIdProvider);
    state = const AsyncValue.loading();
    final res = await AsyncValue.guard(() => _reportRepository.getActiveShiftSummary(storeId: storeId));
    if (ref.mounted) {
      state = res;
    }
  }

  Future<void> openNewShift(String userId, double startingCash) async {
    final storeId = ref.read(activeStoreIdProvider);
    state = const AsyncValue.loading();
    final res = await AsyncValue.guard(() async {
      await _transactionRepository.openShift(userId, startingCash, storeId: storeId);
      if (ref.mounted) {
        ref.read(reportsProvider.notifier).refresh();
      }
      return _reportRepository.getActiveShiftSummary(storeId: storeId);
    });
    if (ref.mounted) {
      state = res;
    }
  }

  Future<ShiftSummary?> closeActiveShift(double endingCash) async {
    final current = state.value;
    if (current == null) return null;

    ShiftSummary? closedSummary;
    state = const AsyncValue.loading();
    
    // We run the operations and update state inside guard
    state = await AsyncValue.guard(() async {
      await _transactionRepository.closeShift(current.shiftId, endingCash);
      closedSummary = await _reportRepository.getShiftSummary(current.shiftId);
      
      // Refresh general reports and history
      ref.read(reportsProvider.notifier).refresh();
      ref.read(closedShiftsProvider.notifier).refreshHistory();
      ref.read(dailyReportsProvider.notifier).refreshHistory();
      
      return null; // Active shift is now closed (null)
    });

    return closedSummary;
  }
}

final closedShiftsProvider = AsyncNotifierProvider<ClosedShiftsNotifier, List<ShiftSummary>>(ClosedShiftsNotifier.new);

class ClosedShiftsNotifier extends AsyncNotifier<List<ShiftSummary>> {
  late final ReportLocalRepository _reportRepository;

  @override
  FutureOr<List<ShiftSummary>> build() async {
    _reportRepository = ref.watch(reportRepositoryProvider);
    final storeId = ref.watch(activeStoreIdProvider);
    try {
      return await _reportRepository.getClosedShifts(storeId: storeId);
    } catch (_) {
      return const [];
    }
  }

  Future<void> refreshHistory() async {
    final storeId = ref.read(activeStoreIdProvider);
    state = const AsyncValue.loading();
    final res = await AsyncValue.guard(() => _reportRepository.getClosedShifts(storeId: storeId));
    if (ref.mounted) {
      state = res;
    }
  }
}

final dailyReportsProvider = AsyncNotifierProvider<DailyReportsNotifier, List<DailyReportSummary>>(DailyReportsNotifier.new);

class DailyReportsNotifier extends AsyncNotifier<List<DailyReportSummary>> {
  late final ReportLocalRepository _reportRepository;

  @override
  FutureOr<List<DailyReportSummary>> build() async {
    _reportRepository = ref.watch(reportRepositoryProvider);
    final storeId = ref.watch(activeStoreIdProvider);
    try {
      return await _reportRepository.getDailyReportsHistory(storeId: storeId);
    } catch (_) {
      return const [];
    }
  }

  Future<void> refreshHistory() async {
    final storeId = ref.read(activeStoreIdProvider);
    state = const AsyncValue.loading();
    final res = await AsyncValue.guard(() => _reportRepository.getDailyReportsHistory(storeId: storeId));
    if (ref.mounted) {
      state = res;
    }
  }
}

