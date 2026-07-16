import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/finance_bar_chart.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/business_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../transaction/transaction_sheet.dart';
import '../debtors/debtors_screen.dart';
import '../consignments/consignors_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

enum _TrendTypeFilter {
  netProfit('Laba/Rugi Bersih'),
  income('Uang Masuk'),
  expense('Uang Keluar');

  final String label;
  const _TrendTypeFilter(this.label);
}

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  final BusinessModel selectedBusiness;
  final List<BusinessModel> businesses;
  final bool showAppBar;
  final VoidCallback onSwitchBusiness;
  final VoidCallback onShowQris;
  final VoidCallback? onNavigateToRiwayat;

  const ManagerDashboardScreen({
    super.key,
    required this.selectedBusiness,
    required this.businesses,
    this.showAppBar = true,
    required this.onSwitchBusiness,
    required this.onShowQris,
    this.onNavigateToRiwayat,
  });

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> {
  List<TransactionModel> _recentTransactions = [];
  bool _recentLoading = true;
  TrendFilter _selectedTrendFilter = TrendFilter.daily;
  _TrendTypeFilter _selectedTypeFilter = _TrendTypeFilter.netProfit;

  @override
  void initState() {
    super.initState();
    _loadRecentTransactions();
  }

  @override
  void didUpdateWidget(ManagerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBusiness.businessId !=
        widget.selectedBusiness.businessId) {
      _loadRecentTransactions();
    }
  }

  Future<void> _loadRecentTransactions() async {
    setState(() => _recentLoading = true);
    try {
      final allTx = await SupabaseService.instance.getTransactionsByBusiness(
        widget.selectedBusiness.businessId,
      );
      if (mounted) {
        setState(() {
          _recentTransactions = allTx.take(5).toList();
          _recentLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _recentLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(transactionRefreshProvider, (prev, next) {
      if (prev != null && prev != next) _loadRecentTransactions();
    });
    final currentUser = ref.watch(currentUserProvider);
    final isManager = currentUser?.role == AppConstants.roleManager;
    final summaryAsync = ref.watch(
      businessSummaryProvider(widget.selectedBusiness.businessId),
    );
    final trendAsync = isManager
        ? ref.watch(
            businessNetProfitsTrendProvider((
              businessId: widget.selectedBusiness.businessId,
              filter: _selectedTrendFilter,
            )),
          )
        : null;

    final body = summaryAsync.when(
      data: (summary) {
        final netProfit = summary['netProfit'] ?? 0;
        final isProfit = netProfit >= 0;
        return _buildContent(summary, netProfit, isProfit, trendAsync, isManager);
      },
      loading: () => _buildLoadingState(),
      error: (error, _) => ErrorRetryWidget(
        message: ErrorHandler.classify(error).userMessage,
        onRetry: () => ref.invalidate(
          businessSummaryProvider(widget.selectedBusiness.businessId),
        ),
      ),
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(title: Text(widget.selectedBusiness.name)),
      body: body,
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent(
    Map<String, double> summary,
    double netProfit,
    bool isProfit,
    AsyncValue<List<({String period, double income, double expense, double netProfit})>>? trendAsync,
    bool isManager,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          businessSummaryProvider(widget.selectedBusiness.businessId),
        );
        await _loadRecentTransactions();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        children: [
          _buildBusinessHeader(),
          const SizedBox(height: AppSpacing.s12),
          _buildNetProfitCard(netProfit, isProfit),
          const SizedBox(height: AppSpacing.s12),
          if (isManager) ...[
            // === Trend Chart ===
            Text('Tren Keuangan', style: AppTheme.heading3),
            const SizedBox(height: AppSpacing.s8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TrendFilter>(
                    initialValue: _selectedTrendFilter,
                    isDense: true,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                      isDense: true,
                      labelText: 'Periode Waktu',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                    items: TrendFilter.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              _trendFilterLabel(f),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.onSurfaceColorTheme(context),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedTrendFilter = value);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: DropdownButtonFormField<_TrendTypeFilter>(
                    initialValue: _selectedTypeFilter,
                    isDense: true,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                      isDense: true,
                      labelText: 'Tipe Grafik',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                    items: _TrendTypeFilter.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              f.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.onSurfaceColorTheme(context),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedTypeFilter = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            trendAsync!.when(
              data: (trendData) {
                if (trendData.isEmpty) {
                  return SizedBox(
                    height: 160,
                    child: Center(
                      child: Text('Belum ada data grafik', style: AppTheme.caption),
                    ),
                  );
                }
                final barPoints = trendData
                    .map((d) {
                      double val = 0;
                      switch (_selectedTypeFilter) {
                        case _TrendTypeFilter.netProfit:
                          val = d.netProfit;
                          break;
                        case _TrendTypeFilter.income:
                          val = d.income;
                          break;
                        case _TrendTypeFilter.expense:
                          val = d.expense;
                          break;
                      }
                      return FinanceBarDataPoint(
                        period: d.period,
                        value: val,
                      );
                    })
                    .toList();
                final timeLabel = _selectedTrendFilter == TrendFilter.daily
                    ? '7 Hari Terakhir'
                    : _selectedTrendFilter == TrendFilter.weekly
                        ? '5 Minggu Terakhir'
                        : _selectedTrendFilter == TrendFilter.monthly
                            ? '6 Bulan Terakhir'
                            : '5 Tahun Terakhir';

                Color? customBarColor;
                if (_selectedTypeFilter == _TrendTypeFilter.income) {
                  customBarColor = AppTheme.profitChartColor(context);
                } else if (_selectedTypeFilter == _TrendTypeFilter.expense) {
                  customBarColor = AppTheme.lossChartColor(context);
                }

                return FinanceBarChart(
                  isWeekly: _selectedTrendFilter == TrendFilter.weekly,
                  data: barPoints,
                  title: 'Tren ${_selectedTypeFilter.label} ($timeLabel)',
                  barColor: customBarColor,
                  tooltipColorBuilder: (val) {
                    if (_selectedTypeFilter == _TrendTypeFilter.income) {
                      return AppTheme.profitChartColor(context);
                    } else if (_selectedTypeFilter == _TrendTypeFilter.expense) {
                      return AppTheme.lossChartColor(context);
                    }
                    return val >= 0
                        ? AppTheme.profitChartColor(context)
                        : AppTheme.lossChartColor(context);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => SizedBox(
                height: 160,
                child: Center(
                  child: Text('Gagal memuat grafik', style: AppTheme.caption),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          Text('Aksi Cepat', style: AppTheme.heading3),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  icon: Icons.trending_up_rounded,
                  label: 'Uang\nMasuk',
                  color: AppTheme.profitColorTheme(context),
                  onTap: () => TransactionSheet.show(
                    context,
                    widget.selectedBusiness,
                    startAsIncome: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.trending_down_rounded,
                  label: 'Uang\nKeluar',
                  color: AppTheme.lossColorTheme(context),
                  onTap: () => TransactionSheet.show(
                    context,
                    widget.selectedBusiness,
                    startAsIncome: false,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.qr_code_rounded,
                  label: 'QRIS',
                  color: AppTheme.infoColorTheme(context),
                  onTap: widget.onShowQris,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Hutang',
                  color: AppTheme.warningColor,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DebtorsScreen(business: widget.selectedBusiness),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.inventory_2_rounded,
                  label: 'Titipan',
                  color: AppTheme.secondaryColor,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ConsignorsScreen(business: widget.selectedBusiness),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          _buildDebtConsignmentSummary(widget.selectedBusiness.businessId),
          const SizedBox(height: AppSpacing.s12),
          Text('Transaksi Terbaru', style: AppTheme.heading3),
          const SizedBox(height: AppSpacing.s12),
          if (_recentLoading)
            ...List.generate(
              3,
              (_) => const Center(child: CircularProgressIndicator()),
            )
          else if (_recentTransactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: AppIconSize.s48,
                        color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      const Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        'Tap tombol + untuk mencatat transaksi pertama',
                        style: AppTheme.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...List.generate(_recentTransactions.length, (i) {
              final tx = _recentTransactions[i];
              final isIncome = tx.type == AppConstants.typeIncome;
              return FadeInEntrance(
                delay: Duration(milliseconds: i * 50),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i < _recentTransactions.length - 1 ? 8 : 0,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  (isIncome
                                          ? AppTheme.profitColorTheme(context)
                                          : AppTheme.lossColorTheme(context))
                                      .withValues(alpha: 0.12),                               borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: isIncome
                                  ? AppTheme.profitColorTheme(context)
                                  : AppTheme.lossColorTheme(context),
                              size: AppIconSize.s20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FormatHelpers.displayDateWithTime(tx.transactionDate, tx.createdAt),
                                  style: AppTheme.caption.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                                if (tx.description?.isNotEmpty == true)
                                  Text(
                                    tx.description!,
                                    style: AppTheme.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            FormatHelpers.rupiah(tx.amount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isIncome
                                  ? AppTheme.profitColorTheme(context)
                                  : AppTheme.lossColorTheme(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: AppSpacing.s8),
          if (_recentTransactions.length >= 5)
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.history_rounded, size: AppIconSize.s18),
                label: const Text('Lihat Semua'),
                onPressed: widget.onNavigateToRiwayat ?? () {},
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.accentColorTheme(context) : AppTheme.profitColorTheme(context);
    return Card(
      child: InkWell(
        onTap: widget.businesses.length > 1 ? widget.onSwitchBusiness : null,
        splashColor: (isDark ? AppTheme.accent : AppTheme.primary).withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
        highlightColor: (isDark ? AppTheme.accent : AppTheme.primary)
            .withValues(alpha: isDark ? 0.08 : 0.04),
        hoverColor: (isDark ? AppTheme.accent : AppTheme.primary).withValues(
          alpha: isDark ? 0.06 : 0.02,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                  gradient: LinearGradient(
                    colors: [
                      isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                      isDark ? AppTheme.accent : AppTheme.primary,
                      (isDark ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.1, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: (isDark ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.05),
                            blurRadius: 2,
                            spreadRadius: -1,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: (isDark ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.18),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: AppIconSize.s24,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selectedBusiness.name,
                      style: AppTheme.heading3,
                    ),
                    if (widget.selectedBusiness.description != null &&
                        widget.selectedBusiness.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        widget.selectedBusiness.description!,
                        style: AppTheme.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s2,
                          ),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusLarge,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: AppIconSize.s10,
                                color: activeColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: activeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.businesses.length > 1) ...[
                          const SizedBox(width: AppSpacing.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s8,
                              vertical: AppSpacing.s2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHighestColorTheme(context).withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.radiusLarge,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz_rounded, size: AppIconSize.s10),
                                SizedBox(width: 3),
                                Text(
                                  'Ganti',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.businesses.length > 1)
                Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariantColorTheme(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetProfitCard(double netProfit, bool isProfit) {
    return NetProfitCard(netProfit: netProfit, style: NetProfitCardStyle.row);
  }

  Widget _buildDebtConsignmentSummary(int businessId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([
        SupabaseService.instance.getDebtSummary(businessId),
        SupabaseService.instance.getConsignmentSummary(businessId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final debtSummary = snapshot.data![0];
        final consignmentSummary = snapshot.data![1];
        final debtOwed = (debtSummary['totalOwed'] as num?)?.toDouble() ?? 0;
        final debtCount = (debtSummary['activeCount'] as int?) ?? 0;
        final consOwed =
            (consignmentSummary['totalOwed'] as num?)?.toDouble() ?? 0;
        final consCount = (consignmentSummary['activeCount'] as int?) ?? 0;

        if (debtOwed == 0 && consOwed == 0) return const SizedBox.shrink();

        return Row(
          children: [
            if (debtOwed > 0)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: AppIconSize.s14,
                  color: AppTheme.warningColorTheme(context),
                            ),
                            const SizedBox(width: AppSpacing.s4),
                            Text(
                              'Piutang',
                              style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          FormatHelpers.rupiah(debtOwed),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warningColor,
                          ),
                        ),
                        Text(
                          '$debtCount aktif',
                          style: AppTheme.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (debtOwed > 0 && consOwed > 0)
              const SizedBox(width: AppSpacing.s8),
            if (consOwed > 0)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_rounded,
                              size: AppIconSize.s14,
                  color: AppTheme.secondaryColorTheme(context),
                            ),
                            const SizedBox(width: AppSpacing.s4),
                            Text(
                              'Titipan',
                              style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          FormatHelpers.rupiah(consOwed),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        Text(
                          '$consCount aktif',
                          style: AppTheme.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _trendFilterLabel(TrendFilter filter) {
    return switch (filter) {
      TrendFilter.daily => 'Harian',
      TrendFilter.weekly => 'Mingguan',
      TrendFilter.monthly => 'Bulanan',
      TrendFilter.yearly => 'Tahunan',
    };
  }
}
