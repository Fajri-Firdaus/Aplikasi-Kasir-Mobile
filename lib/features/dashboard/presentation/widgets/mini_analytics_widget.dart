import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reports/providers/reports_provider.dart';

class MiniAnalyticsWidget extends ConsumerWidget {
  const MiniAnalyticsWidget({super.key});

  static const _hourlySales = [
    {'hour': '08', 'sales': 450000},
    {'hour': '09', 'sales': 720000},
    {'hour': '10', 'sales': 890000},
    {'hour': '11', 'sales': 1200000},
    {'hour': '12', 'sales': 1850000},
    {'hour': '13', 'sales': 1650000},
    {'hour': '14', 'sales': 980000},
    {'hour': '15', 'sales': 1100000},
    {'hour': '16', 'sales': 1420000},
  ];

  static const _topProducts = [
    {'rank': 1, 'name': 'Nasi Goreng Spesial', 'sold': 48, 'color': Color(0xFFFBBF24)},
    {'rank': 2, 'name': 'Es Teh Manis', 'sold': 42, 'color': Color(0xFFD1D5DB)},
    {'rank': 3, 'name': 'Ayam Bakar', 'sold': 35, 'color': Color(0xFFFB923C)},
    {'rank': 4, 'name': 'Mie Goreng', 'sold': 28, 'color': Color(0xFF93C5FD)},
    {'rank': 5, 'name': 'Kopi Susu', 'sold': 25, 'color': Color(0xFFC4B5FD)},
  ];

  String _formatCurrencyFull(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportData = ref.watch(reportsProvider);

    return Column(
      children: [
        _buildSalesTrendCard(reportData),
        const SizedBox(height: 12),
        _buildTopProductsCard(),
      ],
    );
  }

  Widget _buildSalesTrendCard(ReportData reportData) {
    final maxSales = _hourlySales.map((e) => e['sales'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Tren Penjualan Hari Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  Text('Per jam', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ],
              ),
              const Icon(Icons.trending_up, color: Color(0xFF16A34A), size: 22),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _hourlySales.map((data) {
                final sales = data['sales'] as int;
                final ratio = sales / maxSales;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(4),
                              )),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data['hour']}',
                          style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Hari Ini', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              Text(
                'Rp ${_formatCurrencyFull(reportData.totalRevenue.toInt())}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard() {
    final maxSold = (_topProducts.first['sold'] as int);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Produk Terlaris Hari Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  Text('Top 5 penjualan', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ],
              ),
              const Icon(Icons.emoji_events_outlined, color: Color(0xFFF59E0B), size: 22),
            ],
          ),
          const SizedBox(height: 12),
          ..._topProducts.map((product) {
            final sold = product['sold'] as int;
            final ratio = sold / maxSold;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: product['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${product['rank']}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1F2937)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product['name']}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('$sold terjual', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
