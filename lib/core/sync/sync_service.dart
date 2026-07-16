import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/notif_log.dart';

/// Sync Service — V1 Cloud-Only.
/// Offline/local storage sync deferred to V2.
/// All data operations are performed directly on Supabase.
class SyncService {
  static SyncService? _instance;

  SyncService._();

  static SyncService get instance => _instance ??= SyncService._();

  Future<void> initialize() async {
    NotifLog.info('Sync: initialized (cloud-only mode)');
  }

  Future<void> triggerSync() async {
    NotifLog.info('Sync: triggered — all data already on cloud');
  }

  int getUnsyncedCount() => 0;

  void dispose() {
    NotifLog.info('Sync: disposed');
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

final unsyncedCountProvider = Provider<int>((ref) {
  return 0;
});
