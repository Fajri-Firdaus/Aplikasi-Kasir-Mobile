import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/reports/presentation/reports_page.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  testWidgets('ReportsPage renders Financial Tab correctly without error', (WidgetTester tester) async {
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
          home: ReportsPage(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // Verify Financial Tab title & elements are present
    expect(find.text('Analisis Keuangan & Pendapatan'), findsOneWidget);
    expect(find.text('Pendapatan'), findsOneWidget);
    expect(find.text('HPP'), findsOneWidget);
    expect(find.text('Laba Bersih'), findsOneWidget);
    expect(find.text('10 Transaksi Terakhir'), findsOneWidget);
  });
}
