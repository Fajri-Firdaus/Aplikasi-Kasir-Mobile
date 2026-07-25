import 'package:flutter/material.dart';
import '../../../transactions/data/transaction.dart';
import '../../../transactions/data/transaction_local_repository.dart';
import '../../../transactions/presentation/widgets/transaction_receipt_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: FutureBuilder<int>(
                future: repo.getDailyTransactionSequence(transaction.id),
                builder: (context, snapshot) {
                  final seq = snapshot.data ?? 1;
                  return TransactionReceiptWidget(
                    transaction: transaction,
                    repo: repo,
                    dailySequence: seq,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
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
