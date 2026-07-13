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
import '../../providers/business_providers.dart';
import '../../providers/transaction_provider.dart';
import '../transaction/transaction_sheet.dart';
import '../debtors/debtors_screen.dart';
import '../consignments/consignors_screen.dart';

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
    final cs = Theme.of(context).colorScheme;
    final summaryAsync = ref.watch(
      businessSummaryProvider(widget.selectedBusiness.businessId),
    );

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

  Widget _buildLoadingState(ColorScheme cs) {
    return const Center(child: CircularProgressIndicator());
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
          businessSummaryProvider(widget.selectedBusiness.businessId),
        );
        await _loadRecentTransactions();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.s16,
          AppTheme.s12,
          AppTheme.s16,
          AppTheme.s16,
        ),
        children: [
          _buildBusinessHeader(cs),
          const SizedBox(height: AppTheme.s12),
          _buildNetProfitCard(netProfit, isProfit),
          const SizedBox(height: AppTheme.s12),
          Text('Aksi Cepat', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.s12),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: AppTheme.s12),
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
              const SizedBox(width: 10),
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
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: AppTheme.s12),
          _buildDebtConsignmentSummary(widget.selectedBusiness.businessId),
          const SizedBox(height: AppTheme.s12),
          Text('Transaksi Terbaru', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.s12),
          if (_recentLoading)
            ...List.generate(
              3,
              (_) => const Center(child: CircularProgressIndicator()),
            )
          else if (_recentTransactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.s24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: AppTheme.s12),
                      const Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.s4),
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
                      padding: const EdgeInsets.all(12),
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
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: isIncome
                                  ? AppTheme.profitColorTheme(context)
                                  : AppTheme.lossColorTheme(context),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppTheme.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FormatHelpers.displayDate(tx.transactionDate),
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
          const SizedBox(height: AppTheme.s8),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: InkWell(
        onTap: widget.businesses.length > 1 ? widget.onSwitchBusiness : null,
        splashColor: (isDark ? AppTheme.accent : AppTheme.primary).withValues(
          alpha: 0.15,
        ),
        highlightColor: (isDark ? AppTheme.accent : AppTheme.primary)
            .withValues(alpha: 0.08),
        hoverColor: (isDark ? AppTheme.accent : AppTheme.primary).withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.s16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkDivider
                      : AppTheme.secondaryBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: isDark ? AppTheme.accent : AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.s12),
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
                    const SizedBox(height: AppTheme.s4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.profitColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 10,
                                color: AppTheme.profitColor,
                              ),
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
                          const SizedBox(width: AppTheme.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
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
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
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
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 14,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Piutang',
                              style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.s4),
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
              const SizedBox(width: AppTheme.s8),
            if (consOwed > 0)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_rounded,
                              size: 14,
                              color: AppTheme.secondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Titipan',
                              style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.s4),
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
}
