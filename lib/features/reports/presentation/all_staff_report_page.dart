import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../data/report_local_repository.dart';

enum StaffPeriod { today, week, month, year, custom }

enum StaffSort { salesDesc, salesAsc, txDesc, txAsc, shiftDesc, nameAsc }

class AllStaffReportPage extends ConsumerStatefulWidget {
  const AllStaffReportPage({super.key});

  @override
  ConsumerState<AllStaffReportPage> createState() => _AllStaffReportPageState();
}

class _AllStaffReportPageState extends ConsumerState<AllStaffReportPage> {
  StaffPeriod _period = StaffPeriod.month;
  StaffSort _sort = StaffSort.salesDesc;
  DateTimeRange? _customRange;
  String _searchQuery = '';
  bool _isLoading = false;

  StaffReportSummary? _summary;
  List<CashierPerformance> _filteredStaffList = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  String _formatFullDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  (DateTime, DateTime) get _activeDateRange {
    final now = DateTime.now();
    switch (_period) {
      case StaffPeriod.today:
        return (now, now);
      case StaffPeriod.week:
        final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return (start, end);
      case StaffPeriod.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return (start, end);
      case StaffPeriod.year:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31);
        return (start, end);
      case StaffPeriod.custom:
        final start = _customRange?.start ?? now;
        final end = _customRange?.end ?? now;
        return (start, end);
    }
  }

  String get _periodSubtitle {
    final range = _activeDateRange;
    final startStr = _formatFullDate(range.$1);
    final endStr = _formatFullDate(range.$2);

    if (_period == StaffPeriod.today || startStr == endStr) {
      return startStr;
    }
    return '$startStr — $endStr';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(reportRepositoryProvider);
    final storeId = ref.read(activeStoreIdProvider);
    final range = _activeDateRange;

    final summary = await repo.getStaffReportSummary(
      startDate: range.$1,
      endDate: range.$2,
      storeId: storeId,
    );

    if (mounted) {
      setState(() {
        _summary = summary;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    if (_summary == null) return;
    var list = List<CashierPerformance>.from(_summary!.staffList);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.username.toLowerCase().contains(q) ||
            s.role.toLowerCase().contains(q);
      }).toList();
    }

    switch (_sort) {
      case StaffSort.salesDesc:
        list.sort((a, b) => b.totalSales.compareTo(a.totalSales));
        break;
      case StaffSort.salesAsc:
        list.sort((a, b) => a.totalSales.compareTo(b.totalSales));
        break;
      case StaffSort.txDesc:
        list.sort((a, b) => b.totalTransactions.compareTo(a.totalTransactions));
        break;
      case StaffSort.txAsc:
        list.sort((a, b) => a.totalTransactions.compareTo(b.totalTransactions));
        break;
      case StaffSort.shiftDesc:
        list.sort((a, b) => b.totalShifts.compareTo(a.totalShifts));
        break;
      case StaffSort.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    _filteredStaffList = list;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = StaffPeriod.custom;
      });
      _loadData();
    }
  }

  String _formatCurrency(num value) {
    final amount = value.toInt();
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final storeName = settings.storeName.isNotEmpty ? settings.storeName : 'Toko POS';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan Detail SDM & Kasir',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1F2937)),
            ),
            Text(
              '$storeName • $_periodSubtitle',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateBanner(),
              const SizedBox(height: 16),
              _buildMetricCards(),
              const SizedBox(height: 16),
              _buildPeriodChips(),
              const SizedBox(height: 16),
              _buildSearchAndSort(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _buildStaffList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF4F46E5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rentang Periode: $_periodSubtitle',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF3730A3),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'SQLite DB',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    final totalStaff = _summary?.totalStaff ?? 0;
    final activeStaff = _summary?.activeStaffCount ?? 0;
    final totalShifts = _summary?.totalShiftsWorked ?? 0;
    final totalRevenue = _summary?.totalStaffRevenue ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _cardItem('Total Staf', '$totalStaff Staf', 'Terdaftar di toko', Icons.badge_outlined, const Color(0xFF4F46E5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _cardItem('Kasir Aktif', '$activeStaff Orang', 'Pernah transaksi', Icons.verified_user_outlined, const Color(0xFF10B981)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _cardItem('Total Shift', '$totalShifts Shift', 'Penggunaan kasir', Icons.access_time_filled_outlined, const Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _cardItem('Omset SDM', _formatCurrency(totalRevenue), 'Total penjualan kasir', Icons.payments_outlined, const Color(0xFF2563EB)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardItem(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F2937)),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips() {
    final periods = [
      (StaffPeriod.today, 'Hari Ini'),
      (StaffPeriod.week, 'Minggu Ini'),
      (StaffPeriod.month, 'Bulan Ini'),
      (StaffPeriod.year, 'Tahun Ini'),
      (StaffPeriod.custom, _customRange != null ? 'Custom Date' : 'Custom'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final selected = _period == p.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p.$2),
              selected: selected,
              onSelected: (val) {
                if (val) {
                  if (p.$1 == StaffPeriod.custom) {
                    _pickCustomRange();
                  } else {
                    setState(() {
                      _period = p.$1;
                    });
                    _loadData();
                  }
                }
              },
              selectedColor: const Color(0xFF4F46E5),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF374151),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: selected ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              onChanged: (v) {
                setState(() {
                  _searchQuery = v;
                  _applyFiltersAndSort();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Cari nama, username, role...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF6B7280)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StaffSort>(
              value: _sort,
              icon: const Icon(Icons.sort, color: Color(0xFF4F46E5), size: 20),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _sort = val;
                    _applyFiltersAndSort();
                  });
                }
              },
              items: const [
                DropdownMenuItem(value: StaffSort.salesDesc, child: Text('Omset Terbanyak', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: StaffSort.salesAsc, child: Text('Omset Terendah', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: StaffSort.txDesc, child: Text('Trx Terbanyak', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: StaffSort.txAsc, child: Text('Trx Terendah', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: StaffSort.shiftDesc, child: Text('Shift Terbanyak', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: StaffSort.nameAsc, child: Text('Nama (A-Z)', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffList() {
    if (_filteredStaffList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: const [
            Icon(Icons.people_outline, size: 56, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text(
              'Tidak ada data staf ditemukan',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF374151)),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci pencarian atau filter periode',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_filteredStaffList.length, (index) {
        final staff = _filteredStaffList[index];
        final rank = index + 1;
        final initials = staff.name.trim().isNotEmpty
            ? staff.name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
            : 'ST';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFFFEF3C7)
                          : rank == 2
                              ? const Color(0xFFF3F4F6)
                              : rank == 3
                                  ? const Color(0xFFFFEDD5)
                                  : const Color(0xFFF9FAFB),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: rank == 1
                            ? const Color(0xFFF59E0B)
                            : rank == 2
                                ? const Color(0xFF9CA3AF)
                                : rank == 3
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: rank == 1
                              ? const Color(0xFFB45309)
                              : rank == 2
                                  ? const Color(0xFF4B5563)
                                  : rank == 3
                                      ? const Color(0xFFC2410C)
                                      : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                staff.name.isNotEmpty ? staff.name : staff.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF1F2937),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: staff.role.toLowerCase() == 'admin'
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                staff.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: staff.role.toLowerCase() == 'admin'
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${staff.username}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(staff.totalSales),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rata-rata: ${_formatCurrency(staff.averageTransactionValue)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoChip(Icons.access_time_filled_outlined, '${staff.totalShifts} Shift Dijalankan', const Color(0xFFF59E0B)),
                  _infoChip(Icons.shopping_bag_outlined, '${staff.totalTransactions} Transaksi', const Color(0xFF2563EB)),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
        ),
      ],
    );
  }
}
