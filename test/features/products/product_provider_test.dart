import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_flutter/features/products/providers/product_provider.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('ProductNotifier adds new product', () {
    // ASUMSI: ProductNotifier dan method addProduct sudah ada.
    // Saat ini di kode utama hanya ada FutureProvider sederhana (productsProvider),
    // sehingga pengujian ini diekspektasikan GAGAL / ERROR COMPILATION.
    final container = ProviderContainer();
    final notifier = container.read(productNotifierProvider.notifier);
    
    final newProduct = const Product(id: '99', name: 'Produk Baru', price: 10000, category: 'Lainnya', imageUrl: '', stock: 10);
    notifier.addProduct(newProduct);
    
    final state = container.read(productNotifierProvider);
    expect(state.any((p) => p.id == '99'), true);
  });

  test('ProductNotifier deletes product', () {
    final container = ProviderContainer();
    final notifier = container.read(productNotifierProvider.notifier);
    
    notifier.deleteProduct('1'); // ID 1
    
    final state = container.read(productNotifierProvider);
    expect(state.any((p) => p.id == '1'), false);
  });

  test('ProductNotifier updates product', () {
    final container = ProviderContainer();
    final notifier = container.read(productNotifierProvider.notifier);
    
    final updatedProduct = const Product(id: '1', name: 'Nasi Goreng Super', price: 50000, category: 'Makanan', imageUrl: '', stock: 5);
    notifier.updateProduct('1', updatedProduct);
    
    final state = container.read(productNotifierProvider);
    final product = state.firstWhere((p) => p.id == '1');
    expect(product.name, 'Nasi Goreng Super');
  });
}
