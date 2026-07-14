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

  // Debt Status
  static const String debtUnpaid = 'unpaid';
  static const String debtPartial = 'partial';
  static const String debtPaid = 'paid';

  // Consignment Status
  static const String consignmentActive = 'active';
  static const String consignmentSettled = 'settled';
  static const String consignmentCancelled = 'cancelled';

  // Consignment Type
  static const String consignmentTypeReseller = 'reseller';
  static const String consignmentTypeDaily = 'daily';

  // Consignment Report Status
  static const String reportPending = 'pending';
  static const String reportReported = 'reported';
  static const String reportSettled = 'settled';

  // Consignment Categories
  static const String categoryKomisiTitipan = 'Komisi Titipan';
  static const String categoryPiutang = 'Piutang';

  // Storage Keys
  static const String keySessionUser = 'session_user';
}
