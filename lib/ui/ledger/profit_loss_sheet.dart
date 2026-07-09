import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import '../../core/export/export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/transaction_provider.dart';

// ==================== Data Models ====================

/// Aggregated P&L data for a given period
class ProfitLossData {
  final double totalIncome;
  final double totalCogs;
  final double grossProfit;
  final double totalExpense;
  final double netProfit;
  final String status; // 'laba' or 'rugi'
  final List<CategoryBreakdown> incomeBreakdown;
  final List<CategoryBreakdown> expenseBreakdown;
  final List<TransactionModel> transactions;

  const ProfitLossData({
    this.totalIncome = 0,
    this.totalCogs = 0,
    this.grossProfit = 0,
    this.totalExpense = 0,
    this.netProfit = 0,
    this.status = 'laba',
    this.incomeBreakdown = const [],
    this.expenseBreakdown = const [],
    this.transactions = const [],
  });
}

/// Breakdown by category
class CategoryBreakdown {
  final String categoryName;
  final double amount;
  final int count;

  const CategoryBreakdown({
    required this.categoryName,
    required this.amount,
    required this.count,
  });
}

/// Period filter options
enum PeriodFilter {
  thisMonth('Bulan Ini'),
  lastMonth('Bulan Lalu'),
  last3Months('3 Bulan'),
  custom('Kustom');

  final String label;
  const PeriodFilter(this.label);
}

// ==================== P&L Provider ====================

