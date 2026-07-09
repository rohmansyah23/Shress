import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../owner/owner_shell.dart';
import '../manager/manager_shell.dart';

/// Splash screen with reactive route guard logic.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  bool _subscribed = false;

  void _navigateToDashboard(String role) {
    Widget destination;
    switch (role) {
      case AppConstants.roleOwner:
        destination = const OwnerShell();
      case AppConstants.roleManager:
      case AppConstants.roleStaff:
        destination = const ManagerShell();
      default:
        destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_subscribed) {
      _subscribed = true;
      ref.listen(authProvider, (_, next) {
        if (_navigated) return;

        if (next.status == AuthStatus.authenticated && next.user != null) {
          _navigated = true;
          _navigateToDashboard(next.user!.role);
        } else if (next.status == AuthStatus.unauthenticated) {
          _navigated = true;
          _navigateToLogin();
        }
      });
    }
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: AppTheme.heading1.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Multi-tenant Financial Reports',
              style: AppTheme.caption.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 48),

            if (authState.status == AuthStatus.unknown)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Memeriksa sesi...',
                    style: AppTheme.caption,
                  ),
                ],
              )
            else
              Text(
                authState.status == AuthStatus.authenticated
                    ? 'Selamat datang kembali!'
                    : 'Mengalihkan...',
                style: AppTheme.caption,
              ),
          ],
        ),
      ),
    );
  }
}
