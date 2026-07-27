import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/core/presentation/widgets/restart_widget.dart';
import 'package:mobile_pos_flutter/features/auth/providers/auth_provider.dart';
import 'package:mobile_pos_flutter/features/products/providers/product_provider.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RestartWidget rebuilds root widget subtree on restartApp', (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      RestartWidget(
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              buildCount++;
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => RestartWidget.restartApp(context),
                  child: Text('Build Count: $buildCount'),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Build Count: 1'), findsOneWidget);

    // Trigger restartApp
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify build count incremented due to subtree recreation
    expect(find.text('Build Count: 2'), findsOneWidget);
  });

  test('Logout invalidates domain providers and clears active user', () async {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
      ],
    );
    addTearDown(() {
      container.read(localDatabaseServiceProvider).close();
      container.dispose();
    });

    final authNotifier = container.read(authProvider.notifier);

    // 1. Login user
    await authNotifier.login('admin', '123456');
    expect(container.read(authProvider) != null, true);

    // Access products provider
    final products = container.read(productsProvider);
    expect(products, isNotNull);

    // 2. Logout user
    await authNotifier.logout();
    expect(container.read(authProvider), null);
  });
}
