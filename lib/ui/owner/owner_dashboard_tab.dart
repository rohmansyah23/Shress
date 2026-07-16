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
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_providers.dart';
import '../../providers/transaction_provider.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'create_business_screen.dart';
import 'user_management_panel.dart';
import '../reports/owner_report_screen.dart';
import '../transaction/transaction_sheet.dart';
import '../transaction/transaction_history_screen.dart';
import '../settings/settings_screen.dart';
import '../category/category_management_screen.dart';
import 'manage_businesses_screen.dart';
import 'send_notification_screen.dart';
import '../debtors/debtors_screen.dart';
import '../consignments/consignors_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

enum TrendTypeFilter {
  netProfit('Laba/Rugi Bersih'),
  income('Uang Masuk'),
  expense('Uang Keluar');

  final String label;
  const TrendTypeFilter(this.label);
}

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

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allBusinessesProvider);
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

              // === Trend Chart dengan Filter ===
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
              const SizedBox(height: AppSpacing.s12),

              Text('Bisnis Saya', style: AppTheme.heading3),
              const SizedBox(height: AppSpacing.s12),

              if (businesses.isEmpty)
                _buildEmptyBusinesses()
              else ...[
                for (int i = 0; i < businesses.length; i++) ...[
                  FadeInEntrance(
                    delay: Duration(milliseconds: i * 50),
                    child: _BusinessCardWithSummary(
                      business: businesses[i],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DashboardScreen(
                              business: businesses[i],
                              showAppBar: true,
                              onNavigateToRiwayat: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TransactionHistoryScreen(
                                      business: businesses[i],
                                      showAppBar: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      onLaporan: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerReportScreen(
                              initialBusinessId: businesses[i].businessId,
                              initialPeriod: OwnerPeriodFilter.thisWeek,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (i < businesses.length - 1)
                    const SizedBox(height: AppSpacing.s8),
                ],
              ],

              const SizedBox(height: AppSpacing.s8),
              _buildFinanceOtherSummary(businesses),
              const SizedBox(height: AppSpacing.s12),
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
                        _pickBusinessForPiutang(context, businesses);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.inventory_2_rounded,
                      label: 'Titipan',
                      color: AppTheme.secondaryColorTheme(context),
                      onTap: () {
                        _pickBusinessForTitipan(context, businesses);
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
                      icon: Icons.store_rounded,
                      label: 'Kelola\nBisnis',
                      color: AppTheme.profitColorTheme(context),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ManageBusinessesScreen(),
                          ),
                        );
                        ref.invalidate(allBusinessesProvider);
                        ref.invalidate(transactionRefreshProvider);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.category_rounded,
                      label: 'Kelola\nKategori',
                      color: AppTheme.warningColorTheme(context),
                      onTap: () {
                        _pickBusinessAndManageCategories(context, businesses);
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
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
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
                  const SizedBox(width: AppSpacing.s12),
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

  Widget _buildEmptyBusinesses() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainerColorTheme(context),
                borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              ),
              child: Icon(
                Icons.store_rounded,
                size: AppIconSize.s32,
                color: AppTheme.primaryColorTheme(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            const Text(
              'Selamat datang di Sheress!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Anda belum memiliki bisnis.\nBuat bisnis pertama Anda atau ikuti panduan\nuntuk memulai.',
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(height: 1.5),
            ),              const SizedBox(height: AppSpacing.s20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.rocket_launch_rounded, size: AppIconSize.s18),
                  label: const Text('Panduan Cepat'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.s12),
                FilledButton.icon(
                  icon: const Icon(Icons.add_business_rounded, size: AppIconSize.s18),
                  label: const Text('Buat Bisnis'),
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const CreateBusinessScreen(),
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(allBusinessesProvider);
                      ref.invalidate(transactionRefreshProvider);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pickBusinessAndAdd(
    BuildContext context,
    List<BusinessModel> businesses,
  ) {
    if (businesses.isEmpty) return;
    if (businesses.length == 1) {
      TransactionSheet.show(context, businesses.first);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Pilih Bisnis'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: businesses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.store_rounded),
              title: Text(businesses[i].name),
              onTap: () {
                Navigator.pop(ctx);
                TransactionSheet.show(context, businesses[i]);
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _pickBusinessAndManageCategories(
    BuildContext context,
    List<BusinessModel> businesses,
  ) {
    if (businesses.isEmpty) {
      ErrorSnackbar.showWarning(context, 'Tambahkan bisnis terlebih dahulu');
      return;
    }
    if (businesses.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryManagementScreen(business: businesses.first),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Pilih Bisnis'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: businesses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.store_rounded),
              title: Text(businesses[i].name),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CategoryManagementScreen(business: businesses[i]),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

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
                          Text('Piutang Aktif', style: AppTheme.labelSmall),
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
                            color: AppTheme.secondaryColorTheme(context),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Text('Titipan Aktif', style: AppTheme.labelSmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        FormatHelpers.rupiah(totalOwed),
                        style: AppTheme.amountMedium.copyWith(
                          color: AppTheme.secondaryColorTheme(context),
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
              );
            },
          ),
        ),
      ],
    );
  }

  void _pickBusinessForPiutang(
    BuildContext context,
    List<BusinessModel> businesses,
  ) {
    if (businesses.isEmpty) return;
    if (businesses.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DebtorsScreen(business: businesses.first),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Pilih Bisnis'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: businesses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: Text(businesses[i].name),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DebtorsScreen(business: businesses[i]),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _pickBusinessForTitipan(
    BuildContext context,
    List<BusinessModel> businesses,
  ) {
    if (businesses.isEmpty) return;
    if (businesses.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConsignorsScreen(business: businesses.first),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Pilih Bisnis'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: businesses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.inventory_2_rounded),
              title: Text(businesses[i].name),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConsignorsScreen(business: businesses[i]),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
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

class _BusinessCardWithSummary extends ConsumerWidget {
  final BusinessModel business;
  final VoidCallback onTap;
  final VoidCallback onLaporan;

  const _BusinessCardWithSummary({
    required this.business,
    required this.onTap,
    required this.onLaporan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(
      businessSummaryProvider(business.businessId),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final netProfit = summaryAsync.asData?.value['netProfit'] as num?;
    final isLoading = summaryAsync.isLoading;
    final isProfit = netProfit != null && netProfit >= 0;

    return Card(
      child: InkWell(

        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        onTap: onTap,
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
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: AppTheme.heading3),
                    const SizedBox(height: AppSpacing.s4),
                    if (isLoading)
                      const Text('Memuat...', style: TextStyle(fontSize: 12))
                    else
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isProfit
                                  ? AppTheme.profitColorTheme(context)
                                  : AppTheme.lossChartColor(context),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s6),
                          Text(
                            netProfit != null
                                ? 'Laba/Rugi: ${FormatHelpers.rupiah(netProfit.toDouble())}'
                                : 'Belum ada data',
                            style: TextStyle(
                              fontSize: 12,
                              color: isProfit
                                  ? AppTheme.profitColorTheme(context)
                                  : AppTheme.lossColorTheme(context),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.bar_chart_rounded,
                  color: netProfit != null
                      ? (isProfit
                          ? AppTheme.profitColorTheme(context)
                          : AppTheme.lossColorTheme(context))
                      : (isDark ? AppTheme.accent : AppTheme.primary),
                ),
                tooltip: 'Laporan',
                onPressed: onLaporan,
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceVariantColorTheme(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
