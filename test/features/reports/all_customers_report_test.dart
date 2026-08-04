import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/reports/data/report_local_repository.dart';
import 'package:mobile_pos_flutter/features/reports/presentation/all_customers_report_page.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  testWidgets('AllCustomersReportPage renders period filters, summary cards, and search', (WidgetTester tester) async {
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
          home: AllCustomersReportPage(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Laporan Detail Pelanggan'), findsOneWidget);
    expect(find.text('Total Pelanggan'), findsOneWidget);
    expect(find.text('Transaksi Pelanggan'), findsOneWidget);
    expect(find.text('Omset Pelanggan'), findsOneWidget);
    expect(find.text('Rata-rata Belanja'), findsOneWidget);

    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsOneWidget);
    expect(find.text('Tahun Ini'), findsOneWidget);
    expect(find.textContaining('Rentang Periode:'), findsOneWidget);
    expect(find.text('SQLite DB'), findsOneWidget);
  });
}
