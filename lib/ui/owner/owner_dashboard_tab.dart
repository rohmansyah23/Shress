import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../auth/login_screen.dart';
import '../dashboard/qris_upload_screen.dart';
import 'business_owner_shell.dart';
import '../reports/owner_report_screen.dart';
import '../transaction/transaction_sheet.dart';
class OwnerDashboardTab extends ConsumerStatefulWidget {
  final dynamic user;
  final void Function(int index)? onTabSwitch;

  const OwnerDashboardTab({
    super.key,
    required this.user,
    this.onTabSwitch,
  });

  @override
  ConsumerState<OwnerDashboardTab> createState() =>
      _OwnerDashboardTabState();
}

class _OwnerDashboardTabState extends ConsumerState<OwnerDashboardTab> {
  Map<int, double> _netProfits = {};
  bool _loadingSummaries = true;

  @override
  void initState() {
    super.initState();
    _loadNetProfits();
  }

  Future<void> _loadNetProfits() async {
    setState(() => _loadingSummaries = true);
    try {
      final businesses = await SupabaseService.instance
          .getAccessibleBusinesses(widget.user.userId, widget.user.role);
      final Map<int, double> profits = {};

      for (final b in businesses) {
        final s = await SupabaseService.instance
            .getBusinessSummary(b.businessId);
        profits[b.businessId] = s['netProfit'] ?? 0;
      }

      if (mounted) {
        setState(() {
          _netProfits = profits;
          _loadingSummaries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSummaries = false);
      }
    }
  }

  double get _totalNetProfit =>
      _netProfits.values.fold(0.0, (sum, v) => sum + v);

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

  Widget _buildTotalSummary() {
    if (_loadingSummaries) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final isProfit = _totalNetProfit >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isProfit
                        ? AppTheme.profitColor
                        : AppTheme.lossColor)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isProfit
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: isProfit
                    ? AppTheme.profitColor
                    : AppTheme.lossColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Laba / Rugi Bersih',
                      style: AppTheme.caption.copyWith(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    FormatHelpers.rupiah(_totalNetProfit),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isProfit
                          ? AppTheme.profitColor
                          : AppTheme.lossColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isProfit
                        ? AppTheme.profitColor
                        : AppTheme.lossColor)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isProfit ? 'LABA' : 'RUGI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isProfit
                      ? AppTheme.profitColor
                      : AppTheme.lossColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final businessesAsync = ref.watch(allBusinessesProvider);

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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allBusinessesProvider);
          ref.invalidate(transactionRefreshProvider);
          await _loadNetProfits();
        },
        child: businessesAsync.when(
          data: (businesses) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Halo, ${widget.user.username}',
                  style: AppTheme.heading2),
              const SizedBox(height: 4),
              Text('Owner • ${businesses.length} bisnis',
                  style: AppTheme.caption),
              const SizedBox(height: 24),

              _buildTotalSummary(),
              const SizedBox(height: 24),

              Text('Bisnis Saya', style: AppTheme.heading3),
              const SizedBox(height: 12),

              if (businesses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Belum ada bisnis.',
                        textAlign: TextAlign.center,
                        style: AppTheme.caption,
                      ),
                    ),
                  ),
                )
              else
                for (final business in businesses) ...[
                  _BusinessCard(
                    business: business,
                    netProfit: _netProfits[business.businessId],
                    isLoading: _loadingSummaries,
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BusinessOwnerShell(
                            business: business,
                          ),
                        ),
                      );
                    },
                    onLaporan: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OwnerReportScreen(
                            initialBusinessId: business.businessId,
                            initialPeriod: OwnerPeriodFilter.thisWeek,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

              const SizedBox(height: 16),
              Text('Akses Cepat', style: AppTheme.heading3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_circle_rounded,
                      label: 'Tambah Transaksi',
                      color: AppTheme.infoColor,
                      onTap: () {
                        _pickBusinessAndAdd(context, businesses);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.people_rounded,
                      label: 'Kelola User',
                      color: AppTheme.warningColor,
                      onTap: () => widget.onTabSwitch?.call(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.assessment_rounded,
                      label: 'Laporan',
                      color: AppTheme.profitColor,
                      onTap: () => widget.onTabSwitch?.call(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorRetryWidget(
            message: ErrorHandler.classify(error).userMessage,
            onRetry: () {
              ref.invalidate(allBusinessesProvider);
              ref.invalidate(transactionRefreshProvider);
            },
          ),
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessModel business;
  final double? netProfit;
  final bool isLoading;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onLaporan;

  const _BusinessCard({
    required this.business,
    required this.netProfit,
    required this.isLoading,
    required this.colorScheme,
    required this.onTap,
    required this.onLaporan,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = netProfit != null && netProfit! >= 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                                ? 'Laba/Rugi: ${FormatHelpers.rupiah(netProfit!)}'
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
                  color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
