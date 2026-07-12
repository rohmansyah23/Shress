import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'query_cache_provider.dart';

class PaginatedListState<T> {
  final List<T> items;
  final bool isLoading;
  final bool allLoaded;
  final String? error;

  const PaginatedListState({
    this.items = const [],
    this.isLoading = false,
    this.allLoaded = false,
    this.error,
  });

  PaginatedListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? allLoaded,
    String? error,
  }) {
    return PaginatedListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      allLoaded: allLoaded ?? this.allLoaded,
      error: error,
    );
  }
}

abstract class PaginatedListNotifier<T> extends StateNotifier<PaginatedListState<T>> {
  final int limit;
  final QueryCache _cache = QueryCache();
  int _offset = 0;

  PaginatedListNotifier({this.limit = 20}) : super(const PaginatedListState());

  Future<List<T>> fetchPage(int offset, int limit);

  String get cacheKeyPrefix => '${runtimeType}_';

  void invalidateCache() {
    _cache.clear();
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.allLoaded) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final newItems = await fetchPage(_offset, limit);
      _offset += newItems.length;
      final allLoaded = newItems.length < limit;

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        allLoaded: allLoaded,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    _offset = 0;
    _cache.clear();
    state = const PaginatedListState(isLoading: true);

    try {
      final newItems = await fetchPage(0, limit);
      _offset = newItems.length;
      final allLoaded = newItems.length < limit;

      state = PaginatedListState(
        items: newItems,
        isLoading: false,
        allLoaded: allLoaded,
      );
    } catch (e) {
      state = PaginatedListState(error: e.toString());
    }
  }

  V? cacheGet<V>(String key) => _cache.get<V>(key);
  void cacheSet(String key, dynamic data, {Duration? ttl}) => _cache.set(key, data, ttl: ttl);
}
