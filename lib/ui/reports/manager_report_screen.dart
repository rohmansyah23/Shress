import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
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
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${FormatHelpers.daysInMonth(now.year, now.month)}';
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


// ==================== UI ====================

class ManagerReportScreen extends ConsumerStatefulWidget {
  final BusinessModel business;
  final bool showAppBar;

  const ManagerReportScreen({super.key, required this.business, this.showAppBar = true});

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
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${FormatHelpers.daysInMonth(now.year, now.month)}';
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
        return '${FormatHelpers.displayDate('${_customStart!.year}-${_customStart!.month.toString().padLeft(2, '0')}-${_customStart!.day.toString().padLeft(2, '0')}')} - ${FormatHelpers.displayDate('${_customEnd!.year}-${_customEnd!.month.toString().padLeft(2, '0')}-${_customEnd!.day.toString().padLeft(2, '0')}')}';
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

    final body = reportAsync.when(
      data: (data) => _buildSummary(data, colorScheme),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorRetryWidget.fromAppError(
        ErrorHandler.classify(error),
        onRetry: () => ref.invalidate(managerReportProvider(params)),
      ),
    );

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.showAppBar) ...[
          const SizedBox(height: AppTheme.s12),
          _buildPeriodSelector(colorScheme),
        ],
        Expanded(child: body),
      ],
    );

    if (!widget.showAppBar) return SafeArea(child: mainContent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildPeriodSelector(colorScheme),
        ),
      ),
      body: body,
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final period in PeriodFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: AppTheme.s8),
                child: GestureDetector(
                  onTap: () {
                    if (period == PeriodFilter.custom) {
                      _pickCustomRange();
                    } else {
                      setState(() => _selectedPeriod = period);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.s16, vertical: AppTheme.s8),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == period
                          ? (isLight ? colorScheme.primary : AppTheme.accent)
                          : (isLight
                                ? colorScheme.surfaceContainer
                                : AppTheme.darkBackground),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedPeriod == period
                            ? Colors.transparent
                            : (isLight ? colorScheme.outlineVariant : AppTheme.accent),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      period.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedPeriod == period ? FontWeight.w600 : FontWeight.normal,
                            color: _selectedPeriod == period
                                ? AppTheme.card
                                : (isLight ? colorScheme.onSurfaceVariant : AppTheme.accent),
                      ),
                    ),
                  ),
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
        padding: const EdgeInsets.all(AppTheme.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_periodLabel,
                style: AppTheme.labelSmall.copyWith(fontSize: 12)),
            const SizedBox(height: AppTheme.s16),

            NetProfitCard(
              netProfit: data.netProfit,
              style: NetProfitCardStyle.accentBar,
            ),
            const SizedBox(height: AppTheme.s12),

            // Detail cards grid
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Pendapatan',
                    amount: data.totalIncome,
                    icon: Icons.trending_up_rounded,
                    color: AppTheme.profitColorTheme(context),
                  ),
                ),
                const SizedBox(width: AppTheme.s12),
                Expanded(
                  child: SummaryCard(
                    title: 'HPP',
                    amount: data.totalCogs,
                    icon: Icons.inventory_rounded,
                    color: AppTheme.warningColorTheme(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.s12),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Laba Kotor',
                    amount: data.grossProfit,
                    icon: Icons.monetization_on_rounded,
                    color: AppTheme.infoColorTheme(context),
                  ),
                ),
                const SizedBox(width: AppTheme.s12),
                Expanded(
                  child: SummaryCard(
                    title: 'Pengeluaran',
                    amount: data.totalExpense,
                    icon: Icons.trending_down_rounded,
                    color: AppTheme.lossColorTheme(context),
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


