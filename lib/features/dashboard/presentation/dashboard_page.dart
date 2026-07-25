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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                ProfileHeader(
                  onNotificationTap: () => setState(() => _notificationOpen = !_notificationOpen),
                  notificationCount: 3,
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
                child: _NotificationPanel(
                  onClose: () => setState(() => _notificationOpen = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  final VoidCallback onClose;
  const _NotificationPanel({required this.onClose});

  static const _notifications = [
    {'icon': Icons.warning_amber_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFEDD5), 'title': 'Stok Menipis', 'body': 'Teh Tarik Original tersisa 8 unit', 'time': '5 menit lalu'},
    {'icon': Icons.check_circle_outline, 'color': Color(0xFF16A34A), 'bg': Color(0xFFDCFCE7), 'title': 'Transaksi Selesai', 'body': 'Transaksi #T-042 berhasil', 'time': '12 menit lalu'},
    {'icon': Icons.info_outline, 'color': Color(0xFF2563EB), 'bg': Color(0xFFDBEAFE), 'title': 'Pengingat Shift', 'body': 'Shift pagi segera berakhir', 'time': '1 jam lalu'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _notifications.map((n) {
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: n['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 20),
                    ),
                    title: Text('${n['title']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${n['body']}', style: const TextStyle(fontSize: 12)),
                        Text('${n['time']}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                    isThreeLine: true,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
