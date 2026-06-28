import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reports/providers/reports_provider.dart';

class InventoryAlertsWidget extends ConsumerWidget {
  const InventoryAlertsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportData = ref.watch(reportsProvider);
    final lowStockItems = reportData.lowStockProducts;

    return Column(
      children: [
        _buildLowStockCard(context, lowStockItems),
        const SizedBox(height: 12),
        _buildShiftStatusCard(context),
      ],
    );
  }

  Widget _buildLowStockCard(BuildContext context, List<dynamic> lowStockItems) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFED7AA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Peringatan Stok Menipis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    Text(
                      lowStockItems.isEmpty 
                        ? 'Stok produk terpantau aman'
                        : '${lowStockItems.length} produk perlu diisi ulang',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lowStockItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...lowStockItems.map((item) {
              final stock = item.stock as int;
              const minStock = 10; // Default min stock alert threshold
              final percentage = stock / minStock;
              final isVeryLow = stock <= 3;
              final borderColor = isVeryLow ? const Color(0xFFEF4444) : const Color(0xFFF97316);
              final bgColor = isVeryLow ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED);
              final badgeBg = isVeryLow ? const Color(0xFFFEE2E2) : const Color(0xFFFFEDD5);
              final badgeText = isVeryLow ? const Color(0xFFB91C1C) : const Color(0xFFC2410C);
              final progressColor = isVeryLow ? const Color(0xFFEF4444) : const Color(0xFFF97316);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(left: BorderSide(color: borderColor, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F2937))),
                                Text(item.category, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '$stock / $minStock',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeText),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Semua stok di atas ambang batas aman.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFEDD5),
                foregroundColor: const Color(0xFFC2410C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Lihat Semua Produk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftStatusCard(BuildContext context) {
    // Static shift card - no active shift by default
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status Shift', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    Text('Belum ada shift aktif', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Mulai Shift', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
