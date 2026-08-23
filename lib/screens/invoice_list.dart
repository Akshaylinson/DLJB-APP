import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/app_database.dart';
import '../db/settings_db.dart';
import '../models/sales_hdr.dart';
import 'invoice_form.dart';
import 'settings_screen.dart';

const _kDark = Color(0xFF2B2B2B);
const _kHeaderBg = Color(0xFF3A3A3A);
const _kOrange = Color(0xFFD4622A);
const _kBlue = Color(0xFF1A3A6B);
const _kBg = Color(0xFFF0F0F0);
const _kStripe = Color(0xFFF5F5F5);
const _kBorder = Color(0xFFCFCFCF);

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceMonthGroup {
  final String label;
  final String badge;
  final List<SalesHdr> invoices = [];

  _InvoiceMonthGroup({
    required this.label,
    required this.badge,
  });
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<SalesHdr> _invoices = [];
  Map<String, String> _settings = {};
  bool _loading = true;

  String get _companyName {
    final name = _settings[SettingsDb.keyCoName]?.trim() ?? '';
    return name.isEmpty ? 'DLJB' : name;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      AppDatabase.getAllHdr(),
      AppDatabase.getDefaultStrings(),
    ]);
    final invoices = List<SalesHdr>.from(results[0] as List<SalesHdr>);
    invoices.sort(_compareInvoices);
    if (!mounted) return;
    setState(() {
      _invoices = invoices;
      _settings = results[1] as Map<String, String>;
      _loading = false;
    });
  }

  int _compareInvoices(SalesHdr a, SalesHdr b) {
    final ad = a.invDt;
    final bd = b.invDt;
    if (ad == null && bd == null) {
      return (b.id ?? 0).compareTo(a.id ?? 0);
    }
    if (ad == null) return 1;
    if (bd == null) return -1;
    final cmp = bd.compareTo(ad);
    if (cmp != 0) return cmp;
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }

  Future<void> _delete(SalesHdr hdr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Delete invoice ${hdr.invNo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && hdr.id != null) {
      await AppDatabase.deleteHdr(hdr.id!);
      await _load();
    }
  }

  List<_InvoiceMonthGroup> _groups() {
    final map = <String, _InvoiceMonthGroup>{};
    for (final inv in _invoices) {
      final dt = inv.invDt;
      final key = dt == null ? 'undated' : '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      final existing = map[key];
      if (existing != null) {
        existing.invoices.add(inv);
        continue;
      }
      final label = dt == null ? 'Undated invoices' : DateFormat('MMMM yyyy').format(dt);
      final badge = dt == null ? '??' : DateFormat('MMM').format(dt).toUpperCase();
      final group = _InvoiceMonthGroup(
        label: label,
        badge: badge,
      );
      group.invoices.add(inv);
      map[key] = group;
    }
    return map.values.toList();
  }

  double get _totalSales => _invoices.fold(0.0, (sum, inv) => sum + inv.taxAt);

  double get _thisMonthSales {
    final now = DateTime.now();
    return _invoices.fold(0.0, (sum, inv) {
      final dt = inv.invDt;
      if (dt == null) return sum;
      final sameMonth = dt.year == now.year && dt.month == now.month;
      return sameMonth ? sum + inv.taxAt : sum;
    });
  }

  int get _thisMonthCount {
    final now = DateTime.now();
    return _invoices.where((inv) {
      final dt = inv.invDt;
      return dt != null && dt.year == now.year && dt.month == now.month;
    }).length;
  }

  double get _averageBill => _invoices.isEmpty ? 0 : _totalSales / _invoices.length;

  String get _latestBillDate {
    for (final inv in _invoices) {
      final dt = inv.invDt;
      if (dt != null) return DateFormat('dd MMM yyyy').format(dt);
    }
    return 'No invoices';
  }

  @override
  Widget build(BuildContext context) {
    final recordCount = _invoices.length;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildTopBar(),
          _buildAccentBar(),
          Expanded(
            child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            children: [
                              _buildHeroHeader(constraints.maxWidth),
                              const SizedBox(height: 12),
                              _buildAnalytics(constraints.maxWidth),
                              const SizedBox(height: 12),
                              _buildCharts(constraints.maxWidth),
                              const SizedBox(height: 12),
                              if (_invoices.isEmpty)
                                _emptyState()
                              else
                                ..._groups().map((group) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildMonthSection(group, constraints.maxWidth),
                                    )),
                              const SizedBox(height: 84),
                            ],
                          );
                        },
                      ),
                  ),
          ),
          _buildBottomBar(recordCount),
        ],
      ),
    );
  }

  Widget _buildTopBar() => Container(
        color: _kDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Text(
                ':: DLJB',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                tooltip: 'Settings',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  await _load();
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildAccentBar() => Container(
        color: _kOrange,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: const Row(
          children: [
            Text(
              'Invoice Dashboard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildHeroHeader(double width) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _companyName,
                      style: TextStyle(
                        color: _kDark,
                        fontSize: width > 700 ? 28 : 22,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recent invoices first, grouped by month for fast scanning and quick follow-up.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: width > 1000 ? 260 : 220,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Latest invoice',
                        style: TextStyle(
                          color: _kDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _latestBillDate,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics(double width) {
    final cards = [
      _metricCard(
        title: 'Invoices',
        value: '${_invoices.length}',
        icon: Icons.receipt_long_outlined,
      ),
      _metricCard(
        title: 'Total Sales',
        value: _money(_totalSales),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _metricCard(
        title: 'This Month',
        value: _money(_thisMonthSales),
        sub: '$_thisMonthCount bills',
        icon: Icons.calendar_month_outlined,
      ),
      _metricCard(
        title: 'Average Bill',
        value: _money(_averageBill),
        icon: Icons.bar_chart_outlined,
      ),
    ];

    if (width < 920) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 920,
          child: Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                SizedBox(width: 220, height: 92, child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: SizedBox(height: 92, child: cards[i])),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              border: Border.all(color: _kBorder),
            ),
            child: Icon(icon, color: _kDark, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: _kDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(double width) {
    final year = _chartYear;
    final stats = _monthlyStatsFor(year);
    final revenueData = stats.map((e) => e.revenue).toList(growable: false);
    final countData = stats.map((e) => e.count.toDouble()).toList(growable: false);
    final totalRevenue = stats.fold<double>(0, (sum, item) => sum + item.revenue);
    final totalCount = stats.fold<int>(0, (sum, item) => sum + item.count);
    final left = _chartPanel(
      title: 'Monthly Revenue Trend',
      subtitle: 'Revenue by month for $year',
      summary: _money(totalRevenue),
      child: _MonthlyLineChart(
        data: revenueData,
        labels: _monthLabels,
        lineColor: _kOrange,
      ),
    );
    final right = _chartPanel(
      title: 'Monthly Invoice Volume',
      subtitle: 'Invoice count by month for $year',
      summary: '$totalCount invoices',
      child: _MonthlyBarChart(
        data: countData,
        labels: _monthLabels,
        barColor: _kDark,
      ),
    );

    if (width < 1100) {
      return Column(
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _chartPanel({
    required String title,
    required String subtitle,
    required String summary,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _kHeaderBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 220,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(_InvoiceMonthGroup group, double width) {
    final sectionTotal = group.invoices.fold(0.0, (sum, inv) => sum + inv.taxAt);
    final compact = width < 760;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _kHeaderBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    group.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${group.invoices.length} invoice${group.invoices.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _money(sectionTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (compact) _buildCompactMonthList(group.invoices) else _buildDesktopMonthTable(group.invoices),
        ],
      ),
    );
  }

  Widget _buildDesktopMonthTable(List<SalesHdr> invoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFFF2F2F2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: const [
              SizedBox(width: 52, child: _TableHeaderText('#')),
              Expanded(flex: 2, child: _TableHeaderText('Invoice No')),
              Expanded(flex: 4, child: _TableHeaderText('Receiver')),
              Expanded(flex: 2, child: _TableHeaderText('Date')),
              Expanded(flex: 2, child: _TableHeaderText('Total (₹)')),
              SizedBox(width: 44),
            ],
          ),
        ),
        for (int i = 0; i < invoices.length; i++)
          _desktopInvoiceRow(invoices[i], i),
      ],
    );
  }

  Widget _desktopInvoiceRow(SalesHdr inv, int index) {
    final dt = inv.invDt != null ? DateFormat('dd-MM-yyyy').format(inv.invDt!) : '—';
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InvoiceForm(hdrId: inv.id)),
        );
        await _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: index.isEven ? Colors.white : _kStripe,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE9EDF5)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 52, child: Text('${index + 1}', style: const TextStyle(fontSize: 12))),
            Expanded(
              flex: 2,
              child: Text(
                inv.invNo.isEmpty ? '—' : inv.invNo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                inv.rName.isEmpty ? '—' : inv.rName,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(dt, style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${inv.taxAt.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 44,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                onPressed: () => _delete(inv),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete invoice',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMonthList(List<SalesHdr> invoices) {
    return Column(
      children: [
        for (int i = 0; i < invoices.length; i++) ...[
          _compactInvoiceCard(invoices[i], i),
          if (i < invoices.length - 1)
            const Divider(height: 1, thickness: 1, color: Color(0xFFE9EDF5)),
        ],
      ],
    );
  }

  Widget _compactInvoiceCard(SalesHdr inv, int index) {
    final dt = inv.invDt != null ? DateFormat('dd-MM-yyyy').format(inv.invDt!) : '—';
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InvoiceForm(hdrId: inv.id)),
        );
        await _load();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: index.isEven ? Colors.white : _kStripe,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE9EDF5)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                border: Border.all(color: _kBorder),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _kBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv.invNo.isEmpty ? 'Invoice —' : 'Invoice ${inv.invNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inv.rName.isEmpty ? 'No receiver name' : inv.rName,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.event_outlined, dt),
                      _infoChip(Icons.payments_outlined, _money(inv.taxAt)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: () => _delete(inv),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _kDark),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  Widget _emptyState() => Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No invoices yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a new invoice to see monthly groups, analytics, and recent activity here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
          ],
        ),
      );

  Widget _buildBottomBar(int recordCount) => Container(
        color: _kDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Text(
                '$recordCount record${recordCount == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InvoiceForm()),
                  );
                  await _load();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
            ],
          ),
        ),
      );

  int get _chartYear {
    for (final inv in _invoices) {
      final dt = inv.invDt;
      if (dt != null) return dt.year;
    }
    return DateTime.now().year;
  }

  List<_MonthlyStat> _monthlyStatsFor(int year) {
    return List.generate(12, (monthIndex) {
      final month = monthIndex + 1;
      final monthInvoices = _invoices.where((inv) {
        final dt = inv.invDt;
        return dt != null && dt.year == year && dt.month == month;
      }).toList(growable: false);
      final revenue = monthInvoices.fold<double>(0, (sum, inv) => sum + inv.taxAt);
      return _MonthlyStat(
        monthLabel: _monthLabels[monthIndex],
        revenue: revenue,
        count: monthInvoices.length,
      );
    });
  }

  String _money(double value) => '₹${value.toStringAsFixed(2)}';
}

const List<String> _monthLabels = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class _MonthlyStat {
  final String monthLabel;
  final double revenue;
  final int count;

  const _MonthlyStat({
    required this.monthLabel,
    required this.revenue,
    required this.count,
  });
}

class _TableHeaderText extends StatelessWidget {
  final String text;
  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF2B2B2B),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _MonthlyLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;

  const _MonthlyLineChart({
    required this.data,
    required this.labels,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _MonthlyLineChartPainter(
              data: data,
              lineColor: lineColor,
              gridColor: const Color(0xFFD7D7D7),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        _ChartLabelsRow(labels: labels),
      ],
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color barColor;

  const _MonthlyBarChart({
    required this.data,
    required this.labels,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _MonthlyBarChartPainter(
              data: data,
              barColor: barColor,
              gridColor: const Color(0xFFD7D7D7),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        _ChartLabelsRow(labels: labels),
      ],
    );
  }
}

class _ChartLabelsRow extends StatelessWidget {
  final List<String> labels;

  const _ChartLabelsRow({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthlyLineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color gridColor;

  _MonthlyLineChartPainter({
    required this.data,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = lineColor;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor;

    final plot = Rect.fromLTWH(12, 8, size.width - 18, size.height - 18);
    final maxValue = math.max<double>(1, data.fold<double>(0, (a, b) => math.max(a, b)));
    final gridSteps = 4;

    for (int i = 0; i <= gridSteps; i++) {
      final dy = plot.top + (plot.height * i / gridSteps);
      canvas.drawLine(Offset(plot.left, dy), Offset(plot.right, dy), gridPaint);
    }

    final baseline = Offset(plot.left, plot.bottom);
    canvas.drawLine(baseline, Offset(plot.right, plot.bottom), gridPaint);

    if (data.every((value) => value == 0)) {
      return;
    }

    final path = Path();
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? plot.left
          : plot.left + (plot.width * i / (data.length - 1));
      final y = plot.bottom - ((data[i] / maxValue) * plot.height);
      final point = Offset(x, y);
      points.add(point);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 3.4, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyLineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _MonthlyBarChartPainter extends CustomPainter {
  final List<double> data;
  final Color barColor;
  final Color gridColor;

  _MonthlyBarChartPainter({
    required this.data,
    required this.barColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor;

    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = barColor;

    final plot = Rect.fromLTWH(12, 8, size.width - 18, size.height - 18);
    final maxValue = math.max<double>(1, data.fold<double>(0, (a, b) => math.max(a, b)));
    final gridSteps = 4;

    for (int i = 0; i <= gridSteps; i++) {
      final dy = plot.top + (plot.height * i / gridSteps);
      canvas.drawLine(Offset(plot.left, dy), Offset(plot.right, dy), gridPaint);
    }

    final n = data.length;
    if (n == 0) return;
    final cellW = plot.width / n;
    final barW = math.max<double>(6, cellW * 0.56);

    for (int i = 0; i < n; i++) {
      final value = data[i];
      final h = (value / maxValue) * plot.height;
      final left = plot.left + (cellW * i) + ((cellW - barW) / 2);
      final top = plot.bottom - h;
      final rect = Rect.fromLTWH(left, top, barW, h);
      canvas.drawRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyBarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.barColor != barColor ||
        oldDelegate.gridColor != gridColor;
  }
}
