import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/features/transactions/presentation/transaction_page.dart';
import 'package:mobile_pos_flutter/features/transactions/providers/cart_provider.dart';
import 'package:mobile_pos_flutter/features/products/providers/product_provider.dart';
import 'package:mobile_pos_flutter/features/products/data/product.dart';
import 'package:mobile_pos_flutter/features/reports/providers/reports_provider.dart';
import 'package:mobile_pos_flutter/features/reports/data/report_local_repository.dart';
import 'package:mobile_pos_flutter/features/customers/providers/customer_provider.dart';
import 'package:mobile_pos_flutter/features/customers/data/customer.dart';
import 'dart:async';

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

class MockActiveShiftNotifier extends ActiveShiftNotifier {
  final ShiftSummary? _mockShift;
  MockActiveShiftNotifier(this._mockShift);

  @override
  Future<ShiftSummary?> build() async {
    return _mockShift;
  }
}

class MockCustomerNotifier extends CustomerNotifier {
  final List<Customer> _mockCustomers;
  MockCustomerNotifier(this._mockCustomers);

  @override
  FutureOr<List<Customer>> build() async {
    return _mockCustomers;
  }

  @override
  Future<void> refresh() async {
    state = AsyncValue.data(_mockCustomers);
  }

  @override
  Future<Customer> addCustomer(String name, String phone) async {
    final customer = Customer(
      id: (_mockCustomers.length + 1).toString(),
      name: name,
      phone: phone,
      createdAt: DateTime.now().toIso8601String(),
    );
    _mockCustomers.add(customer);
    state = AsyncValue.data(List.from(_mockCustomers));
    return customer;
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

  const mockShift = ShiftSummary(
    shiftId: '1',
    userId: '1',
    username: 'admin',
    startTime: '2026-07-19T00:00:00Z',
    startingCash: 500000.0,
    endingCash: 0.0,
    totalSalesCash: 0.0,
    totalSalesNonCash: 0.0,
    totalSalesVoid: 0.0,
    expectedDrawerCash: 500000.0,
    discrepancy: 0.0,
    totalTransactions: 0,
    status: 'open',
    shiftNumber: 1,
  );

  testWidgets('TransactionPage cart sheet allows incrementing and decrementing items', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productNotifierProvider.overrideWith(() => MockProductNotifier(mockProducts)),
          activeShiftProvider.overrideWith(() => MockActiveShiftNotifier(mockShift)),
          customerProvider.overrideWith(() => MockCustomerNotifier([])),
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
