import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sync Service — V1 Cloud-Only.
/// Offline/local storage sync deferred to V2.
/// All data operations are performed directly on Supabase.
class SyncService {
  static SyncService? _instance;

  SyncService._();

  static SyncService get instance => _instance ??= SyncService._();

  Future<void> initialize() async {
    // No-op in V1: all operations are cloud-only
  }

  Future<void> triggerSync() async {
    // No-op in V1: all data is already on cloud
  }

  int getUnsyncedCount() => 0;

  void dispose() {}
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

final unsyncedCountProvider = Provider<int>((ref) {
  return 0;
});
