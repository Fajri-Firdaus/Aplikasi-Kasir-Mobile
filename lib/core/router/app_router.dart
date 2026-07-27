import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/users/data/app_user.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/main_layout.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/transactions/presentation/transaction_page.dart';
import '../../features/products/presentation/products_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/reports/presentation/all_transactions_page.dart';
import '../../features/reports/presentation/all_product_performance_page.dart';
import '../../features/reports/presentation/all_inventory_stock_page.dart';
import '../../features/reports/presentation/all_customers_report_page.dart';
import '../../features/reports/presentation/all_staff_report_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/settings/presentation/profile_page.dart';
import '../../features/settings/presentation/store_settings_page.dart';
import '../../features/users/presentation/users_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>();
final _shellNavigatorPOSKey = GlobalKey<NavigatorState>();
final _shellNavigatorProductsKey = GlobalKey<NavigatorState>();
final _shellNavigatorReportsKey = GlobalKey<NavigatorState>();
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AppUser?>(
      authProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: routerNotifier,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = ref.read(authProvider) != null;
      final loggingIn = state.uri.toString() == '/login';
      
      // If not logged in and not heading to login, redirect to login
      if (!isAuth && !loggingIn) return '/login';
      
      // If logged in and heading to login, redirect to home
      if (isAuth && loggingIn) return '/dashboard';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPOSKey,
            routes: [
              GoRoute(
                path: '/pos',
                pageBuilder: (context, state) => const NoTransitionPage(child: TransactionPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProductsKey,
            routes: [
              GoRoute(
                path: '/products',
                pageBuilder: (context, state) => const NoTransitionPage(child: ProductsPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorReportsKey,
            routes: [
              GoRoute(
                path: '/reports',
                pageBuilder: (context, state) => const NoTransitionPage(child: ReportsPage()),
                routes: [
                  GoRoute(
                    path: 'all-transactions',
                    builder: (context, state) => const AllTransactionsPage(),
                  ),
                  GoRoute(
                    path: 'all-product-performance',
                    builder: (context, state) => const AllProductPerformancePage(),
                  ),
                  GoRoute(
                    path: 'all-inventory-stock',
                    builder: (context, state) => const AllInventoryStockPage(),
                  ),
                  GoRoute(
                    path: 'all-customers',
                    builder: (context, state) => const AllCustomersReportPage(),
                  ),
                  GoRoute(
                    path: 'all-staff',
                    builder: (context, state) => const AllStaffReportPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()),
                routes: [
                  GoRoute(
                    path: 'users',
                    builder: (context, state) => const UsersPage(),
                  ),
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ProfilePage(),
                  ),
                  GoRoute(
                    path: 'store',
                    builder: (context, state) => const StoreSettingsPage(),
                  ),
                ]
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
