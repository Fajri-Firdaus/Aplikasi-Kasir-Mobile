import 'package:flutter/material.dart';
import '../../data/transaction.dart';
import '../../data/transaction_local_repository.dart';
import '../../../customers/data/customer.dart';

String formatReceiptTransactionId(String isoCreatedAt, int dailySequence) {
  final dt = DateTime.tryParse(isoCreatedAt)?.toLocal() ?? DateTime.now();
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');
  final seq = dailySequence.toString().padLeft(3, '0');
  return '$year$month$day$hour$minute$second-$seq';
}

class TransactionReceiptWidget extends StatelessWidget {
  final Transaction transaction;
  final TransactionLocalRepository repo;
  final Customer? customer;
  final int dailySequence;

  const TransactionReceiptWidget({
    super.key,
    required this.transaction,
    required this.repo,
    this.customer,
    this.dailySequence = 1,
  });

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _formatDateTime(String isoStr) {
    final parsed = DateTime.tryParse(isoStr);
    if (parsed == null) return isoStr;
    final local = parsed.toLocal();
    final dayStr = local.day.toString().padLeft(2, '0');
    final monthStr = local.month.toString().padLeft(2, '0');
    final yearStr = local.year;
    final hourStr = local.hour.toString().padLeft(2, '0');
    final minStr = local.minute.toString().padLeft(2, '0');
    final secStr = local.second.toString().padLeft(2, '0');
    return '$dayStr/$monthStr/$yearStr $hourStr:$minStr:$secStr WIB';
  }

  String _getPaymentLabel(String method) {
    final m = method.toLowerCase();
    if (m == 'cash' || m == 'tunai') return 'Tunai';
    if (m == 'qris') return 'QRIS';
    if (m == 'transfer') return 'Transfer Bank';
    return 'Kartu Debit/Kredit';
  }

  @override
  Widget build(BuildContext context) {
    final isVoid = transaction.status == 'void';
    final formattedReceiptId = formatReceiptTransactionId(transaction.createdAt, dailySequence);
    final change = (transaction.cashReceived - transaction.totalAmount).clamp(0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Toko
          const Center(
            child: Text(
              'MOBILE POS',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(height: 2),
          const Center(
            child: Text(
              'STRUK BUKTI PEMBAYARAN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),

          // Detail Tabel Transaksi DB
          _receiptRow('No. Struk', formattedReceiptId, isBoldValue: true),
          const SizedBox(height: 4),
          _receiptRow('ID Shift', 'Shift #${transaction.shiftId}'),
          const SizedBox(height: 4),
          _receiptRow('Waktu', _formatDateTime(transaction.createdAt)),
          const SizedBox(height: 4),
          _receiptRow('Status', isVoid ? 'VOID' : 'SUKSES', valueColor: isVoid ? Colors.red : const Color(0xFF16A34A), isBoldValue: true),
          
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),

          // Customer Info
          FutureBuilder<Customer?>(
            future: customer != null
                ? Future.value(customer)
                : (transaction.customerId != null && transaction.customerId!.isNotEmpty)
                    ? repo.getCustomerById(transaction.customerId!)
                    : Future.value(null),
            builder: (context, snapshot) {
              final cust = snapshot.data;
              final custName = cust != null ? cust.name : 'Umum (Non-Member)';
              final custPhone = cust?.phone;

              return Column(
                children: [
                  _receiptRow('Pelanggan', custName, isBoldValue: cust != null),
                  if (custPhone != null && custPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _receiptRow('No. Telp', custPhone),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),

          // Daftar Items
          const Text('RINCIAN PEMBELIAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF374151), letterSpacing: 0.5)),
          const SizedBox(height: 8),

          FutureBuilder<List<TransactionItemDetail>>(
            future: repo.getTransactionItemDetails(transaction.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Text('Tidak ada detail item', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)));
              }

              return Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                              Text('${item.quantity} x Rp ${_formatCurrency(item.sellPriceAtSale.toInt())}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        Text(
                          'Rp ${_formatCurrency(item.subtotal.toInt())}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),

          // Total & Payment Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL HARGA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
              Text(
                'Rp ${_formatCurrency(transaction.totalAmount.toInt())}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _receiptRow('Metode Pembayaran', _getPaymentLabel(transaction.paymentMethod)),

          if (transaction.paymentMethod.toLowerCase() == 'cash' || transaction.paymentMethod.toLowerCase() == 'tunai') ...[
            const SizedBox(height: 4),
            _receiptRow('Uang Diterima', 'Rp ${_formatCurrency(transaction.cashReceived.toInt())}'),
            const SizedBox(height: 4),
            _receiptRow('Kembalian', 'Rp ${_formatCurrency(change.toInt())}', valueColor: const Color(0xFF16A34A), isBoldValue: true),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Terima kasih atas kunjungan Anda!',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBoldValue ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF111827),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
