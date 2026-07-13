import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/providers/product_provider.dart';
import '../../products/data/product.dart';
import '../../../core/theme/app_colors.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});
  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _showFilters = false;

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final categories = ['Semua', ...products.map((p) => p.category).toSet().toList()];
    final filtered = products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == 'Semua' || p.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
    final lowStock = products.where((p) => p.stock <= 5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Manajemen Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                            Text('${products.length} produk', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showProductForm(context, null),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _showFilters = !_showFilters),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: _showFilters ? const Color(0xFFDBEAFE) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: _showFilters ? Border.all(color: const Color(0xFF2563EB)) : null,
                          ),
                          child: Icon(Icons.tune, size: 22, color: _showFilters ? const Color(0xFF2563EB) : const Color(0xFF374151)),
                        ),
                      ),
                    ],
                  ),
                  if (_showFilters) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (_, i) {
                          final cat = categories[i];
                          final active = cat == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cat == 'Semua' ? 'Semua' : cat,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF374151)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Low stock alert
            if (lowStock.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${lowStock.length} Produk Stok Menipis', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF9A3412))),
                          const SizedBox(height: 2),
                          Text(lowStock.map((p) => p.name).join(', '),
                              style: const TextStyle(fontSize: 11, color: Color(0xFFEA580C))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Product list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 12),
                          Text(_searchQuery.isNotEmpty ? 'Produk tidak ditemukan' : 'Belum ada produk',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                          const SizedBox(height: 4),
                          Text(_searchQuery.isNotEmpty ? 'Coba kata kunci lain' : 'Mulai tambahkan produk baru',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _showProductForm(context, null),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                              child: const Text('Tambah Produk'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ProductListCard(
                        product: filtered[i],
                        onEdit: () => _showProductForm(context, filtered[i]),
                        onDelete: () => _confirmDelete(context, filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductForm(BuildContext context, Product? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProductFormSheet(product: product, onSave: (p) {
        final notifier = ref.read(productNotifierProvider.notifier);
        if (product == null) { notifier.addProduct(p); } else { notifier.updateProduct(product.id, p); }
        Navigator.pop(context);
      }),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Produk "${product.name}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(productNotifierProvider.notifier).deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// --- Product List Card ---
class _ProductListCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductListCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stock <= 5;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
            child: SizedBox(
              width: 80, height: 80,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Center(child: Icon(Icons.fastfood_outlined, color: Color(0xFF9CA3AF), size: 32)),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (product.sku != null && product.sku!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('SKU: ${product.sku}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(6)),
                      child: Text(product.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLowStock ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Stok: ${product.stock}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isLowStock ? const Color(0xFFDC2626) : const Color(0xFF16A34A))),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Jual: Rp ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                      const SizedBox(width: 8),
                      Text('Beli: Rp ${product.buyPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2563EB)), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)), onPressed: onDelete),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// --- Product Form Bottom Sheet ---
class _ProductFormSheet extends StatefulWidget {
  final Product? product;
  final void Function(Product) onSave;
  const _ProductFormSheet({required this.product, required this.onSave});
  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _buyPriceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _skuCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _buyPriceCtrl = TextEditingController(text: p != null ? p.buyPrice.toStringAsFixed(0) : '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _imageCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _buyPriceCtrl.dispose();
    _stockCtrl.dispose(); _categoryCtrl.dispose(); _imageCtrl.dispose();
    _skuCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _buyPriceCtrl.text.isEmpty || _stockCtrl.text.isEmpty || _categoryCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua field bertanda * wajib diisi')));
      return;
    }
    final p = widget.product;
    widget.onSave(Product(
      id: p?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      buyPrice: double.tryParse(_buyPriceCtrl.text) ?? 0,
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      category: _categoryCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim().isEmpty ? 'https://picsum.photos/200' : _imageCtrl.text.trim(),
      sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            _buildField('Nama Produk *', _nameCtrl, 'cth. Nasi Goreng Spesial'),
            _buildField('Kategori *', _categoryCtrl, 'cth. Makanan'),
            _buildField('SKU (opsional)', _skuCtrl, 'cth. BRG001'),
            _buildField('Harga Beli / Modal *', _buyPriceCtrl, 'cth. 15000', type: TextInputType.number),
            _buildField('Harga Jual *', _priceCtrl, 'cth. 25000', type: TextInputType.number),
            _buildField('Stok *', _stockCtrl, 'cth. 50', type: TextInputType.number),
            _buildField('URL Gambar (opsional)', _imageCtrl, 'https://...'),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(widget.product == null ? 'Simpan Produk' : 'Update Produk',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: type,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true, fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
