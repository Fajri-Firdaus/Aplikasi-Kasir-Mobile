import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/providers/product_provider.dart';
import '../../products/data/product.dart';
import '../providers/cart_provider.dart';
import '../../../core/theme/app_colors.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});
  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final categories = ['Semua', ...products.map((p) => p.category).toSet().toList()];
    final filtered = products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == 'Semua' || p.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();

    final totalAmount = cartNotifier.totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.point_of_sale, color: Color(0xFF2563EB), size: 22),
                        const SizedBox(width: 8),
                        const Text('Transaksi Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                      ],
                    ),
                  ),
                  if (cartItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showClearCartDialog(context, cartNotifier),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Kosongkan'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
                    ),
                ],
              ),
            ),
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            // Category chips
            Container(
              color: Colors.white,
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final active = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: active,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFFF3F4F6),
                      labelStyle: TextStyle(color: active ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.w600, fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Product grid
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Produk tidak ditemukan', style: TextStyle(color: Color(0xFF6B7280))))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _ProductCard(
                        product: filtered[i],
                        onAdd: () => ref.read(cartProvider.notifier).addProduct(filtered[i]),
                      ),
                    ),
            ),
            // Cart footer
            if (cartItems.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, -4))],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${cartItems.length} item', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        Text(
                          'Total: Rp ${_formatCurrency(totalAmount.toInt())}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showCartSheet(context, ref),
                            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                            label: const Text('Keranjang'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => _showPaymentDialog(context, ref, totalAmount),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Bayar - Rp ${_formatCurrency(totalAmount.toInt())}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  void _showClearCartDialog(BuildContext context, CartNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kosongkan Keranjang?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Semua item di keranjang akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () { notifier.clearCart(); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showCartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CartSheet(formatCurrency: _formatCurrency, onCheckout: (total) {
        Navigator.pop(context);
        _showPaymentDialog(context, ref, total);
      }),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentSheet(total: total, formatCurrency: _formatCurrency, onSuccess: (method, cash) async {
        final paymentMethod = method == 'Tunai' ? 'cash' : (method == 'QRIS' ? 'qris' : 'transfer');
        final cashReceived = method == 'Tunai' ? cash : total;

        try {
          await ref.read(cartProvider.notifier).checkout(
            paymentMethod: paymentMethod,
            cashReceived: cashReceived,
          );

          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Transaksi berhasil!')]),
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/dashboard');
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text('Gagal menyimpan transaksi: $e'))]),
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }),
    );
  }
}

// --- Product Card ---
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  const _ProductCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;
    return GestureDetector(
      onTap: isOutOfStock ? null : onAdd,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(child: Icon(Icons.fastfood_outlined, color: Color(0xFF9CA3AF), size: 40)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rp ${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.stock > 10 ? const Color(0xFFDCFCE7) : product.stock > 0 ? const Color(0xFFFFEDD5) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${product.stock}',
                                style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: product.stock > 10 ? const Color(0xFF16A34A) : product.stock > 0 ? const Color(0xFFEA580C) : const Color(0xFFDC2626),
                                )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isOutOfStock)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            if (isOutOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('Habis', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDC2626)))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Cart Bottom Sheet ---
class _CartSheet extends ConsumerWidget {
  final String Function(int) formatCurrency;
  final void Function(double) onCheckout;
  const _CartSheet({required this.formatCurrency, required this.onCheckout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Keranjang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
                  onPressed: cartItems.isEmpty ? null : () { notifier.clearCart(); Navigator.pop(context); },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.shopping_cart_outlined, size: 60, color: Color(0xFFD1D5DB)),
                    SizedBox(height: 12),
                    Text('Keranjang kosong', style: TextStyle(color: Color(0xFF6B7280))),
                  ]))
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final item = cartItems[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('Rp ${item.product.price.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                              ]),
                            ),
                            Row(children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF2563EB)),
                                onPressed: () => notifier.updateQuantity(item.product.id, item.quantity - 1),
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
                                onPressed: () => notifier.updateQuantity(item.product.id, item.quantity + 1),
                              ),
                            ]),
                            Text('Rp ${formatCurrency(item.totalPrice.toInt())}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF111827))),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (cartItems.isNotEmpty) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, -4))],
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Rp ${formatCurrency(notifier.totalAmount.toInt())}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
              ]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => onCheckout(notifier.totalAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lanjut Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

// --- Payment Bottom Sheet ---
class _PaymentSheet extends StatefulWidget {
  final double total;
  final String Function(int) formatCurrency;
  final void Function(String method, double cash) onSuccess;
  const _PaymentSheet({required this.total, required this.formatCurrency, required this.onSuccess});
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _cashController = TextEditingController();
  double _cashAmount = 0;
  String _selectedMethod = 'Tunai';

  double get _change => (_cashAmount - widget.total).clamp(0, double.infinity);
  bool get _canPay => _selectedMethod != 'Tunai' || _cashAmount >= widget.total;

  @override
  void dispose() { _cashController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total Tagihan', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('Rp ${widget.formatCurrency(widget.total.toInt())}',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ]),
              ),
              const SizedBox(height: 16),
              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: ['Tunai', 'QRIS', 'Transfer'].map((m) {
                final active = m == _selectedMethod;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMethod = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border: active ? null : Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Center(child: Text(m, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: active ? Colors.white : const Color(0xFF374151)))),
                    ),
                  ),
                ),
                );
              }).toList()),
              if (_selectedMethod == 'Tunai') ...[
                const SizedBox(height: 16),
                const Text('Uang Diterima', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => _cashAmount = double.tryParse(v.replaceAll('.', '')) ?? 0),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    filled: true, fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    hintText: '0',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [50000, 100000, 200000].map((v) => ActionChip(
                  label: Text('Rp ${widget.formatCurrency(v)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: () { setState(() { _cashAmount = v.toDouble(); _cashController.text = v.toString(); }); },
                  backgroundColor: const Color(0xFFDBEAFE),
                )).toList()),
                if (_cashAmount >= widget.total) Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                      Text('Rp ${widget.formatCurrency(_change.toInt())}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF16A34A))),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _canPay ? () => widget.onSuccess(_selectedMethod, _cashAmount) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: const Color(0xFFD1D5DB),
                ),
                child: const Text('Konfirmasi Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
