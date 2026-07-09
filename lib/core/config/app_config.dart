import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  /// Validate .env configuration at startup.
  /// Returns `null` if valid, or an error message if misconfigured.
  static String? validate() {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || url == 'https://your-project-id.supabase.co') {
      return '❌ SUPABASE_URL tidak dikonfigurasi dengan benar di file .env\n'
          '   Buka .env dan ganti dengan URL project Supabase Anda.\n'
          '   Dapatkan URL ini dari: Project Settings > API > Project URL';
    }

    if (anonKey.isEmpty || anonKey == 'your-supabase-anon-key-here') {
      return '❌ SUPABASE_ANON_KEY tidak dikonfigurasi dengan benar di file .env\n'
          '   Buka .env dan ganti dengan Anon Key project Supabase Anda.\n'
          '   Dapatkan dari: Project Settings > API > anon/public key';
    }

    if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
      return '❌ Format SUPABASE_URL tidak valid di file .env\n'
          '   Pastikan URL lengkap, contoh: https://xxx.supabase.co';
    }

    return null; // Valid
  }

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get supabaseServiceRoleKey =>
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'SSRS Finance';

  static String get appEnvironment =>
      dotenv.env['APP_ENVIRONMENT'] ?? 'development';

  static int get syncIntervalSeconds =>
      int.tryParse(dotenv.env['SYNC_INTERVAL_SECONDS'] ?? '') ?? 30;

  static int get syncBatchSize =>
      int.tryParse(dotenv.env['SYNC_BATCH_SIZE'] ?? '') ?? 50;

  static int get qrisCacheDays =>
      int.tryParse(dotenv.env['QRIS_CACHE_DAYS'] ?? '') ?? 30;
}
