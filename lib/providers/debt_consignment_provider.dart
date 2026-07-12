import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/debt_model.dart';
import '../data/local/models/consignment_model.dart';
import '../data/remote/supabase_service.dart';
import 'paginated_list_provider.dart';
import 'transaction_provider.dart';

// ==================== Debt Providers ====================

final debtorsProvider =
    FutureProvider.family<List<dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getDebtorsByBusiness(businessId);
});

final debtSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getDebtSummary(businessId);
});

class DebtListNotifier extends PaginatedListNotifier<DebtModel> {
  final int businessId;

  String? _statusFilter;
  int? _debtorId;

  DebtListNotifier(this.businessId) : super(limit: 20);

  void setFilters({String? statusFilter, int? debtorId}) {
    _statusFilter = statusFilter;
    _debtorId = debtorId;
    invalidateCache();
    refresh();
  }

  String _cacheKey(int offset) {
    return 'debt_b$businessId'
        '_o$offset'
        '_s${_statusFilter ?? ''}'
        '_d$_debtorId';
  }

  @override
  Future<List<DebtModel>> fetchPage(int offset, int limit) async {
    final key = _cacheKey(offset);
    final cached = cacheGet<List<DebtModel>>(key);
    if (cached != null) return cached;

    final result = await SupabaseService.instance.getDebtsPage(
      businessId: businessId,
      offset: offset,
      limit: limit,
      statusFilter: _statusFilter,
      debtorId: _debtorId,
    );
    cacheSet(key, result);
    return result;
  }
}

final debtListProvider = StateNotifierProvider.family<DebtListNotifier, PaginatedListState<DebtModel>, int>(
  (ref, businessId) {
    ref.watch(transactionRefreshProvider);
    return DebtListNotifier(businessId);
  },
);

final debtsByDebtorProvider =
    FutureProvider.family<List<dynamic>, int>((ref, debtorId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getDebtsByDebtor(debtorId);
});

// ==================== Consignment Providers ====================

final consignorsProvider =
    FutureProvider.family<List<dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getConsignorsByBusiness(businessId);
});

final consignmentSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getConsignmentSummary(businessId);
});

class ConsignmentListNotifier extends PaginatedListNotifier<ConsignmentModel> {
  final int businessId;

  String? _statusFilter;
  String? _typeFilter;
  int? _consignorId;

  ConsignmentListNotifier(this.businessId) : super(limit: 20);

  void setFilters({String? statusFilter, String? typeFilter, int? consignorId}) {
    _statusFilter = statusFilter;
    _typeFilter = typeFilter;
    _consignorId = consignorId;
    invalidateCache();
    refresh();
  }

  String _cacheKey(int offset) {
    return 'cons_b$businessId'
        '_o$offset'
        '_st${_statusFilter ?? ''}'
        '_ty${_typeFilter ?? ''}'
        '_c$_consignorId';
  }

  @override
  Future<List<ConsignmentModel>> fetchPage(int offset, int limit) async {
    final key = _cacheKey(offset);
    final cached = cacheGet<List<ConsignmentModel>>(key);
    if (cached != null) return cached;

    final result = await SupabaseService.instance.getConsignmentsPage(
      businessId: businessId,
      offset: offset,
      limit: limit,
      statusFilter: _statusFilter,
      typeFilter: _typeFilter,
      consignorId: _consignorId,
    );
    cacheSet(key, result);
    return result;
  }
}

final consignmentListProvider = StateNotifierProvider.family<ConsignmentListNotifier, PaginatedListState<ConsignmentModel>, int>(
  (ref, businessId) {
    ref.watch(transactionRefreshProvider);
    return ConsignmentListNotifier(businessId);
  },
);

final consignmentsByConsignorProvider =
    FutureProvider.family<List<dynamic>, int>((ref, consignorId) async {
  ref.watch(transactionRefreshProvider);
  return SupabaseService.instance.getConsignmentsByConsignor(consignorId);
});

void triggerDebtRefresh(WidgetRef ref) {
  ref.read(transactionRefreshProvider.notifier).state++;
}
