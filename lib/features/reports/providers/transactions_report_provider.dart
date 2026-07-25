import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/data/transaction.dart';
import '../../transactions/data/transaction_local_repository.dart';

enum TransactionFilterPeriod {
  today,
  week,
  month,
  year,
  custom,
}

class AllTransactionsState {
  final TransactionFilterPeriod period;
  final DateTimeRange? customRange;
  final List<Transaction> transactions;
  final bool isLoading;

  AllTransactionsState({
    required this.period,
    this.customRange,
    required this.transactions,
    this.isLoading = false,
  });

  AllTransactionsState copyWith({
    TransactionFilterPeriod? period,
    DateTimeRange? customRange,
    List<Transaction>? transactions,
    bool? isLoading,
  }) {
    return AllTransactionsState(
      period: period ?? this.period,
      customRange: customRange ?? this.customRange,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  double get totalRevenue => transactions
      .where((t) => t.status != 'void')
      .fold(0.0, (sum, t) => sum + t.totalAmount);

  int get totalCount => transactions.where((t) => t.status != 'void').length;
}

final recentTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getRecentTransactions(limit: 10);
});

final allTransactionsNotifierProvider = NotifierProvider<AllTransactionsNotifier, AllTransactionsState>(
  AllTransactionsNotifier.new,
);

class AllTransactionsNotifier extends Notifier<AllTransactionsState> {
  late final TransactionLocalRepository _repository;

  @override
  AllTransactionsState build() {
    _repository = ref.watch(transactionRepositoryProvider);
    Future.microtask(() => filterBy(TransactionFilterPeriod.today));
    return AllTransactionsState(
      period: TransactionFilterPeriod.today,
      transactions: const [],
      isLoading: true,
    );
  }

  Future<void> filterBy(TransactionFilterPeriod period, {DateTimeRange? customRange}) async {
    state = state.copyWith(period: period, customRange: customRange, isLoading: true);

    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (period) {
      case TransactionFilterPeriod.today:
        start = now;
        end = now;
        break;
      case TransactionFilterPeriod.week:
        start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 6));
        break;
      case TransactionFilterPeriod.month:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case TransactionFilterPeriod.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      case TransactionFilterPeriod.custom:
        if (customRange != null) {
          start = customRange.start;
          end = customRange.end;
        }
        break;
    }

    try {
      final txns = await _repository.getFilteredTransactions(startDate: start, endDate: end);
      if (ref.mounted) {
        state = state.copyWith(transactions: txns, isLoading: false);
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(transactions: [], isLoading: false);
      }
    }
  }
}
