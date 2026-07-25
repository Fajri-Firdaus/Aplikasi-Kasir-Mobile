import 'package:flutter/material.dart';
import '../../../transactions/data/transaction.dart';
import '../../../transactions/data/transaction_local_repository.dart';
import '../../../customers/data/customer.dart';

void showTransactionDetailModal(BuildContext context, Transaction transaction, TransactionLocalRepository repo) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _TransactionDetailModalContent(transaction: transaction, repo: repo),
  );
}

class _TransactionDetailModalContent extends StatelessWidget {
  final Transaction transaction;
  final TransactionLocalRepository repo;

  const _TransactionDetailModalContent({
    required this.transaction,
    required this.repo,
  });

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _formatDate(String isoStr) {
    final parsed = DateTime.tryParse(isoStr);
    if (parsed == null) return isoStr;
    final local = parsed.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dayStr = local.day.toString().padLeft(2, '0');
    final monthStr = months[local.month - 1];
    final yearStr = local.year;
    final hourStr = local.hour.toString().padLeft(2, '0');
    final minStr = local.minute.toString().padLeft(2, '0');
    return '$dayStr $monthStr $yearStr, $hourStr:$minStr WIB';
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
      return {'label': 'Debit/Kredit', 'icon': Icons.credit_card_outlined, 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVoid = transaction.status == 'void';
    final badge = _getPaymentBadge(transaction.paymentMethod);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaksi #${transaction.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(_formatDate(transaction.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isVoid ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isVoid ? 'VOID' : 'SUKSES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isVoid ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: badge['bg'] as Color, borderRadius: BorderRadius.circular(6)),
                  child: Icon(badge['icon'] as IconData, size: 16, color: badge['color'] as Color),
                ),
                const SizedBox(width: 8),
                Text('Metode: ${badge['label']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badge['color'] as Color)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Customer Info Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: FutureBuilder<Customer?>(
              future: (transaction.customerId != null && transaction.customerId!.isNotEmpty)
                  ? repo.getCustomerById(transaction.customerId!)
                  : Future.value(null),
              builder: (context, snapshot) {
                final customer = snapshot.data;
                final hasCustomer = customer != null;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: hasCustomer ? const Color(0xFFFCE7F3) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        hasCustomer ? Icons.person : Icons.person_outline,
                        size: 16,
                        color: hasCustomer ? const Color(0xFFDB2777) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pelanggan: ${hasCustomer ? customer.name : 'Umum (Non-Member)'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: hasCustomer ? const Color(0xFF111827) : const Color(0xFF6B7280),
                            ),
                          ),
                          if (hasCustomer && customer.phone != null && customer.phone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'No. Telp: ${customer.phone}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('DAFTAR ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF374151), letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Flexible(
            child: FutureBuilder<List<TransactionItemDetail>>(
              future: repo.getTransactionItemDetails(transaction.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Tidak ada rincian item', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF111827))),
                                const SizedBox(height: 2),
                                Text('${item.quantity} x Rp ${_formatCurrency(item.sellPriceAtSale.toInt())}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${_formatCurrency(item.subtotal.toInt())}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
              Text(
                'Rp ${_formatCurrency(transaction.totalAmount.toInt())}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          if (transaction.paymentMethod.toLowerCase() == 'cash' || transaction.paymentMethod.toLowerCase() == 'tunai') ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Uang Diterima', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                Text('Rp ${_formatCurrency(transaction.cashReceived.toInt())}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                Text(
                  'Rp ${_formatCurrency((transaction.cashReceived - transaction.totalAmount).toInt().clamp(0, 999999999))}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: const Color(0xFF374151),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
