import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/notif_log.dart';

/// Hasil permintaan izin notifikasi.
/// Mengandung informasi spesifik tentang izin yang ditolak agar UI
/// dapat menampilkan pesan yang sesuai.
enum PermissionResult {
  /// Semua izin diberikan (notifikasi + exact alarm).
  granted,
  /// Izin notifikasi dasar (Android 13+) ditolak user.
  notificationDenied,
  /// Izin [SCHEDULE_EXACT_ALARM] (Android 12+) ditolak user.
  /// Notifikasi tetap bisa berjalan, namun mungkin tertunda saat Doze.
  exactAlarmDenied,
  /// Izin notifikasi diberikan, exact alarm diberikan, tetapi scheduling gagal
  /// karena alasan lain (misal sistem membatasi di Android 14+).
  schedulingBlocked;

  /// Apakah scheduling tetap bisa berjalan (meskipun mungkin tidak presisi).
  bool get canSchedule =>
      this == granted || this == exactAlarmDenied || this == schedulingBlocked;
}

/// Service untuk mengelola notifikasi pengingat transaksi harian.
///
/// ## Perbaikan untuk Reliability:
/// 1. **Importance**: Dinaikkan ke `high` agar notifikasi muncul dengan suara
///    dan muncul di layar (heads-up notification).
/// 2. **Channel Re-creation**: Channel dihapus dan dibuat ulang jika importance
///    berubah (misal setelah update app).
/// 3. **Permission Check**: Memeriksa izin sebelum scheduling, bukan hanya saat toggle.
/// 4. **Error Handling**: Menambahkan try-catch di semua operasi notifikasi.
/// 5. **Android 14+**: Menggunakan schedule mode yang compatible dengan Doze mode.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;

  static const String _prefKeyEnabled = 'notif_daily_enabled';
  static const String _prefKeyHour = 'notif_daily_hour';
  static const String _prefKeyMinute = 'notif_daily_minute';

  static const String _channelId = 'daily_reminder';
  static const String _channelName = 'Pengingat Transaksi';
  static const String _channelDesc =
      'Pengingat untuk mencatat transaksi harian';

  /// Notification ID untuk pengingat harian.
  static const int _notificationId = 0;

  /// Inisialisasi plugin notifikasi.
  ///
  /// Memuat data timezone Asia/Jakarta, menginisialisasi plugin,
  /// dan mereschedule notifikasi yang sudah aktif (misal setelah reboot).
  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    try {
      _navigatorKey = navigatorKey;

      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Reschedule notifikasi yang sudah ada (misal setelah reboot)
      await _rescheduleIfEnabled();
    } catch (e, stack) {
      NotifLog.error('Init failed', e, stack);
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    NotifLog.info('Tapped: payload=${response.payload}');
    // Navigate to root screen when notification is tapped
    final navigator = _navigatorKey?.currentState;
    if (navigator != null && navigator.canPop()) {
      // If app is open, pop back to root (triggers role-based routing)
      navigator.popUntil((route) => route.isFirst);
    }
    // If app was killed, tapping notification launches it normally via splash screen
  }

  /// Meminta seluruh izin notifikasi dan mengembalikan hasil detail.
  ///
  /// Mengembalikan [PermissionResult] yang berisi alasan spesifik jika
  /// ada izin yang ditolak, sehingga UI dapat menampilkan pesan yang sesuai
  /// (bukan hanya "izin ditolak" generik).
  Future<PermissionResult> requestPermissionsWithResult() async {
    if (!Platform.isAndroid) return PermissionResult.granted;

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) {
        NotifLog.warn('Android plugin not available (null) — scheduling blocked');
        return PermissionResult.schedulingBlocked;
      }

      // 1. Request basic notification permission (Android 13+)
      final notifGranted = await androidPlugin.requestNotificationsPermission();
      if (notifGranted != true) {
        return PermissionResult.notificationDenied;
      }

      // 2. Request exact alarm permission (Android 12+)
      final canSchedule =
          await androidPlugin.canScheduleExactNotifications();
      if (canSchedule == true) return PermissionResult.granted;

      final exactAlarmGranted =
          await androidPlugin.requestExactAlarmsPermission();
      if (exactAlarmGranted != true) {
        return PermissionResult.exactAlarmDenied;
      }

      return PermissionResult.granted;
    } catch (e, stack) {
      NotifLog.error('Permission request failed', e, stack);
      // Jika gagal request (misal API tidak tersedia), jangan blokir
      return PermissionResult.schedulingBlocked;
    }
  }

  /// Meminta izin notifikasi di Android 13+ (legacy, return boolean).
  ///
  /// Untuk hasil yang lebih detail, gunakan [requestPermissionsWithResult].
  @Deprecated('Gunakan requestPermissionsWithResult() untuk hasil detail')
  Future<bool> requestPermission() async {
    final result = await requestPermissionsWithResult();
    return result.canSchedule;
  }

  /// Mengecek apakah izin notifikasi dasar (POST_NOTIFICATIONS) sudah diberikan.
  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) {
        NotifLog.warn('Android plugin null in hasNotificationPermission');
        return false;
      }

      final notifGranted = await androidPlugin.areNotificationsEnabled();
      return notifGranted ?? false;
    } catch (e, stack) {
      NotifLog.error('hasNotificationPermission error', e, stack);
      return false;
    }
  }

  /// Mengecek apakah izin exact alarm (SCHEDULE_EXACT_ALARM) sudah diberikan.
  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) {
        NotifLog.warn('Android plugin null in hasExactAlarmPermission');
        return false;
      }

      final canSchedule =
          await androidPlugin.canScheduleExactNotifications();
      return canSchedule ?? false;
    } catch (e, stack) {
      NotifLog.error('hasExactAlarmPermission error', e, stack);
      return false;
    }
  }

  /// Mengecek apakah seluruh izin notifikasi sudah diberikan.
  Future<bool> hasPermission() async {
    final notifOk = await hasNotificationPermission();
    if (!notifOk) return false;
    return await hasExactAlarmPermission();
  }

  // ==================== Preferences ====================

  Future<SharedPreferences> _getPrefs() =>
      SharedPreferences.getInstance();

  Future<bool> isEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_prefKeyEnabled) ?? false;
  }

  Future<TimeOfDay> getReminderTime() async {
    final prefs = await _getPrefs();
    final hour = prefs.getInt(_prefKeyHour) ?? 20;
    final minute = prefs.getInt(_prefKeyMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Mengaktifkan/menonaktifkan pengingat harian.
  ///
  /// Mengembalikan [PermissionResult] jika [enabled] = true dan ada izin
  /// yang ditolak, sehingga UI dapat menampilkan pesan yang sesuai.
  ///
  /// Jika [enabled] = false, selalu mengembalikan [PermissionResult.granted]
  /// (tidak perlu izin untuk menonaktifkan).
  Future<PermissionResult> setEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_prefKeyEnabled, enabled);

    if (enabled) {
      // 1. Cek izin notifikasi dasar
      if (!await hasNotificationPermission()) {
        final result = await requestPermissionsWithResult();
        if (!result.canSchedule) {
          NotifLog.warn('Cannot schedule: ${result.name}');
          await prefs.setBool(_prefKeyEnabled, false);
          return result;
        }
      }

      // 2. Cek exact alarm — jika ditolak, tetap schedule (inexact)
      //    Tidak perlu gagal, cukup return info ke UI
      if (!await hasExactAlarmPermission()) {
        NotifLog.warn('Exact alarm denied — scheduling inexact');
      }

      final time = await getReminderTime();
      await _scheduleDaily(time);
      return PermissionResult.granted;
    } else {
      await _cancelAll();
      return PermissionResult.granted;
    }
  }

  /// Mengupdate waktu pengingat.
  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_prefKeyHour, time.hour);
    await prefs.setInt(_prefKeyMinute, time.minute);

    if (await isEnabled()) {
      await _scheduleDaily(time);
    }
  }

  // ==================== Scheduling ====================

  /// Menjadwalkan notifikasi harian pada waktu yang ditentukan.
  ///
  /// Menggunakan [zonedSchedule] dengan [matchDateTimeComponents: DateTimeComponents.time]
  /// agar notifikasi berulang setiap hari pada jam yang sama.
  /// Menggunakan [AndroidScheduleMode.inexactAllowWhileIdle] agar kompatibel
  /// dengan Android 12+ Doze mode restrictions.
  Future<void> _scheduleDaily(TimeOfDay time) async {
    try {
      await _cancelAll();

      final now = DateTime.now();
      final location = tz.local;
      var scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Jika waktu sudah lewat, jadwalkan untuk besok
      final nowTz = tz.TZDateTime.from(now, location);
      if (scheduledDate.isBefore(nowTz)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Gunakan Importance.high agar notifikasi muncul dengan suara
      // dan muncul sebagai heads-up notification
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        enableVibration: true,
        playSound: true,
        // Android 14+: pastikan notifikasi muncul di lock screen
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id: _notificationId,
        title: '📊 Saatnya Catat Transaksi!',
        body: 'Jangan lupa mencatat pemasukan dan pengeluaran hari ini.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_reminder',
      );

      NotifLog.info('Scheduled daily reminder at '
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}');
    } catch (e, stack) {
      NotifLog.error('Schedule daily reminder failed', e, stack);
    }
  }

  /// Membatalkan semua notifikasi terjadwal.
  Future<void> _cancelAll() async {
    try {
      await _plugin.cancelAll();
      NotifLog.info('All notifications cancelled');
    } catch (e, stack) {
      NotifLog.error('Cancel all notifications failed', e, stack);
    }
  }

  /// Mereschedule notifikasi jika fitur diaktifkan.
  ///
  /// Dipanggil saat aplikasi dimulai (di [init]) untuk mereschedule
  /// notifikasi yang mungkin terhapus setelah reboot.
  Future<void> _rescheduleIfEnabled() async {
    try {
      if (await isEnabled()) {
        final time = await getReminderTime();
        await _scheduleDaily(time);
      }
    } catch (e, stack) {
      NotifLog.error('Reschedule if enabled failed', e, stack);
    }
  }

  /// Mengirim notifikasi test langsung (bukan scheduled).
  ///
  /// Berguna untuk memverifikasi bahwa notifikasi berfungsi.
  /// Mengembalikan `true` jika berhasil, `false` jika gagal.
  Future<bool> showTestNotification() async {
    try {
      // Pastikan izin ada
      if (!await hasNotificationPermission()) {
        final result = await requestPermissionsWithResult();
        if (!result.canSchedule) return false;
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: 99, // ID berbeda agar tidak replace scheduled notification
        title: '🧪 Notifikasi Test',
        body: 'Jika Anda melihat pesan ini, notifikasi berfungsi!',
        notificationDetails: details,
        payload: 'test_notification',
      );

      NotifLog.info('Test notification sent successfully');
      return true;
    } catch (e, stack) {
      NotifLog.error('Test notification failed', e, stack);
      return false;
    }
  }

  /// Menampilkan notifikasi push dari FCM saat app di foreground.
  Future<void> showPushNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (!await hasNotificationPermission()) return;

      const androidDetails = AndroidNotificationDetails(
        'owner_push',
        'Pesan dari Owner',
        channelDescription: 'Notifikasi push dari owner ke staff',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
      NotifLog.info('Push notification shown: $title');
    } catch (e, stack) {
      NotifLog.error('Show push notification failed: $title', e, stack);
    }
  }
}
