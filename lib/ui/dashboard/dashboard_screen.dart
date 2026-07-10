import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../core/widgets/trend_chart.dart';
import '../../core/network/connectivity_service.dart';
import '../../data/local/models/business_model.dart';
import '../../providers/auth_provider.dart';
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
  @override
  Widget build(BuildContext context) {
    final summaryAsync =
        ref.watch(businessSummaryProvider(widget.business.businessId));
    final trendAsync =
        ref.watch(monthlyNetProfitsProvider(widget.business.businessId));

    final body = summaryAsync.when(
      data: (summary) {
        final trendData = trendAsync.asData?.value;
        final isTrendLoading = trendAsync.isLoading;
        return _buildContent(summary, trendData, isTrendLoading);
      },
      loading: () => const SkeletonDashboard(),
      error: (error, _) {
        final appError =
            error is AppError ? error : ErrorHandler.classify(error);
        return ErrorRetryWidget.fromAppError(
          appError,
          onRetry: () {
            ref.invalidate(businessSummaryProvider(widget.business.businessId));
            ref.invalidate(monthlyNetProfitsProvider(widget.business.businessId));
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
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Riwayat Transaksi',
            onPressed: () {
              if (widget.onNavigateToRiwayat != null) {
                widget.onNavigateToRiwayat!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TransactionHistoryScreen(business: widget.business),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildContent(
    Map<String, double> summary,
    List<({String month, double netProfit})>? trendData,
    bool isTrendLoading,
  ) {
    final netProfit = summary['netProfit'] ?? 0;

    return Column(
      children: [
        Consumer(builder: (context, ref, _) {
          final isOnline = ref.watch(isOnlineProvider);
          return OfflineBanner(
            isOffline: !isOnline,
            onRetry: () {
              ref.invalidate(
                  businessSummaryProvider(widget.business.businessId));
              ref.invalidate(
                  monthlyNetProfitsProvider(widget.business.businessId));
            },
          );
        }),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                  businessSummaryProvider(widget.business.businessId));
              ref.invalidate(
                  monthlyNetProfitsProvider(widget.business.businessId));
              await Future.wait([
                ref.read(
                    businessSummaryProvider(widget.business.businessId).future),
                ref.read(
                    monthlyNetProfitsProvider(widget.business.businessId).future),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: SummaryCard(
                              title: 'Pendapatan',
                              amount: summary['totalIncome'] ?? 0,
                              icon: Icons.trending_up_rounded,
                              color: AppTheme.profitColor)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: SummaryCard(
                              title: 'HPP (COGS)',
                              amount: summary['totalCogs'] ?? 0,
                              icon: Icons.inventory_rounded,
                              color: AppTheme.warningColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: SummaryCard(
                              title: 'Laba Kotor',
                              amount: summary['grossProfit'] ?? 0,
                              icon: Icons.monetization_on_rounded,
                              color: AppTheme.infoColor)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: SummaryCard(
                              title: 'Pengeluaran',
                              amount: summary['totalExpense'] ?? 0,
                              icon: Icons.trending_down_rounded,
                              color: AppTheme.lossColor)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // === Trend Chart ===
                  if (!isTrendLoading &&
                      trendData != null &&
                      trendData.isNotEmpty) ...[
                    TrendChart(
                      data: trendData
                          .map((d) => TrendDataPoint(
                              month: d.month, netProfit: d.netProfit))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

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
                                  context, widget.business,
                                  startAsIncome: true))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: QuickActionButton(
                              icon: Icons.trending_down_rounded,
                              label: 'Uang\nKeluar',
                              color: AppTheme.lossColor,
                              onTap: () => TransactionSheet.show(
                                  context, widget.business,
                                  startAsIncome: false))),
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
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => TransactionHistoryScreen(
                                  business: widget.business)));
                        }
                      })),
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
}


