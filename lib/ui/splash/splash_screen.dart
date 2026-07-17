import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../owner/owner_shell.dart';
import '../manager/manager_shell.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

/// Splash screen with reactive route guard logic.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthState());
  }

  void _checkAuthState() {
    if (_navigated) return;
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      _navigated = true;
      _navigateToDashboard(authState.user!.role);
    } else if (authState.status == AuthStatus.unauthenticated) {
      _navigated = true;
      _navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (_navigated) return;

      if (next.status == AuthStatus.authenticated && next.user != null) {
        _navigated = true;
        _navigateToDashboard(next.user!.role);
      } else if (next.status == AuthStatus.unauthenticated) {
        _navigated = true;
        _navigateToLogin();
      }
    });

    final authState = ref.watch(authProvider);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainerColorTheme(context),
                borderRadius: BorderRadius.circular(AppRadius.radiusXL),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                size: AppIconSize.s48,
                color: AppTheme.onPrimaryContainerColorTheme(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              AppConstants.appName,
              style: AppTheme.heading1.copyWith(
                color: AppTheme.primaryColorTheme(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Multi-tenant Financial Reports',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppSpacing.s48),

            if (authState.status == AuthStatus.unknown)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.s16),
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
