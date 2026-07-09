import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/constants/constants.dart';
import 'core/network/connectivity_service.dart';
import 'core/services/sentry_service.dart';
import 'core/widgets/global_error_boundary.dart';
import 'core/widgets/offline_overlay.dart';
import 'data/remote/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'ui/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _runApp();
  } catch (e, stack) {
    // ignore: avoid_print
    print('[Fatal] Unhandled error during app startup: $e');
    SentryService.instance.captureException(
      e,
      stackTrace: stack,
      category: 'startup',
      extras: {'source': 'main'},
    );

    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text('Gagal memulai aplikasi. Silakan coba lagi.'),
          ),
        ),
      ),
    );
  }
}

Future<void> _runApp() async {
  // Load environment variables
  await AppConfig.load();

  // Initialize Sentry for crash reporting (before any error handlers)
  final sentryDsn = AppConfig.sentryDsn;
  if (sentryDsn.isNotEmpty) {
    await SentryService.instance.init(dsn: sentryDsn);
  } else {
    // ignore: avoid_print
    print('⚠️  SENTRY_DSN tidak dikonfigurasi — crash reporting dinonaktifkan.\n'
        '   Untuk mengaktifkan, tambahkan SENTRY_DSN ke file .env');
  }

  // Set up global error handlers before app initializes
  final errorObserver = initGlobalErrorHandlers();

  // Validate .env configuration
  final configError = AppConfig.validate();
  if (configError != null) {
    // ignore: avoid_print
    print('⚠️  $configError');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    // ignore: avoid_print
    print('⚠️  Supabase initialization failed: $e');
    SentryService.instance.captureException(
      e,
      category: 'startup',
      extras: {'source': 'supabase_init'},
    );
  }

  // Initialize SupabaseService singleton
  SupabaseService.instance.init(Supabase.instance.client);

  // Initialize ConnectivityService for offline detection
  await ConnectivityService.instance.initialize();

  runApp(
    ProviderScope(
      observers: [
        errorObserver,
      ],
      child: const SheressApp(),
    ),
  );
}

class SheressApp extends StatelessWidget {
  const SheressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Stack(
        children: [
          const SplashScreen(),
          const OfflineOverlay(),
        ],
      ),
    );
  }
}
