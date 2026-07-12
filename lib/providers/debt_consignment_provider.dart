import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/remote/supabase_service.dart';
import 'transaction_provider.dart';

// ==================== Debt Providers ====================

final debtorsProvider =
    FutureProvider.family<List<dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getDebtorsByBusiness(businessId);
});

final debtsProvider =
    FutureProvider.family<List<dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getDebtsByBusiness(businessId);
});

final debtsByDebtorProvider =
    FutureProvider.family<List<dynamic>, int>((ref, debtorId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getDebtsByDebtor(debtorId);
});

final debtSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getDebtSummary(businessId);
});

// ==================== Consignment Providers ====================

final consignorsProvider =
    FutureProvider.family<List<dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getConsignorsByBusiness(businessId);
});

final consignmentsProvider =
    FutureProvider.family<List<dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getConsignmentsByBusiness(businessId);
});

final consignmentsByConsignorProvider =
    FutureProvider.family<List<dynamic>, int>((ref, consignorId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getConsignmentsByConsignor(consignorId);
});

final consignmentSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getConsignmentSummary(businessId);
});

void triggerDebtRefresh(WidgetRef ref) {
  ref.read(transactionRefreshProvider.notifier).state++;
}
