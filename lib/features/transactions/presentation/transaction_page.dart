import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/providers/product_provider.dart';
import '../../products/data/product.dart';
import '../providers/cart_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../reports/providers/reports_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../customers/data/customer.dart';
import '../data/cart_item.dart';
import '../data/transaction.dart';
import '../data/transaction_local_repository.dart';
import 'widgets/transaction_receipt_widget.dart';

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
    final activeShiftAsync = ref.watch(activeShiftProvider);

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
        child: activeShiftAsync.when(
          data: (shift) {
            if (shift == null) {
              return _buildNoActiveShiftView();
            }
            return Column(
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
                                onPressed: () => _showPaymentDialog(context, ref, totalAmount, null),
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
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Gagal memuat status shift: $err')),
        ),
      ),
    );
  }

  Widget _buildNoActiveShiftView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock_outlined,
                color: Color(0xFFDC2626),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Shift Belum Dibuka',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Anda harus memulai shift kasir terlebih dahulu sebelum dapat melakukan transaksi penjualan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      builder: (_) => _CartSheet(formatCurrency: _formatCurrency, onCheckout: (total, customer) {
        Navigator.pop(context);
        _showPaymentDialog(context, ref, total, customer);
      }),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, double total, Customer? customer) {
    final cartItems = ref.read(cartProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentSheet(
        total: total,
        customer: customer,
        items: cartItems,
        formatCurrency: _formatCurrency,
        onSuccess: (method, cash) async {
          final paymentMethod = method == 'Tunai' ? 'cash' : (method == 'QRIS' ? 'qris' : 'transfer');
          final cashReceived = method == 'Tunai' ? cash : total;

          try {
            final createdTxn = await ref.read(cartProvider.notifier).checkout(
              paymentMethod: paymentMethod,
              cashReceived: cashReceived,
              customerId: customer?.id,
            );

            if (!context.mounted) return;
            Navigator.pop(context);

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => _ReceiptDialog(
                transaction: createdTxn,
                customer: customer,
                onClose: () {
                  Navigator.pop(dialogContext);
                  context.go('/dashboard');
                },
              ),
            );
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
        },
      ),
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
                    child: product.imageUrl.trim().isEmpty
                        ? Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Center(child: Icon(Icons.fastfood_outlined, color: Color(0xFF9CA3AF), size: 40)),
                          )
                        : Image.network(
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
                          Text('Rp ${_formatCurrency(product.price.toInt())}',
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
class _CartSheet extends ConsumerStatefulWidget {
  final String Function(int) formatCurrency;
  final void Function(double total, Customer? customer) onCheckout;
  const _CartSheet({required this.formatCurrency, required this.onCheckout});

  @override
  ConsumerState<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<_CartSheet> {
  Customer? _selectedCustomer;
  bool _isAddingNew = false;
  String _searchQuery = '';
  final _customerSearchController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  @override
  void dispose() {
    _customerSearchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Widget _buildCustomerSection() {
    final customersAsync = ref.watch(customerProvider);

    if (_isAddingNew) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tambah Pelanggan Baru',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                ),
                TextButton(
                  onPressed: () => setState(() => _isAddingNew = false),
                  child: const Text('Batal', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'Nama Pelanggan',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor HP',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = _customerNameController.text.trim();
                  final phone = _customerPhoneController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama pelanggan harus diisi')),
                    );
                    return;
                  }
                  try {
                    final newCust = await ref.read(customerProvider.notifier).addCustomer(name, phone);
                    setState(() {
                      _selectedCustomer = newCust;
                      _isAddingNew = false;
                      _customerNameController.clear();
                      _customerPhoneController.clear();
                    });
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan pelanggan: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Simpan & Pilih', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pelanggan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Pelanggan Baru', style: TextStyle(fontSize: 12)),
                onPressed: () => setState(() => _isAddingNew = true),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerSearchController,
                  decoration: InputDecoration(
                    hintText: 'Ketik nama / no HP pelanggan...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() {
                              _searchQuery = '';
                              _customerSearchController.clear();
                            }),
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
            ],
          ),
          customersAsync.when(
            data: (customers) {
              final query = _searchQuery.trim().toLowerCase();
              final filteredCustomers = query.isEmpty 
                  ? <Customer>[] 
                  : customers.where((c) {
                      return c.name.toLowerCase().contains(query) ||
                          (c.phone != null && c.phone!.contains(query));
                    }).take(5).toList();

              if (_searchQuery.trim().isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (filteredCustomers.isEmpty)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF2563EB)),
                          title: Text('Pelanggan "$_searchQuery" tidak ditemukan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Tap di sini untuk membuat pelanggan baru', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                          onTap: () {
                            setState(() {
                              _isAddingNew = true;
                              _customerNameController.text = _searchQuery.trim();
                              _searchQuery = '';
                              _customerSearchController.clear();
                            });
                          },
                        )
                      else ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 12, top: 8, bottom: 4),
                          child: Text(
                            'Pilihan Pelanggan Terkait:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                          ),
                        ),
                        ...filteredCustomers.map((c) {
                          final isSelected = _selectedCustomer?.id == c.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCustomer = c;
                                _searchQuery = '';
                                _customerSearchController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                                border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 16,
                                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF111827),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (c.phone != null && c.phone!.isNotEmpty)
                                          Text(
                                            c.phone!,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 18),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                );
              }

              final dropdownItems = <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Pelanggan Umum (Non-Member)', style: TextStyle(fontSize: 13)),
                ),
              ];

              bool foundSelected = _selectedCustomer == null;

              for (final c in customers) {
                if (_selectedCustomer != null && c.id == _selectedCustomer!.id) {
                  foundSelected = true;
                }
                final display = c.phone != null && c.phone!.isNotEmpty ? '${c.name} (${c.phone})' : c.name;
                dropdownItems.add(
                  DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(display, style: const TextStyle(fontSize: 13)),
                  ),
                );
              }

              if (!foundSelected && _selectedCustomer != null) {
                final display = _selectedCustomer!.phone != null && _selectedCustomer!.phone!.isNotEmpty 
                    ? '${_selectedCustomer!.name} (${_selectedCustomer!.phone})' 
                    : _selectedCustomer!.name;
                dropdownItems.add(
                  DropdownMenuItem<String?>(
                    value: _selectedCustomer!.id,
                    child: Text(display, style: const TextStyle(fontSize: 13)),
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedCustomer?.id,
                    hint: const Text('Pilih Pelanggan (Umum)', style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    items: dropdownItems,
                    onChanged: (val) {
                      setState(() {
                        if (val == null) {
                          _selectedCustomer = null;
                        } else {
                          _selectedCustomer = customers.firstWhere(
                            (c) => c.id == val,
                            orElse: () => _selectedCustomer!,
                          );
                        }
                      });
                    },
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (err, st) => Text('Gagal memuat pelanggan: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
          if (_selectedCustomer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pelanggan Terpilih: ${_selectedCustomer!.name}${_selectedCustomer!.phone != null && _selectedCustomer!.phone!.isNotEmpty ? " (${_selectedCustomer!.phone})" : ""}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedCustomer = null),
                    child: const Text(
                      'Ganti',
                      style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
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
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: cartItems.length + 1,
                      itemBuilder: (_, i) {
                        if (i == cartItems.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildCustomerSection(),
                          );
                        }

                        final item = cartItems[i];
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      Text('Rp ${widget.formatCurrency(item.product.price.toInt())}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
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
                                  Text('Rp ${widget.formatCurrency(item.totalPrice.toInt())}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF111827))),
                                ],
                              ),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                          ],
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
                  Text('Rp ${widget.formatCurrency(notifier.totalAmount.toInt())}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                ]),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () => widget.onCheckout(notifier.totalAmount, _selectedCustomer),
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
      ),
    );
  }
}

// --- Payment Bottom Sheet ---
class _PaymentSheet extends StatefulWidget {
  final double total;
  final Customer? customer;
  final List<CartItem> items;
  final String Function(int) formatCurrency;
  final void Function(String method, double cash) onSuccess;

  const _PaymentSheet({
    required this.total,
    this.customer,
    required this.items,
    required this.formatCurrency,
    required this.onSuccess,
  });

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
              const SizedBox(height: 12),
              // Detail Pelanggan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.person_outline, size: 16, color: Color(0xFF4B5563)),
                        SizedBox(width: 6),
                        Text('Detail Pelanggan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF374151))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.customer != null ? widget.customer!.name : 'Pelanggan Umum (Non-Member)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.customer != null ? const Color(0xFFDBEAFE) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.customer != null ? 'Member' : 'Umum',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.customer != null ? const Color(0xFF1D4ED8) : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.customer?.phone != null && widget.customer!.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'No HP: ${widget.customer!.phone}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Detail Orderan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF4B5563)),
                        const SizedBox(width: 6),
                        Text('Detail Orderan (${widget.items.length} item)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF374151))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...widget.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.name} x${item.quantity}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF111827), fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Rp ${widget.formatCurrency(item.totalPrice.toInt())}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
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

String _formatCurrency(int val) {
  return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

// --- Receipt Popup Dialog ---
class _ReceiptDialog extends ConsumerWidget {
  final Transaction transaction;
  final Customer? customer;
  final VoidCallback onClose;

  const _ReceiptDialog({
    required this.transaction,
    this.customer,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(transactionRepositoryProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 36),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 16),

              FutureBuilder<int>(
                future: repo.getDailyTransactionSequence(transaction.id),
                builder: (context, snapshot) {
                  final seq = snapshot.data ?? 1;
                  return TransactionReceiptWidget(
                    transaction: transaction,
                    repo: repo,
                    customer: customer,
                    dailySequence: seq,
                  );
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('Cetak Struk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(children: [Icon(Icons.print, color: Colors.white), SizedBox(width: 8), Text('Mencetak struk ke printer...')]),
                            backgroundColor: Color(0xFF2563EB),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onClose,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
