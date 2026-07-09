import 'models/financial_report_model.dart';

/// LocalDatabase — V1 Cloud-Only.
/// Offline/local storage is deferred to V2.
/// All data operations use SupabaseService directly.
///
/// This class is kept as a stub for backward compatibility.
/// It will be completely removed in V2 when offline storage is re-implemented.
class LocalDatabase {
  LocalDatabase._();

  static LocalDatabase get instance => LocalDatabase._();

  Future<void> initialize() async {
    // No-op in V1: all operations are cloud-only
  }

  Future<void> clearAll() async {
    // No-op in V1
  }

  // ==================== Stub Methods ====================

  int getUnsyncedTransactions() => 0;

  List<FinancialReportModel> getReportsByBusiness(int businessId) => const [];
}
