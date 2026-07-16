import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/notif_log.dart';
import 'notification_service.dart';

/// Service untuk mengelola Firebase Cloud Messaging (FCM).
///
/// Menangani:
/// - Request izin notifikasi
/// - Registrasi & penyimpanan FCM token ke Supabase
/// - Handle token refresh
/// - Handle foreground message
/// - Handle background/killed tap
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;
  String? _userId;

  /// Set user ID setelah login. Simpan token ke Supabase jika token sudah ada.
  void setUserId(String userId) {
    _userId = userId;
    NotifLog.info('FCM User ID set: $userId');
    // Simpan atau reactivate token
    if (_currentToken != null) {
      _saveToken(_currentToken!);
    }
  }

  /// Clear user ID saat logout.
  void clearUserId() {
    _userId = null;
  }

  /// Inisialisasi FCM: request permission, simpan token, listen events.
  Future<void> init() async {
    try {
      // 1. Request izin
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        NotifLog.warn('FCM permission denied by user');
        return;
      }

      // 2. Dapatkan token
      _currentToken = await _messaging.getToken();
      NotifLog.info('FCM Token obtained: ${_currentToken?.substring(0, 20)}...');

      // 3. Simpan token ke Supabase
      if (_currentToken != null) {
        await _saveToken(_currentToken!);
      }

      // 4. Listen token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        NotifLog.info('FCM Token refreshed');
        _currentToken = newToken;
        _saveToken(newToken);
      });

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Handle background tap (app opened from background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // 7. Handle killed state tap (app opened from terminated)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }
    } catch (e, stack) {
      NotifLog.error('FCM init failed', e, stack);
    }
  }

  /// Simpan FCM token ke Supabase push_tokens table.
  ///
  /// Jika token sudah ada (same user + same token), update updated_at.
  /// Jika user punya token lama yang sudah tidak aktif, mark sebagai inactive.
  Future<void> _saveToken(String token) async {
    try {
      if (_userId == null) {
        NotifLog.info('FCM No user ID set — skipping token save');
        return;
      }

      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'web';

      // Deactivate old tokens for this user with same platform
      await Supabase.instance.client
          .from('push_tokens')
          .update({'is_active': false})
          .eq('user_id', _userId!)
          .eq('platform', platform)
          .neq('fcm_token', token);

      // Upsert current token
      await Supabase.instance.client.from('push_tokens').upsert(
        {
          'user_id': _userId!,
          'fcm_token': token,
          'platform': platform,
          'device_info': await _getDeviceInfo(),
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );

      NotifLog.info('FCM Token saved to Supabase');
    } catch (e, stack) {
      NotifLog.error('FCM save token failed', e, stack);
    }
  }

  /// Deactivate token saat logout (set is_active: false, jangan DELETE).
  /// Token tetap ada di tabel agar tidak perlu insert ulang saat login lagi.
  Future<void> deactivateToken() async {
    try {
      if (_currentToken == null || _userId == null) return;

      await Supabase.instance.client
          .from('push_tokens')
          .update({'is_active': false})
          .eq('user_id', _userId!)
          .eq('fcm_token', _currentToken!);

      NotifLog.info('FCM Token deactivated');
    } catch (e, stack) {
      NotifLog.error('FCM deactivate token failed', e, stack);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    NotifLog.info('FCM Foreground message: title=${message.notification?.title}');
    if (message.notification != null) {
      NotificationService.instance.showPushNotification(
        id: message.hashCode,
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
      );
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    NotifLog.info('FCM Message tapped: title=${message.notification?.title}');
    // Navigate di-handle oleh listener di UI layer
  }

  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return 'Android';
      } else if (Platform.isIOS) {
        return 'iOS';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
}

/// Top-level function untuk background message handler.
/// Harus di-declare di luar class (top-level) sesuai requirement Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  NotifLog.background('FCM Background message: ${message.notification?.title}');
}
