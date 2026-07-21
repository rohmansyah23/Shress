import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/finance_bar_chart.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_providers.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recent_selected_businesses_provider.dart';
import '../auth/login_screen.dart';
import 'user_management_panel.dart';
import '../transaction/transaction_sheet.dart';
import '../settings/settings_screen.dart';
import 'send_notification_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import 'owner_debtors_screen.dart';
import 'owner_consignors_screen.dart';
import 'owner_category_management_screen.dart';

import '../../core/theme/app_icon_size.dart';

enum TrendTypeFilter {
  netProfit('Laba/Rugi Bersih'),
  income('Uang Masuk'),
  expense('Uang Keluar');

  final String label;
  const TrendTypeFilter(this.label);
}

final recentTransactionsProvider = FutureProvider.family<List<TransactionModel>, String>((ref, businessIdsKey) async {
  ref.watch(transactionRefreshProvider);
  if (businessIdsKey.isEmpty) return [];
  final businessIds = businessIdsKey.split(',').map(int.parse).toList();
  return await SupabaseService.instance.getTransactionsPage(
    businessId: 0,
    offset: 0,
    limit: 5,
    businessIds: businessIds,
  );
});

class OwnerDashboardTab extends ConsumerStatefulWidget {
  final dynamic user;
  final bool showAppBar;
  final void Function(int index)? onTabSwitch;

  const OwnerDashboardTab({
    super.key,
    required this.user,
    this.showAppBar = true,
    this.onTabSwitch,
  });

  @override
  ConsumerState<OwnerDashboardTab> createState() => _OwnerDashboardTabState();
}

class _OwnerDashboardTabState extends ConsumerState<OwnerDashboardTab> {
  TrendFilter _selectedTrendFilter = TrendFilter.daily;
  TrendTypeFilter _selectedTypeFilter = TrendTypeFilter.netProfit;

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(allBusinessesProvider);

