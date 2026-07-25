import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cart_item.dart';
import '../data/transaction.dart';
import '../data/transaction_local_repository.dart';
import '../../products/data/product.dart';
import '../../products/providers/product_provider.dart';
import '../../reports/providers/reports_provider.dart';
import '../../reports/providers/transactions_report_provider.dart';

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addProduct(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        existingItem.copyWith(quantity: existingItem.quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeProduct(productId);
      return;
    }
    final existingIndex = state.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        existingItem.copyWith(quantity: newQuantity),
        ...state.sublist(existingIndex + 1),
      ];
    }
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (total, item) => total + item.totalPrice);
  }

  Future<Transaction> checkout({
    required String paymentMethod,
    required double cashReceived,
    String? customerId,
  }) async {
    final repository = ref.read(transactionRepositoryProvider);
    final productNotifier = ref.read(productNotifierProvider.notifier);

    // Ensure active shift exists
    final activeShift = await repository.getActiveShift();
    if (activeShift == null) {
      throw Exception('Shift harus dibuka terlebih dahulu sebelum melakukan transaksi.');
    }

    final createdTxn = await repository.checkout(
      shiftId: activeShift.id,
      customerId: customerId,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      cashReceived: cashReceived,
      items: state,
    );

    // Refresh reports data & recent transactions after successful checkout
    ref.read(reportsProvider.notifier).refresh();
    ref.read(activeShiftProvider.notifier).refreshShift();
    ref.invalidate(recentTransactionsProvider);

    // Refresh stocks locally in the productNotifierProvider
    for (final item in state) {
      productNotifier.decrementStock(item.product.id, item.quantity);
    }

    clearCart();
    return createdTxn;
  }
}
