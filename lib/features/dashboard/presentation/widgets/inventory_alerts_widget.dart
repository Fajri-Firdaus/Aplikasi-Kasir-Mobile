import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reports/providers/reports_provider.dart';
import '../../../reports/data/report_local_repository.dart';
import '../../../auth/providers/auth_provider.dart';

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
        _buildShiftStatusCard(context, ref),
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

  Widget _buildShiftStatusCard(BuildContext context, WidgetRef ref) {
    final activeShiftAsync = ref.watch(activeShiftProvider);

    return activeShiftAsync.when(
      data: (shift) {
        final hasActiveShift = shift != null;

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
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasActiveShift ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasActiveShift ? Icons.check_circle_outline : Icons.access_time, 
                      color: hasActiveShift ? const Color(0xFF16A34A) : const Color(0xFF2563EB), 
                      size: 20
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Shift', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        Text(
                          hasActiveShift 
                              ? 'Shift #${shift.shiftId} (Ke-${shift.shiftNumber}) Aktif (Kasir: ${shift.username})' 
                              : 'Belum ada shift aktif', 
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasActiveShift) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo Laci Kas:', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                    Text(
                      'Rp ${_formatCurrency(shift.expectedDrawerCash.toInt())}', 
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827))
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (hasActiveShift) {
                      _showCloseShiftDialog(context, ref, shift);
                    } else {
                      _showOpenShiftDialog(context, ref);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasActiveShift ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    hasActiveShift ? 'Tutup / Ganti Shift' : 'Mulai Shift', 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Text('Gagal memuat status shift: $err', style: const TextStyle(color: Colors.red, fontSize: 11)),
    );
  }

  void _showOpenShiftDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController startingCashController = TextEditingController(text: '500000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Buka Shift Kasir Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Silakan masukkan saldo awal laci kas (Starting Cash) untuk memulai shift.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Saldo Awal Laci Kas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: startingCashController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final startingCash = double.tryParse(startingCashController.text) ?? 0.0;
              final currentUser = ref.read(currentUserProvider).value;
              final userId = currentUser?.id ?? '1';
              Navigator.pop(ctx);
              try {
                await ref.read(activeShiftProvider.notifier).openNewShift(userId, startingCash);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shift kasir berhasil dibuka.'),
                    backgroundColor: Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membuka shift: $e'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Buka Shift'),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context, WidgetRef ref, ShiftSummary activeShift) {
    final TextEditingController actualCashController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tutup / Ganti Shift Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shift #${activeShift.shiftId} aktif (${activeShift.username}). Masukkan jumlah uang fisik setoran di laci kas.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Jumlah Uang Fisik Setoran di Laci',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: actualCashController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = actualCashController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Silakan masukkan nominal uang fisik setoran.'),
                    backgroundColor: Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              final actualCash = double.tryParse(text);
              if (actualCash == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nominal harus berupa angka.'),
                    backgroundColor: Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              
              // Prompt option
              _promptCloseOptionDialog(context, ref, activeShift, actualCash);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }

  void _promptCloseOptionDialog(BuildContext context, WidgetRef ref, ShiftSummary shift, double actualCash) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Opsi Penutupan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Pilih "Ganti Shift" untuk melakukan handover kasir, atau pilih "Tutup Hari" jika seluruh aktivitas penjualan hari ini telah berakhir.',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final closed = await ref.read(activeShiftProvider.notifier).closeActiveShift(actualCash);
                if (!context.mounted) return;
                if (closed != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Shift #${closed.shiftId} berhasil ditutup. Selisih: Rp ${closed.discrepancy.toInt()}'),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menutup shift: $e'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ganti Shift'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final closed = await ref.read(activeShiftProvider.notifier).closeActiveShift(actualCash);
                if (closed != null) {
                  final todayStr = DateTime.now().toLocal().toString().substring(0, 10);
                  final daily = await ref.read(reportRepositoryProvider).getDailyReportSummary(todayStr);
                  if (!context.mounted) return;
                  if (daily != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tutup Hari Berhasil! Total Penjualan: Rp ${(daily.totalSalesCash + daily.totalSalesNonCash).toInt()}'),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menutup hari: $e'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tutup Hari'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
