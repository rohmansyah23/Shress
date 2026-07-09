import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/models/business_model.dart';
import '../business_switcher/business_switcher_screen.dart';
import '../business_detail/business_detail_screen.dart';
import '../transaction/transaction_history_screen.dart';

/// Owner Dashboard Tab — shows all businesses and quick actions
class OwnerDashboardTab extends ConsumerWidget {
  final dynamic user;

  const OwnerDashboardTab({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final db = LocalDatabase.instance;
    final businesses = db.getAllBusinesses();

    return SingleChildScrollView(
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
                      builder: (_) => BusinessDetailScreen(business: business),
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
                  icon: Icons.business_rounded,
                  label: 'Lihat Semua\nBisnis',
                  color: colorScheme.primary,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusinessSwitcherScreen()));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OwnerQuickActionCard(
                  icon: Icons.assessment_rounded,
                  label: 'Laporan\nKeuangan',
                  color: AppTheme.profitColor,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan - coming soon')));
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          OwnerQuickActionCard(
            icon: Icons.history_rounded,
            label: 'Riwayat\nTransaksi',
            color: AppTheme.infoColor,
            onTap: () {
              if (businesses.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada bisnis')));
                return;
              }
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionHistoryScreen(business: businesses.first)));
            },
          ),
        ],
      ),
    );
  }
}

/// Business card used in the Owner dashboard
class OwnerBusinessCard extends StatelessWidget {
  final BusinessModel business;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const OwnerBusinessCard({super.key, required this.business, required this.colorScheme, required this.onTap});

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
                child: Icon(Icons.store_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: AppTheme.heading3),
                    const SizedBox(height: 4),
                    Text('ID: ${business.businessId}', style: AppTheme.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action card for the Owner dashboard
class OwnerQuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const OwnerQuickActionCard({super.key, required this.icon, required this.label, required this.color, required this.onTap});

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
              Text(label, textAlign: TextAlign.center, style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}
