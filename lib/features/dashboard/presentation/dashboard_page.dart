import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'widgets/profile_header.dart';
import 'widgets/start_transaction_card.dart';
import 'widgets/performance_summary.dart';
import 'widgets/quick_actions_widget.dart';
import 'widgets/mini_analytics_widget.dart';
import 'widgets/inventory_alerts_widget.dart';
import '../../reports/providers/reports_provider.dart';
import '../../notifications/presentation/notification_panel.dart';
import '../../notifications/providers/notification_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _notificationOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reportsProvider.notifier).refresh();
      ref.read(notificationNotifierProvider.notifier).syncFromDatabase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                ProfileHeader(
                  onNotificationTap: () => setState(() => _notificationOpen = !_notificationOpen),
                  notificationCount: unreadCount,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        StartTransactionCard(
                          onStartTransaction: () => context.go('/pos'),
                        ),
                        const SizedBox(height: 12),
                        const PerformanceSummary(),
                        const SizedBox(height: 12),
                        QuickActionsWidget(
                          onAddProduct: () => context.go('/products'),
                          onPrintReport: () => context.go('/reports'),
                        ),
                        const SizedBox(height: 12),
                        const MiniAnalyticsWidget(),
                        const SizedBox(height: 12),
                        const InventoryAlertsWidget(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Notification panel overlay
            if (_notificationOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _notificationOpen = false),
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),
            if (_notificationOpen)
              Positioned(
                top: 0,
                right: 0,
                width: MediaQuery.of(context).size.width * 0.85,
                bottom: 0,
                child: NotificationPanel(
                  onClose: () => setState(() => _notificationOpen = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

