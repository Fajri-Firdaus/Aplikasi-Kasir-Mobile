import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/reports/presentation/all_product_performance_page.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  testWidgets('AllProductPerformancePage renders period filter chips and sorting toggle', (WidgetTester tester) async {
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
          home: AllProductPerformancePage(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Performa Produk & Menu'), findsOneWidget);
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsOneWidget);
    expect(find.text('Tahun Ini'), findsOneWidget);
    expect(find.text('Terbanyak'), findsOneWidget);
  });
}
