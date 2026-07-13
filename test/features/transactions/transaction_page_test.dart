import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/features/transactions/presentation/transaction_page.dart';
import 'package:mobile_pos_flutter/features/transactions/providers/cart_provider.dart';
import 'package:mobile_pos_flutter/features/products/providers/product_provider.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';

class MockProductNotifier extends ProductNotifier {
  final List<Product> _mockProducts;
  MockProductNotifier(this._mockProducts);

  @override
  List<Product> build() {
    return _mockProducts;
  }

  @override
  Future<void> loadProducts() async {
    // No-op
  }
}

void main() {
  final mockProducts = [
    const Product(
      id: '1',
      name: 'Nasi Goreng',
      price: 20000,
      category: 'Makanan',
      imageUrl: '',
      stock: 10,
      sku: 'MK001',
    ),
  ];

  testWidgets('TransactionPage cart sheet allows incrementing and decrementing items', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productNotifierProvider.overrideWith(() => MockProductNotifier(mockProducts)),
        ],
        child: const MaterialApp(
          home: TransactionPage(),
        ),
      ),
    );

    // Let the products load in the notifier
    await tester.pumpAndSettle();

    // Verify product card is shown
    expect(find.text('Nasi Goreng'), findsOneWidget);

    // Tap product card to add to cart
    await tester.tap(find.text('Nasi Goreng'));
    await tester.pumpAndSettle();

    // Verify footer shows 1 item
    expect(find.text('1 item'), findsOneWidget);

    // Open cart sheet
    await tester.tap(find.text('Keranjang'));
    await tester.pumpAndSettle();

    // Verify item quantity is 1 in cart sheet
    expect(find.text('1'), findsOneWidget);

    // Tap increment (+) button
    final incrementButton = find.byIcon(Icons.add_circle_outline);
    expect(incrementButton, findsOneWidget);
    await tester.tap(incrementButton);
    await tester.pumpAndSettle();

    // Verify item quantity is updated to 2
    expect(find.text('2'), findsOneWidget);

    // Tap decrement (-) button
    final decrementButton = find.byIcon(Icons.remove_circle_outline);
    expect(decrementButton, findsOneWidget);
    await tester.tap(decrementButton);
    await tester.pumpAndSettle();

    // Verify item quantity goes back to 1
    expect(find.text('1'), findsOneWidget);
  });
}
