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
import '../dashboard/qris_display_screen.dart';

// ==================== Data Models ====================

class ManagerReportData {
  final double totalIncome;
  final double totalCogs;
  final double grossProfit;
  final double totalExpense;
  final double netProfit;
  final String status;

  const ManagerReportData({
    this.totalIncome = 0,
    this.totalCogs = 0,
    this.grossProfit = 0,
    this.totalExpense = 0,
    this.netProfit = 0,
    this.status = 'laba',
  });
}

enum PeriodFilter {
  today('Hari Ini'),
  thisWeek('Minggu Ini'),
  thisMonth('Bulan Ini'),
  thisYear('Tahun Ini'),
  custom('Custom');

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

  double totalIncome = 0, totalCogs = 0, totalExpense = 0;

  for (final tx in transactions) {
    if (tx.type == AppConstants.typeIncome) {
      totalIncome += tx.amount;
      totalCogs += tx.cogs;
    } else {
      totalExpense += tx.amount;
    }
  }

  final grossProfit = totalIncome - totalCogs;
  final netProfit = grossProfit - totalExpense;

  return ManagerReportData(
    totalIncome: totalIncome,
    totalCogs: totalCogs,
    grossProfit: grossProfit,
    totalExpense: totalExpense,
    netProfit: netProfit,
    status: netProfit >= 0 ? 'laba' : 'rugi',
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

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        return _formatDate(now);
      case PeriodFilter.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return _formatDate(weekStart);
      case PeriodFilter.thisMonth:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      case PeriodFilter.thisYear:
        return '${now.year}-01-01';
      case PeriodFilter.custom:
        if (_customStart == null) return null;
        return _formatDate(_customStart!);
    }
  }

  String? get _endDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        return _formatDate(now);
      case PeriodFilter.thisWeek:
        return _formatDate(now);
      case PeriodFilter.thisMonth:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${_daysInMonth(now.year, now.month)}';
      case PeriodFilter.thisYear:
        return '${now.year}-12-31';
      case PeriodFilter.custom:
        if (_customEnd == null) return null;
        return _formatDate(_customEnd!);
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        return 'Hari Ini';
      case PeriodFilter.thisWeek:
        return 'Minggu Ini';
      case PeriodFilter.thisMonth:
        return FormatHelpers.displayPeriod(
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');
      case PeriodFilter.thisYear:
        return 'Tahun ${DateTime.now().year}';
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
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'QRIS Pembayaran',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      QrisDisplayScreen(business: widget.business),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildPeriodSelector(colorScheme),
        ),
      ),
      body: reportAsync.when(
        data: (data) => _buildSummary(data, colorScheme),
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
              elevation: 2,
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
                          horizontal: 14, vertical: 6),
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
                          fontSize: 12,
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

          ],
        ),
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


