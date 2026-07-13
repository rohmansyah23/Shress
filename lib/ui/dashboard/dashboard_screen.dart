import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/trend_chart.dart';
import '../../core/network/connectivity_service.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/business_providers.dart';
import '../transaction/transaction_sheet.dart';
import '../transaction/transaction_history_screen.dart';

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
    AsyncValue<List<({String period, double netProfit})>> trendAsync,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NetProfitCard(
                    netProfit: netProfit,
                    style: NetProfitCardStyle.accentBar,
                  ),
                  const SizedBox(height: AppTheme.s12),
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
                      const SizedBox(width: AppTheme.s12),
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
                  const SizedBox(height: AppTheme.s12),
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
                      const SizedBox(width: AppTheme.s12),
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
                  const SizedBox(height: 24),

                  // === Trend Chart dengan Filter ===
                  Text('Tren Laba/Rugi', style: AppTheme.heading3),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTrendFilterChip('Harian', TrendFilter.daily),
                      const SizedBox(width: 8),
                      _buildTrendFilterChip('Mingguan', TrendFilter.weekly),
                      const SizedBox(width: 8),
                      _buildTrendFilterChip('Bulanan', TrendFilter.monthly),
                      const SizedBox(width: 8),
                      _buildTrendFilterChip('Tahunan', TrendFilter.yearly),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                      return TrendChart(
                        data: trendData
                            .map(
                              (d) => TrendDataPoint(
                                month: d.period,
                                netProfit: d.netProfit,
                              ),
                            )
                            .toList(),
                        title: _selectedTrendFilter == TrendFilter.daily
                            ? 'Tren Laba/Rugi 7 Hari Terakhir'
                            : _selectedTrendFilter == TrendFilter.weekly
                            ? 'Tren Laba/Rugi 5 Minggu Terakhir'
                            : _selectedTrendFilter == TrendFilter.monthly
                            ? 'Tren Laba/Rugi 6 Bulan Terakhir'
                            : 'Tren Laba/Rugi 5 Tahun Terakhir',
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
                  const SizedBox(height: 24),

                  Text('Aksi Cepat', style: AppTheme.heading3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.trending_up_rounded,
                          label: 'Uang\nMasuk',
                          color: AppTheme.profitColor,
                          onTap: () => TransactionSheet.show(
                            context,
                            widget.business,
                            startAsIncome: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.trending_down_rounded,
                          label: 'Uang\nKeluar',
                          color: AppTheme.lossColor,
                          onTap: () => TransactionSheet.show(
                            context,
                            widget.business,
                            startAsIncome: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.history_rounded,
                          label: 'Riwayat\nTransaksi',
                          color: AppTheme.infoColor,
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

  Widget _buildTrendFilterChip(String label, TrendFilter value) {
    final isSelected = _selectedTrendFilter == value;
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: () => setState(() => _selectedTrendFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight ? colorScheme.primary : AppTheme.accent)
              : (isLight
                    ? colorScheme.surfaceContainer
                    : AppTheme.darkBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isLight ? colorScheme.outlineVariant : AppTheme.accent),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? AppTheme.card
                : (isLight ? colorScheme.onSurfaceVariant : AppTheme.accent),
          ),
        ),
      ),
    );
  }
}
