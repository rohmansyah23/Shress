import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../owner/owner_shell.dart';
import '../manager/manager_shell.dart';
import 'forgot_password_screen.dart';
import 'widgets/auth_text_field.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_icon_size.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _navigated = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToDashboard(String role) {
    if (_navigated) return;
    _navigated = true;

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

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(authProvider.notifier)
        .login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success && !_navigated) {
      final role = ref.read(authProvider).user?.role;
      if (role != null) {
        _navigateToDashboard(role);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo area
                      Card(
                        elevation: 0,
                        color: isDark
                            ? AppTheme.accent.withValues(alpha: 0.08)
                            : AppTheme.primary.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusXL,
                          ),
                        ),
                        margin: EdgeInsets.zero,
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: Icon(
                            Icons.account_balance_rounded,
                            size: AppIconSize.s44,
                            color: isDark ? AppTheme.accent : AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Text(
                        AppConstants.appName,
                        style: AppTheme.heading1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'Silakan masuk untuk mengelola laporan keuangan',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s40),

                      // Error message
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppTheme.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppTheme.danger,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.danger,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                      ],

                      // Email/Username
                      AuthTextField(
                        controller: _identifierController,
                        labelText: 'Email / Username',
                        hintText: 'Masukkan email atau username Anda',
                        prefixIcon: Icons.person_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email atau username tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      // Password
                      AuthTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Masukkan password Anda',
                        prefixIcon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 22,
                            color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.s32),

                      // Login button
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.onPrimaryColorTheme(context),
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      // Forgot password
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Lupa Password?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkPrimary
                                  : AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
