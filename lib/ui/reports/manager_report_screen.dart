import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
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

class ManagerReportData {
  final double totalIncome;
  final double totalCogs;
  final double grossProfit;
  final double totalExpense;
  final double netProfit;
  final String status;
  final List<CategoryBreakdown> incomeBreakdown;
  final List<CategoryBreakdown> expenseBreakdown;
  final List<TransactionModel> transactions;

  const ManagerReportData({
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

enum PeriodFilter {
  thisMonth('Bulan Ini'),
  lastMonth('Bulan Lalu'),
  last3Months('3 Bulan'),
  custom('Kustom');

  final String label;
  const PeriodFilter(this.label);
}

// ==================== Provider ====================

final managerReportProvider =
    FutureProvider.family<ManagerReportData, _ReportParams>((ref, params) async {
  ref.watch(transactionRefreshProvider);
  final supa = SupabaseService.instance;

  List<TransactionModel> transactions;
  if (params.startDate != null && params.endDate != null) {
    transactions = await supa.getTransactionsByDateRange(
      params.businessId,
      params.startDate!,
      params.endDate!,
    );
  } else {
    final now = DateTime.now();
    final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final end =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${_daysInMonth(now.year, now.month)}';
    transactions = await supa.getTransactionsByDateRange(
        params.businessId, start, end);
  }

  final categories = await supa.getCategoriesByBusiness(params.businessId);
  final categoryMap = {for (final c in categories) c.categoryId: c};

  double totalIncome = 0, totalCogs = 0, totalExpense = 0;
  final Map<int, double> incomeByCat = {};
  final Map<int, int> incomeCountByCat = {};
  final Map<int, double> expenseByCat = {};
  final Map<int, int> expenseCountByCat = {};

  for (final tx in transactions) {
    if (tx.type == AppConstants.typeIncome) {
      totalIncome += tx.amount;
      totalCogs += tx.cogs;
      incomeByCat.update(tx.categoryId, (v) => v + tx.amount,
          ifAbsent: () => tx.amount);
      incomeCountByCat.update(tx.categoryId, (v) => v + 1, ifAbsent: () => 1);
    } else {
      totalExpense += tx.amount;
      expenseByCat.update(tx.categoryId, (v) => v + tx.amount,
          ifAbsent: () => tx.amount);
      expenseCountByCat.update(tx.categoryId, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  final grossProfit = totalIncome - totalCogs;
  final netProfit = grossProfit - totalExpense;

  final incomeBreakdown = incomeByCat.entries
      .map((e) {
        final cat = categoryMap[e.key];
        return CategoryBreakdown(
          categoryName: cat?.name ?? 'Kategori #${e.key}',
          amount: e.value,
          count: incomeCountByCat[e.key] ?? 0,
        );
      })
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final expenseBreakdown = expenseByCat.entries
      .map((e) {
        final cat = categoryMap[e.key];
        return CategoryBreakdown(
          categoryName: cat?.name ?? 'Kategori #${e.key}',
          amount: e.value,
          count: expenseCountByCat[e.key] ?? 0,
        );
      })
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final sortedTx = List<TransactionModel>.from(transactions)
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

  return ManagerReportData(
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

class _ReportParams {
  final int businessId;
  final String? startDate;
  final String? endDate;

  const _ReportParams({
    required this.businessId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      other is _ReportParams &&
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

class ManagerReportScreen extends ConsumerStatefulWidget {
  final BusinessModel business;

  const ManagerReportScreen({super.key, required this.business});

  @override
  ConsumerState<ManagerReportScreen> createState() =>
      _ManagerReportScreenState();
}

class _ManagerReportScreenState extends ConsumerState<ManagerReportScreen> {
  PeriodFilter _selectedPeriod = PeriodFilter.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _showTransactionDetail = false;

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
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${_daysInMonth(now.year, now.month)}';
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
    final params = _ReportParams(
      businessId: widget.business.businessId,
      startDate: _startDate,
      endDate: _endDate,
    );
    final reportAsync = ref.watch(managerReportProvider(params));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            icon: Icon(
              _showTransactionDetail
                  ? Icons.pie_chart_rounded
                  : Icons.receipt_long_rounded,
            ),
            tooltip:
                _showTransactionDetail ? 'Lihat Ringkasan' : 'Lihat Transaksi',
            onPressed: () =>
                setState(() => _showTransactionDetail = !_showTransactionDetail),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildPeriodSelector(colorScheme),
        ),
      ),
      body: reportAsync.when(
        data: (data) => _showTransactionDetail
            ? _buildTransactionList(data)
            : _buildSummary(data, colorScheme),
        loading: () => const SkeletonReport(),
        error: (error, _) => ErrorRetryWidget.fromAppError(
          ErrorHandler.classify(error),
          onRetry: () => ref.invalidate(managerReportProvider(params)),
        ),
      ),
    );
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

  _ReportParams get _currentParams => _ReportParams(
    businessId: widget.business.businessId,
    startDate: _startDate,
    endDate: _endDate,
  );

  Widget _buildSummary(ManagerReportData data, ColorScheme colorScheme) {
    final p = _currentParams;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(managerReportProvider(p));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_periodLabel,
                style: AppTheme.labelSmall.copyWith(fontSize: 12)),
            const SizedBox(height: 16),

            // Net Profit Card
            Card(
              color: data.netProfit >= 0
                  ? AppTheme.profitColor.withValues(alpha: 0.1)
                  : AppTheme.lossColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Laba / Rugi Bersih', style: AppTheme.labelSmall),
                    const SizedBox(height: 8),
                    Text(
                      FormatHelpers.rupiah(data.netProfit),
                      style: AppTheme.amountLarge.copyWith(
                        color: data.netProfit >= 0
                            ? AppTheme.profitColor
                            : AppTheme.lossColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: data.netProfit >= 0
                            ? AppTheme.profitColor
                            : AppTheme.lossColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.netProfit >= 0 ? 'LABA' : 'RUGI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Detail cards grid
            Row(
              children: [
                Expanded(
                  child: _DetailCard(
                    title: 'Pendapatan',
                    amount: data.totalIncome,
                    icon: Icons.trending_up_rounded,
                    color: AppTheme.profitColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailCard(
                    title: 'HPP',
                    amount: data.totalCogs,
                    icon: Icons.inventory_rounded,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailCard(
                    title: 'Laba Kotor',
                    amount: data.grossProfit,
                    icon: Icons.monetization_on_rounded,
                    color: AppTheme.infoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailCard(
                    title: 'Pengeluaran',
                    amount: data.totalExpense,
                    icon: Icons.trending_down_rounded,
                    color: AppTheme.lossColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Income breakdown
            Text('Pendapatan', style: AppTheme.heading3),
            const SizedBox(height: 8),
            ...data.incomeBreakdown.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(b.categoryName,
                              style: const TextStyle(fontSize: 13))),
                      Text('${b.count}×',
                          style: AppTheme.caption.copyWith(fontSize: 11)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: Text(
                          FormatHelpers.rupiah(b.amount),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.profitColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const Divider(height: 24),

            // Expense breakdown
            Text('Pengeluaran', style: AppTheme.heading3),
            const SizedBox(height: 8),
            ...data.expenseBreakdown.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(b.categoryName,
                              style: const TextStyle(fontSize: 13))),
                      Text('${b.count}×',
                          style: AppTheme.caption.copyWith(fontSize: 11)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: Text(
                          FormatHelpers.rupiah(b.amount),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.lossColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(ManagerReportData data) {
    final p = _currentParams;
    if (data.transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada transaksi'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(managerReportProvider(p));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.transactions.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  _MiniCard('Pendapatan', data.totalIncome, AppTheme.profitColor),
                  const SizedBox(width: 8),
                  _MiniCard('Pengeluaran', data.totalExpense, AppTheme.lossColor),
                  const SizedBox(width: 8),
                  _MiniCard('Laba/Rugi', data.netProfit,
                      data.netProfit >= 0 ? AppTheme.profitColor : AppTheme.lossColor),
                ],
              ),
            );
          }

          final tx = data.transactions[index - 1];
          final isIncome = tx.type == AppConstants.typeIncome;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
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
                              fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
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
                        Text('HPP: ${FormatHelpers.rupiah(tx.cogs)}',
                            style: AppTheme.caption.copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _DetailCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(title, style: AppTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              FormatHelpers.rupiah(amount),
              style: AppTheme.amountMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _MiniCard(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
              const SizedBox(height: 4),
              Text(
                FormatHelpers.rupiah(amount),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
