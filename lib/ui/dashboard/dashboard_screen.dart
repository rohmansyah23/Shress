import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../core/network/connectivity_service.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../transaction/transaction_sheet.dart';
import '../transaction/transaction_history_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final BusinessModel business;

  const DashboardScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(business.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Riwayat Transaksi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      TransactionHistoryScreen(business: business),
                ),
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
      body: _DashboardContent(business: business),
    );
  }
}

class _DashboardContent extends ConsumerStatefulWidget {
  final BusinessModel business;

  const _DashboardContent({required this.business});

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  Map<String, double> _summary = {
    'totalIncome': 0,
    'totalCogs': 0,
    'grossProfit': 0,
    'totalExpense': 0,
    'netProfit': 0,
  };
  bool _isLoading = true;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.watch(transactionRefreshProvider);
    ref.watch(isOnlineProvider);
    if (!_isLoading && _error == null) {
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final summary = await SupabaseService.instance
          .getBusinessSummary(widget.business.businessId);
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is AppError ? e : ErrorHandler.classify(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SkeletonDashboard();
    }

    if (_error != null) {
      return ErrorRetryWidget.fromAppError(
        _error!,
        onRetry: _loadSummary,
      );
    }

    final netProfit = _summary['netProfit'] ?? 0;
    final isProfit = netProfit >= 0;

    return Column(
      children: [
        Consumer(builder: (context, ref, _) {
          final isOnline = ref.watch(isOnlineProvider);
          return OfflineBanner(isOffline: !isOnline, onRetry: _loadSummary);
        }),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSummary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: isProfit
                        ? AppTheme.profitColor.withValues(alpha: 0.1)
                        : AppTheme.lossColor.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text('Laba / Rugi Bersih', style: AppTheme.labelSmall),
                          const SizedBox(height: 8),
                          Text(FormatHelpers.rupiah(netProfit),
                            style: AppTheme.amountLarge.copyWith(
                              color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isProfit ? 'LABA' : 'RUGI',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 11,
                                fontWeight: FontWeight.bold, letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _DetailCard(title: 'Pendapatan', amount: _summary['totalIncome'] ?? 0, icon: Icons.trending_up_rounded, color: AppTheme.profitColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _DetailCard(title: 'HPP (COGS)', amount: _summary['totalCogs'] ?? 0, icon: Icons.inventory_rounded, color: AppTheme.warningColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _DetailCard(title: 'Laba Kotor', amount: _summary['grossProfit'] ?? 0, icon: Icons.monetization_on_rounded, color: AppTheme.infoColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _DetailCard(title: 'Pengeluaran', amount: _summary['totalExpense'] ?? 0, icon: Icons.trending_down_rounded, color: AppTheme.lossColor)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Aksi Cepat', style: AppTheme.heading3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _ActionButton(icon: Icons.trending_up_rounded, label: 'Uang\nMasuk', color: AppTheme.profitColor, onTap: () => TransactionSheet.show(context, widget.business))),
                      const SizedBox(width: 12),
                      Expanded(child: _ActionButton(icon: Icons.trending_down_rounded, label: 'Uang\nKeluar', color: AppTheme.lossColor, onTap: () => TransactionSheet.show(context, widget.business))),
                      const SizedBox(width: 12),
                      Expanded(child: _ActionButton(icon: Icons.history_rounded, label: 'Riwayat\nTransaksi', color: AppTheme.infoColor, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionHistoryScreen(business: widget.business))))),
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

class _DetailCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _DetailCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 6), Text(title, style: AppTheme.labelSmall)]),
            const SizedBox(height: 12),
            Text(FormatHelpers.rupiah(amount), style: AppTheme.amountMedium.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: AppTheme.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}
