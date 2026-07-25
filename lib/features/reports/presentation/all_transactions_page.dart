import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../transactions/data/transaction_local_repository.dart';
import '../providers/transactions_report_provider.dart';
import 'widgets/transaction_detail_modal.dart';

class AllTransactionsPage extends ConsumerStatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  ConsumerState<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends ConsumerState<AllTransactionsPage> {
  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _formatDateShort(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(String isoStr) {
    final parsed = DateTime.tryParse(isoStr);
    if (parsed == null) return isoStr;
    final local = parsed.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dayStr = local.day.toString().padLeft(2, '0');
    final monthStr = months[local.month - 1];
    final yearStr = local.year;
    final hourStr = local.hour.toString().padLeft(2, '0');
    final minStr = local.minute.toString().padLeft(2, '0');
    return '$dayStr $monthStr $yearStr, $hourStr:$minStr';
  }

  Map<String, dynamic> _getPaymentBadge(String method) {
    final m = method.toLowerCase();
    if (m == 'cash' || m == 'tunai') {
      return {'label': 'Tunai', 'icon': Icons.payments_outlined, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)};
    } else if (m == 'qris') {
      return {'label': 'QRIS', 'icon': Icons.qr_code_scanner_outlined, 'color': const Color(0xFF2563EB), 'bg': const Color(0xFFDBEAFE)};
    } else if (m == 'transfer') {
      return {'label': 'Transfer', 'icon': Icons.account_balance_outlined, 'color': const Color(0xFF7C3AED), 'bg': const Color(0xFFEDE9FE)};
    } else {
      return {'label': 'Debit', 'icon': Icons.credit_card_outlined, 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7)};
    }
  }

  Future<void> _handleCustomDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Rentang Tanggal',
    );

    if (picked != null) {
      ref.read(allTransactionsNotifierProvider.notifier).filterBy(
        TransactionFilterPeriod.custom,
        customRange: picked,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(allTransactionsNotifierProvider);
    final repo = ref.watch(transactionRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Seluruh Transaksi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Hari Ini', TransactionFilterPeriod.today, state.period),
                  const SizedBox(width: 8),
                  _filterChip('Minggu Ini', TransactionFilterPeriod.week, state.period),
                  const SizedBox(width: 8),
                  _filterChip('Bulan Ini', TransactionFilterPeriod.month, state.period),
                  const SizedBox(width: 8),
                  _filterChip('Tahun Ini', TransactionFilterPeriod.year, state.period),
                  const SizedBox(width: 8),
                  _customFilterChip(state),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Summary Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Transaksi', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('${state.totalCount} Transaksi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Nominal', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('Rp ${_formatCurrency(state.totalRevenue.toInt())}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFF9CA3AF)),
                            SizedBox(height: 12),
                            Text('Tidak ada transaksi pada periode ini', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        itemCount: state.transactions.length,
                        itemBuilder: (context, index) {
                          final txn = state.transactions[index];
                          final badge = _getPaymentBadge(txn.paymentMethod);
                          final isVoid = txn.status == 'void';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => showTransactionDetailModal(context, txn, repo),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isVoid ? const Color(0xFFFEE2E2) : badge['bg'] as Color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isVoid ? Icons.block : badge['icon'] as IconData,
                                        color: isVoid ? const Color(0xFFDC2626) : badge['color'] as Color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('#TRX-${txn.id.padLeft(4, '0')}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827))),
                                              if (isVoid) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                                  child: const Text('VOID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(_formatTime(txn.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Rp ${_formatCurrency(txn.totalAmount.toInt())}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            color: isVoid ? const Color(0xFF9CA3AF) : const Color(0xFF2563EB),
                                            decoration: isVoid ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badge['bg'] as Color,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(badge['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badge['color'] as Color)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, TransactionFilterPeriod period, TransactionFilterPeriod activePeriod) {
    final active = period == activePeriod;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? Colors.white : const Color(0xFF374151),
      ),
      onSelected: (val) {
        if (val) {
          ref.read(allTransactionsNotifierProvider.notifier).filterBy(period);
        }
      },
    );
  }

  Widget _customFilterChip(AllTransactionsState state) {
    final active = state.period == TransactionFilterPeriod.custom;
    String label = 'Custom';
    if (active && state.customRange != null) {
      label = '${_formatDateShort(state.customRange!.start)} - ${_formatDateShort(state.customRange!.end)}';
    }

    return ChoiceChip(
      avatar: Icon(Icons.date_range, size: 14, color: active ? Colors.white : const Color(0xFF374151)),
      label: Text(label),
      selected: active,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? Colors.white : const Color(0xFF374151),
      ),
      onSelected: (val) {
        _handleCustomDateRange(context);
      },
    );
  }
}