final profitLossProvider =
    FutureProvider.family<ProfitLossData, _PnLParams>((ref, params) async {
  ref.watch(transactionRefreshProvider);
  final supa = SupabaseService.instance;

  // Get transactions for the period
  List<TransactionModel> transactions;
  if (params.startDate != null && params.endDate != null) {
    transactions = await supa.getTransactionsByDateRange(
      params.businessId,
      params.startDate!,
      params.endDate!,
    );
  } else {
    // Default: current month
    final now = DateTime.now();
    final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-${_daysInMonth(now.year, now.month)}';
    transactions = await supa.getTransactionsByDateRange(params.businessId, start, end);
  }

  // Get categories for names
  final categories = await supa.getCategoriesByBusiness(params.businessId);
  final categoryMap = {for (final c in categories) c.categoryId: c};

  // Aggregate
  double totalIncome = 0, totalCogs = 0, totalExpense = 0;
  final Map<int, double> incomeByCat = {};
  final Map<int, int> incomeCountByCat = {};
  final Map<int, double> expenseByCat = {};
  final Map<int, int> expenseCountByCat = {};

  for (final tx in transactions) {
    if (tx.type == AppConstants.typeIncome) {
      totalIncome += tx.amount;
      totalCogs += tx.cogs;
      incomeByCat.update(tx.categoryId, (v) => v + tx.amount, ifAbsent: () => tx.amount);
      incomeCountByCat.update(tx.categoryId, (v) => v + 1, ifAbsent: () => 1);
    } else {
      totalExpense += tx.amount;
      expenseByCat.update(tx.categoryId, (v) => v + tx.amount, ifAbsent: () => tx.amount);
      expenseCountByCat.update(tx.categoryId, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  final grossProfit = totalIncome - totalCogs;
  final netProfit = grossProfit - totalExpense;

  // Build breakdowns
  final incomeBreakdown = incomeByCat.entries.map((e) {
    final cat = categoryMap[e.key];
    return CategoryBreakdown(
      categoryName: cat?.name ?? 'Kategori #${e.key}',
      amount: e.value,
      count: incomeCountByCat[e.key] ?? 0,
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final expenseBreakdown = expenseByCat.entries.map((e) {
    final cat = categoryMap[e.key];
    return CategoryBreakdown(
      categoryName: cat?.name ?? 'Kategori #${e.key}',
      amount: e.value,
      count: expenseCountByCat[e.key] ?? 0,
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  // Sort transactions by date descending
  final sortedTx = List<TransactionModel>.from(transactions)
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

  return ProfitLossData(
    totalIncome: totalIncome,
    totalCogs: totalCogs,
    grossProfit: grossProfit,
    totalExpense: totalExpense,
    netProfit: netProfit,
    status: netProfit >= 0 ? 'laba' : 'rugi',
    incomeBreakdown: incomeBreakdown,
    expenseBreakdown: expenseBreakdown,
    transactions: sortedTx,
  );
});

class _PnLParams {
  final int businessId;
  final String? startDate;
  final String? endDate;

  const _PnLParams({
    required this.businessId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      other is _PnLParams &&
      other.businessId == businessId &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(businessId, startDate, endDate);
}

int _daysInMonth(int year, int month) {
  if (month == 2) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
  }
  return [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
}

// ==================== UI ====================

/// Profit & Loss Sheet with analytical timeline filters
class ProfitLossSheet extends ConsumerStatefulWidget {
  final BusinessModel business;

  const ProfitLossSheet({super.key, required this.business});

  @override
  ConsumerState<ProfitLossSheet> createState() => _ProfitLossSheetState();
}

class _ProfitLossSheetState extends ConsumerState<ProfitLossSheet> {
  PeriodFilter _selectedPeriod = PeriodFilter.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _showTransactionDetail = false;
  bool _showWeeklyBreakdown = false;

  /// Whether the currently selected period spans only a single month
  bool get _isSingleMonth {
    switch (_selectedPeriod) {
      case PeriodFilter.thisMonth:
      case PeriodFilter.lastMonth:
        return true;
      case PeriodFilter.last3Months:
        return false;
      case PeriodFilter.custom:
        if (_customStart == null || _customEnd == null) return true;
        // Single month if start and end are in the same month+year
        return _customStart!.year == _customEnd!.year &&
            _customStart!.month == _customEnd!.month;
    }
  }

  String? get _startDate {
    switch (_selectedPeriod) {
      case PeriodFilter.thisMonth:
        final now = DateTime.now();
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      case PeriodFilter.lastMonth:
        final last = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        return '${last.year}-${last.month.toString().padLeft(2, '0')}-01';
      case PeriodFilter.last3Months:
        final threeMonthsAgo =
            DateTime(DateTime.now().year, DateTime.now().month - 3, 1);
        return '${threeMonthsAgo.year}-${threeMonthsAgo.month.toString().padLeft(2, '0')}-01';
      case PeriodFilter.custom:
        if (_customStart == null) return null;
        return '${_customStart!.year}-${_customStart!.month.toString().padLeft(2, '0')}-${_customStart!.day.toString().padLeft(2, '0')}';
    }
  }

  String? get _endDate {
    switch (_selectedPeriod) {
      case PeriodFilter.thisMonth:
        final now = DateTime.now();
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${_daysInMonth(now.year, now.month).toString().padLeft(2, '0')}';
      case PeriodFilter.lastMonth:
        final last = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        final lastMonthEnd = DateTime(last.year, last.month + 1, 0);
        return '${lastMonthEnd.year}-${lastMonthEnd.month.toString().padLeft(2, '0')}-${lastMonthEnd.day.toString().padLeft(2, '0')}';
      case PeriodFilter.last3Months:
        final now = DateTime.now();
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case PeriodFilter.custom:
        if (_customEnd == null) return null;
        return '${_customEnd!.year}-${_customEnd!.month.toString().padLeft(2, '0')}-${_customEnd!.day.toString().padLeft(2, '0')}';
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case PeriodFilter.thisMonth:
        final now = DateTime.now();
        return FormatHelpers.displayPeriod(
            '${now.year}-${now.month.toString().padLeft(2, '0')}');
      case PeriodFilter.lastMonth:
        final last = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        return FormatHelpers.displayPeriod(
            '${last.year}-${last.month.toString().padLeft(2, '0')}');
      case PeriodFilter.last3Months:
        return '3 Bulan Terakhir';
      case PeriodFilter.custom:
        if (_customStart == null || _customEnd == null) return 'Pilih Tanggal';
        return '${_customStart!.day}/${_customStart!.month} - ${_customEnd!.day}/${_customEnd!.month}';
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(
              start: DateTime(DateTime.now().year, DateTime.now().month, 1),
              end: DateTime.now(),
            ),
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _selectedPeriod = PeriodFilter.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = _PnLParams(
      businessId: widget.business.businessId,
      startDate: _startDate,
      endDate: _endDate,
    );
    final plAsync = ref.watch(profitLossProvider(params));
    final colorScheme = Theme.of(context).colorScheme;

    final plParams = params;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Laba / Rugi'),
        actions: [
          // Export menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Ekspor Laporan',
            onSelected: (value) => _handleExport(value, plParams),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: ListTile(
                leading: Icon(Icons.table_chart_outlined),
                title: Text('CSV'),
                subtitle: Text('Spreadsheet'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
              PopupMenuItem(value: 'pdf', child: ListTile(
                leading: Icon(Icons.picture_as_pdf_outlined),
                title: Text('PDF'),
                subtitle: Text('Dokumen siap cetak'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
          // Toggle transaction list
          IconButton(
            icon: Icon(
              _showTransactionDetail
                  ? Icons.pie_chart_rounded
                  : Icons.receipt_long_rounded,
            ),
            tooltip: _showTransactionDetail
                ? 'Lihat Ringkasan'
                : 'Lihat Transaksi',
            onPressed: () =>
                setState(() => _showTransactionDetail = !_showTransactionDetail),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildPeriodSelector(colorScheme),
        ),
      ),
      body: plAsync.when(
        data: (pl) => _showTransactionDetail
            ? _buildTransactionList(pl, colorScheme)
            : _buildAccountingLayout(pl, colorScheme),
        loading: () => const SkeletonReport(),
        error: (error, _) => ErrorRetryWidget.fromAppError(
          ErrorHandler.classify(error),
          onRetry: () => ref.invalidate(profitLossProvider(params)),
        ),
      ),
    );
  }

  Future<void> _handleExport(String format, _PnLParams params) async {
    final asyncValue = ref.read(profitLossProvider(params));
    final data = asyncValue.requireValue;

    if (data.transactions.isEmpty &&
        data.incomeBreakdown.isEmpty &&
        data.expenseBreakdown.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menyiapkan file ${format.toUpperCase()}...'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      if (format == 'csv') {
        await ExportService.exportCsv(
          businessName: widget.business.name,
          periodLabel: _periodLabel,
          data: data,
        );
      } else if (format == 'pdf') {
        await ExportService.exportPdf(
          businessName: widget.business.name,
          periodLabel: _periodLabel,
          data: data,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor: $e'),
          backgroundColor: AppTheme.lossColor,
        ),
      );
    }
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final period in PeriodFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(period.label),
                  selected: _selectedPeriod == period,
                  onSelected: (selected) {
                    if (period == PeriodFilter.custom) {
                      _pickCustomRange();
                    } else if (selected) {
                      setState(() => _selectedPeriod = period);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== Accounting Layout ====================

  /// Compute weekly breakdown chart data from transactions
  List<_MonthBarData> _computeWeeklyChartData(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return [];

    final Map<int, double> incomeByWeek = {};
    final Map<int, double> expenseByWeek = {};
    final weekSet = <int>{};

    for (final tx in transactions) {
      // Parse the date to determine which week of the month
      DateTime date;
      try {
        date = DateTime.parse(tx.transactionDate);
      } catch (_) {
        continue;
      }
      final day = date.day;
      final week = ((day - 1) ~/ 7) + 1; // Week 1-5
      weekSet.add(week);

      if (tx.type == AppConstants.typeIncome) {
        incomeByWeek.update(week, (v) => v + tx.amount, ifAbsent: () => tx.amount);
      } else {
        expenseByWeek.update(week, (v) => v + tx.amount, ifAbsent: () => tx.amount);
      }
    }

    final sortedWeeks = weekSet.toList()..sort();

    return sortedWeeks.map((week) => _MonthBarData(
      monthLabel: 'Minggu $week',
      income: incomeByWeek[week] ?? 0,
      expense: expenseByWeek[week] ?? 0,
    )).toList();
  }

  Widget _buildAccountingLayout(ProfitLossData pl, ColorScheme colorScheme) {
    final showWeekly = _showWeeklyBreakdown && _isSingleMonth;
    final chartData = showWeekly
        ? _computeWeeklyChartData(pl.transactions)
        : _computeMonthlyChartData(pl.transactions);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(profitLossProvider(
          _PnLParams(businessId: widget.business.businessId),
        ));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period header
            Text(
              _periodLabel,
              style: AppTheme.labelSmall.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Bar chart (monthly or weekly)
            if (chartData.isNotEmpty) ...[
              _buildMonthlyBarChart(chartData, colorScheme),
              const SizedBox(height: 24),
            ],

            // ==================== INCOME SECTION ====================
            _SectionHeader(title: 'PENDAPATAN', color: AppTheme.profitColor),

            // Income category breakdown
            ...pl.incomeBreakdown.map((b) => _BreakdownRow(
                  label: b.categoryName,
                  amount: b.amount,
                  count: b.count,
                  color: AppTheme.profitColor,
                )),

            if (pl.incomeBreakdown.isEmpty)
              _EmptyRow(label: 'Belum ada pendapatan'),

            const Divider(height: 24),
            _TotalRow(
              label: 'Total Pendapatan',
              amount: pl.totalIncome,
              color: AppTheme.profitColor,
              bold: true,
            ),

            const SizedBox(height: 16),

            // ==================== COGS SECTION ====================
            _SectionHeader(title: 'HPP (HARGA POKOK PENJUALAN)', color: AppTheme.warningColor),

            _TotalRow(
              label: 'Total HPP',
              amount: pl.totalCogs,
              color: AppTheme.warningColor,
              bold: true,
            ),

            const SizedBox(height: 16),

            // ==================== GROSS PROFIT ====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.infoColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded,
                      color: AppTheme.infoColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'LABA KOTOR',
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ),
                  Text(
                    FormatHelpers.rupiah(pl.grossProfit),
                    style: AppTheme.amountMedium.copyWith(
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================== EXPENSE SECTION ====================
            _SectionHeader(title: 'PENGELUARAN', color: AppTheme.lossColor),

            ...pl.expenseBreakdown.map((b) => _BreakdownRow(
                  label: b.categoryName,
                  amount: b.amount,
                  count: b.count,
                  color: AppTheme.lossColor,
                )),

            if (pl.expenseBreakdown.isEmpty)
              _EmptyRow(label: 'Belum ada pengeluaran'),

            const Divider(height: 24),
            _TotalRow(
              label: 'Total Pengeluaran',
              amount: pl.totalExpense,
              color: AppTheme.lossColor,
              bold: true,
            ),

            const SizedBox(height: 24),

            // ==================== NET PROFIT ====================
            Card(
              color: pl.netProfit >= 0
                  ? AppTheme.profitColor.withValues(alpha: 0.08)
                  : AppTheme.lossColor.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'LABA / RUGI BERSIH',
                      style: AppTheme.labelSmall.copyWith(
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      FormatHelpers.rupiah(pl.netProfit),
                      style: AppTheme.amountLarge.copyWith(
                        color: pl.netProfit >= 0
                            ? AppTheme.profitColor
                            : AppTheme.lossColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: pl.netProfit >= 0
                            ? AppTheme.profitColor
                            : AppTheme.lossColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pl.netProfit >= 0 ? '🟢 LABA' : '🔴 RUGI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Periode: $_periodLabel',
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ==================== Combined Bar + Line Chart ====================

  Widget _buildMonthlyBarChart(List<_MonthBarData> data, ColorScheme colorScheme) {
    final maxValue = data.fold<double>(0, (max, d) =>
        [max, d.income, d.expense].reduce((a, b) => a > b ? a : b));
    if (maxValue == 0) return const SizedBox.shrink();

    final barWidth = data.length > 4 ? 10.0 : 16.0;
    // Accommodate negative net profit (rugi) below the bar baseline
    final minNet = data.map((d) => d.netProfit).reduce((a, b) => a < b ? a : b);
    final chartMinY = minNet < 0 ? minNet * 1.25 : 0.0;
    final chartMaxY = maxValue * 1.25;
    final chartRange = chartMaxY - chartMinY;

    // Net profit line spots
    final lineSpots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i].netProfit),
    );

    // Shared chart config
    const leftReserved = 36.0;
    const bottomReserved = 28.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                // Chart title + weekly toggle
                Text(
                  data.length <= 5 && _isSingleMonth
                      ? 'Grafik Mingguan'
                      : 'Grafik Bulanan',
                  style: AppTheme.labelSmall.copyWith(fontSize: 12),
                ),
                if (_isSingleMonth) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _showWeeklyBreakdown = !_showWeeklyBreakdown),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _showWeeklyBreakdown
                            ? colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _showWeeklyBreakdown
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showWeeklyBreakdown
                                ? Icons.calendar_view_week_rounded
                                : Icons.calendar_view_month_rounded,
                            size: 12,
                            color: _showWeeklyBreakdown
                                ? colorScheme.primary
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _showWeeklyBreakdown ? 'Minggu' : 'Bulan',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _showWeeklyBreakdown
                                  ? colorScheme.primary
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Legend
                _legendDot(AppTheme.profitColor, 'Pemasukan'),
                const SizedBox(width: 10),
                _legendDot(AppTheme.lossColor, 'Pengeluaran'),
                const SizedBox(width: 10),
                _legendLine('Laba/Rugi'),
              ],
            ),
            const SizedBox(height: 20),

            // Combined bar + line chart
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  // Bottom layer: Bar chart
                  BarChart(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutCubic,
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.grey.shade800,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final idx = group.x.toInt();
                            if (idx < 0 || idx >= data.length) return null;
                            final monthData = data[idx];
                            final label = rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                            return BarTooltipItem(
                              '${monthData.monthLabel}\n$label\n${FormatHelpers.rupiah(rod.toY)}\n\nLaba/Rugi:\n${FormatHelpers.rupiah(monthData.netProfit)}',
                              TextStyle(
                                color: rod.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: bottomReserved,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  data[idx].monthLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: leftReserved,
                            interval: maxValue / 4,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  _compactAmount(value),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      minY: chartMinY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartRange / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(data.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: data[i].income,
                              color: AppTheme.profitColor,
                              width: barWidth,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: data[i].expense,
                              color: AppTheme.lossColor,
                              width: barWidth,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                          barsSpace: 4,
                        );
                      }),
                    ),
                  ),

                  // Top layer: Net profit line chart overlay
                  LineChart(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutCubic,
                    LineChartData(
                      minY: chartMinY,
                      maxY: chartMaxY,
                      clipData: const FlClipData.all(),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                            reservedSize: bottomReserved,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                            reservedSize: leftReserved,
                          ),
                        ),
                      ),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineSpots,
                          isCurved: true,
                          color: AppTheme.infoColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3.5,
                                color: Colors.white,
                                strokeWidth: 2.5,
                                strokeColor: data[index].netProfit >= 0
                                    ? AppTheme.profitColor
                                    : AppTheme.lossColor,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.infoColor.withValues(alpha: 0.06),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Net profit summary per period
            ...data.map((d) => _buildProfitSummaryRow(d)),
          ],
        ),
      ),
    );
  }

  /// Single profit summary row used in the chart card
  Widget _buildProfitSummaryRow(_MonthBarData d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            d.monthLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            FormatHelpers.rupiah(d.income),
            style: const TextStyle(fontSize: 10, color: AppTheme.profitColor),
          ),
          const Spacer(),
          Icon(
            d.netProfit >= 0
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: d.netProfit >= 0 ? AppTheme.profitColor : AppTheme.lossColor,
          ),
          const SizedBox(width: 2),
          Text(
            FormatHelpers.rupiah(d.netProfit.abs()),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: d.netProfit >= 0 ? AppTheme.profitColor : AppTheme.lossColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Legend entry: line + color for net profit trend in chart title
  Widget _legendLine(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.show_chart_rounded, size: 10, color: AppTheme.infoColor),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  // ==================== Transaction List ====================

  Widget _buildTransactionList(ProfitLossData pl, ColorScheme colorScheme) {
    if (pl.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Belum ada transaksi', style: AppTheme.caption),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(profitLossProvider(
          _PnLParams(businessId: widget.business.businessId),
        ));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pl.transactions.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Summary header
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniSummaryCard(
                      label: 'Pendapatan',
                      amount: pl.totalIncome,
                      color: AppTheme.profitColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniSummaryCard(
                      label: 'Pengeluaran',
                      amount: pl.totalExpense,
                      color: AppTheme.lossColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniSummaryCard(
                      label: 'Laba/Rugi',
                      amount: pl.netProfit,
                      color: pl.netProfit >= 0
                          ? AppTheme.profitColor
                          : AppTheme.lossColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final tx = pl.transactions[index - 1];
          final isIncome = tx.type == AppConstants.typeIncome;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showTransactionDetailDialog(tx),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Type icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isIncome
                                ? AppTheme.profitColor
                                : AppTheme.lossColor)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isIncome
                            ? AppTheme.profitColor
                            : AppTheme.lossColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Date & description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FormatHelpers.displayDate(tx.transactionDate),
                            style: AppTheme.caption.copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx.description?.isNotEmpty == true
                                ? tx.description!
                                : (isIncome ? 'Pendapatan' : 'Pengeluaran'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          FormatHelpers.rupiah(tx.amount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isIncome
                                ? AppTheme.profitColor
                                : AppTheme.lossColor,
                          ),
                        ),
                        if (isIncome && tx.cogs > 0)
                          Text(
                            'HPP: ${FormatHelpers.rupiah(tx.cogs)}',
                            style: AppTheme.caption.copyWith(fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showTransactionDetailDialog(TransactionModel tx) async {
    final isIncome = tx.type == AppConstants.typeIncome;
    final catName = await _getCategoryName(tx.categoryId);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: isIncome ? AppTheme.profitColor : AppTheme.lossColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(isIncome ? 'Uang Masuk' : 'Uang Keluar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Tanggal', FormatHelpers.displayDate(tx.transactionDate)),
            _detailRow('Kategori', catName),
            _detailRow('Jumlah', FormatHelpers.rupiah(tx.amount)),
            if (isIncome && tx.cogs > 0)
              _detailRow('HPP', FormatHelpers.rupiah(tx.cogs)),
            _detailRow('Metode Bayar', _paymentLabel(tx.paymentMethod)),
            if (tx.description?.isNotEmpty == true)
              _detailRow('Deskripsi', tx.description!),
            _detailRow(
              'Status',
              tx.statusSync ? 'Tersimpan (Online)' : 'Menunggu Sinkronisasi',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<String> _getCategoryName(int categoryId) async {
    return SupabaseService.instance
        .getCategoryName(widget.business.businessId, categoryId);
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS';
      default:
        return 'Lainnya';
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTheme.caption.copyWith(fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ==================== Reusable Widgets ====================

// ==================== Monthly Bar Chart Helpers ====================

/// Data for a single month bar group
class _MonthBarData {
  final String monthLabel;
  final double income;
  final double expense;
  final double netProfit;

  const _MonthBarData({
    required this.monthLabel,
    required this.income,
    required this.expense,
  }) : netProfit = income - expense;
}

/// Compute monthly chart data from transaction list (grouped by YYYY-MM)
List<_MonthBarData> _computeMonthlyChartData(List<TransactionModel> transactions) {
  if (transactions.isEmpty) return [];

  final Map<String, double> incomeByMonth = {};
  final Map<String, double> expenseByMonth = {};
  final monthSet = <String>{};

  for (final tx in transactions) {
    final monthKey = tx.transactionDate.length >= 7
        ? tx.transactionDate.substring(0, 7)
        : tx.transactionDate;
    monthSet.add(monthKey);

    if (tx.type == AppConstants.typeIncome) {
      incomeByMonth.update(monthKey, (v) => v + tx.amount, ifAbsent: () => tx.amount);
    } else {
      expenseByMonth.update(monthKey, (v) => v + tx.amount, ifAbsent: () => tx.amount);
    }
  }

  final sortedMonths = monthSet.toList()..sort();

  return sortedMonths.map((month) => _MonthBarData(
    monthLabel: _shortMonthLabel(month),
    income: incomeByMonth[month] ?? 0,
    expense: expenseByMonth[month] ?? 0,
  )).toList();
}

/// Short month label (e.g. "Jan", "Feb") from YYYY-MM
String _shortMonthLabel(String periodStr) {
  try {
    final date = DateTime.parse('$periodStr-01');
    return DateFormat('MMM', 'id_ID').format(date);
  } catch (_) {
    return periodStr;
  }
}

/// Compact amount for chart axis (e.g. "5jt" for 5,000,000)
String _compactAmount(double amount) {
  final abs = amount.abs();
  if (abs >= 1_000_000_000) {
    return '${(amount / 1_000_000_000).toStringAsFixed(1)}M';
  } else if (abs >= 1_000_000) {
    return '${(amount / 1_000_000).toStringAsFixed(0)}jt';
  } else if (abs >= 1_000) {
    return '${(amount / 1_000).toStringAsFixed(0)}rb';
  }
  return amount.toStringAsFixed(0);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count×',
              style: AppTheme.caption.copyWith(fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              FormatHelpers.rupiah(amount),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              FormatHelpers.rupiah(amount),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String label;
  const _EmptyRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label, style: AppTheme.caption),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _MiniSummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(label,
                style: AppTheme.caption.copyWith(fontSize: 10)),
            const SizedBox(height: 4),
            Text(
              FormatHelpers.rupiah(amount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
