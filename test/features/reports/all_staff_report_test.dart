import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/reports/data/report_local_repository.dart';
import 'package:mobile_pos_flutter/features/reports/presentation/all_staff_report_page.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  testWidgets('AllStaffReportPage renders metrics, period chips, search bar, and staff list', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
      ],
    );
    addTearDown(() {
      container.read(localDatabaseServiceProvider).close();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AllStaffReportPage(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Laporan Detail SDM & Kasir'), findsOneWidget);
    expect(find.text('Total Staf'), findsOneWidget);
    expect(find.text('Kasir Aktif'), findsOneWidget);
    expect(find.text('Total Shift'), findsOneWidget);
    expect(find.text('Omset SDM'), findsOneWidget);

    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsOneWidget);
    expect(find.text('Tahun Ini'), findsOneWidget);
    expect(find.textContaining('Rentang Periode:'), findsOneWidget);
    expect(find.text('SQLite DB'), findsOneWidget);
  });

  testWidgets('getStaffReportSummary fetches staff performance from SQLite database', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final container = ProviderContainer(
        overrides: [
          localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
        ],
      );

      try {
        final repo = container.read(reportRepositoryProvider);
        final now = DateTime.now();

        final summary = await repo.getStaffReportSummary(
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
          storeId: 'store-uuid-001',
        );

        expect(summary, isNotNull);
        expect(summary.totalStaff, greaterThanOrEqualTo(0));
        expect(summary.staffList, isA<List<CashierPerformance>>());
      } finally {
        await container.read(localDatabaseServiceProvider).close();
        container.dispose();
      }
    });
  });
}
