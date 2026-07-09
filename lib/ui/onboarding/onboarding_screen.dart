import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handshake_rounded, size: 96, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('Selamat datang di ${AppConstants.appName}', style: AppTheme.heading2),
              const SizedBox(height: 12),
              Text('Ikuti beberapa langkah singkat untuk menyiapkan akun dan bisnis Anda.', style: AppTheme.bodyText, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Mulai')),
            ],
          ),
        ),
      ),
    );
  }
}
