import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product.dart';
import '../data/product_local_repository.dart';
import '../../reports/providers/reports_provider.dart';
import '../../auth/providers/auth_provider.dart';

// NotifierProvider for full CRUD support (required by tests & UI)
final productNotifierProvider = NotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);

// Backward-compat alias so existing UI code still works
final productsProvider = productNotifierProvider;

class ProductNotifier extends Notifier<List<Product>> {
  late final ProductLocalRepository _repository;

  @override
  List<Product> build() {
    _repository = ref.watch(productRepositoryProvider);
    final storeId = ref.watch(activeStoreIdProvider);
    Future.microtask(() => loadProducts(storeId: storeId));
    return [];
  }

  Future<void> loadProducts({String? storeId}) async {
    try {
      final activeStoreId = storeId ?? ref.read(activeStoreIdProvider);
      final list = await _repository.getAll(storeId: activeStoreId);
      if (ref.mounted) {
        state = list;
      }
    } catch (e) {
      // Fail silently or handle error in state
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final storeId = ref.read(activeStoreIdProvider);
      final newProduct = await _repository.create(product, storeId: storeId);
      state = [...state, newProduct];
      ref.read(reportsProvider.notifier).refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateProduct(String id, Product updated) async {
    try {
      await _repository.update(id, updated);
      state = [
        for (final p in state)
          if (p.id == id) updated else p,
      ];
      ref.read(reportsProvider.notifier).refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.delete(id);
      state = state.where((p) => p.id != id).toList();
      ref.read(reportsProvider.notifier).refresh();
    } catch (e) {
      // Handle error
    }
  }

  void decrementStock(String id, int quantity) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(stock: (p.stock - quantity).clamp(0, p.stock))
        else
          p,
    ];
    ref.read(reportsProvider.notifier).refresh();
  }
}