    final body = businessesAsync.when(
      data: (businesses) {
        final allIds = businesses.map((b) => b.businessId).toList()..sort();
        final idsKey = allIds.join(',');
        final trendAsync = ref.watch(
          allBusinessesNetProfitsTrendProvider((
            businessIdsKey: idsKey,
            filter: _selectedTrendFilter,
          )),
        );
        final recentTransactionsAsync = ref.watch(recentTransactionsProvider(idsKey));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allBusinessesProvider);
            ref.invalidate(recentTransactionsProvider);
            for (final id in allIds) {
              ref.invalidate(businessSummaryProvider(id));
            }
            ref.invalidate(allBusinessesNetProfitsTrendProvider);
            ref.invalidate(combinedBusinessSummaryProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Text(
                'Halo, ${widget.user.displayName ?? widget.user.username}',
                style: AppTheme.heading2,
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Owner • ${businesses.length} bisnis',
                style: AppTheme.caption,
              ),
              const SizedBox(height: AppSpacing.s12),

              _buildTotalNetProfit(businesses),
              const SizedBox(height: AppSpacing.s12),
              _buildFinanceOtherSummary(businesses),
              const SizedBox(height: AppSpacing.s16),

              Text('Menu Lainnya', style: AppTheme.heading3),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.add_circle_rounded,
                      label: 'Tambah\nTransaksi',
                      color: AppTheme.infoColorTheme(context),
                      onTap: () {
                        _pickBusinessAndAdd(context, businesses);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.receipt_long_rounded,
                      label: 'Piutang',
                      color: AppTheme.warningColorTheme(context),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerDebtorsScreen(businesses: businesses),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.inventory_2_rounded,
                      label: 'Titipan',
                      color: AppTheme.consignmentColorTheme(context),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerConsignorsScreen(businesses: businesses),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.category_rounded,
                      label: 'Kelola\nKategori',
                      color: AppTheme.warningColorTheme(context),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerCategoryManagementScreen(businesses: businesses),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.people_rounded,
                      label: 'Kelola\nUser',
                      color: AppTheme.infoColorTheme(context),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UserManagementPanel(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.notifications_active_outlined,
                      label: 'Kirim\nPesan',
                      color: AppTheme.lossColorTheme(context),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SendNotificationScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.settings_rounded,
                      label: 'Pengaturan',
                      color: AppTheme.infoColorTheme(context),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),

              // === Trend Chart dengan Filter ===
              Text('Tren Keuangan', style: AppTheme.heading3),
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TrendFilter>(
                      initialValue: _selectedTrendFilter,
                      isDense: true,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s6,
                        ),
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
                    child: DropdownButtonFormField<TrendTypeFilter>(
                      initialValue: _selectedTypeFilter,
                      isDense: true,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s6,
                        ),
                        isDense: true,
                        labelText: 'Tipe Grafik',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      items: TrendTypeFilter.values
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
                      case TrendTypeFilter.netProfit:
                        val = d.netProfit;
                        break;
                      case TrendTypeFilter.income:
                        val = d.income;
                        break;
                      case TrendTypeFilter.expense:
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
                  if (_selectedTypeFilter == TrendTypeFilter.income) {
                    customBarColor = AppTheme.profitChartColor(context);
                  } else if (_selectedTypeFilter == TrendTypeFilter.expense) {
                    customBarColor = AppTheme.lossChartColor(context);
                  }

                  return FinanceBarChart(
                    isWeekly: _selectedTrendFilter == TrendFilter.weekly,
                    data: barPoints,
                    title: chartTitle,
                    barColor: customBarColor,
                    tooltipColorBuilder: (val) {
                      if (_selectedTypeFilter == TrendTypeFilter.income) {
                        return AppTheme.profitChartColor(context);
                      } else if (_selectedTypeFilter == TrendTypeFilter.expense) {
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
              const SizedBox(height: AppSpacing.s24),
              Text(
                'Transaksi Terbaru',
                style: AppTheme.heading3,
              ),
              const SizedBox(height: AppSpacing.s12),
              recentTransactionsAsync.when(
                data: (recentTransactions) {
                  if (recentTransactions.isEmpty) {
                    return Card(
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
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: List.generate(recentTransactions.length, (i) {
                      final tx = recentTransactions[i];
                      final isIncome = tx.type == AppConstants.typeIncome;
                      final bizName = businesses.firstWhere(
                        (b) => b.businessId == tx.businessId,
                        orElse: () => BusinessModel(
                          businessId: tx.businessId,
                          name: 'Bisnis',
                        ),
                      ).name;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i < recentTransactions.length - 1 ? 8.0 : 0.0,
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
                                    color: (isIncome
                                            ? AppTheme.profitColorTheme(context)
                                            : AppTheme.lossColorTheme(context))
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
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
                                        bizName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        FormatHelpers.displayDateWithTime(tx.transactionDate, tx.createdAt),
                                        style: AppTheme.caption.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (tx.description?.isNotEmpty == true) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          tx.description!,
                                          style: AppTheme.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.s24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    child: Text(
                      'Gagal memuat transaksi',
                      style: TextStyle(color: AppTheme.lossColorTheme(context)),
                    ),
                  ),
                ),
              ),
              if (businesses.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.history_rounded, size: AppIconSize.s18),
                    label: const Text('Lihat Semua'),
                    onPressed: () {
                      widget.onTabSwitch?.call(1);
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorRetryWidget(
        message: ErrorHandler.classify(error).userMessage,
        onRetry: () => ref.invalidate(allBusinessesProvider),
      ),
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  Widget _buildTotalNetProfit(List<BusinessModel> businesses) {
    final allIds = businesses.map((b) => b.businessId).toList()..sort();
    if (allIds.isEmpty) return const SizedBox.shrink();
    final idsKey = allIds.join(',');

    final combinedAsync = ref.watch(combinedBusinessSummaryProvider(idsKey));
    return combinedAsync.when(
      data: (summary) {
        final total = (summary['netProfit'] as num?)?.toDouble() ?? 0;
        return NetProfitCard(
          netProfit: total,
          style: NetProfitCardStyle.row,
          title: 'Total Laba / Rugi Bersih',
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  // Removed unused _buildEmptyBusinesses helper method.

  void _pickBusinessAndAdd(
    BuildContext context,
    List<BusinessModel> businesses,
  ) {
    if (businesses.isEmpty) return;
    if (businesses.length == 1) {
      TransactionSheet.show(context, businesses.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            final double keyboardHeight = MediaQuery.of(dialogCtx).viewInsets.bottom;
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (sheetCtx, scrollController) {
                return Material(
                  color: AppTheme.surfaceColorTheme(sheetCtx),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.radiusMedium),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: keyboardHeight),
                    child: _BusinessSelectorSheetContent(
                      businesses: businesses,
                      scrollController: scrollController,
                      parentContext: context,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Removed unused _pickBusinessAndManageCategories helper method.

  Widget _buildFinanceOtherSummary(List<BusinessModel> businesses) {
    if (businesses.isEmpty) return const SizedBox.shrink();

    final allIds = businesses.map((b) => b.businessId).toList()..sort();

    return Row(
      children: [
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future:
                Future.wait(
                  allIds.map(
                    (id) => SupabaseService.instance.getDebtSummary(id),
                  ),
                ).then((summaries) {
                  double totalOwed = 0;
                  int activeCount = 0;
                  for (final s in summaries) {
                    totalOwed += (s['totalOwed'] as num?)?.toDouble() ?? 0;
                    activeCount += (s['activeCount'] as int?) ?? 0;
                  }
                  return {'totalOwed': totalOwed, 'activeCount': activeCount};
                }),
            builder: (context, snapshot) {
              final totalOwed =
                  (snapshot.data?['totalOwed'] as num?)?.toDouble() ?? 0;
              final activeCount = (snapshot.data?['activeCount'] as int?) ?? 0;
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OwnerDebtorsScreen(businesses: businesses),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: AppIconSize.s18,
                              color: AppTheme.warningColorTheme(context),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Flexible(
                              child: Text(
                                'Piutang Aktif',
                                style: AppTheme.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          FormatHelpers.rupiah(totalOwed),
                          style: AppTheme.amountMedium.copyWith(
                            color: AppTheme.warningColorTheme(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          '$activeCount hutang aktif',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future:
                Future.wait(
                  allIds.map(
                    (id) => SupabaseService.instance.getConsignmentSummary(id),
                  ),
                ).then((summaries) {
                  double totalOwed = 0;
                  int activeCount = 0;
                  for (final s in summaries) {
                    totalOwed += (s['totalOwed'] as num?)?.toDouble() ?? 0;
                    activeCount += (s['activeCount'] as int?) ?? 0;
                  }
                  return {'totalOwed': totalOwed, 'activeCount': activeCount};
                }),
            builder: (context, snapshot) {
              final totalOwed =
                  (snapshot.data?['totalOwed'] as num?)?.toDouble() ?? 0;
              final activeCount = (snapshot.data?['activeCount'] as int?) ?? 0;
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OwnerConsignorsScreen(businesses: businesses),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_rounded,
                              size: AppIconSize.s18,
                              color: AppTheme.consignmentColorTheme(context),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Flexible(
                              child: Text(
                                'Titipan Aktif',
                                style: AppTheme.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          FormatHelpers.rupiah(totalOwed),
                          style: AppTheme.amountMedium.copyWith(
                            color: AppTheme.consignmentColorTheme(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          '$activeCount titipan aktif',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Removed unused _pickBusinessForPiutang and _pickBusinessForTitipan helper methods.

  String _trendFilterLabel(TrendFilter filter) {
    return switch (filter) {
      TrendFilter.daily => 'Harian',
      TrendFilter.weekly => 'Mingguan',
      TrendFilter.monthly => 'Bulanan',
      TrendFilter.yearly => 'Tahunan',
    };
  }
}

// Removed unused _BusinessCardWithSummary widget.

class _BusinessSelectorSheetContent extends ConsumerStatefulWidget {
  final List<BusinessModel> businesses;
  final ScrollController scrollController;
  final BuildContext parentContext;

  const _BusinessSelectorSheetContent({
    required this.businesses,
    required this.scrollController,
    required this.parentContext,
  });

  @override
  ConsumerState<_BusinessSelectorSheetContent> createState() =>
      _BusinessSelectorSheetContentState();
}

class _BusinessSelectorSheetContentState
    extends ConsumerState<_BusinessSelectorSheetContent> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentIds = ref.watch(recentSelectedBusinessesProvider);

    // Filter recent businesses based on the current list of businesses
    final recentBusinesses = recentIds
        .map((id) => widget.businesses.firstWhere(
              (b) => b.businessId == id,
              orElse: () => BusinessModel(businessId: -1, name: ''),
            ))
        .where((b) => b.businessId != -1)
        .toList();

    // Filter all businesses based on search query
    final filteredBusinesses = widget.businesses.where((b) {
      return b.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Handle bar indicator
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          'Pilih Bisnis untuk Transaksi',
          style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceColorTheme(context),
            ),
            decoration: InputDecoration(
              hintText: 'Cari nama bisnis...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
        const SizedBox(height: 8),

        // Recent Businesses (Chips)
        if (recentBusinesses.isNotEmpty && _searchQuery.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sering Digunakan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariantColorTheme(context),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              itemCount: recentBusinesses.length,
              itemBuilder: (context, index) {
                final b = recentBusinesses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    avatar: Icon(
                      Icons.history_rounded,
                      size: 14,
                      color: AppTheme.primaryColorTheme(context),
                    ),
                    label: Text(
                      b.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                    ),
                    backgroundColor: AppTheme.surfaceContainerColorTheme(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                      side: BorderSide(
                        color: AppTheme.outlineColorTheme(context).withValues(alpha: 0.15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // Update SharedPreferences recent selections
                      ref.read(recentSelectedBusinessesProvider.notifier).addBusiness(b.businessId);
                      TransactionSheet.show(widget.parentContext, b);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 16),
        ],

        // All Businesses List
        Expanded(
          child: filteredBusinesses.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_rounded,
                          size: 40,
                          color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bisnis tidak ditemukan',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.onSurfaceVariantColorTheme(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                  itemCount: filteredBusinesses.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final b = filteredBusinesses[i];
                    return ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColorTheme(context).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          size: 16,
                          color: AppTheme.primaryColorTheme(context),
                        ),
                      ),
                      title: Text(
                        b.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceColorTheme(context),
                        ),
                      ),
                      subtitle: b.description != null && b.description!.isNotEmpty
                          ? Text(
                              b.description!,
                              style: AppTheme.caption.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(recentSelectedBusinessesProvider.notifier).addBusiness(b.businessId);
                        TransactionSheet.show(widget.parentContext, b);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
