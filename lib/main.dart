import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/constants/constants.dart';
import 'core/network/connectivity_service.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await AppConfig.load();

  // Validate .env configuration
  final configError = AppConfig.validate();
  if (configError != null) {
    // Print error to console and still allow app to run with limited features
    // ignore: avoid_print
    print('\n⚠️  KONFIGURASI .env ERROR:');
    // ignore: avoid_print
    print(configError);
    // ignore: avoid_print
    print('Aplikasi akan berjalan dalam mode terbatas (offline-only).\n');
  }

  // Initialize Supabase (will fail gracefully if .env is misconfigured)
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    // ignore: avoid_print
    print('⚠️  Supabase initialization skipped: .env not configured.');
  }

  // Initialize Local Database (Hive)
  await LocalDatabase.instance.initialize();

  // Initialize Connectivity Service (singleton)
  await ConnectivityService.instance.initialize();

  // Initialize Sync Service (singleton)
  await SyncService.instance.initialize(
    localDb: LocalDatabase.instance,
    supabase: Supabase.instance.client,
    connectivityService: ConnectivityService.instance,
  );

  runApp(
    const ProviderScope(
      child: SSRSFinanceApp(),
    ),
  );
}

class SSRSFinanceApp extends StatelessWidget {
  const SSRSFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

/// Temporary placeholder splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: AppTheme.heading1.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Multi-tenant Financial Reports',
              style: AppTheme.caption,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
