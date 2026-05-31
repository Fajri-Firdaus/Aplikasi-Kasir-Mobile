import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/reports/providers/reports_provider.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
      ],
    );
    addTearDown(() {
      container.read(localDatabaseServiceProvider).close();
      container.dispose();
    });
    return container;
  }

  test('ReportsNotifier filters data by date and fetches from SQLite', () async {
    final container = createContainer();
    final notifier = container.read(reportsProvider.notifier);
    
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 1, 31);
    
    // Trigger filter update
    notifier.setFilter(startDate: start, endDate: end);
    
    // Wait for the async db operation inside loadReportData to resolve and update state
    await notifier.loadReportData(start, end);
    
    final reportData = container.read(reportsProvider);
    
    expect(reportData.totalRevenue, 0.0); // Should be 0 since no transactions are inside January 2026 in testing db
    expect(reportData.startDate, start);
    expect(reportData.endDate, end);
  });
}
