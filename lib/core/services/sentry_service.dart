import 'package:flutter/foundation.dart';
import 'package:sentry/sentry.dart';

/// Wrapper around [Sentry] that integrates with the app's existing
/// error-handling pipeline.
///
/// Uses the pure-Dart `sentry` package (not `sentry_flutter`) to avoid
/// native Kotlin compilation conflicts. All core SDK features (exception
/// capture, breadcrumbs, user context, tags, scopes) are available.
class SentryService {
  SentryService._();

  static final SentryService instance = SentryService._();

  bool _initialized = false;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Initialize the Sentry SDK with the given [dsn].
  ///
  /// Must be called once before any other methods. Call this early in
  /// `main()`, after loading environment variables.
  Future<void> init({required String dsn}) async {
    if (_initialized) return;

    // Filter out network-related errors in debug builds to reduce noise
    final beforeSend = kDebugMode
        ? (SentryEvent event, Hint hint) {
            final throwable = event.throwable;
            if (throwable != null) {
              final msg = throwable.toString().toLowerCase();
              if (msg.contains('socketerror') ||
                  msg.contains('connection refused') ||
                  msg.contains('handshake error') ||
                  msg.contains('failed host lookup') ||
                  msg.contains('network is unreachable')) {
                return null; // Drop network errors in debug
              }
            }
            return event;
          }
        : null;

    await Sentry.init(
      (options) {
        options.dsn = dsn;
        options.environment =
            const String.fromEnvironment('APP_ENVIRONMENT', defaultValue: 'development');

        // Performance tracing — sample rate 0 in debug, configurable in release
        options.tracesSampleRate =
            kDebugMode ? 0.0 : 0.2;

        // Maximum breadcrumbs
        options.maxBreadcrumbs = 100;

        if (beforeSend != null) {
          options.beforeSend = beforeSend;
        }
      },
      // Do NOT use appRunner — we manage our own zone/error handlers
    );

    _initialized = true;
  }

  /// Capture an exception to Sentry with optional context.
  Future<SentryId?> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? category,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) return null;

    // Add a breadcrumb for context
    if (category != null) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: exception.toString(),
          category: category,
          level: SentryLevel.error,
          data: extras,
        ),
      );
    }

    return Sentry.captureException(
      exception,
      stackTrace: stackTrace,
    );
  }

  /// Capture a message (non-fatal event) to Sentry.
  Future<SentryId?> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) return null;

    // Attach extras via breadcrumb for context
    if (extras != null && extras.isNotEmpty) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: 'message',
          level: level,
          data: extras,
        ),
      );
    }

    return Sentry.captureMessage(
      message,
      level: level,
    );
  }

  /// Set a user context so errors are attributed to the current user.
  void setUser({
    required String id,
    String? email,
    String? username,
  }) {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
      ));
    });
  }

  /// Remove the current user context (e.g., on logout).
  void clearUser() {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Set a tag on all future events (e.g., role, business_id).
  void setTag(String key, String value) {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Remove a tag.
  void removeTag(String key) {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.removeTag(key);
    });
  }

  /// Add contextual data to the current scope.
  void setExtra(String key, dynamic value) {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }
}
