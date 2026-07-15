import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await ref
        .read(authProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ErrorSnackbar.showError(context, error);
    } else {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _emailSent
                      ? Icons.mark_email_unread_rounded
                      : Icons.lock_outline_rounded,
                  size: 72,
                  color: _emailSent
                      ? AppTheme.profitColor
                      : AppTheme.primaryColorTheme(context),
                ),
                const SizedBox(height: AppTheme.s16),
                Text(
                  _emailSent ? 'Email Terkirim' : 'Lupa Password?',
                  textAlign: TextAlign.center,
                  style: AppTheme.heading2,
                ),
                const SizedBox(height: AppTheme.s8),
                Text(
                  _emailSent
                      ? 'Kami telah mengirimkan tautan reset password ke:\n${_emailController.text.trim()}\n\nCek kotak masuk email Anda dan ikuti petunjuk untuk mengatur ulang password.'
                      : 'Masukkan email yang terdaftar. Kami akan mengirimkan tautan untuk mereset password Anda.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText.copyWith(height: 1.5),
                ),
                const SizedBox(height: AppTheme.s32),

                if (!_emailSent) ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSendReset(),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!value.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.s24),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _handleSendReset,
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
                                    'Kirim Tautan Reset',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: AppTheme.profitColor,
                  ),
                  const SizedBox(height: AppTheme.s24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Kembali ke Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.s12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _emailSent = false;
                        _emailController.clear();
                      });
                    },
                    child: const Text(
                      'Kirim ulang ke email lain',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.s24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
