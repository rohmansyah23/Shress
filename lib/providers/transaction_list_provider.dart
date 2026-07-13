import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/transaction_model.dart';
import '../data/remote/supabase_service.dart';
import 'paginated_list_provider.dart';
import 'transaction_provider.dart';

class TransactionListNotifier extends PaginatedListNotifier<TransactionModel> {
  final int businessId;

  String? _typeFilter;
  String? _dateStart;
  String? _dateEnd;
  String? _searchQuery;
  String? _paymentMethod;

  TransactionListNotifier(this.businessId) : super(limit: 20);

  void setFilters({
    String? typeFilter,
    String? dateStart,
    String? dateEnd,
    String? searchQuery,
    String? paymentMethod,
  }) {
    _typeFilter = typeFilter;
    _dateStart = dateStart;
    _dateEnd = dateEnd;
    _searchQuery = searchQuery;
    _paymentMethod = paymentMethod;
    invalidateCache();
    refresh();
  }

  String _cacheKey(int offset) {
    return 'tx_b$businessId'
        '_o$offset'
        '_t${_typeFilter ?? ''}'
        '_ds${_dateStart ?? ''}'
        '_de${_dateEnd ?? ''}'
        '_s$_searchQuery'
        '_pm${_paymentMethod ?? ''}';
  }

  @override
  Future<List<TransactionModel>> fetchPage(int offset, int limit) async {
    final key = _cacheKey(offset);
    final cached = cacheGet<List<TransactionModel>>(key);
    if (cached != null) return cached;

    final result = await SupabaseService.instance.getTransactionsPage(
      businessId: businessId,
      offset: offset,
      limit: limit,
      typeFilter: _typeFilter,
      dateStart: _dateStart,
      dateEnd: _dateEnd,
      searchQuery: _searchQuery,
      paymentMethod: _paymentMethod,
    );
    cacheSet(key, result);
    return result;
  }
}

final transactionListProvider = StateNotifierProvider.family<TransactionListNotifier, PaginatedListState<TransactionModel>, int>(
  (ref, businessId) {
    final notifier = TransactionListNotifier(businessId);
    ref.listen<int>(transactionRefreshProvider, (prev, next) {
      if (prev != next) {
        notifier.refresh();
      }
    });
    return notifier;
  },
);

class AllTransactionsListNotifier extends PaginatedListNotifier<TransactionModel> {
  final List<int> businessIds;

  String? _typeFilter;
  String? _dateStart;
  String? _dateEnd;
  String? _searchQuery;
  String? _paymentMethod;

  AllTransactionsListNotifier(this.businessIds) : super(limit: 20);

  void setFilters({
    String? typeFilter,
    String? dateStart,
    String? dateEnd,
    String? searchQuery,
    String? paymentMethod,
  }) {
    _typeFilter = typeFilter;
    _dateStart = dateStart;
    _dateEnd = dateEnd;
    _searchQuery = searchQuery;
    _paymentMethod = paymentMethod;
    invalidateCache();
    refresh();
  }

  String _cacheKey(int offset) {
    final idsKey = (businessIds..sort()).join(',');
    return 'tx_all_$idsKey'
        '_o$offset'
        '_t${_typeFilter ?? ''}'
        '_ds${_dateStart ?? ''}'
        '_de${_dateEnd ?? ''}'
        '_s$_searchQuery'
        '_pm${_paymentMethod ?? ''}';
  }

  @override
  Future<List<TransactionModel>> fetchPage(int offset, int limit) async {
    final key = _cacheKey(offset);
    final cached = cacheGet<List<TransactionModel>>(key);
    if (cached != null) return cached;

    final result = await SupabaseService.instance.getTransactionsPage(
      businessId: 0,
      offset: offset,
      limit: limit,
      typeFilter: _typeFilter,
      dateStart: _dateStart,
      dateEnd: _dateEnd,
      searchQuery: _searchQuery,
      paymentMethod: _paymentMethod,
      businessIds: businessIds,
    );
    cacheSet(key, result);
    return result;
  }
}

final allTransactionsListProvider = StateNotifierProvider.family<AllTransactionsListNotifier, PaginatedListState<TransactionModel>, List<int>>(
  (ref, businessIds) {
    final notifier = AllTransactionsListNotifier(businessIds);
    ref.listen<int>(transactionRefreshProvider, (prev, next) {
      if (prev != next) {
        notifier.refresh();
      }
    });
    return notifier;
  },
);
