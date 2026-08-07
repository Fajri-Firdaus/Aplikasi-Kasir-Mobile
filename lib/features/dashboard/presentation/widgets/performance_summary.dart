import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reports/providers/reports_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/utils/role_extension.dart';

class PerformanceSummary extends ConsumerWidget {
  const PerformanceSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportData = ref.watch(reportsProvider);
    final user = ref.watch(authProvider);
    final isCashier = user.isCashier;

    final stats = [
      _StatItem(
        label: 'Penjualan Hari Ini',
        value: 'Rp ${_formatCurrency(reportData.totalRevenue.toInt())}',
        icon: Icons.attach_money,
        iconColor: const Color(0xFF16A34A),
        iconBgColor: const Color(0xFFDCFCE7),
      ),
      _StatItem(
        label: 'Total Transaksi',
        value: '${reportData.totalTransactions}',
        icon: Icons.shopping_bag_outlined,
        iconColor: const Color(0xFF2563EB),
        iconBgColor: const Color(0xFFDBEAFE),
      ),
      if (!isCashier)
        _StatItem(
          label: 'Laba Bersih',
          value: 'Rp ${_formatCurrency(reportData.netProfit.toInt())}',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFF7C3AED),
          iconBgColor: const Color(0xFFEDE9FE),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Performa',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...stats.map((stat) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StatRow(stat: stat),
              )),
        ],
      ),
    );
  }

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class _StatRow extends StatelessWidget {
  final _StatItem stat;
  const _StatRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stat.iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                const SizedBox(height: 2),
                Text(stat.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
