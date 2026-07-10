import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/business_providers.dart';
import '../transaction/transaction_sheet.dart';

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
      final allTx = await SupabaseService.instance
          .getTransactionsByBusiness(widget.selectedBusiness.businessId);
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
    final cs = Theme.of(context).colorScheme;
    final summaryAsync = ref.watch(
        businessSummaryProvider(widget.selectedBusiness.businessId));

    final body = summaryAsync.when(
      data: (summary) {
        final netProfit = summary['netProfit'] ?? 0;
        final isProfit = netProfit >= 0;
        return _buildContent(cs, summary, netProfit, isProfit);
      },
      loading: () => _buildLoadingState(cs),
      error: (error, _) => ErrorRetryWidget(
        message: ErrorHandler.classify(error).userMessage,
        onRetry: () => ref.invalidate(
            businessSummaryProvider(widget.selectedBusiness.businessId)),
      ),
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedBusiness.name),
      ),
      body: body,
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildBusinessHeader(cs),
        const SizedBox(height: 24),
        const SkeletonNetProfitCardRow(),
        const SizedBox(height: 16),
        Text('Aksi Cepat', style: AppTheme.heading3),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            3,
            (_) => const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SkeletonActionButton(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Transaksi Terbaru', style: AppTheme.heading3),
        const SizedBox(height: 12),
        ...List.generate(3, (_) => const SkeletonTransactionItem()),
      ],
    );
  }

  Widget _buildContent(
    ColorScheme cs,
    Map<String, double> summary,
    double netProfit,
    bool isProfit,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
            businessSummaryProvider(widget.selectedBusiness.businessId));
        await _loadRecentTransactions();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildBusinessHeader(cs),
          const SizedBox(height: 24),
          _buildNetProfitCard(netProfit, isProfit),
          const SizedBox(height: 16),
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
                    context, widget.selectedBusiness,
                    startAsIncome: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.trending_down_rounded,
                  label: 'Uang\nKeluar',
                  color: AppTheme.lossColor,
                  onTap: () => TransactionSheet.show(
                    context, widget.selectedBusiness,
                    startAsIncome: false,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.qr_code_rounded,
                  label: 'QRIS',
                  color: AppTheme.infoColor,
                  onTap: widget.onShowQris,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Transaksi Terbaru', style: AppTheme.heading3),
          const SizedBox(height: 12),
          if (_recentLoading)
            ...List.generate(3, (_) => const SkeletonTransactionItem())
          else if (_recentTransactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 48,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                      bottom: i < _recentTransactions.length - 1 ? 8 : 0),
                  child: Card(
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
                                style: AppTheme.caption
                                    .copyWith(fontSize: 11),
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
                                ? AppTheme.profitColor
                                : AppTheme.lossColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (_recentTransactions.length >= 5)
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Lihat Semua'),
                onPressed: widget.onNavigateToRiwayat ?? () {},
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessHeader(ColorScheme cs) {
    return InkWell(
      onTap: widget.businesses.length > 1 ? widget.onSwitchBusiness : null,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.store_rounded,
                    color: cs.primary, size: 24),
              ),
              const SizedBox(width: 12),
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
                      const SizedBox(height: 2),
                      Text(
                        widget.selectedBusiness.description!,
                        style: AppTheme.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.profitColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 10,
                                  color: AppTheme.profitColor),
                              SizedBox(width: 3),
                              Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.profitColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.businesses.length > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz_rounded, size: 10),
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
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetProfitCard(double netProfit, bool isProfit) {
    return NetProfitCard(
      netProfit: netProfit,
      style: NetProfitCardStyle.row,
    );
  }
}


