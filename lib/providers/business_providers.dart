import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/remote/supabase_service.dart';
import 'transaction_provider.dart';

/// Summary (pendapatan, HPP, laba kotor, pengeluaran, laba bersih) untuk satu bisnis.
final businessSummaryProvider =
    FutureProvider.family<Map<String, double>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getBusinessSummary(businessId);
});

/// Gabungan summary untuk banyak bisnis (total pendapatan, HPP, laba, dll).
final combinedBusinessSummaryProvider =
    FutureProvider.family<Map<String, double>, String>(
        (ref, businessIdsKey) async {
  ref.watch(transactionRefreshProvider);
  if (businessIdsKey.isEmpty) return {};
  final businessIds = businessIdsKey.split(',').map(int.parse).toList();
  return SupabaseService.instance.getAllBusinessesSummary(businessIds);
});

/// Tren laba/rugi berdasarkan filter untuk satu bisnis (harian, mingguan, bulanan, tahunan).
final businessNetProfitsTrendProvider = FutureProvider.family<
    List<({String period, double income, double expense, double netProfit})>,
    ({int businessId, TrendFilter filter})>((ref, params) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getNetProfitsTrend(
    businessIds: [params.businessId],
    filter: params.filter,
  );
});

/// Gabungan tren laba/rugi berdasarkan filter untuk banyak bisnis (Owner view).
final allBusinessesNetProfitsTrendProvider = FutureProvider.family<
    List<({String period, double income, double expense, double netProfit})>,
    ({String businessIdsKey, TrendFilter filter})>((ref, params) async {
  ref.watch(transactionRefreshProvider);
  if (params.businessIdsKey.isEmpty) return [];
  final businessIds = params.businessIdsKey.split(',').map(int.parse).toList();
  return SupabaseService.instance.getNetProfitsTrend(
    businessIds: businessIds,
    filter: params.filter,
  );
});
