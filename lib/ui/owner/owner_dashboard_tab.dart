import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../auth/login_screen.dart';
import '../business_detail/business_detail_screen.dart';
import '../transaction/transaction_history_screen.dart';

/// Owner Dashboard Tab — shows all businesses, summary, and quick actions.
/// With working transaction history and financial reports (no more "Coming Soon").
class OwnerDashboardTab extends ConsumerWidget {
  final dynamic user;

  const OwnerDashboardTab({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final businessesAsync = ref.watch(allBusinessesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSRS Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {                  Navigator.of(context).pushAndRemoveUntil(
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
          ref.invalidate(allBusinessesProvider);
          ref.invalidate(transactionRefreshProvider);
        },
        child: businessesAsync.when(
          data: (businesses) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, ${user.username}', style: AppTheme.heading2),
                const SizedBox(height: 4),
                Text('Owner • Overview semua bisnis', style: AppTheme.caption),
                const SizedBox(height: 24),

                Text('Semua Bisnis', style: AppTheme.heading3),
                const SizedBox(height: 12),

                if (businesses.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Belum ada bisnis. Tambahkan melalui Supabase Dashboard.',
                          textAlign: TextAlign.center,
                          style: AppTheme.caption,
                        ),
                      ),
                    ),
                  )
                else
                  for (final business in businesses)
                    OwnerBusinessCard(
                      business: business,
                      colorScheme: colorScheme,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BusinessDetailScreen(business: business),
                          ),
                        );
                      },
                    ),

                const SizedBox(height: 32),

                Text('Aksi Cepat', style: AppTheme.heading3),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OwnerQuickActionCard(
                        icon: Icons.history_rounded,
                        label: 'Riwayat Transaksi',
                        color: AppTheme.infoColor,
                        onTap: () {
                          if (businesses.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Belum ada bisnis')),
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TransactionHistoryScreen(
                                business: businesses.first,
                                isOwnerView: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OwnerQuickActionCard(
                        icon: Icons.assessment_rounded,
                        label: 'Laporan Keuangan',
                        color: AppTheme.profitColor,
                        onTap: () {
                          if (businesses.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Belum ada bisnis')),
                            );
                            return;
                          }
                          // Navigate to the report tab (index 2 in OwnerShell)
                          // Since we're already inside OwnerShell, we show a business picker
                          _showBusinessPicker(context, businesses);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          loading: () => const SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 120, height: 22),
                SizedBox(height: 4),
                SkeletonLine(width: 180, height: 12),
                SizedBox(height: 24),
                SkeletonLine(width: 100, height: 18),
                SizedBox(height: 12),
                SkeletonBusinessList(),
              ],
            ),
          ),
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

  void _showBusinessPicker(BuildContext context, List<BusinessModel> businesses) {
    if (businesses.length == 1) {
      // Only one business, go directly to transaction history
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TransactionHistoryScreen(business: businesses.first),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Bisnis', style: AppTheme.heading3),
            const SizedBox(height: 16),
            ...businesses.map((b) => ListTile(
                  leading: Icon(Icons.store_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(b.name),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionHistoryScreen(business: b),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class OwnerBusinessCard extends StatelessWidget {
  final BusinessModel business;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const OwnerBusinessCard({
    super.key,
    required this.business,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                child:
                    Icon(Icons.store_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: AppTheme.heading3),
                    const SizedBox(height: 4),
                    Text('ID: ${business.businessId}',
                        style: AppTheme.caption),
                  ],
                ),
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

class OwnerQuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const OwnerQuickActionCard({
    super.key,
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
