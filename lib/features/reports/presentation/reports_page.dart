import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/reports_provider.dart';
import '../providers/transactions_report_provider.dart';
import '../data/report_local_repository.dart';
import '../../products/providers/product_provider.dart';
import '../../products/data/product.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/data/transaction_local_repository.dart';
import '../../transactions/presentation/widgets/transaction_receipt_widget.dart';
import 'widgets/transaction_detail_modal.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  int _activeTab = 0;
  String _historyMode = 'shift';
  String _selectedCashier = 'Semua Kasir';
  late final PageController _pageController;
  late final ScrollController _tabScrollController;
  late final TextEditingController _startingCashController;
  late final TextEditingController _actualCashController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeTab);
    _tabScrollController = ScrollController();
    _startingCashController = TextEditingController(text: '500000');
    _actualCashController = TextEditingController();
    _notesController = TextEditingController();
    Future.microtask(() {
      ref.read(reportsProvider.notifier).refresh();
      ref.read(activeShiftProvider.notifier).refreshShift();
      ref.read(closedShiftsProvider.notifier).refreshHistory();
      ref.read(dailyReportsProvider.notifier).refreshHistory();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabScrollController.dispose();
    _startingCashController.dispose();
    _actualCashController.dispose();
    _notesController.dispose();
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

  static const _tabs = [
    {'key': 'financial', 'label': 'Keuangan', 'icon': Icons.attach_money},
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
        child: Column(
          children: [
            _buildHeader(),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductTab(reportData),
                        const SizedBox(height: 20),
                        _buildInventoryTab(ref.watch(productsProvider)),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildStaffTab(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildCustomerTab(reportData),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Laporan & Analitik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                Text('Ringkasan data laporan toko dan operasional', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
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

  Widget _buildFinancialTab(ReportData reportData) {
    return Column(children: [
      _sectionTitle('Analisis Keuangan & Pendapatan', Icons.attach_money, const Color(0xFF2563EB)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard('Pendapatan', 'Rp ${_formatCurrency(reportData.totalRevenue.toInt())}', Icons.trending_up, const Color(0xFF16A34A), const Color(0xFFDCFCE7))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('HPP', 'Rp ${_formatCurrency(reportData.totalHpp.toInt())}', Icons.trending_down, const Color(0xFFDC2626), const Color(0xFFFEE2E2))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statCard('Laba Bersih', 'Rp ${_formatCurrency(reportData.netProfit.toInt())}', Icons.account_balance_wallet_outlined, const Color(0xFF2563EB), const Color(0xFFDBEAFE))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Transaksi', '${reportData.totalTransactions}', Icons.receipt_long_outlined, const Color(0xFF7C3AED), const Color(0xFFEDE9FE))),
      ]),
      const SizedBox(height: 16),
      _buildTodayRevenueChart(reportData),
      const SizedBox(height: 14),
      _buildWeeklyRevenueChart(reportData),
      const SizedBox(height: 14),
      _buildMonthlyRevenueChart(reportData),
      const SizedBox(height: 16),
      _buildRecentTransactionsSection(),
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
    final displayedTop = top.take(10).toList();
    return Column(children: [
      _sectionTitle(
        'Performa Produk & Menu',
        Icons.inventory_2_outlined,
        const Color(0xFF16A34A),
        onActionTap: () => context.go('/reports/all-product-performance'),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(
          children: displayedTop.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final colors = [const Color(0xFFFBBF24), const Color(0xFFD1D5DB), const Color(0xFFFB923C), const Color(0xFF93C5FD), const Color(0xFFC4B5FD)];
            final color = colors[i % colors.length];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: i < displayedTop.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))) : null),
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

    final displayedProducts = sortedProducts.take(10).toList();

    return Column(children: [
      _sectionTitle(
        'Inventaris & Stok',
        Icons.warehouse_outlined,
        const Color(0xFFF97316),
        onActionTap: () => context.go('/reports/all-inventory-stock'),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: displayedProducts.asMap().entries.map((e) {
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
            decoration: BoxDecoration(border: i < displayedProducts.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))) : null),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('SKU: ${product.sku ?? '-'} • ${product.category}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
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

  Widget _buildCustomerTab(ReportData reportData) {
    final summary = reportData.customerSummary;
    final totalCust = summary?.totalCustomers ?? 0;
    final totalTx = summary?.totalCustomerTransactions ?? 0;
    final totalRev = summary?.totalCustomerRevenue ?? 0.0;
    final avgVal = summary?.averageTransactionValue ?? 0.0;
    final topCustomers = summary?.topCustomers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Insight Pelanggan (CRM)', Icons.person_outline, const Color(0xFFDB2777)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard('Total Pelanggan Terdaftar', '$totalCust Orang', Icons.people_outline, const Color(0xFFDB2777), const Color(0xFFFCE7F3))),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Transaksi Pelanggan', '$totalTx Transaksi', Icons.shopping_bag_outlined, const Color(0xFF7C3AED), const Color(0xFFEDE9FE))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statCard('Omset dari Pelanggan', 'Rp ${_formatCurrency(totalRev.toInt())}', Icons.payments_outlined, const Color(0xFF059669), const Color(0xFFD1FAE5))),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Rata-rata Nilai Belanja', 'Rp ${_formatCurrency(avgVal.toInt())}', Icons.analytics_outlined, const Color(0xFF2563EB), const Color(0xFFDBEAFE))),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('10 Pelanggan Teratas (Top Buyers)', Icons.star_outline, const Color(0xFFD97706)),
        const SizedBox(height: 12),
        if (topCustomers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              children: [
                Icon(Icons.person_search_outlined, size: 48, color: Color(0xFF9CA3AF)),
                SizedBox(height: 8),
                Text(
                  'Belum ada transaksi pelanggan terdaftar pada periode ini',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: topCustomers.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final cust = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: idx <= 3 ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '#$idx',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: idx <= 3 ? const Color(0xFFD97706) : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cust.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                                ),
                                if (cust.phone != null && cust.phone!.isNotEmpty)
                                  Text(
                                    cust.phone!,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rp ${_formatCurrency(cust.totalSpent.toInt())}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF2563EB)),
                              ),
                              Text(
                                '${cust.totalTransactions} Transaksi',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (idx < topCustomers.length) const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildXZReportTab(ReportData reportData) {
    final activeShiftAsync = ref.watch(activeShiftProvider);
    final closedShiftsAsync = ref.watch(closedShiftsProvider);
    final dailyReportsAsync = ref.watch(dailyReportsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        activeShiftAsync.when(
          data: (shift) {
            if (shift == null) {
              return _buildNoActiveShiftView();
            }
            return _buildActiveShiftView(shift);
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Terjadi kesalahan: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _sectionTitle('Riwayat Laporan', Icons.history, const Color(0xFF4B5563))),
            DropdownButton<String>(
              value: _historyMode,
              items: const [
                DropdownMenuItem(value: 'shift', child: Text('Berdasarkan Shift', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'day', child: Text('Berdasarkan Hari', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'cashier', child: Text('Berdasarkan Nama Kasir', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _historyMode = val;
                  });
                }
              },
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 16),
            ),
          ],
        ),
        if (_historyMode == 'cashier') ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pilih Kasir:', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.bold)),
              closedShiftsAsync.when(
                data: (shifts) {
                  final uniqueCashiers = ['Semua Kasir'];
                  for (final s in shifts) {
                    if (!uniqueCashiers.contains(s.username)) {
                      uniqueCashiers.add(s.username);
                    }
                  }
                  if (!uniqueCashiers.contains(_selectedCashier)) {
                    _selectedCashier = 'Semua Kasir';
                  }
                  return DropdownButton<String>(
                    value: _selectedCashier,
                    items: uniqueCashiers.map((name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCashier = val;
                        });
                      }
                    },
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  );
                },
                loading: () => const SizedBox(),
                error: (e, s) => const SizedBox(),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _historyMode == 'shift' || _historyMode == 'cashier'
            ? closedShiftsAsync.when(
                data: (shifts) {
                  final filteredShifts = _historyMode == 'cashier' && _selectedCashier != 'Semua Kasir'
                      ? shifts.where((s) => s.username == _selectedCashier).toList()
                      : shifts;

                  if (filteredShifts.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Center(
                        child: Text(
                          _historyMode == 'cashier' && _selectedCashier != 'Semua Kasir'
                              ? 'Belum ada riwayat shift untuk kasir $_selectedCashier'
                              : 'Belum ada riwayat shift yang ditutup',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filteredShifts.map((s) {
                      DateTime? parsedEnd = DateTime.tryParse(s.endTime ?? '');
                      if (parsedEnd != null) {
                        if (!parsedEnd.isUtc) parsedEnd = DateTime.parse('${s.endTime!}Z');
                        parsedEnd = parsedEnd.toLocal();
                      }
                      final endStr = parsedEnd != null 
                          ? "${parsedEnd.day.toString().padLeft(2, '0')}/${parsedEnd.month.toString().padLeft(2, '0')}/${parsedEnd.year} ${parsedEnd.hour.toString().padLeft(2, '0')}:${parsedEnd.minute.toString().padLeft(2, '0')}"
                          : "-";
                      final dateOnlyStr = parsedEnd != null 
                          ? "${parsedEnd.day.toString().padLeft(2, '0')}/${parsedEnd.month.toString().padLeft(2, '0')}/${parsedEnd.year}"
                          : "-";

                      final totalSales = s.totalSalesCash + s.totalSalesNonCash;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF4B5563)),
                          ),
                          title: Text(
                            '$dateOnlyStr - Shift Ke-${s.shiftNumber} - ${s.username}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Ditutup: $endStr\nTotal Penjualan: Rp ${_formatCurrency(totalSales.toInt())}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.print_outlined, color: Color(0xFF4B5563)),
                            onPressed: () => _showPrintPreviewDialog(s, isZReport: true),
                            tooltip: 'Cetak Z-Report',
                          ),
                          onTap: () => _showPrintPreviewDialog(s, isZReport: true),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Text(
                  'Gagal memuat riwayat: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
            : dailyReportsAsync.when(
                data: (reports) {
                  if (reports.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Text(
                          'Belum ada riwayat harian yang ditutup',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: reports.map((d) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.date_range_outlined, color: Color(0xFF3B82F6)),
                          ),
                          title: Text(
                            'Z-Report Tanggal: ${d.date}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Total Shift: ${d.totalShiftsCount} | Trx: ${d.totalTransactions}\nSales: Rp ${_formatCurrency((d.totalSalesCash + d.totalSalesNonCash).toInt())}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.print_outlined, color: Color(0xFF3B82F6)),
                            onPressed: () => _showDailyPrintPreviewDialog(d),
                            tooltip: 'Cetak Z-Report Harian',
                          ),
                          onTap: () => _showDailyPrintPreviewDialog(d),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Text(
                  'Gagal memuat riwayat harian: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
      ],
    );
  }

  Widget _buildNoActiveShiftView() {
    return Column(
      children: [
        _sectionTitle('Laporan X-Report & Z-Report', Icons.summarize_outlined, const Color(0xFF7C3AED)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: Color(0xFFF3E8FF), shape: BoxShape.circle),
                child: const Icon(Icons.storefront_outlined, color: Color(0xFF7C3AED), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Shift Kasir Belum Aktif',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan buka shift kasir baru terlebih dahulu untuk mulai mencatat transaksi dan mengaudit saldo laci kas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saldo Awal Laci Kas (Starting Cash)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _startingCashController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final startingCash = double.tryParse(_startingCashController.text) ?? 0.0;
                    final currentUser = ref.read(currentUserProvider).value;
                    final userId = currentUser?.id ?? '1';
                    
                    try {
                      await ref.read(activeShiftProvider.notifier).openNewShift(userId, startingCash);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Shift kasir berhasil dibuka.'),
                          backgroundColor: Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal membuka shift: $e'),
                          backgroundColor: const Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Buka Shift Kasir', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Atau cetak Z-Report hari ini jika semua shift telah selesai:', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final todayDateStr = DateTime.now().toLocal().toString().substring(0, 10);
                    final dailySummary = await ref.read(reportRepositoryProvider).getDailyReportSummary(todayDateStr);
                    if (!mounted) return;
                    if (dailySummary != null) {
                      _showDailyPrintPreviewDialog(dailySummary);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Belum ada data shift untuk hari ini.'),
                          backgroundColor: Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.summarize_outlined, size: 14),
                  label: const Text('Cetak Z-Report Hari Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveShiftView(ShiftSummary shift) {
    DateTime? parsedStart = DateTime.tryParse(shift.startTime);
    if (parsedStart != null) {
      if (!parsedStart.isUtc) {
        parsedStart = DateTime.parse('${shift.startTime}Z');
      }
      parsedStart = parsedStart.toLocal();
    }
    final startStr = parsedStart != null 
        ? "${parsedStart.day.toString().padLeft(2, '0')}/${parsedStart.month.toString().padLeft(2, '0')} ${parsedStart.hour.toString().padLeft(2, '0')}:${parsedStart.minute.toString().padLeft(2, '0')}"
        : "-";

    final duration = parsedStart != null ? DateTime.now().difference(parsedStart) : Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationStr = "${hours}j ${minutes}m";

    return Column(
      children: [
        _sectionTitle('Laporan X-Report & Z-Report', Icons.summarize_outlined, const Color(0xFF7C3AED)),
        const SizedBox(height: 12),
        // Active Shift Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text('SHIFT #${shift.shiftId} (Ke-${shift.shiftNumber}) AKTIF', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text('Kasir: ${shift.username}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Rp ${_formatCurrency(shift.expectedDrawerCash.toInt())}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const Text('Ekspektasi Uang Tunai di Laci', style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _xzStat('Mulai', startStr),
                  _xzStat('Durasi', durationStr),
                  _xzStat('Transaksi', '${shift.totalTransactions}'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showPrintPreviewDialog(shift, isZReport: false),
                  icon: const Icon(Icons.print_outlined, size: 16, color: Colors.white),
                  label: const Text('Cetak / Review X-Report', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x80FFFFFF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Shift Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detail Kas Shift Ini', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 12),
              _rowDetail('Saldo Awal (Starting Cash)', 'Rp ${_formatCurrency(shift.startingCash.toInt())}'),
              _rowDetail('Penjualan Tunai', 'Rp ${_formatCurrency(shift.totalSalesCash.toInt())}'),
              _rowDetail('Penjualan Non-Tunai', 'Rp ${_formatCurrency(shift.totalSalesNonCash.toInt())}'),
              _rowDetail('Total Penjualan Kotor', 'Rp ${_formatCurrency((shift.totalSalesCash + shift.totalSalesNonCash).toInt())}', isBold: true),
              _rowDetail('Void / Pembatalan', 'Rp ${_formatCurrency(shift.totalSalesVoid.toInt())}', color: const Color(0xFFDC2626)),
              const Divider(),
              _rowDetail('Ekspektasi Uang Tunai Laci', 'Rp ${_formatCurrency(shift.expectedDrawerCash.toInt())}', isBold: true, color: const Color(0xFF2563EB)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Z-Report / Handover Form Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 6),
                  Text('Tutup Shift / Ganti Shift', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan total uang fisik laci untuk mencatat setoran sebelum berpindah shift atau menutup hari (Z-Report).',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Jumlah Uang Fisik Setoran di Laci',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _actualCashController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: 'Masukkan jumlah uang setoran',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleCloseShift(shift, isDailyZReport: false),
                        icon: const Icon(Icons.sync_alt, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        label: const Text('Ganti Shift', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleCloseShift(shift, isDailyZReport: true),
                        icon: const Icon(Icons.summarize_outlined, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        label: const Text('Tutup Hari', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowDetail(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: const Color(0xFF4B5563), fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12, color: color ?? const Color(0xFF111827), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleCloseShift(ShiftSummary shift, {required bool isDailyZReport}) {
    final text = _actualCashController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan jumlah uang fisik setoran.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final actualCash = double.tryParse(text);
    if (actualCash == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah uang setoran harus berupa angka.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDailyZReport ? 'Tutup Hari (Z-Report)?' : 'Berganti Shift?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(isDailyZReport 
            ? 'Anda akan menutup shift kasir saat ini sekaligus mengkonsolidasikan seluruh shift hari ini untuk mencetak Z-Report Harian.'
            : 'Anda akan menutup shift kasir aktif saat ini (Shift Handover). Kasir berikutnya dapat membuka shift baru.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation dialog
              
              try {
                final closedSummary = await ref.read(activeShiftProvider.notifier).closeActiveShift(actualCash);
                if (!mounted) return;
                _actualCashController.clear();
                
                if (closedSummary != null) {
                  if (isDailyZReport) {
                    final todayStr = DateTime.now().toLocal().toString().substring(0, 10);
                    final dailySummary = await ref.read(reportRepositoryProvider).getDailyReportSummary(todayStr);
                    if (dailySummary != null) {
                      _showDailyReportSuccessDialog(dailySummary);
                    }
                  } else {
                    _showCloseShiftSuccessDialog(closedSummary);
                  }
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menutup shift: $e'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDailyZReport ? const Color(0xFFEF4444) : const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: Text(isDailyZReport ? 'Tutup Hari' : 'Ganti Shift'),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftSuccessDialog(ShiftSummary closedShift) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final discrepancy = closedShift.discrepancy;
        final isMatch = discrepancy == 0;
        final isShortage = discrepancy < 0;
        
        final discrepancyColor = isMatch 
            ? const Color(0xFF16A34A) 
            : isShortage ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
            
        final discrepancyLabel = isMatch
            ? 'Sesuai'
            : isShortage ? 'Kekurangan (Shortage)' : 'Kelebihan (Over)';

        final sign = discrepancy > 0 ? "+" : "";

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Shift Berhasil Ditutup!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Berikut ringkasan Z-Report penutupan shift kasir:', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              _rowDetail('Shift Ke', '${closedShift.shiftNumber}'),
              _rowDetail('Total Penjualan', 'Rp ${_formatCurrency((closedShift.totalSalesCash + closedShift.totalSalesNonCash).toInt())}'),
              _rowDetail('Ekspektasi Uang Laci', 'Rp ${_formatCurrency(closedShift.expectedDrawerCash.toInt())}'),
              _rowDetail('Uang Fisik Aktual', 'Rp ${_formatCurrency(closedShift.endingCash.toInt())}'),
              const Divider(),
              _rowDetail(
                discrepancyLabel,
                'Rp $sign${_formatCurrency(discrepancy.toInt())}',
                isBold: true,
                color: discrepancyColor,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showPrintPreviewDialog(closedShift, isZReport: true);
              },
              icon: const Icon(Icons.print, size: 16),
              label: const Text('Cetak Z-Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Selesai'),
            ),
          ],
        );
      },
    );
  }

  void _showDailyReportSuccessDialog(DailyReportSummary dailyReport) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final discrepancy = dailyReport.totalDiscrepancy;
        final isMatch = discrepancy == 0;
        final isShortage = discrepancy < 0;
        
        final discrepancyColor = isMatch 
            ? const Color(0xFF16A34A) 
            : isShortage ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
            
        final discrepancyLabel = isMatch
            ? 'Sesuai'
            : isShortage ? 'Kekurangan (Shortage)' : 'Kelebihan (Over)';

        final sign = discrepancy > 0 ? "+" : "";

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Tutup Hari Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Z-Report Harian konsolidasi untuk tanggal ${dailyReport.date}:', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              _rowDetail('Total Shift', '${dailyReport.totalShiftsCount}'),
              _rowDetail('Total Penjualan', 'Rp ${_formatCurrency((dailyReport.totalSalesCash + dailyReport.totalSalesNonCash).toInt())}'),
              _rowDetail('Ekspektasi Uang Laci', 'Rp ${_formatCurrency(dailyReport.totalExpectedCash.toInt())}'),
              _rowDetail('Uang Fisik Aktual', 'Rp ${_formatCurrency(dailyReport.totalEndingCash.toInt())}'),
              const Divider(),
              _rowDetail(
                discrepancyLabel,
                'Rp $sign${_formatCurrency(discrepancy.toInt())}',
                isBold: true,
                color: discrepancyColor,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showDailyPrintPreviewDialog(dailyReport);
              },
              icon: const Icon(Icons.print, size: 16),
              label: const Text('Cetak Z-Report Harian'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Selesai'),
            ),
          ],
        );
      },
    );
  }

  void _showReceiptPreviewDialog(String title, String receiptText) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt, color: Colors.grey, size: 28),
                    const SizedBox(height: 10),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        receiptText,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          height: 1.3,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Laporan berhasil dicetak ke printer.'),
                          backgroundColor: Color(0xFF2563EB),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Cetak Struk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrintPreviewDialog(ShiftSummary shift, {required bool isZReport}) {
    final title = isZReport ? 'Pratinjau Struk Z-Report' : 'Pratinjau Struk X-Report';
    final receipt = _generateReceiptText(shift, isZReport);
    _showReceiptPreviewDialog(title, receipt);
  }

  void _showDailyPrintPreviewDialog(DailyReportSummary summary) {
    final receipt = _generateDailyReceiptText(summary);
    _showReceiptPreviewDialog('Pratinjau Struk Z-Report Harian', receipt);
  }

  String _generateReceiptText(ShiftSummary shift, bool isZReport) {
    DateTime? parsedStart = DateTime.tryParse(shift.startTime);
    if (parsedStart != null) {
      if (!parsedStart.isUtc) parsedStart = DateTime.parse('${shift.startTime}Z');
      parsedStart = parsedStart.toLocal();
    }
    final startStr = parsedStart != null 
        ? "${parsedStart.day}/${parsedStart.month}/${parsedStart.year} ${parsedStart.hour.toString().padLeft(2, '0')}:${parsedStart.minute.toString().padLeft(2, '0')}"
        : "-";

    String endStr = "-";
    if (shift.endTime != null) {
      DateTime? parsedEnd = DateTime.tryParse(shift.endTime!);
      if (parsedEnd != null) {
        if (!parsedEnd.isUtc) parsedEnd = DateTime.parse('${shift.endTime!}Z');
        parsedEnd = parsedEnd.toLocal();
      }
      endStr = parsedEnd != null 
          ? "${parsedEnd.day}/${parsedEnd.month}/${parsedEnd.year} ${parsedEnd.hour.toString().padLeft(2, '0')}:${parsedEnd.minute.toString().padLeft(2, '0')}"
          : "-";
    }

    final totalSales = shift.totalSalesCash + shift.totalSalesNonCash;

    final buffer = StringBuffer();
    buffer.writeln("================================");
    buffer.writeln("       MOBILE POS SYSTEM        ");
    buffer.writeln("      Jl. Merdeka No. 123       ");
    buffer.writeln("         08123456789            ");
    buffer.writeln("================================");
    buffer.writeln("          ${isZReport ? 'Z-REPORT (SHIFT CLOSE)' : 'X-REPORT (MID)'}");
    buffer.writeln("--------------------------------");
    buffer.writeln("Shift ID    : #${shift.shiftId} (Shift Ke-${shift.shiftNumber})");
    buffer.writeln("Kasir       : ${shift.username}");
    buffer.writeln("Waktu Mulai : $startStr");
    if (isZReport) {
      buffer.writeln("Waktu Tutup : $endStr");
    }
    buffer.writeln("Status      : ${shift.status.toUpperCase()}");
    buffer.writeln("--------------------------------");
    buffer.writeln("Saldo Awal  : Rp ${_formatCurrency(shift.startingCash.toInt())}");
    buffer.writeln("Sales Cash  : Rp ${_formatCurrency(shift.totalSalesCash.toInt())}");
    buffer.writeln("Sales QRIS  : Rp ${_formatCurrency(shift.totalSalesNonCash.toInt())}");
    buffer.writeln("Total Sales : Rp ${_formatCurrency(totalSales.toInt())}");
    buffer.writeln("Void Txns   : Rp ${_formatCurrency(shift.totalSalesVoid.toInt())}");
    buffer.writeln("Total Trx   : ${shift.totalTransactions}");
    buffer.writeln("--------------------------------");
    buffer.writeln("Expected    : Rp ${_formatCurrency(shift.expectedDrawerCash.toInt())}");
    if (isZReport) {
      buffer.writeln("Actual Cash : Rp ${_formatCurrency(shift.endingCash.toInt())}");
      final prefix = shift.discrepancy >= 0 ? "+" : "";
      buffer.writeln("Selisih     : Rp $prefix${_formatCurrency(shift.discrepancy.toInt())}");
    }
    buffer.writeln("================================");
    buffer.writeln("        BUKTI AUDIT KAS        ");
    buffer.writeln("    ${DateTime.now().toLocal().toString().substring(0, 16)}    ");
    buffer.writeln("================================");
    return buffer.toString();
  }

  String _generateDailyReceiptText(DailyReportSummary summary) {
    final buffer = StringBuffer();
    buffer.writeln("================================");
    buffer.writeln("       MOBILE POS SYSTEM        ");
    buffer.writeln("      Jl. Merdeka No. 123       ");
    buffer.writeln("         08123456789            ");
    buffer.writeln("================================");
    buffer.writeln("        DAILY Z-REPORT          ");
    buffer.writeln("--------------------------------");
    buffer.writeln("Tanggal     : ${summary.date}");
    buffer.writeln("Total Shift : ${summary.totalShiftsCount}");
    buffer.writeln("--------------------------------");
    buffer.writeln("Total Modal : Rp ${_formatCurrency(summary.totalStartingCash.toInt())}");
    buffer.writeln("Sales Cash  : Rp ${_formatCurrency(summary.totalSalesCash.toInt())}");
    buffer.writeln("Sales QRIS  : Rp ${_formatCurrency(summary.totalSalesNonCash.toInt())}");
    buffer.writeln("Total Sales : Rp ${_formatCurrency((summary.totalSalesCash + summary.totalSalesNonCash).toInt())}");
    buffer.writeln("Void Txns   : Rp ${_formatCurrency(summary.totalSalesVoid.toInt())}");
    buffer.writeln("Total Trx   : ${summary.totalTransactions}");
    buffer.writeln("--------------------------------");
    buffer.writeln("Expected    : Rp ${_formatCurrency(summary.totalExpectedCash.toInt())}");
    buffer.writeln("Actual Cash : Rp ${_formatCurrency(summary.totalEndingCash.toInt())}");
    final prefix = summary.totalDiscrepancy >= 0 ? "+" : "";
    buffer.writeln("Selisih     : Rp $prefix${_formatCurrency(summary.totalDiscrepancy.toInt())}");
    buffer.writeln("================================");
    buffer.writeln("       TUTUP HARI BERHASIL      ");
    buffer.writeln("    ${DateTime.now().toLocal().toString().substring(0, 16)}    ");
    buffer.writeln("================================");
    return buffer.toString();
  }

  Widget _sectionTitle(String title, IconData icon, Color color, {VoidCallback? onActionTap, String? actionLabel}) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)))),
      if (onActionTap != null)
        InkWell(
          onTap: onActionTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                Text(
                  actionLabel ?? 'Lihat Semua',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        ),
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

  String _formatDateShort(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateFull(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  Widget _buildTodayRevenueChart(ReportData reportData) {
    final now = DateTime.now();
    final chartData = reportData.hourlySales;
    final maxVal = chartData.isEmpty 
        ? 1.0 
        : chartData.map((h) => h.totalSales).reduce((a, b) => a > b ? a : b);
    final divisor = maxVal > 0 ? maxVal : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tren Pendapatan Hari Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(_formatDateFull(now), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(6)),
              child: const Text('Per Jam', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(chartData.length, (i) {
              final h = chartData[i];
              final hourLabel = h.hour.split(':').first;
              final isLabelVisible = i % 4 == 3 || i == 0;
              final heightFactor = (h.totalSales / divisor).clamp(0.0, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: heightFactor == 0 ? 0.04 : heightFactor,
                            child: Container(
                              decoration: BoxDecoration(
                                color: heightFactor == 0 ? const Color(0xFFE5E7EB) : const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLabelVisible ? hourLabel : '',
                        style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFF3F4F6), height: 1),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Pendapatan Hari Ini', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
            Text('Rp ${_formatCurrency(reportData.totalRevenue.toInt())}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
          ],
        ),
      ]),
    );
  }

  Widget _buildWeeklyRevenueChart(ReportData reportData) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final chartData = reportData.weeklyDailySales;
    final maxVal = chartData.isEmpty
        ? 1.0
        : chartData.map((d) => d.totalSales).reduce((a, b) => a > b ? a : b);
    final divisor = maxVal > 0 ? maxVal : 1.0;

    final dateRangeStr = '${_formatDateShort(monday)} - ${_formatDateShort(sunday)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tren Pendapatan Minggu Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 12, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text('Senin - Minggu ($dateRangeStr)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(6)),
              child: const Text('Per Hari', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(chartData.length, (i) {
              final d = chartData[i];
              final heightFactor = (d.totalSales / divisor).clamp(0.0, 1.0);
              final isToday = d.date.year == now.year && d.date.month == now.month && d.date.day == now.day;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (d.totalSales > 0)
                        Text(
                          '${(d.totalSales / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isToday ? const Color(0xFF059669) : const Color(0xFF6B7280)),
                        )
                      else
                        const SizedBox(height: 10),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: heightFactor == 0 ? 0.04 : heightFactor,
                            child: Container(
                              decoration: BoxDecoration(
                                color: heightFactor == 0
                                    ? const Color(0xFFE5E7EB)
                                    : (isToday ? const Color(0xFF059669) : const Color(0xFF10B981)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.dayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday ? const Color(0xFF059669) : const Color(0xFF374151),
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFF3F4F6), height: 1),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Pendapatan Minggu Ini', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
            Text('Rp ${_formatCurrency(reportData.weeklyTotalRevenue.toInt())}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
          ],
        ),
      ]),
    );
  }

  Widget _buildMonthlyRevenueChart(ReportData reportData) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final chartData = reportData.monthlyWeeklySales;
    final maxVal = chartData.isEmpty
        ? 1.0
        : chartData.map((w) => w.totalSales).reduce((a, b) => a > b ? a : b);
    final divisor = maxVal > 0 ? maxVal : 1.0;

    final dateRangeStr = '${_formatDateShort(monthStart)} - ${_formatDateShort(monthEnd)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tren Pendapatan Bulan Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 12, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 4),
                      Text(dateRangeStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
              child: const Text('Per Minggu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(chartData.length, (i) {
              final w = chartData[i];
              final heightFactor = (w.totalSales / divisor).clamp(0.0, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (w.totalSales > 0)
                        Text(
                          '${(w.totalSales / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                        )
                      else
                        const SizedBox(height: 10),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: heightFactor == 0 ? 0.04 : heightFactor,
                            child: Container(
                              decoration: BoxDecoration(
                                color: heightFactor == 0 ? const Color(0xFFE5E7EB) : const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        w.label,
                        style: const TextStyle(fontSize: 9, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFF3F4F6), height: 1),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Pendapatan Bulan Ini', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
            Text('Rp ${_formatCurrency(reportData.monthlyTotalRevenue.toInt())}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
          ],
        ),
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

  String _formatTime(String isoStr) {
    final parsed = DateTime.tryParse(isoStr);
    if (parsed == null) return isoStr;
    final local = parsed.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dayStr = local.day.toString().padLeft(2, '0');
    final monthStr = months[local.month - 1];
    final yearStr = local.year;
    final hourStr = local.hour.toString().padLeft(2, '0');
    final minStr = local.minute.toString().padLeft(2, '0');
    return '$dayStr $monthStr $yearStr, $hourStr:$minStr';
  }

  Map<String, dynamic> _getPaymentBadge(String method) {
    final m = method.toLowerCase();
    if (m == 'cash' || m == 'tunai') {
      return {'label': 'Tunai', 'icon': Icons.payments_outlined, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)};
    } else if (m == 'qris') {
      return {'label': 'QRIS', 'icon': Icons.qr_code_scanner_outlined, 'color': const Color(0xFF2563EB), 'bg': const Color(0xFFDBEAFE)};
    } else if (m == 'transfer') {
      return {'label': 'Transfer', 'icon': Icons.account_balance_outlined, 'color': const Color(0xFF7C3AED), 'bg': const Color(0xFFEDE9FE)};
    } else {
      return {'label': 'Debit', 'icon': Icons.credit_card_outlined, 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7)};
    }
  }

  Widget _buildRecentTransactionsSection() {
    final recentAsync = ref.watch(recentTransactionsProvider);
    final repo = ref.watch(transactionRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.history, size: 18, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('10 Transaksi Terakhir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              ],
            ),
            InkWell(
              onTap: () => context.push('/reports/all-transactions'),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Lihat Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        recentAsync.when(
          data: (txns) {
            if (txns.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                  child: Text('Belum ada transaksi tercatat', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: txns.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final txn = entry.value;
                  final isVoid = txn.status == 'void';
                  final badge = _getPaymentBadge(txn.paymentMethod);

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => showTransactionDetailModal(context, txn, repo),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isVoid ? const Color(0xFFFEE2E2) : badge['bg'] as Color,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isVoid ? Icons.block : badge['icon'] as IconData,
                                  color: isVoid ? const Color(0xFFDC2626) : badge['color'] as Color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        FutureBuilder<int>(
                                          future: repo.getDailyTransactionSequence(txn.id),
                                          builder: (context, seqSnap) {
                                            final seq = seqSnap.data ?? 1;
                                            final receiptId = formatReceiptTransactionId(txn.createdAt, seq);
                                            return Text(
                                              '#$receiptId',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF111827)),
                                            );
                                          },
                                        ),
                                        if (isVoid) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('VOID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(_formatTime(txn.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rp ${_formatCurrency(txn.totalAmount.toInt())}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: isVoid ? const Color(0xFF9CA3AF) : const Color(0xFF2563EB),
                                      decoration: isVoid ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badge['bg'] as Color,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(badge['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badge['color'] as Color)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (idx < txns.length - 1) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ],
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, s) => Center(child: Text('Gagal memuat transaksi: $e', style: const TextStyle(color: Colors.red, fontSize: 12))),
        ),
      ],
    );
  }
}
