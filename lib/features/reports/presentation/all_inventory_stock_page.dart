import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/providers/product_provider.dart';

class AllInventoryStockPage extends ConsumerStatefulWidget {
  const AllInventoryStockPage({super.key});

  @override
  ConsumerState<AllInventoryStockPage> createState() => _AllInventoryStockPageState();
}

class _AllInventoryStockPageState extends ConsumerState<AllInventoryStockPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final sortedProducts = [...products]..sort((a, b) => a.stock.compareTo(b.stock));

    final filteredProducts = sortedProducts.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.sku != null && p.sku!.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (!matchesSearch) return false;

      if (_selectedStatus == 'Kritis') return p.stock <= 3;
      if (_selectedStatus == 'Menipis') return p.stock > 3 && p.stock <= 10;
      if (_selectedStatus == 'Aman') return p.stock > 10;

      return true;
    }).toList();

    final criticalCount = products.where((p) => p.stock <= 3).length;
    final warningCount = products.where((p) => p.stock > 3 && p.stock <= 10).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Semua Detail Inventaris & Stok',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827)),
            ),
            Text(
              '${products.length} item terdaftar dalam inventaris',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter & Search Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Search Input
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan nama atau SKU...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6B7280)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Status Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', products.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('Kritis', criticalCount, color: const Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        _buildFilterChip('Menipis', warningCount, color: const Color(0xFFEA580C)),
                        const SizedBox(width: 8),
                        _buildFilterChip('Aman', products.length - criticalCount - warningCount, color: const Color(0xFF16A34A)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Inventory List
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isNotEmpty ? 'Produk tidak ditemukan' : 'Tidak ada produk untuk filter ini',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = filteredProducts[i];
                        final stock = p.stock;

                        final String status;
                        if (stock <= 3) {
                          status = 'Kritis';
                        } else if (stock <= 10) {
                          status = 'Menipis';
                        } else {
                          status = 'Aman';
                        }

                        final isCritical = status == 'Kritis';
                        final isWarning = status == 'Menipis';
                        final statusColor = isCritical
                            ? const Color(0xFFDC2626)
                            : isWarning
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF16A34A);
                        final statusBg = isCritical
                            ? const Color(0xFFFEE2E2)
                            : isWarning
                                ? const Color(0xFFFFEDD5)
                                : const Color(0xFFDCFCE7);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isCritical
                                      ? Icons.warning_amber_rounded
                                      : isWarning
                                          ? Icons.error_outline
                                          : Icons.check_circle_outline,
                                  color: statusColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF111827)),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (p.sku != null && p.sku!.isNotEmpty) ...[
                                          Text(
                                            'SKU: ${p.sku}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                          ),
                                          const Text(' • ', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                                        ],
                                        Text(
                                          p.category,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${p.stock} unit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {Color? color}) {
    final isSelected = _selectedStatus == label;
    final activeColor = color ?? const Color(0xFF2563EB);

    return ChoiceChip(
      label: Text(
        '$label ($count)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF374151),
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: const Color(0xFFF3F4F6),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = label);
        }
      },
    );
  }
}
