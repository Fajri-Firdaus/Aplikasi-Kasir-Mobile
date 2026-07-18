import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reports_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/data/product.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  int _activeTab = 0;
  String _selectedDateLabel = 'Hari Ini';
  bool _showDateFilter = false;
  bool _showExportMenu = false;
  late final PageController _pageController;
  late final ScrollController _tabScrollController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeTab);
    _tabScrollController = ScrollController();
    Future.microtask(() {
      ref.read(reportsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveTab(int index) {
    if (!_tabScrollController.hasClients) return;
    const double tabWidth = 98.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetOffset = (index * tabWidth) - (screenWidth / 2) + (tabWidth / 2);
    final double maxScroll = _tabScrollController.position.maxScrollExtent;
    final double clampedOffset = targetOffset.clamp(0.0, maxScroll);

    _tabScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _updateDateFilter(String opt) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (opt) {
      case 'Hari Ini':
        start = now;
        break;
      case '7 Hari':
        start = now.subtract(const Duration(days: 6));
        break;
      case '30 Hari':
        start = now.subtract(const Duration(days: 29));
        break;
      case 'Bulan Ini':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Tahun Ini':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = now;
    }

    ref.read(reportsProvider.notifier).setFilter(startDate: start, endDate: end);
  }

  static const _dateOptions = ['Hari Ini', '7 Hari', '30 Hari', 'Bulan Ini', 'Tahun Ini'];
  static const _tabs = [
    {'key': 'financial', 'label': 'Keuangan', 'icon': Icons.attach_money},
    {'key': 'product', 'label': 'Produk', 'icon': Icons.inventory_2_outlined},
    {'key': 'inventory', 'label': 'Inventaris', 'icon': Icons.warehouse_outlined},
    {'key': 'staff', 'label': 'SDM', 'icon': Icons.people_outline},
    {'key': 'customer', 'label': 'Pelanggan', 'icon': Icons.person_outline},
    {'key': 'xzreport', 'label': 'X/Z Report', 'icon': Icons.summarize_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final reportData = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() { _showDateFilter = false; _showExportMenu = false; }),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              _buildHeader(reportData),
              _buildTabBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _activeTab = index;
                    });
                    _scrollToActiveTab(index);
                  },
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildFinancialTab(reportData),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildProductTab(reportData),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildInventoryTab(ref.watch(productsProvider)),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildStaffTab(),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildCustomerTab(),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildXZReportTab(reportData),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ReportData reportData) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Laporan & Analitik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                Text('Data per $_selectedDateLabel', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() { _showDateFilter = !_showDateFilter; _showExportMenu = false; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today, size: 13, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Text(_selectedDateLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                const Icon(Icons.keyboard_arrow_down, size: 15, color: Color(0xFF2563EB)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() { _showExportMenu = !_showExportMenu; _showDateFilter = false; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download_outlined, size: 15, color: Color(0xFF374151)),
                SizedBox(width: 4),
                Text('Ekspor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          if (_showDateFilter)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
              ),
              child: Column(
                children: _dateOptions.map((opt) => InkWell(
                  onTap: () {
                    setState(() { _selectedDateLabel = opt; _showDateFilter = false; });
                    _updateDateFilter(opt);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: opt == _selectedDateLabel ? const Color(0xFFDBEAFE) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(opt, style: TextStyle(
                        fontWeight: opt == _selectedDateLabel ? FontWeight.w700 : FontWeight.normal,
                        color: opt == _selectedDateLabel ? const Color(0xFF2563EB) : const Color(0xFF374151),
                        fontSize: 13,
                      ))),
                      if (opt == _selectedDateLabel) const Icon(Icons.check, size: 16, color: Color(0xFF2563EB)),
                    ]),
                  ),
                )).toList(),
              ),
            ),
          if (_showExportMenu)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
              ),
              child: Column(children: [
                _exportOption(Icons.picture_as_pdf, 'Ekspor PDF', const Color(0xFFDC2626), () => _handleExport('PDF')),
                const Divider(height: 1),
                _exportOption(Icons.table_chart_outlined, 'Ekspor Excel/CSV', const Color(0xFF16A34A), () => _handleExport('CSV')),
              ]),
            ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: ListView.builder(
              controller: _tabScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _tabs.length,
              itemBuilder: (_, i) {
                final tab = _tabs[i];
                final active = i == _activeTab;
                return GestureDetector(
                  onTap: () {
                    setState(() => _activeTab = i);
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    _scrollToActiveTab(i);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(tab['icon'] as IconData, size: 14,
                              color: active ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF)),
                          const SizedBox(width: 5),
                          Text(tab['label'] as String, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: active ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                          )),
                        ]),
                        const SizedBox(height: 4),
                        if (active)
                          Container(height: 2, width: 40, decoration: BoxDecoration(
                            color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(1),
                          )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
        ],
      ),
    );
  }

  Widget _exportOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        ]),
      ),
    );
  }

  void _handleExport(String format) {
    setState(() => _showExportMenu = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mengekspor laporan sebagai $format...'), backgroundColor: const Color(0xFF2563EB), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildFinancialTab(ReportData reportData) {
    return Column(children: [
      _sectionTitle('Analisis Keuangan & Pendapatan', Icons.attach_money, const Color(0xFF2563EB)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard('Pendapatan', 'Rp ${_formatCurrency(reportData.totalRevenue.toInt())}', Icons.trending_up, const Color(0xFF16A34A), const Color(0xFFDCFCE7))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Pengeluaran', 'Rp ${_formatCurrency(reportData.totalExpense.toInt())}', Icons.trending_down, const Color(0xFFDC2626), const Color(0xFFFEE2E2))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statCard('Laba Bersih', 'Rp ${_formatCurrency(reportData.netProfit.toInt())}', Icons.account_balance_wallet_outlined, const Color(0xFF2563EB), const Color(0xFFDBEAFE))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Transaksi', '${reportData.totalTransactions}', Icons.receipt_long_outlined, const Color(0xFF7C3AED), const Color(0xFFEDE9FE))),
      ]),
      const SizedBox(height: 16),
      _buildRevenueChart(reportData),
    ]);
  }

  Widget _buildProductTab(ReportData reportData) {
    final top = reportData.topProducts;
    if (top.isEmpty) {
      return Column(children: [
        _sectionTitle('Performa Produk & Menu', Icons.inventory_2_outlined, const Color(0xFF16A34A)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: const Center(
            child: Text('Tidak ada data produk terjual pada periode ini', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ),
        ),
      ]);
    }
    return Column(children: [
      _sectionTitle('Performa Produk & Menu', Icons.inventory_2_outlined, const Color(0xFF16A34A)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(
          children: top.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final colors = [const Color(0xFFFBBF24), const Color(0xFFD1D5DB), const Color(0xFFFB923C), const Color(0xFF93C5FD), const Color(0xFFC4B5FD)];
            final color = colors[i % colors.length];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: i < top.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))) : null),
              child: Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${p.totalSold} terjual', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ])),
                Text('Rp ${_formatCurrency(p.revenue.toInt())}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF2563EB))),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildInventoryTab(List<Product> products) {
    final sortedProducts = [...products]..sort((a, b) => a.stock.compareTo(b.stock));

    if (sortedProducts.isEmpty) {
      return Column(children: [
        _sectionTitle('Inventaris & Stok', Icons.warehouse_outlined, const Color(0xFFF97316)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: const Center(
            child: Text('Tidak ada produk dalam inventaris', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ),
        ),
      ]);
    }

    return Column(children: [
      _sectionTitle('Inventaris & Stok', Icons.warehouse_outlined, const Color(0xFFF97316)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: sortedProducts.asMap().entries.map((e) {
          final i = e.key;
          final product = e.value;
          final stock = product.stock;
          const min = 10;
          
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
          final statusColor = isCritical ? const Color(0xFFDC2626) : isWarning ? const Color(0xFFEA580C) : const Color(0xFF16A34A);
          final statusBg = isCritical ? const Color(0xFFFEE2E2) : isWarning ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: i < sortedProducts.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))) : null),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
                  value: (stock / min).clamp(0.0, 1.0), minHeight: 5,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                )),
                const SizedBox(height: 2),
                Text('$stock / $min unit', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              ])),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ]),
          );
        }).toList()),
      ),
    ]);
  }

  Widget _buildStaffTab() {
    final staff = [
      {'name': 'Budi Santoso', 'role': 'Kasir', 'trx': 28, 'total': 'Rp 1.250.000'},
      {'name': 'Sari Wijaya', 'role': 'Kasir', 'trx': 20, 'total': 'Rp 1.200.000'},
    ];
    return Column(children: [
      _sectionTitle('Kinerja Operasional & SDM', Icons.people_outline, const Color(0xFF4F46E5)),
      const SizedBox(height: 12),
      ...staff.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
                child: Center(child: Text('${s['name']}'.split(' ').map((n) => n[0]).join(), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${s['role']}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${s['trx']} transaksi', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF2563EB))),
              Text('${s['total']}', style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      )),
    ]);
  }

  Widget _buildCustomerTab() {
    return Column(children: [
      _sectionTitle('Insight Pelanggan (CRM)', Icons.person_outline, const Color(0xFFDB2777)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard('Total Pelanggan', '32', Icons.people_outline, const Color(0xFFDB2777), const Color(0xFFFCE7F3))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Pelanggan Baru', '8', Icons.person_add_alt_outlined, const Color(0xFF7C3AED), const Color(0xFFEDE9FE))),
      ]),
      const SizedBox(height: 10),
      _statCard('Rata-rata Nilai Transaksi', 'Rp 51.042', Icons.shopping_bag_outlined, const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
    ]);
  }

  Widget _buildXZReportTab(ReportData reportData) {
    return Column(children: [
      _sectionTitle('Laporan X-Report & Z-Report', Icons.summarize_outlined, const Color(0xFF7C3AED)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
            SizedBox(width: 6),
            Text('X-Report (Shift Aktif)', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          Text('Rp ${_formatCurrency(reportData.totalRevenue.toInt())}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const Text('Total penjualan shift ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Row(children: [
            _xzStat('Transaksi', '${reportData.totalTransactions}'),
            const SizedBox(width: 20),
            _xzStat('Mulai Shift', '08:00'),
            const SizedBox(width: 20),
            _xzStat('Durasi', '6j 30m'),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Cetak X-Report', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF7C3AED), size: 18),
            SizedBox(width: 6),
            Text('Z-Report (Tutup Hari)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          const Text('Hasilkan laporan akhir hari untuk menutup semua shift dan menyimpan data penjualan harian.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Generate Z-Report', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    ]);
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)))),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        ])),
      ]),
    );
  }

  Widget _buildRevenueChart(ReportData reportData) {
    final chartData = reportData.hourlySales;
    final maxVal = chartData.isEmpty 
        ? 1.0 
        : chartData.map((h) => h.totalSales).reduce((a, b) => a > b ? a : b);
    final divisor = maxVal > 0 ? maxVal : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tren Pendapatan Hari Ini', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const Text('Per jam', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        const SizedBox(height: 16),
        SizedBox(height: 80, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(chartData.length, (i) {
          final h = chartData[i];
          final hourLabel = h.hour.split(':').first;
          final isLabelVisible = i % 4 == 3 || i == 0;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Flexible(child: FractionallySizedBox(
                heightFactor: h.totalSales / divisor,
                child: Container(decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                )),
              )),
              const SizedBox(height: 4),
              Text(
                isLabelVisible ? hourLabel : '',
                style: const TextStyle(fontSize: 8, color: Color(0xFF9CA3AF)),
              ),
            ]),
          ));
        }))),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFE5E7EB), height: 1),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Hari Ini', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Text('Rp ${_formatCurrency(reportData.totalRevenue.toInt())}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
        ]),
      ]),
    );
  }

  Widget _xzStat(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
    ]);
  }

  String _formatCurrency(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
