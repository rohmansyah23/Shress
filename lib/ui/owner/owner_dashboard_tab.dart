import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../core/widgets/trend_chart.dart';
import '../../data/local/models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_providers.dart';
import '../../providers/transaction_provider.dart';
import '../auth/login_screen.dart';
import '../dashboard/qris_upload_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'business_owner_shell.dart';
import 'create_business_screen.dart';
import 'user_management_panel.dart';
import '../reports/owner_report_screen.dart';
import '../transaction/transaction_sheet.dart';

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
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final businessesAsync = ref.watch(allBusinessesProvider);

    final body = businessesAsync.when(
      data: (businesses) {
        final allIds = businesses.map((b) => b.businessId).toList()..sort();
        final idsKey = allIds.join(',');
        final trendAsync = ref.watch(allMonthlyNetProfitsProvider(idsKey));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allBusinessesProvider);
            for (final id in allIds) {
              ref.invalidate(businessSummaryProvider(id));
            }
            ref.invalidate(allMonthlyNetProfitsProvider(idsKey));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Halo, ${widget.user.username}',
                  style: AppTheme.heading2),
              const SizedBox(height: 4),
              Text('Owner • ${businesses.length} bisnis',
                  style: AppTheme.caption),
              const SizedBox(height: 24),

              _buildTotalNetProfit(businesses),
              const SizedBox(height: 24),

              // === Trend Chart ===
              if (trendAsync.hasValue &&
                  trendAsync.value!.isNotEmpty) ...[
                TrendChart(
                  data: trendAsync.value!
                      .map((d) => TrendDataPoint(
                          month: d.month, netProfit: d.netProfit))
                      .toList(),
                  title: 'Tren Laba/Rugi Semua Bisnis',
                ),
                const SizedBox(height: 24),
              ],

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
                            builder: (_) => BusinessOwnerShell(
                              business: businesses[i],
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
                      icon: Icons.add_business_rounded,
                      label: 'Tambah\nBisnis',
                      color: AppTheme.profitColor,
                      onTap: () async {
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.people_rounded,
                      label: 'Kelola\nUser',
                      color: AppTheme.warningColor,
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
                      icon: Icons.assessment_rounded,
                      label: 'Laporan',
                      color: AppTheme.profitColor,
                      onTap: () => widget.onTabSwitch?.call(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.settings_rounded,
                      label: 'Pengaturan',
                      color: AppTheme.infoColor,
                      onTap: () => widget.onTabSwitch?.call(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.qr_code_rounded,
                      label: 'Upload\nQRIS',
                      color: AppTheme.infoColor,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QrisUploadScreen(),
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
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'Upload QRIS',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const QrisUploadScreen()),
              );
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
      loading: () => const SkeletonNetProfitCardRow(),
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


