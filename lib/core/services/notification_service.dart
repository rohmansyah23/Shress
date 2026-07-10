import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Service untuk mengelola notifikasi pengingat transaksi harian.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _prefKeyEnabled = 'notif_daily_enabled';
  static const String _prefKeyHour = 'notif_daily_hour';
  static const String _prefKeyMinute = 'notif_daily_minute';

  static const String _channelId = 'daily_reminder';
  static const String _channelName = 'Pengingat Transaksi';
  static const String _channelDesc =
      'Pengingat untuk mencatat transaksi harian';

  /// Inisialisasi plugin notifikasi.
  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[Notification] Tapped: ${response.payload}');
  }

  /// Meminta izin notifikasi di Android 13+.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Mengecek apakah izin notifikasi sudah diberikan.
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final granted = await androidPlugin.areNotificationsEnabled();
    return granted ?? false;
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
  Future<void> setEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_prefKeyEnabled, enabled);
    if (enabled) {
      final time = await getReminderTime();
      await _scheduleDaily(time);
    } else {
      await _cancelAll();
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

  Future<void> _scheduleDaily(TimeOfDay time) async {
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

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: 0,
      title: '📊 Saatnya Catat Transaksi!',
      body: 'Jangan lupa mencatat pemasukan dan pengeluaran hari ini.',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  Future<void> _cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> _rescheduleIfEnabled() async {
    if (await isEnabled()) {
      final time = await getReminderTime();
      await _scheduleDaily(time);
    }
  }
}
