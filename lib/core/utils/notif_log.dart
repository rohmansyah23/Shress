import 'package:flutter/foundation.dart';

import 'package:sentry/sentry.dart';

import '../services/sentry_service.dart';

/// Utility untuk logging notifikasi yang berfungsi di **debug dan release build**.
///
/// `debugPrint()` — yang biasa dipakai — hanya mencetak log di debug build.
/// Di release build, semua log `debugPrint()` tidak muncul di logcat,
/// sehingga sangat sulit mendiagnosis masalah notifikasi di perangkat pengguna.
///
/// ## Fitur
///
/// - **Logging lintas build mode**: Info/warn log via `print()` (release)
///   atau `debugPrint()` (debug). Error log otomatis dikirim ke Sentry.
/// - **Timestamp otomatis**: Setiap log menyertakan jam:menit:detik.milidetik
///   sehingga kronologi kejadian mudah dilacak.
/// - **Level terstruktur**: `info`, `warn`, `error` — memudahkan
///   pemfilteran log saat debugging.
/// - **Integrasi Sentry**: Error otomatis terkirim ke Sentry untuk
///   monitoring produksi.
///
/// ## Contoh penggunaan
///
/// ```dart
/// NotifLog.info('Service initialized');
/// NotifLog.warn('Permission denied, using inexact scheduling');
/// NotifLog.error('Schedule failed', error, stackTrace);
/// ```
class NotifLog {
  NotifLog._();

  static String _timestamp() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  /// Log informasi umum (misal: inisialisasi sukses, notifikasi terkirim).
  static void info(String message) {
    _log('INFO', message, null);
  }

  /// Log peringatan (misal: izin exact alarm ditolak, scheduling inexact).
  static void warn(String message) {
    _log('WARN', message, null);
  }

  /// Log error. Error otomatis dikirim ke Sentry jika [exception] disertakan.
  ///
  /// [exception] dan [stackTrace] akan diteruskan ke [SentryService.captureException].
  static void error(
    String message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    _log('ERROR', message, exception, stackTrace: stackTrace);
  }

  static void _log(
    String level,
    String message,
    Object? exception, {
    StackTrace? stackTrace,
  }) {
    final timestamp = _timestamp();
    const tag = 'Notif';
    final line = '[$timestamp][$level][$tag] $message';

    // Di debug mode: gunakan debugPrint (throttled output)
    // Di release mode: gunakan print (muncul di logcat)
    if (kDebugMode) {
      debugPrint(line);
    } else {
      // ignore: avoid_print
      print(line);
    }

    // Kirim error ke Sentry untuk monitoring produksi
    if (exception != null) {
      SentryService.instance.captureException(
        exception,
        stackTrace: stackTrace,
        category: 'notification',
        extras: {
          'log_message': message,
          'log_level': level,
        },
      );
    } else if (level == 'ERROR') {
      // Error tanpa exception — kirim sebagai message ke Sentry
      SentryService.instance.captureMessage(
        message,
        level: SentryLevel.error,
        extras: {'category': 'notification'},
      );
    }
  }

  /// Log peristiwa yang terjadi di background isolate (FCM background handler).
  ///
  /// Background isolate tidak bisa akses platform channel, jadi cukup print
  /// langsung. Method ini tidak perlu (dan tidak bisa) kirim ke Sentry.
  static void background(String message) {
    // ignore: avoid_print
    print('[${_timestamp()}][BACKGROUND][Notif] $message');
  }
}
