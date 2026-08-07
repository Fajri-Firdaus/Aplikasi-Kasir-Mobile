import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/core/utils/role_extension.dart';
import 'package:mobile_pos_flutter/features/users/data/app_user.dart';
import 'package:mobile_pos_flutter/features/auth/providers/auth_provider.dart';
import 'package:mobile_pos_flutter/features/dashboard/presentation/widgets/performance_summary.dart';
import 'package:mobile_pos_flutter/features/products/presentation/products_page.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';
import 'package:mobile_pos_flutter/features/products/providers/product_provider.dart';
import 'package:mobile_pos_flutter/features/settings/presentation/settings_page.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  const adminUser = AppUser(
    id: 'user_admin',
    name: 'Admin Utama',
    username: 'admin',
    email: 'admin@example.com',
    role: 'admin',
    createdAt: '2026-01-01',
  );

  const cashierUser = AppUser(
    id: 'user_cashier',
    name: 'Kasir Toko',
    username: 'kasir1',
    email: 'kasir1@example.com',
    role: 'kasir',
    createdAt: '2026-01-01',
  );

  group('Role Extension Helper Unit Tests', () {
    test('UserRoleX correctly identifies Admin role', () {
      expect(adminUser.isAdmin, true);
      expect(adminUser.isCashier, false);
    });

    test('UserRoleX correctly identifies Cashier role', () {
      expect(cashierUser.isAdmin, false);
      expect(cashierUser.isCashier, true);
    });
  });

  group('Widget Role Scoping Tests', () {
    testWidgets('PerformanceSummary shows Laba Bersih for Admin', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
            authProvider.overrideWith(() => FakeAuthNotifier(adminUser)),
          ],
          child: const MaterialApp(home: Scaffold(body: PerformanceSummary())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Penjualan Hari Ini'), findsOneWidget);
      expect(find.text('Total Transaksi'), findsOneWidget);
      expect(find.text('Laba Bersih'), findsOneWidget);
    });

    testWidgets('PerformanceSummary HIDES Laba Bersih for Cashier', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
            authProvider.overrideWith(() => FakeAuthNotifier(cashierUser)),
          ],
          child: const MaterialApp(home: Scaffold(body: PerformanceSummary())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Penjualan Hari Ini'), findsOneWidget);
      expect(find.text('Total Transaksi'), findsOneWidget);
      expect(find.text('Laba Bersih'), findsNothing);
    });

    testWidgets('ProductsPage HIDES Tambah button and Harga Beli for Cashier', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
            authProvider.overrideWith(() => FakeAuthNotifier(cashierUser)),
            productNotifierProvider.overrideWith(() => FakeProductNotifier([
              const Product(id: '1', name: 'Kopi Susu', price: 18000, buyPrice: 10000, category: 'Minuman', imageUrl: '', stock: 20, sku: 'KP01')
            ])),
          ],
          child: const MaterialApp(home: ProductsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Header Tambah button should NOT be visible
      expect(find.text('Tambah'), findsNothing);

      // Product card should show Jual price but NOT Beli price
      expect(find.textContaining('Jual: Rp'), findsOneWidget);
      expect(find.textContaining('Beli: Rp'), findsNothing);

      // Edit & Delete icons should NOT be visible
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('SettingsPage HIDES management groups and shows only Logout for Cashier', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
            authProvider.overrideWith(() => FakeAuthNotifier(cashierUser)),
          ],
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lainnya'), findsOneWidget);
      expect(find.text('Kasir Toko'), findsOneWidget);
      expect(find.text('KASIR'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Admin menu groups should NOT be visible
      expect(find.text('Manajemen User'), findsNothing);
      expect(find.text('Pengaturan Toko'), findsNothing);
      expect(find.text('Printer & Hardware'), findsNothing);
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  final AppUser initialUser;
  FakeAuthNotifier(this.initialUser);

  @override
  AppUser? build() => initialUser;
}

class FakeProductNotifier extends ProductNotifier {
  final List<Product> initialProducts;
  FakeProductNotifier(this.initialProducts);

  @override
  List<Product> build() => initialProducts;
}
