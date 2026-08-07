import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/widgets/restart_widget.dart';
import '../../../core/utils/role_extension.dart';
import '../../auth/providers/auth_provider.dart';

class MainLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 800;
    final user = ref.watch(authProvider);
    final isCashier = user.isCashier;

    // Branches mapping:
    // Admin: 0: Dashboard, 1: POS, 2: Products, 3: Reports, 4: Settings
    // Cashier: 0: Dashboard, 1: POS, 2: Products, 3: Settings (mapped to branch 4)
    final currentBranch = navigationShell.currentIndex;
    final selectedUiIndex = isCashier
        ? (currentBranch == 4 ? 3 : (currentBranch < 3 ? currentBranch : 0))
        : currentBranch;

    final railDestinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('Home'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: Text('Transaksi'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: Text('Produk'),
      ),
      if (!isCashier)
        const NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Laporan'),
        ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Lainnya'),
      ),
    ];

    final bottomNavItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart_outlined),
        activeIcon: Icon(Icons.shopping_cart),
        label: 'Transaksi',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        activeIcon: Icon(Icons.inventory_2),
        label: 'Produk',
      ),
      if (!isCashier)
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Laporan',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Lainnya',
      ),
    ];

    void onTap(int uiIndex) {
      int branchIndex = uiIndex;
      if (isCashier) {
        if (uiIndex == 3) {
          branchIndex = 4; // Settings branch
        }
      }
      navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == navigationShell.currentIndex,
      );
    }

    return Scaffold(
      body: isTablet
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedUiIndex,
                  onDestinationSelected: onTap,
                  backgroundColor: AppColors.primary,
                  unselectedIconTheme: const IconThemeData(color: Colors.white54),
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
                  selectedLabelTextStyle: const TextStyle(color: Colors.white),
                  labelType: NavigationRailLabelType.all,
                  destinations: railDestinations,
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: AppColors.destructive),
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) {
                              RestartWidget.restartApp(context);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: navigationShell),
              ],
            )
          : navigationShell,
      bottomNavigationBar: isTablet
          ? null
          : BottomNavigationBar(
              currentIndex: selectedUiIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blue[600],
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              items: bottomNavItems,
            ),
    );
  }
}
