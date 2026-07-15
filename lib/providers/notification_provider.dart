import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/notification_service.dart';

/// State class untuk pengaturan notifikasi pengingat harian.
class NotificationSettings {
  final bool enabled;
  final TimeOfDay time;

  /// Hasil izin terakhir saat mencoba mengaktifkan notifikasi.
  /// `null` jika belum pernah mencoba atau izin diberikan.
  final PermissionResult? lastPermissionResult;

  NotificationSettings({
    this.enabled = false,
    TimeOfDay? time,
    this.lastPermissionResult,
  }) : time = time ?? const TimeOfDay(hour: 20, minute: 0);

  NotificationSettings copyWith({
    bool? enabled,
    TimeOfDay? time,
    PermissionResult? lastPermissionResult,
    bool clearPermissionResult = false,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      lastPermissionResult: clearPermissionResult
          ? null
          : lastPermissionResult ?? this.lastPermissionResult,
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

  /// Mengaktifkan/menonaktifkan pengingat harian.
  ///
  /// Saat mengaktifkan, method ini akan otomatis meminta izin yang diperlukan
  /// (notifikasi + exact alarm) dan mengembalikan [PermissionResult] agar
  /// UI dapat menampilkan feedback yang sesuai.
  ///
  /// Saat menonaktifkan, selalu mengembalikan [PermissionResult.granted].
  Future<PermissionResult> setEnabled(bool enabled) async {
    final result = await NotificationService.instance.setEnabled(enabled);

    if (enabled) {
      // Update state sesuai hasil izin
      state = state.copyWith(
        enabled: result.canSchedule,
        lastPermissionResult: result == PermissionResult.granted ? null : result,
      );
    } else {
      state = state.copyWith(
        enabled: false,
        clearPermissionResult: true,
      );
    }

    return result;
  }

  /// Membersihkan status izin terakhir (misal setelah user melihat snackbar).
  void clearPermissionResult() {
    state = state.copyWith(clearPermissionResult: true);
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
