import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_local_repository.dart';

enum PerformancePeriod { today, week, month, year, custom }

class AllProductPerformancePage extends ConsumerStatefulWidget {
  const AllProductPerformancePage({super.key});

  @override
  ConsumerState<AllProductPerformancePage> createState() => _AllProductPerformancePageState();
}

class _AllProductPerformancePageState extends ConsumerState<AllProductPerformancePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PerformancePeriod _period = PerformancePeriod.today;
  DateTimeRange? _customRange;
  bool _isAscending = false;
  bool _isLoading = false;
  List<TopProduct> _products = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(reportRepositoryProvider);
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    switch (_period) {
      case PerformancePeriod.today:
        start = now;
        end = now;
        break;
      case PerformancePeriod.week:
        start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 6));
        break;
      case PerformancePeriod.month:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case PerformancePeriod.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      case PerformancePeriod.custom:
        start = _customRange?.start ?? now;
        end = _customRange?.end ?? now;
        break;
    }

    final data = await repo.getTopProducts(start, end);

    if (mounted) {
      setState(() {
        _products = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = PerformancePeriod.custom;
      });
      _loadData();
    }
  }

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  String _getMonthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    if (month >= 1 && month <= 12) return names[month - 1];
    return '';
  }

  String _getPeriodSubtitle() {
    final now = DateTime.now();
    switch (_period) {
      case PerformancePeriod.today:
        return 'Hari Ini (${_formatDate(now)})';
      case PerformancePeriod.week:
        final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return 'Minggu Ini (${_formatDate(monday)} - ${_formatDate(sunday)})';
      case PerformancePeriod.month:
        return 'Bulan Ini (${_getMonthName(now.month)} ${now.year})';
      case PerformancePeriod.year:
        return 'Tahun Ini (${now.year})';
      case PerformancePeriod.custom:
        if (_customRange != null) {
          return 'Custom (${_formatDate(_customRange!.start)} - ${_formatDate(_customRange!.end)})';
        }
        return 'Rentang Kustom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    filteredProducts.sort((a, b) {
      final cmp = _isAscending
          ? a.totalSold.compareTo(b.totalSold)
          : b.totalSold.compareTo(a.totalSold);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });

    final totalSold = _products.fold<int>(0, (sum, p) => sum + p.totalSold);
    final totalRevenue = _products.fold<double>(0.0, (sum, p) => sum + p.revenue);

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
              'Performa Produk & Menu',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827)),
            ),
            Text(
              _getPeriodSubtitle(),
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter & Search Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPeriodChip('Hari Ini', PerformancePeriod.today),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Minggu Ini', PerformancePeriod.week),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Bulan Ini', PerformancePeriod.month),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Tahun Ini', PerformancePeriod.year),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Color(0xFF374151)),
                              const SizedBox(width: 4),
                              Text(
                                _period == PerformancePeriod.custom && _customRange != null
                                    ? '${_formatDate(_customRange!.start)} - ${_formatDate(_customRange!.end)}'
                                    : 'Custom',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _period == PerformancePeriod.custom ? FontWeight.w800 : FontWeight.w600,
                                  color: _period == PerformancePeriod.custom ? Colors.white : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                          selected: _period == PerformancePeriod.custom,
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: const Color(0xFFF3F4F6),
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onSelected: (_) => _selectCustomDateRange(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Search Bar & Sort Toggle Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Cari produk...',
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
                      ),
                      const SizedBox(width: 10),
                      // Sort Order Button
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _isAscending = !_isAscending),
                        icon: Icon(
                          _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: const Color(0xFF2563EB),
                        ),
                        label: Text(
                          _isAscending ? 'Tersedikit' : 'Terbanyak',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Terjual', style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('$totalSold Item', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Penjualan', style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Rp ${_formatCurrency(totalRevenue.toInt())}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Product Performance List / Loader
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isNotEmpty ? 'Produk tidak ditemukan' : 'Tidak ada data penjualan pada periode ini',
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final p = filteredProducts[i];
                            final rank = _isAscending ? (filteredProducts.length - i) : (i + 1);
                            final colors = [
                              const Color(0xFFFBBF24),
                              const Color(0xFFD1D5DB),
                              const Color(0xFFFB923C),
                              const Color(0xFF93C5FD),
                              const Color(0xFFC4B5FD)
                            ];
                            final badgeColor = colors[i % colors.length];

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
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(
                                        '$rank',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827)),
                                      ),
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
                                        Text(
                                          '${p.totalSold} unit terjual',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatCurrency(p.revenue.toInt())}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF2563EB)),
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

  Widget _buildPeriodChip(String label, PerformancePeriod period) {
    final isSelected = _period == period;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF374151),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF3F4F6),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (selected) {
        if (selected && _period != period) {
          setState(() {
            _period = period;
          });
          _loadData();
        }
      },
    );
  }
}
