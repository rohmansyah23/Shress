import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sentry_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_handler.dart';

/// Riverpod [ProviderObserver] that logs provider errors globally.
///
/// Attached to [ProviderScope] in [initGlobalErrorHandlers]. Each time a
/// provider fails with an unhandled exception, this observer logs the error
/// to console and reports it to Sentry (if initialized).
class AppErrorObserver extends ProviderObserver {
  /// Optional callback invoked when a provider fails.
  /// Useful for showing a global SnackBar or persisting error logs.
  final void Function(AppError error, String providerName)? onProviderError;

  const AppErrorObserver({this.onProviderError});

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final appError = ErrorHandler.classify(error);

    // Log to console
    debugPrint('[Provider Error] ${provider.name ?? provider.runtimeType}: '
        '${appError.userMessage}');

    // Report to Sentry — provider errors are not automatically captured
    SentryService.instance.captureException(
      error,
      stackTrace: stackTrace,
      category: 'provider',
      extras: {
        'provider_name': provider.name ?? provider.runtimeType.toString(),
        'user_message': appError.userMessage,
      },
    );

    onProviderError?.call(appError, provider.name ?? provider.runtimeType.toString());
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    // Not needed, but required by ProviderObserver interface
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    // Not needed, but required by ProviderObserver interface
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Not needed, but required by ProviderObserver interface
  }
}

/// A widget that renders when a Flutter framework build error occurs.
///
/// Replaces the default red error screen with a user-friendly message in
/// Bahasa Indonesia, consistent with the [ErrorRetryWidget] pattern.
class AppErrorScreen extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const AppErrorScreen({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    final appError = ErrorHandler.classify(errorDetails.exception);

    return Material(
      child: Container(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.s32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: AppTheme.lossColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppTheme.s24),
              Text(
                'Terjadi Kesalahan',
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.lossColor,
                ),
              ),
              const SizedBox(height: AppTheme.s12),
              Text(
                appError.userMessage,
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppTheme.s8),
              if (appError.isOffline)
                Text(
                  'Periksa koneksi internet Anda',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption,
                ),
              const SizedBox(height: AppTheme.s32),
              FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Muat Ulang'),
                onPressed: () => _handleReload(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppTheme.s24),                  Container(
                    padding: const EdgeInsets.all(AppTheme.s12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  child: Text(
                    errorDetails.exception.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleReload(BuildContext context) {
    // Navigate to a clean loading screen to force a full widget tree rebuild.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const _ReloadScreen(),
      ),
      (route) => false,
    );
  }
}

/// A simple loading screen used as a clean rebuild target after error recovery.
class _ReloadScreen extends StatefulWidget {
  const _ReloadScreen();

  @override
  State<_ReloadScreen> createState() => _ReloadScreenState();
}

class _ReloadScreenState extends State<_ReloadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const _SplashRedirector(),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Intermediate widget that schedules a final navigation to the reload screen.
class _SplashRedirector extends StatefulWidget {
  const _SplashRedirector();

  @override
  State<_SplashRedirector> createState() => _SplashRedirectorState();
}

class _SplashRedirectorState extends State<_SplashRedirector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 48, color: AppTheme.secondaryText),
                    SizedBox(height: AppTheme.s16),
                    Text('Aplikasi dimuat ulang...'),
                    SizedBox(height: AppTheme.s16),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Initialize all global error handlers.
///
/// Call this in `main()` **before** `runApp()` to set up:
/// 1. [FlutterError.onError] — catches Flutter framework errors and reports to Sentry
/// 2. [ErrorWidget.builder] — replaces default red error screen
/// 3. Returns an [AppErrorObserver] for use in [ProviderScope.observers]
AppErrorObserver initGlobalErrorHandlers({
  void Function(AppError error, String providerName)? onProviderError,
}) {
  // ── 1. Flutter framework errors ──────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log to console
    FlutterError.dumpErrorToConsole(details);

    // Report to Sentry
    SentryService.instance.captureException(
      details.exception,
      stackTrace: details.stack,
      category: 'flutter',
      extras: {
        'context': details.context?.toString(),
        'library': details.library,
      },
    );
  };

  // ── 2. Custom error widget builder ───────────────────────────────────
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // In debug mode, show a smaller error bar to aid development
    if (kDebugMode) {
      return Material(
        child: Container(
          color: Colors.yellow.shade50,
          padding: const EdgeInsets.all(AppTheme.s8),
          child: Row(
            children: [                  const Icon(Icons.bug_report_rounded, color: AppTheme.warningColor, size: 18),                const SizedBox(width: AppTheme.s8),
              Expanded(
                child: Text(
                  '${details.exception.runtimeType}: ${details.exception}',
                  style: AppTheme.labelSmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // In release mode, show the user-friendly error screen
    return AppErrorScreen(errorDetails: details);
  };

  // ── 3. Create ProviderObserver ───────────────────────────────────────
  return AppErrorObserver(onProviderError: onProviderError);
}

