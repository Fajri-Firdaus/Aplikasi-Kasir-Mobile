import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product.dart';
import '../data/product_local_repository.dart';

// NotifierProvider for full CRUD support (required by tests & UI)
final productNotifierProvider = NotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);

// Backward-compat alias so existing UI code still works
final productsProvider = productNotifierProvider;

class ProductNotifier extends Notifier<List<Product>> {
  late final ProductLocalRepository _repository;

  @override
  List<Product> build() {
    _repository = ref.watch(productRepositoryProvider);
    Future.microtask(() => loadProducts());
    return [];
  }

  Future<void> loadProducts() async {
    try {
      final list = await _repository.getAll();
      state = list;
    } catch (e) {
      // Fail silently or handle error in state
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final newProduct = await _repository.create(product);
      state = [...state, newProduct];
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
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.delete(id);
      state = state.where((p) => p.id != id).toList();
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
  }
}
