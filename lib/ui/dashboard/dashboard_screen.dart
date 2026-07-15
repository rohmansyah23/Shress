import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/finance_bar_chart.dart';
import '../../core/network/connectivity_service.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/business_providers.dart';
import '../transaction/transaction_sheet.dart';
import '../transaction/transaction_history_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

enum DashboardTrendTypeFilter {
  netProfit('Laba/Rugi Bersih'),
  income('Uang Masuk'),
  expense('Uang Keluar');

  final String label;
  const DashboardTrendTypeFilter(this.label);
}

class DashboardScreen extends ConsumerStatefulWidget {
  final BusinessModel business;
  final bool showAppBar;
  final VoidCallback? onNavigateToRiwayat;
  final VoidCallback? onBack;

  const DashboardScreen({
    super.key,
    required this.business,
    this.showAppBar = true,
    this.onNavigateToRiwayat,
    this.onBack,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  TrendFilter _selectedTrendFilter = TrendFilter.daily;
  DashboardTrendTypeFilter _selectedTypeFilter = DashboardTrendTypeFilter.netProfit;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(
      businessSummaryProvider(widget.business.businessId),
    );
    final trendAsync = ref.watch(
      businessNetProfitsTrendProvider((
        businessId: widget.business.businessId,
        filter: _selectedTrendFilter,
      )),
    );

    final body = summaryAsync.when(
      data: (summary) {
        final isTrendLoading = trendAsync.isLoading;
        return _buildContent(summary, trendAsync, isTrendLoading);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        final appError = error is AppError
            ? error
            : ErrorHandler.classify(error);
        return ErrorRetryWidget.fromAppError(
          appError,
          onRetry: () {
            ref.invalidate(businessSummaryProvider(widget.business.businessId));
            ref.invalidate(businessNetProfitsTrendProvider);
          },
        );
      },
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Kembali',
                onPressed: widget.onBack,
              )
            : null,
        title: Text(widget.business.name),
      ),
      body: body,
    );
  }

  Widget _buildContent(
    Map<String, double> summary,
    AsyncValue<List<({String period, double income, double expense, double netProfit})>> trendAsync,
    bool isTrendLoading,
  ) {
    final netProfit = summary['netProfit'] ?? 0;

    return Column(
      children: [
        Consumer(
          builder: (context, ref, _) {
            final isOnline = ref.watch(isOnlineProvider);
            return OfflineBanner(
              isOffline: !isOnline,
              onRetry: () {
                ref.invalidate(
                  businessSummaryProvider(widget.business.businessId),
                );
                ref.invalidate(businessNetProfitsTrendProvider);
              },
            );
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                businessSummaryProvider(widget.business.businessId),
              );
              ref.invalidate(businessNetProfitsTrendProvider);
              await Future.wait([
                ref.read(
                  businessSummaryProvider(widget.business.businessId).future,
                ),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NetProfitCard(
                    netProfit: netProfit,
                    style: NetProfitCardStyle.row,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Pendapatan',
                          amount: summary['totalIncome'] ?? 0,
                          icon: Icons.trending_up_rounded,
                          color: AppTheme.profitColorTheme(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: SummaryCard(
                          title: 'HPP (COGS)',
                          amount: summary['totalCogs'] ?? 0,
                          icon: Icons.inventory_rounded,
                          color: AppTheme.warningColorTheme(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Laba Kotor',
                          amount: summary['grossProfit'] ?? 0,
                          icon: Icons.monetization_on_rounded,
                          color: AppTheme.infoColorTheme(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: SummaryCard(
                          title: 'Pengeluaran',
                          amount: summary['totalExpense'] ?? 0,
                          icon: Icons.trending_down_rounded,
                          color: AppTheme.lossColorTheme(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),

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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.s12,
                              vertical: AppSpacing.s8,
                            ),
                            isDense: true,
                            labelText: 'Periode Waktu',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.onSurfaceColorTheme(context),
                          ),
                          items: TrendFilter.values
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(
                                    _trendFilterLabel(f),
                                    style: AppTheme.labelSmall.copyWith(
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
                        child: DropdownButtonFormField<DashboardTrendTypeFilter>(
                          initialValue: _selectedTypeFilter,
                          isDense: true,
                          borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.s12,
                              vertical: AppSpacing.s8,
                            ),
                            isDense: true,
                            labelText: 'Tipe Grafik',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.onSurfaceColorTheme(context),
                          ),
                          items: DashboardTrendTypeFilter.values
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(
                                    f.label,
                                    style: AppTheme.labelSmall.copyWith(
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
                  const SizedBox(height: AppSpacing.s16),
                  trendAsync.when(
                    data: (trendData) {
                      if (trendData.isEmpty) {
                        return SizedBox(
                          height: 160,
                          child: Center(
                            child: Text(
                              'Belum ada data grafik',
                              style: AppTheme.caption,
                            ),
                          ),
                        );
                      }

                      final barPoints = trendData.map((d) {
                        double val = 0;
                        switch (_selectedTypeFilter) {
                          case DashboardTrendTypeFilter.netProfit:
                            val = d.netProfit;
                            break;
                          case DashboardTrendTypeFilter.income:
                            val = d.income;
                            break;
                          case DashboardTrendTypeFilter.expense:
                            val = d.expense;
                            break;
                        }
                        return FinanceBarDataPoint(
                          period: d.period,
                          value: val,
                        );
                      }).toList();

                      final timeLabel = _selectedTrendFilter == TrendFilter.daily
                          ? '7 Hari Terakhir'
                          : _selectedTrendFilter == TrendFilter.weekly
                          ? '5 Minggu Terakhir'
                          : _selectedTrendFilter == TrendFilter.monthly
                          ? '6 Bulan Terakhir'
                          : '5 Tahun Terakhir';
                      final chartTitle = 'Tren ${_selectedTypeFilter.label} ($timeLabel)';

                      Color? customBarColor;
                      if (_selectedTypeFilter == DashboardTrendTypeFilter.income) {
                        customBarColor = AppTheme.profitChartColor(context);
                      } else if (_selectedTypeFilter == DashboardTrendTypeFilter.expense) {
                        customBarColor = AppTheme.lossChartColor(context);
                      }

                      return FinanceBarChart(
                        data: barPoints,
                        title: chartTitle,
                        barColor: customBarColor,
                        tooltipColorBuilder: (val) {
                          if (_selectedTypeFilter == DashboardTrendTypeFilter.income) {
                            return AppTheme.profitChartColor(context);
                          } else if (_selectedTypeFilter == DashboardTrendTypeFilter.expense) {
                            return AppTheme.lossChartColor(context);
                          }
                          return val >= 0
                              ? AppTheme.profitChartColor(context)
                              : AppTheme.lossChartColor(context);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => SizedBox(
                      height: 160,
                      child: Center(
                        child: Text(
                          'Gagal memuat grafik',
                          style: AppTheme.caption,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),

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
                            widget.business,
                            startAsIncome: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.trending_down_rounded,
                          label: 'Uang\nKeluar',
                          color: AppTheme.lossColorTheme(context),
                          onTap: () => TransactionSheet.show(
                            context,
                            widget.business,
                            startAsIncome: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.history_rounded,
                          label: 'Riwayat\nTransaksi',
                          color: AppTheme.infoColorTheme(context),
                          onTap: () {
                            if (widget.onNavigateToRiwayat != null) {
                              widget.onNavigateToRiwayat!();
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TransactionHistoryScreen(
                                    business: widget.business,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
