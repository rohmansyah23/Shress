import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to monitor network connectivity status.
/// Emits true when online, false when offline.
class ConnectivityService {
  static ConnectivityService? _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  ConnectivityService._();

  /// Singleton instance
  static ConnectivityService get instance =>
      _instance ??= ConnectivityService._();

  /// Stream that emits connectivity status (true = online, false = offline)
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Initialize and start listening to connectivity changes.
  /// Safe to call multiple times — previous subscription is cancelled first.
  Future<void> initialize() async {
    // Cancel any previous subscription to avoid leaks
    await _subscription?.cancel();
    _subscription = null;

    // Get initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  /// Re-check connectivity without re-subscribing to the stream.
  /// Useful for manual retry buttons — it's lighter than [initialize].
  Future<void> retry() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(online);
    }
  }

  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

// Riverpod Provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Provider that exposes current online status as a stream
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.onConnectivityChanged;
});

/// Provider that returns the current online status synchronously
final isOnlineProvider = Provider<bool>((ref) {
  return ConnectivityService.instance.isOnline;
});
