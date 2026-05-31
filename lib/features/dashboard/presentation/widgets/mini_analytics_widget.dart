import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reports/providers/reports_provider.dart';

class MiniAnalyticsWidget extends ConsumerWidget {
  const MiniAnalyticsWidget({super.key});

  static const _rankColors = [
    Color(0xFFFBBF24), // Rank 1
    Color(0xFFD1D5DB), // Rank 2
    Color(0xFFFB923C), // Rank 3
    Color(0xFF93C5FD), // Rank 4
    Color(0xFFC4B5FD), // Rank 5
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
        _buildTopProductsCard(reportData),
      ],
    );
  }

  Widget _buildSalesTrendCard(ReportData reportData) {
    final hourlySales = reportData.hourlySales;
    
    // Find max sales for scaling the chart, default to 1 to avoid division by zero
    double maxSales = 1.0;
    if (hourlySales.isNotEmpty) {
      final foundMax = hourlySales.map((e) => e.totalSales).reduce((a, b) => a > b ? a : b);
      if (foundMax > 0) maxSales = foundMax;
    }

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
                  Text('Per jam (01:00 - 24:00)', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
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
              children: hourlySales.map((data) {
                final sales = data.totalSales;
                final ratio = sales / maxSales;
                
                // Only show labels for every 3 hours to avoid crowding
                final hourInt = int.tryParse(data.hour.split(':').first) ?? 0;
                final showLabel = hourInt % 4 == 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio.clamp(0.05, 1.0), // Min height so it's visible even with 0 sales
                            child: Container(
                              decoration: BoxDecoration(
                                color: sales > 0 ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(2),
                              )),
                          ),
                        ),
                        if (showLabel) ...[
                          const SizedBox(height: 4),
                          Text(
                            data.hour.split(':').first,
                            style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280)),
                          ),
                        ] else ...[
                          const SizedBox(height: 14), // Spacer to maintain alignment
                        ],
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

  Widget _buildTopProductsCard(ReportData reportData) {
    final topProducts = reportData.topProducts;
    
    if (topProducts.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: Text('Belum ada data penjualan hari ini', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        ),
      );
    }

    final maxSold = topProducts.first.totalSold;

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
          ...topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final sold = product.totalSold;
            final ratio = maxSold > 0 ? (sold / maxSold) : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _rankColors[index % _rankColors.length],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
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
                          product.name,
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

