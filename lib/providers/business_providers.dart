import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/remote/supabase_service.dart';
import 'transaction_provider.dart';

/// Summary (pendapatan, HPP, laba kotor, pengeluaran, laba bersih) untuk satu bisnis.
final businessSummaryProvider =
    FutureProvider.family<Map<String, double>, int>((ref, businessId) async {
  return SupabaseService.instance.getBusinessSummary(businessId);
});

/// Tren laba/rugi bulanan untuk satu bisnis (default 6 bulan).
final monthlyNetProfitsProvider =
    FutureProvider.family<List<({String month, double netProfit})>, int>(
        (ref, businessId) async {
  return SupabaseService.instance.getMonthlyNetProfits(
    businessId,
    months: 6,
  );
});

/// Gabungan tren laba/rugi bulanan untuk banyak bisnis (Owner view).
/// Gunakan [List<int>] via [businessIdsKey] (comma-separated) sebagai family
/// key agar Riverpod bisa membandingkan equality dengan benar.
final allMonthlyNetProfitsProvider = FutureProvider.family<
    List<({String month, double netProfit})>,
    String>((ref, businessIdsKey) async {
  if (businessIdsKey.isEmpty) return [];
  final businessIds = businessIdsKey.split(',').map(int.parse).toList();
  return SupabaseService.instance.getAllMonthlyNetProfits(
    businessIds,
    months: 6,
  );
});

/// Gabungan summary untuk banyak bisnis (total pendapatan, HPP, laba, dll).
final combinedBusinessSummaryProvider =
    FutureProvider.family<Map<String, double>, String>(
        (ref, businessIdsKey) async {
  if (businessIdsKey.isEmpty) return {};
  final businessIds = businessIdsKey.split(',').map(int.parse).toList();
  return SupabaseService.instance.getAllBusinessesSummary(businessIds);
});

/// Tren laba/rugi berdasarkan filter untuk satu bisnis (mingguan, bulanan, tahunan).
final businessNetProfitsTrendProvider = FutureProvider.family<
    List<({String period, double netProfit})>,
    ({int businessId, TrendFilter filter})>((ref, params) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getNetProfitsTrend(
    businessIds: [params.businessId],
    filter: params.filter,
  );
});

/// Gabungan tren laba/rugi berdasarkan filter untuk banyak bisnis (Owner view).
final allBusinessesNetProfitsTrendProvider = FutureProvider.family<
    List<({String period, double netProfit})>,
    ({String businessIdsKey, TrendFilter filter})>((ref, params) async {
  ref.watch(transactionRefreshProvider);
  if (params.businessIdsKey.isEmpty) return [];
  final businessIds = params.businessIdsKey.split(',').map(int.parse).toList();
  return SupabaseService.instance.getNetProfitsTrend(
    businessIds: businessIds,
    filter: params.filter,
  );
});
