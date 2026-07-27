import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_local_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';

enum CustomerPeriod { today, week, month, year, custom }

enum CustomerSortOption {
  revenueDesc('Omset Terbanyak'),
  revenueAsc('Omset Terendah'),
  transDesc('Transaksi Terbanyak'),
  transAsc('Transaksi Terendah'),
  avgDesc('Rata-rata Belanja Tinggi'),
  nameAsc('Nama (A-Z)');

  final String label;
  const CustomerSortOption(this.label);
}

class AllCustomersReportPage extends ConsumerStatefulWidget {
  const AllCustomersReportPage({super.key});

  @override
  ConsumerState<AllCustomersReportPage> createState() => _AllCustomersReportPageState();
}

class _AllCustomersReportPageState extends ConsumerState<AllCustomersReportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CustomerPeriod _period = CustomerPeriod.month;
  DateTimeRange? _customRange;
  CustomerSortOption _sortOption = CustomerSortOption.revenueDesc;
  bool _isLoading = false;
  List<TopCustomer> _customers = [];

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

  String _formatFullDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  (DateTime, DateTime) get _activeDateRange {
    final now = DateTime.now();
    switch (_period) {
      case CustomerPeriod.today:
        return (now, now);
      case CustomerPeriod.week:
        final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return (start, end);
      case CustomerPeriod.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return (start, end);
      case CustomerPeriod.year:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31);
        return (start, end);
      case CustomerPeriod.custom:
        final start = _customRange?.start ?? now;
        final end = _customRange?.end ?? now;
        return (start, end);
    }
  }

  String get _periodDateRangeText {
    final range = _activeDateRange;
    final startStr = _formatFullDate(range.$1);
    final endStr = _formatFullDate(range.$2);

    if (_period == CustomerPeriod.today || startStr == endStr) {
      return startStr;
    }
    return '$startStr — $endStr';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(reportRepositoryProvider);
    final storeId = ref.read(activeStoreIdProvider);

    final range = _activeDateRange;

    final data = await repo.getAllCustomersReport(
      startDate: range.$1,
      endDate: range.$2,
      storeId: storeId,
    );

    if (mounted) {
      setState(() {
        _customers = data;
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
      initialDateRange: _customRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFDB2777)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = CustomerPeriod.custom;
      });
      _loadData();
    }
  }

  List<TopCustomer> get _filteredAndSortedCustomers {
    var list = _customers.where((c) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      final nameMatches = c.name.toLowerCase().contains(query);
      final phoneMatches = (c.phone ?? '').toLowerCase().contains(query);
      return nameMatches || phoneMatches;
    }).toList();

    switch (_sortOption) {
      case CustomerSortOption.revenueDesc:
        list.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case CustomerSortOption.revenueAsc:
        list.sort((a, b) => a.totalSpent.compareTo(b.totalSpent));
        break;
      case CustomerSortOption.transDesc:
        list.sort((a, b) => b.totalTransactions.compareTo(a.totalTransactions));
        break;
      case CustomerSortOption.transAsc:
        list.sort((a, b) => a.totalTransactions.compareTo(b.totalTransactions));
        break;
      case CustomerSortOption.avgDesc:
        list.sort((a, b) => b.averageSpent.compareTo(a.averageSpent));
        break;
      case CustomerSortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return list;
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = _filteredAndSortedCustomers;
    final settings = ref.watch(settingsProvider);
    final storeName = settings.storeName.isNotEmpty ? settings.storeName : 'POS Store';

    // Metrics calculation
    final totalCustomersCount = _customers.length;
    final totalTxCount = _customers.fold<int>(0, (sum, c) => sum + c.totalTransactions);
    final totalRevenueSum = _customers.fold<double>(0.0, (sum, c) => sum + c.totalSpent);
    final avgPerTx = totalTxCount > 0 ? totalRevenueSum / totalTxCount : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan Detail Pelanggan',
              style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '$storeName • $_periodDateRangeText',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter Period Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('Hari Ini', CustomerPeriod.today),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Minggu Ini', CustomerPeriod.week),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Bulan Ini', CustomerPeriod.month),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Tahun Ini', CustomerPeriod.year),
                  const SizedBox(width: 8),
                  _buildPeriodChip(
                    _period == CustomerPeriod.custom && _customRange != null
                        ? '${_customRange!.start.day}/${_customRange!.start.month} - ${_customRange!.end.day}/${_customRange!.end.month}'
                        : 'Custom Range',
                    CustomerPeriod.custom,
                    isCustom: true,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Period Banner Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFBCFE8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFDB2777)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rentang Periode: $_periodDateRangeText',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9D174D),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDB2777),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'SQLite DB',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Summary Metric Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Pelanggan',
                            value: '$totalCustomersCount',
                            subtitle: 'Pelanggan Terdaftar',
                            icon: Icons.people_outline,
                            color: const Color(0xFFDB2777),
                            bgColor: const Color(0xFFFCE7F3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Transaksi Pelanggan',
                            value: '$totalTxCount',
                            subtitle: 'Total Transaksi',
                            icon: Icons.shopping_bag_outlined,
                            color: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFEDE9FE),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12, height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Omset Pelanggan',
                            value: 'Rp ${_formatCurrency(totalRevenueSum.toInt())}',
                            subtitle: 'Total Pendapatan',
                            icon: Icons.payments_outlined,
                            color: const Color(0xFF059669),
                            bgColor: const Color(0xFFD1FAE5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Rata-rata Belanja',
                            value: 'Rp ${_formatCurrency(avgPerTx.toInt())}',
                            subtitle: 'Per Transaksi',
                            icon: Icons.analytics_outlined,
                            color: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFDBEAFE),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Controls Header: Search & Sort
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: const InputDecoration(
                                hintText: 'Cari nama atau telepon...',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<CustomerSortOption>(
                              value: _sortOption,
                              icon: const Icon(Icons.sort, size: 20, color: Color(0xFF4B5563)),
                              onChanged: (newVal) {
                                if (newVal != null) {
                                  setState(() => _sortOption = newVal);
                                }
                              },
                              items: CustomerSortOption.values.map((opt) {
                                return DropdownMenuItem(
                                  value: opt,
                                  child: Text(
                                    opt.label,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Customers List Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Pelanggan (${displayedList.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        Text(
                          'Urutan: ${_sortOption.label}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Customers List
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (displayedList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.person_search_outlined, size: 48, color: Color(0xFF9CA3AF)),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada pelanggan ditemukan dengan kata kunci "$_searchQuery"'
                                  : 'Belum ada data pelanggan pada periode ini',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayedList.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (context, index) {
                            final cust = displayedList[index];
                            final rank = index + 1;
                            final isTop3 = rank <= 3;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isTop3 ? const Color(0xFFFCE7F3) : const Color(0xFFF3F4F6),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '#$rank',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isTop3 ? const Color(0xFFDB2777) : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cust.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatCurrency(cust.totalSpent.toInt())}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF6B7280)),
                                        const SizedBox(width: 4),
                                        Text(
                                          (cust.phone != null && cust.phone!.isNotEmpty) ? cust.phone! : 'Tidak ada telepon',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${cust.totalTransactions} Tx  |  Rata: Rp ${_formatCurrency(cust.averageSpent.toInt())}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, CustomerPeriod period, {bool isCustom = false}) {
    final isSelected = _period == period;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF4B5563),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFDB2777),
      backgroundColor: const Color(0xFFF3F4F6),
      onSelected: (selected) {
        if (isCustom) {
          _selectCustomDateRange();
        } else if (selected) {
          setState(() {
            _period = period;
          });
          _loadData();
        }
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
