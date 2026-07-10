class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Sheress';
  static const String appVersion = '1.0.0';

  // Roles
  static const String roleOwner = 'owner';
  static const String roleManager = 'manager';
  static const String roleStaff = 'staff';

  // Transaction Types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentTransfer = 'transfer';
  static const String paymentQris = 'qris';

  // Report Status
  static const String statusLaba = 'laba';
  static const String statusRugi = 'rugi';

  // Sync
  static const int syncIntervalSeconds = 30;
  static const int syncBatchSize = 50;
  static const int qrisCacheDays = 30;

  // Storage Keys
  static const String keySessionUser = 'session_user';
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyLastSyncTime = 'last_sync_time';

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String periodFormat = 'yyyy-MM';
  static const String displayDateFormat = 'dd MMMM yyyy';
  static const String displayPeriodFormat = 'MMMM yyyy';
}
