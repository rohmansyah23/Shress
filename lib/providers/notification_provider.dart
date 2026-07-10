import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/notification_service.dart';

/// State class untuk pengaturan notifikasi pengingat harian.
class NotificationSettings {
  final bool enabled;
  final TimeOfDay time;

  NotificationSettings({
    this.enabled = false,
    TimeOfDay? time,
  }) : time = time ?? const TimeOfDay(hour: 20, minute: 0);

  NotificationSettings copyWith({bool? enabled, TimeOfDay? time}) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationSettings> {
  NotificationNotifier() : super(NotificationSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_daily_enabled') ?? false;
    final hour = prefs.getInt('notif_daily_hour') ?? 20;
    final minute = prefs.getInt('notif_daily_minute') ?? 0;

    state = NotificationSettings(
      enabled: enabled,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await NotificationService.instance.setEnabled(enabled);
    state = state.copyWith(enabled: enabled);
  }

  Future<void> setTime(TimeOfDay time) async {
    await NotificationService.instance.setReminderTime(time);
    state = state.copyWith(time: time);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationSettings>((ref) {
  return NotificationNotifier();
});
