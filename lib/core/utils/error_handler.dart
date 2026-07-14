import 'package:supabase_flutter/supabase_flutter.dart';

/// Error types for network/data operations
enum AppErrorType {
  network, // No internet connection
  server, // Supabase server error (5xx)
  notFound, // Resource not found (404)
  auth, // Authentication error
  timeout, // Request timeout
  permission, // RLS/permission denied
  unknown, // Generic error
}

/// Structured app error with user-friendly message
class AppError {
  final AppErrorType type;
  final String userMessage; // User-friendly message in Bahasa Indonesia
  final String? technicalMessage; // Original error for debugging
  final bool isOffline;

  const AppError({
    required this.type,
    required this.userMessage,
    this.technicalMessage,
    this.isOffline = false,
  });

  @override
  String toString() => userMessage;
}

/// Handles Supabase errors and network errors, converting them to user-friendly messages.
class ErrorHandler {
  ErrorHandler._();

  /// Classify and convert any error to a user-friendly AppError
  static AppError classify(Object error) {
    // Already an AppError, return directly
    if (error is AppError) {
      return error;
    }

    // Network error (PlatformException with no connection)
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('No address associated') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Network is unreachable') ||
        error.toString().contains('CONNECTION_REFUSED') ||
        error.toString().contains('connection refused') ||
        error.toString().contains('ClientException') ||
        error.toString().contains('HandshakeException')) {
      return AppError(
        type: AppErrorType.network,
        userMessage: 'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.',
        isOffline: true,
        technicalMessage: error.toString(),
      );
    }

    // Timeout errors
    if (error.toString().contains('timeout') ||
        error.toString().contains('Timed out') ||
        error.toString().contains('TimeoutException')) {
      return AppError(
        type: AppErrorType.timeout,
        userMessage: 'Koneksi ke server timeout. Silakan coba lagi.',
        technicalMessage: error.toString(),
      );
    }

    // Supabase PostgrestException
    if (error is PostgrestException) {
      return _classifyPostgrest(error);
    }

    // Supabase AuthException
    if (error is AuthException) {
      return AppError(
        type: AppErrorType.auth,
        userMessage: _mapAuthErrorMessage(error.message),
        technicalMessage: error.toString(),
      );
    }

    // Generic server error
    if (error.toString().contains('500') ||
        error.toString().contains('Internal Server')) {
      return AppError(
        type: AppErrorType.server,
        userMessage: 'Server mengalami gangguan. Silakan coba lagi nanti.',
        technicalMessage: error.toString(),
      );
    }

    // Default unknown error
    return AppError(
      type: AppErrorType.unknown,
      userMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      technicalMessage: error.toString(),
    );
  }

  /// Classify PostgrestException based on code string
  static AppError _classifyPostgrest(PostgrestException e) {
    final message = e.message.toLowerCase();

    // Network-level Postgrest errors
    if (message.contains('network') ||
        message.contains('fetch') ||
        message.contains('Failed to connect') ||
        message.contains('Couldn\'t connect')) {
      return AppError(
        type: AppErrorType.network,
        userMessage: 'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
        isOffline: true,
        technicalMessage: e.toString(),
      );
    }

    // Check HTTP-like codes in the error message
    if (message.contains('404') || message.contains('not found')) {
      return AppError(
        type: AppErrorType.notFound,
        userMessage: 'Data tidak ditemukan.',
        technicalMessage: e.toString(),
      );
    }
    if (message.contains('401') || message.contains('403') ||
        message.contains('unauthorized') || message.contains('forbidden')) {
      return AppError(
        type: AppErrorType.permission,
        userMessage: 'Anda tidak memiliki akses untuk operasi ini. Hubungi Owner.',
        technicalMessage: e.toString(),
      );
    }
    if (message.contains('409') || message.contains('conflict') ||
        message.contains('duplicate')) {
      return AppError(
        type: AppErrorType.unknown,
        userMessage: 'Data sudah ada. Tidak dapat membuat duplikat.',
        technicalMessage: e.toString(),
      );
    }
    if (message.contains('429') || message.contains('too many requests')) {
      return AppError(
        type: AppErrorType.server,
        userMessage: 'Terlalu banyak permintaan. Silakan tunggu beberapa saat.',
        technicalMessage: e.toString(),
      );
    }
    if (message.contains('500') || message.contains('internal')) {
      return AppError(
        type: AppErrorType.server,
        userMessage: 'Server mengalami gangguan. Silakan coba lagi nanti.',
        technicalMessage: e.toString(),
      );
    }

    // Check for RLS policy violation
    if (message.contains('violates row-level security') ||
        message.contains('new row violates')) {
      return AppError(
        type: AppErrorType.permission,
        userMessage: 'Akses ditolak. Hubungi Owner untuk mendapatkan izin.',
        technicalMessage: e.toString(),
      );
    }

    // Permission denied for table (not RLS)
    if (message.contains('permission denied for table') ||
        message.contains('permission denied for relation')) {
      return AppError(
        type: AppErrorType.permission,
        userMessage: 'Akses ditolak. Hubungi Owner untuk mendapatkan izin.',
        technicalMessage: e.toString(),
      );
    }

    // Foreign key constraint violation
    if (message.contains('violates foreign key constraint') ||
        message.contains('foreign key violation')) {
      return AppError(
        type: AppErrorType.unknown,
        userMessage: 'Data referensi tidak valid. Silakan muat ulang halaman.',
        technicalMessage: e.toString(),
      );
    }

    // Check constraint violation
    if (message.contains('violates check constraint')) {
      return AppError(
        type: AppErrorType.unknown,
        userMessage: 'Data tidak memenuhi syarat. Periksa input Anda.',
        technicalMessage: e.toString(),
      );
    }

    // Not-null constraint violation
    if (message.contains('violates not-null constraint') ||
        message.contains('null value in column')) {
      return AppError(
        type: AppErrorType.unknown,
        userMessage: 'Data tidak lengkap. Silakan coba lagi.',
        technicalMessage: e.toString(),
      );
    }

    // Unique constraint violation
    if (message.contains('violates unique constraint') ||
        message.contains('duplicate key value')) {
      return AppError(
        type: AppErrorType.unknown,
        userMessage: 'Data sudah ada. Tidak dapat membuat duplikat.',
        technicalMessage: e.toString(),
      );
    }

    return AppError(
      type: AppErrorType.unknown,
      userMessage: 'Terjadi kesalahan database. Silakan coba lagi.',
      technicalMessage: e.toString(),
    );
  }

  static String _mapAuthErrorMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Email atau password salah';
    }
    if (lower.contains('user not found')) {
      return 'User tidak ditemukan';
    }
    if (lower.contains('email already registered')) {
      return 'Email sudah terdaftar';
    }
    if (lower.contains('weak password')) {
      return 'Password terlalu lemah (min. 6 karakter)';
    }
    if (lower.contains('network')) {
      return 'Tidak ada koneksi internet';
    }
    return message;
  }

  /// Helper to wrap a Future with error handling that returns the result or throws AppError
  static Future<T> guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      throw classify(e);
    }
  }

}
