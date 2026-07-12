import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/trend_chart.dart';
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
import '../debtors/debtors_screen.dart';
import '../consignments/consignors_screen.dart';

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
  ConsumerState<OwnerDashboardTab> createState() =>
      _OwnerDashboardTabState();
}

class _OwnerDashboardTabState extends ConsumerState<OwnerDashboardTab> {
  TrendFilter _selectedTrendFilter = TrendFilter.daily;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final businessesAsync = ref.watch(allBusinessesProvider);

    final body = businessesAsync.when(
      data: (businesses) {
        final allIds = businesses.map((b) => b.businessId).toList()..sort();
        final idsKey = allIds.join(',');
        final trendAsync = ref.watch(allBusinessesNetProfitsTrendProvider((
          businessIdsKey: idsKey,
          filter: _selectedTrendFilter,
        )));

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
            padding: const EdgeInsets.all(16),
            children: [
              Text('Halo, ${widget.user.displayName ?? widget.user.username}',
                  style: AppTheme.heading2),
              const SizedBox(height: 4),
              Text('Owner • ${businesses.length} bisnis',
                  style: AppTheme.caption),
              const SizedBox(height: 24),

              _buildTotalNetProfit(businesses),
              const SizedBox(height: 24),

              // === Trend Chart dengan Filter ===
              Text('Tren Keuangan', style: AppTheme.heading3),
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
                    return const SizedBox(
                      height: 160,
                      child: Center(child: Text('Belum ada data grafik', style: AppTheme.caption)),
                    );
                  }
                  return TrendChart(
                    data: trendData
                        .map((d) => TrendDataPoint(
                            month: d.period, netProfit: d.netProfit))
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => const SizedBox(
                  height: 160,
                  child: Center(child: Text('Gagal memuat grafik', style: AppTheme.caption)),
                ),
              ),
              const SizedBox(height: 24),

              Text('Bisnis Saya', style: AppTheme.heading3),
              const SizedBox(height: 12),

              if (businesses.isEmpty)
                _buildEmptyBusinesses()
              else ...[
                for (int i = 0; i < businesses.length; i++) ...[
                  FadeInEntrance(
                    delay: Duration(milliseconds: i * 50),
                    child: _BusinessCardWithSummary(
                      business: businesses[i],
                      colorScheme: colorScheme,
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
                  const SizedBox(height: 12),
                ],
              ],

              const SizedBox(height: 16),
              _buildFinanceOtherSummary(businesses),
              const SizedBox(height: 16),
              Text('Menu Lainnya', style: AppTheme.heading3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.add_circle_rounded,
                      label: 'Tambah\nTransaksi',
                      color: AppTheme.infoColor,
                      onTap: () {
                        _pickBusinessAndAdd(context, businesses);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.receipt_long_rounded,
                      label: 'Piutang',
                      color: AppTheme.warningColor,
                      onTap: () {
                        _pickBusinessForPiutang(context, businesses);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.inventory_2_rounded,
                       label: 'Titipan',
                      color: AppTheme.secondaryColor,
                      onTap: () {
                        _pickBusinessForTitipan(context, businesses);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.store_rounded,
                      label: 'Kelola\nBisnis',
                      color: AppTheme.profitColor,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.category_rounded,
                      label: 'Kelola\nKategori',
                      color: AppTheme.warningColor,
                      onTap: () {
                        _pickBusinessAndManageCategories(context, businesses);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.people_rounded,
                      label: 'Kelola\nUser',
                      color: AppTheme.infoColor,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.settings_rounded,
                      label: 'Pengaturan',
                      color: AppTheme.infoColor,
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
              const SizedBox(height: 24),
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
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.store_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selamat datang di Sheress!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum memiliki bisnis.\nBuat bisnis pertama Anda atau ikuti panduan\nuntuk memulai.',
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                  label: const Text('Panduan Cepat'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.add_business_rounded, size: 18),
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

  void _pickBusinessAndAdd(BuildContext context, List<BusinessModel> businesses) {
    if (businesses.isEmpty) return;
    if (businesses.length == 1) {
      TransactionSheet.show(context, businesses.first);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _pickBusinessAndManageCategories(BuildContext context, List<BusinessModel> businesses) {
    if (businesses.isEmpty) {
      ErrorSnackbar.showWarning(
          context, 'Tambahkan bisnis terlebih dahulu');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    builder: (_) => CategoryManagementScreen(business: businesses[i]),
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
            future: Future.wait(allIds.map((id) =>
                    SupabaseService.instance.getDebtSummary(id)))
                .then((summaries) {
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
              final activeCount =
                  (snapshot.data?['activeCount'] as int?) ?? 0;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 18, color: AppTheme.warningColor),
                          const SizedBox(width: 6),
                          Text('Piutang Aktif', style: AppTheme.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(FormatHelpers.rupiah(totalOwed),
                          style: AppTheme.amountMedium
                              .copyWith(color: AppTheme.warningColor)),
                      const SizedBox(height: 4),
                      Text('$activeCount hutang aktif',
                          style: AppTheme.caption),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: Future.wait(allIds.map((id) =>
                    SupabaseService.instance.getConsignmentSummary(id)))
                .then((summaries) {
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
              final activeCount =
                  (snapshot.data?['activeCount'] as int?) ?? 0;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2_rounded,
                              size: 18, color: AppTheme.secondaryColor),
                          const SizedBox(width: 6),
                          Text('Titipan Aktif',
                              style: AppTheme.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(FormatHelpers.rupiah(totalOwed),
                          style: AppTheme.amountMedium
                              .copyWith(color: AppTheme.secondaryColor)),
                      const SizedBox(height: 4),
                      Text('$activeCount titipan aktif',
                          style: AppTheme.caption),
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
      BuildContext context, List<BusinessModel> businesses) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    builder: (_) =>
                        DebtorsScreen(business: businesses[i]),
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
      BuildContext context, List<BusinessModel> businesses) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    builder: (_) =>
                        ConsignorsScreen(business: businesses[i]),
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

  Widget _buildTrendFilterChip(String label, TrendFilter value) {
    final isSelected = _selectedTrendFilter == value;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _selectedTrendFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BusinessCardWithSummary extends ConsumerWidget {
  final BusinessModel business;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onLaporan;

  const _BusinessCardWithSummary({
    required this.business,
    required this.colorScheme,
    required this.onTap,
    required this.onLaporan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(businessSummaryProvider(business.businessId));

    final netProfit = summaryAsync.asData?.value['netProfit'] as num?;
    final isLoading = summaryAsync.isLoading;
    final isProfit = netProfit != null && netProfit >= 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.store_rounded,
                    color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: AppTheme.heading3),
                    const SizedBox(height: 4),
                    if (isLoading)
                      const Text('Memuat...',
                          style: TextStyle(fontSize: 12))
                    else
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isProfit
                                  ? AppTheme.profitColor
                                  : AppTheme.lossColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            netProfit != null
                                ? 'Laba/Rugi: ${FormatHelpers.rupiah(netProfit.toDouble())}'
                                : 'Belum ada data',
                            style: TextStyle(
                              fontSize: 12,
                              color: isProfit
                                  ? AppTheme.profitColor
                                  : AppTheme.lossColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.bar_chart_rounded,
                    color: AppTheme.profitColor),
                tooltip: 'Laporan',
                onPressed: onLaporan,
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}


