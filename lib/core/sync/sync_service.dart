import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/connectivity_service.dart';
import '../../data/local/database.dart';

/// Service that manages offline-to-online synchronization.
/// Monitors connectivity and automatically pushes unsynced transactions.
class SyncService {
  static SyncService? _instance;

  late final LocalDatabase _localDb;
  late final SupabaseClient _supabase;
  late final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  bool _initialized = false;

  SyncService._();

  /// Singleton instance
  static SyncService get instance => _instance ??= SyncService._();

  /// Initialize the sync service with required dependencies.
  void _setDependencies({
    required LocalDatabase localDb,
    required SupabaseClient supabase,
    required ConnectivityService connectivityService,
  }) {
    _localDb = localDb;
    _supabase = supabase;
    _connectivityService = connectivityService;
  }

  /// Initialize and start listening to connectivity changes.
  Future<void> initialize({
    required LocalDatabase localDb,
    required SupabaseClient supabase,
    required ConnectivityService connectivityService,
  }) async {
    if (_initialized) return;

    _setDependencies(
      localDb: localDb,
      supabase: supabase,
      connectivityService: connectivityService,
    );

    // Listen for connectivity changes
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        _performSync();
        _startPeriodicSync();
      } else {
        _stopPeriodicSync();
      }
    });

    // If already online, sync immediately
    if (_connectivityService.isOnline) {
      _performSync();
      _startPeriodicSync();
    }

    _initialized = true;
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _stopPeriodicSync();
    _periodicSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _performSync(),
    );
  }

  /// Stop periodic sync timer
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Perform the actual sync operation.
  /// Pushes all unsynced transactions to Supabase.
  Future<void> _performSync() async {
    if (_isSyncing || !_connectivityService.isOnline) return;

    _isSyncing = true;
    try {
      final unsyncedTransactions = _localDb.getUnsyncedTransactions();

      if (unsyncedTransactions.isEmpty) {
        return;
      }

      for (final tx in unsyncedTransactions) {
        try {
          // Push to Supabase
          final response = await _supabase.from('transactions').insert({
            'business_id': tx.businessId,
            'category_id': tx.categoryId,
            'user_id': tx.userId,
            'type': tx.type,
            'amount': tx.amount,
            'cogs': tx.cogs,
            'description': tx.description ?? '',
            'transaction_date': tx.transactionDate,
            'status_sync': true,
          }).select('id').single();

          // Mark as synced locally with the server ID
          if (tx.hiveKey != null) {
            await _localDb.markTransactionSynced(
              tx.hiveKey!,
              response['id'] as int,
            );
          }
        } catch (e) {
          // Log error but continue with remaining transactions
          // ignore: avoid_print
          print('Sync error for transaction: $e');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Sync service error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Manual trigger for sync (can be called from UI)
  Future<void> triggerSync() async {
    await _performSync();
  }

  /// Get count of unsynced transactions
  int getUnsyncedCount() {
    return _localDb.getUnsyncedTransactions().length;
  }

  /// Dispose the service
  void dispose() {
    _connectivitySubscription?.cancel();
    _stopPeriodicSync();
  }
}

// Riverpod Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

/// Provider for unsynced transaction count
final unsyncedCountProvider = Provider<int>((ref) {
  return LocalDatabase.instance.getUnsyncedTransactions().length;
});
