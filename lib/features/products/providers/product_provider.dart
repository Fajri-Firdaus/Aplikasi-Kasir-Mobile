import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product.dart';

// --- Dummy initial data ---
final _initialProducts = [
  const Product(id: '1', name: 'Nasi Goreng Spesial', price: 25000, category: 'Makanan', imageUrl: 'https://picsum.photos/200', stock: 50),
  const Product(id: '2', name: 'Mie Goreng Seafood', price: 30000, category: 'Makanan', imageUrl: 'https://picsum.photos/201', stock: 30),
  const Product(id: '3', name: 'Es Teh Manis', price: 5000, category: 'Minuman', imageUrl: 'https://picsum.photos/202', stock: 100),
  const Product(id: '4', name: 'Kopi Susu Gula Aren', price: 18000, category: 'Minuman', imageUrl: 'https://picsum.photos/203', stock: 40),
  const Product(id: '5', name: 'Ayam Bakar Madu', price: 35000, category: 'Makanan', imageUrl: 'https://picsum.photos/204', stock: 20),
  const Product(id: '6', name: 'Jus Jeruk', price: 12000, category: 'Minuman', imageUrl: 'https://picsum.photos/205', stock: 25),
];

// NotifierProvider for full CRUD support (required by tests & UI)
final productNotifierProvider = NotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);

// Backward-compat alias so existing UI code still works
final productsProvider = productNotifierProvider;

class ProductNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => List.from(_initialProducts);

  void addProduct(Product product) {
    state = [...state, product];
  }

  void updateProduct(String id, Product updated) {
    state = [
      for (final p in state)
        if (p.id == id) updated else p,
    ];
  }

  void deleteProduct(String id) {
    state = state.where((p) => p.id != id).toList();
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
