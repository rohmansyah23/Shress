import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

/// Provider for businesses accessible by the current user
final accessibleBusinessesProvider = FutureProvider<List<BusinessModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final db = LocalDatabase.instance;
  final role = user.role;

  if (role == 'owner') {
    return db.getAllBusinesses();
  }

  // Manager/Staff: get businesses from user_businesses bridge
  final userBusinesses = db.getBusinessesForUser(user.userId);
  final businesses = <BusinessModel>[];
  for (final ub in userBusinesses) {
    final business = db.getBusinessById(ub.businessId);
    if (business != null) {
      businesses.add(business);
    }
  }
  return businesses;
});

/// Business Switcher Screen
/// Allows managers/staff to select which business they want to operate.
/// Owner sees all 3 businesses.
class BusinessSwitcherScreen extends ConsumerWidget {
  const BusinessSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(accessibleBusinessesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Bisnis'),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: businessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada bisnis tersedia',
                    style: AppTheme.heading3.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hubungi Owner untuk mendapatkan akses',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final business = businesses[index];
              return _BusinessCard(
                business: business,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(business: business),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error',
              style: const TextStyle(color: AppTheme.lossColor)),
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback onTap;

  const _BusinessCard({
    required this.business,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Business icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Business info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: AppTheme.heading3,
                    ),
                    if (business.description != null &&
                        business.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        business.description!,
                        style: AppTheme.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
