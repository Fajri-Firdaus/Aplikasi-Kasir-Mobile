import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/features/reports/providers/reports_provider.dart';

void main() {
  test('ReportsNotifier filters data by date', () {
    final container = ProviderContainer();
    final notifier = container.read(reportsProvider.notifier);
    
    final start = DateTime(2023, 1, 1);
    final end = DateTime(2023, 1, 31);
    
    notifier.setFilter(startDate: start, endDate: end);
    final reportData = container.read(reportsProvider);
    
    expect(reportData.totalRevenue, greaterThanOrEqualTo(0));
    expect(reportData.startDate, start);
    expect(reportData.endDate, end);
  });
}
