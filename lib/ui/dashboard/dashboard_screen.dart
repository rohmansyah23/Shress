import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/constants.dart';
import '../../core/qris/qris_resolver.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../auth/login_screen.dart';
import '../transaction/transaction_sheet.dart';
import '../ledger/profit_loss_sheet.dart';

/// Provider for business transactions summary
final businessSummaryProvider =
    FutureProvider.family<Map<String, double>, int>((ref, businessId) async {
  // Watch for refresh triggers (e.g., after saving a transaction)
  ref.watch(transactionRefreshProvider);
  final db = LocalDatabase.instance;
  final transactions = db.getTransactionsByBusiness(businessId);

  double totalIncome = 0;
  double totalCogs = 0;
  double totalExpense = 0;

  for (final tx in transactions) {
    if (tx.type == AppConstants.typeIncome) {
      totalIncome += tx.amount;
      totalCogs += tx.cogs;
    } else if (tx.type == AppConstants.typeExpense) {
      totalExpense += tx.amount;
    }
  }

  return {
    'totalIncome': totalIncome,
    'totalCogs': totalCogs,
    'grossProfit': totalIncome - totalCogs,
    'totalExpense': totalExpense,
    'netProfit': (totalIncome - totalCogs) - totalExpense,
  };
});

/// Active Store Dashboard Screen
class DashboardScreen extends ConsumerWidget {
  final BusinessModel business;

  const DashboardScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = LocalDatabase.instance;
    final unsyncedCount = db.getUnsyncedTransactions().length;
    final summaryAsync = ref.watch(businessSummaryProvider(business.businessId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(business.name),
        actions: [
          // QRIS button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Lihat QRIS',
            onPressed: () => _showQrisOverlay(context),
          ),
          // Logout
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
      body: RefreshIndicator(
        onRefresh: () async {
          await SyncService.instance.triggerSync();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sync banner
              if (unsyncedCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync_problem_rounded,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$unsyncedCount transaksi menunggu sinkronisasi',
                          style: const TextStyle(
                            color: AppTheme.warningColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => SyncService.instance.triggerSync(),
                        child: const Text('Sync'),
                      ),
                    ],
                  ),
                ),

              // Summary cards
              summaryAsync.when(
                data: (summary) => _buildSummaryCards(summary, colorScheme),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Gagal memuat data',
                        style: AppTheme.caption,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick action buttons
              Text('Aksi Cepat', style: AppTheme.heading3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.trending_up_rounded,
                      label: 'Uang\nMasuk',
                      color: AppTheme.profitColor,
                      onTap: () => TransactionSheet.show(context, business),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.trending_down_rounded,
                      label: 'Uang\nKeluar',
                      color: AppTheme.lossColor,
                      onTap: () => TransactionSheet.show(context, business),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.assessment_rounded,
                      label: 'Laporan\nLaba/Rugi',
                      color: AppTheme.infoColor,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfitLossSheet(business: business),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
      Map<String, double> summary, ColorScheme colorScheme) {
    return Column(
      children: [
        // Net Profit card (large, prominent)
        Card(
          color: summary['netProfit']! >= 0
              ? AppTheme.profitColor.withValues(alpha: 0.1)
              : AppTheme.lossColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Laba / Rugi Bersih',
                  style: AppTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatRupiah(summary['netProfit']!),
                  style: AppTheme.amountLarge.copyWith(
                    color: summary['netProfit']! >= 0
                        ? AppTheme.profitColor
                        : AppTheme.lossColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: summary['netProfit']! >= 0
                        ? AppTheme.profitColor
                        : AppTheme.lossColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    summary['netProfit']! >= 0 ? 'LABA' : 'RUGI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Detail cards grid
        Row(
          children: [
            Expanded(
              child: _DetailCard(
                title: 'Pendapatan',
                amount: summary['totalIncome']!,
                icon: Icons.trending_up_rounded,
                color: AppTheme.profitColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DetailCard(
                title: 'HPP (COGS)',
                amount: summary['totalCogs']!,
                icon: Icons.inventory_rounded,
                color: AppTheme.warningColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DetailCard(
                title: 'Laba Kotor',
                amount: summary['grossProfit']!,
                icon: Icons.monetization_on_rounded,
                color: AppTheme.infoColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DetailCard(
                title: 'Pengeluaran',
                amount: summary['totalExpense']!,
                icon: Icons.trending_down_rounded,
                color: AppTheme.lossColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatRupiah(double amount) => FormatHelpers.rupiah(amount);

  void _showQrisOverlay(BuildContext context) {
    final qrisSource = QrisResolver.getQrisSource(business);

    if (qrisSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QRIS belum tersedia untuk bisnis ini'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isLocal = QrisResolver.isLocalAsset(qrisSource);
    final hasLocalQris = QrisResolver.getLocalAssetPath(business.businessId) != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 460,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header with offline indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code, size: 28, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'QRIS Pembayaran',
                  style: AppTheme.heading3,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              business.name,
              style: AppTheme.caption.copyWith(fontSize: 13),
            ),
            if (hasLocalQris) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.profitColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_bolt_rounded, size: 12, color: AppTheme.profitColor),
                    SizedBox(width: 4),
                    Text(
                      'Tersedia offline',
                      style: TextStyle(fontSize: 10, color: AppTheme.profitColor),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // QRIS Image
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: isLocal
                    ? SvgPicture.asset(
                        qrisSource,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => const SizedBox.shrink(),
                      )
                    : Image.network(
                        qrisSource,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan untuk melakukan pembayaran',
              style: AppTheme.caption,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.grey.shade100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code, size: 80, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'QRIS Tidak Tersedia',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
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
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(title, style: AppTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              FormatHelpers.rupiah(amount),
              style: AppTheme.amountMedium.copyWith(color: color),
            ),
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
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(
                  fontSize: 12,
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
