
class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  CacheEntry(this.data, {this.ttl = const Duration(seconds: 30)})
      : cachedAt = DateTime.now();

  bool get isStale => DateTime.now().difference(cachedAt) > ttl;
}

class QueryCache {
  final _cache = <String, CacheEntry<dynamic>>{};
  final int maxEntries;

  QueryCache({this.maxEntries = 50});

  void set<T>(String key, T data, {Duration? ttl}) {
    if (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = CacheEntry<T>(data, ttl: ttl ?? const Duration(seconds: 30));
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isStale) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void invalidate(String key) => _cache.remove(key);

  void invalidateAll(Iterable<String> keys) {
    for (final k in keys) {
      _cache.remove(k);
    }
  }

  void clear() => _cache.clear();

  void invalidateByPrefix(String prefix) {
    _cache.removeWhere((k, _) => k.startsWith(prefix));
  }
}
