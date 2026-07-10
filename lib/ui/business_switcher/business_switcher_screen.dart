import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

/// Business Switcher Screen
/// Allows managers/staff to select which business they want to operate.
class BusinessSwitcherScreen extends ConsumerWidget {
  const BusinessSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(accessibleBusinessesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Bisnis'),
        actions: [
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accessibleBusinessesProvider);
        },
        child: businessesAsync.when(
          data: (businesses) {
            if (businesses.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_rounded,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('Tidak ada bisnis tersedia',
                              style: AppTheme.heading3
                                  .copyWith(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text('Hubungi Owner untuk mendapatkan akses',
                              style: AppTheme.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: businesses.length,
              itemBuilder: (context, index) {
                final business = businesses[index];
                return FadeInEntrance(
                  delay: Duration(milliseconds: index * 50),
                  child: _BusinessCard(
                    business: business,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              DashboardScreen(business: business),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: SkeletonBusinessList(),
          ),
          error: (error, _) => ErrorRetryWidget(
            message: ErrorHandler.classify(error).userMessage,
            onRetry: () => ref.invalidate(accessibleBusinessesProvider),
          ),
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.store_rounded,
                    color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: AppTheme.heading3),
                    if (business.description != null &&
                        business.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(business.description!,
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
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
