import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/error_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === Info Akun ===
          Text('Akun', style: AppTheme.heading3),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      user?.username.isNotEmpty == true
                          ? user!.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AppBadge.role(user?.role ?? ''),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // === Tampilan ===
          Text('Tampilan', style: AppTheme.heading3),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: isDark ? Colors.amber : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tema Aplikasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Terang'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_brightness_rounded),
                          label: Text('Sistem'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Gelap'),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (Set<ThemeMode> selected) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(selected.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    themeMode == ThemeMode.system
                        ? 'Mengikuti pengaturan tema perangkat'
                        : (themeMode == ThemeMode.dark
                            ? 'Tampilan gelap aktif'
                            : 'Tampilan terang aktif'),
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // === Notifikasi ===
          Text('Notifikasi', style: AppTheme.heading3),
          const SizedBox(height: 12),
          const _NotificationReminderCard(),
          const SizedBox(height: 24),

          // === Keamanan ===
          Text('Keamanan', style: AppTheme.heading3),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outlined),
                  title: const Text('Ubah Password'),
                  subtitle:
                      const Text('Ganti password akun Anda'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.logout_rounded,
                      color: AppTheme.lossColor),
                  title: const Text('Keluar',
                      style: TextStyle(color: AppTheme.lossColor)),
                  subtitle:
                      const Text('Logout dari akun saat ini'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _handleLogout(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // === Tentang ===
          Text('Tentang', style: AppTheme.heading3),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline,
                      color: colorScheme.primary),
                  title: const Text('Versi Aplikasi'),
                  trailing: Text(
                    AppConstants.appVersion,
                    style: AppTheme.caption.copyWith(fontSize: 13),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Mode'),
                  subtitle: const Text('Cloud (Online)'),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.profitColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Laporkan Masalah'),
                  subtitle: const Text('Hubungi pengembang'),
                  trailing:
                      const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ErrorSnackbar.showMessage(
      context,
      'Fitur ini akan tersedia segera',
      isError: false,
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    var isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Ubah Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: newPwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (newPwdCtrl.text != confirmPwdCtrl.text) {
                        ErrorSnackbar.showMessage(
                          ctx,
                          'Password tidak cocok',
                        );
                        return;
                      }
                      if (newPwdCtrl.text.length < 6) {
                        ErrorSnackbar.showMessage(
                          ctx,
                          'Password minimal 6 karakter',
                        );
                        return;
                      }
                      final user = ref.read(currentUserProvider);
                      if (user == null) {
                        ErrorSnackbar.showMessage(
                          ctx,
                          'User tidak ditemukan',
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        await ref.read(authRepositoryProvider).updateUserPassword(
                          userId: user.userId,
                          password: newPwdCtrl.text,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ErrorSnackbar.showMessage(
                          context,
                          'Password berhasil diubah',
                          isError: false,
                        );
                      } catch (e) {
                        setDialogState(
                            () => isSubmitting = false);
                        ErrorSnackbar.show(
                          ctx,
                          ErrorHandler.classify(e),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

}


// ==================== Notification Reminder Card ====================

class _NotificationReminderCard extends ConsumerStatefulWidget {
  const _NotificationReminderCard();

  @override
  ConsumerState<_NotificationReminderCard> createState() =>
      _NotificationReminderCardState();
}

class _NotificationReminderCardState
    extends ConsumerState<_NotificationReminderCard> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengingat Transaksi Harian',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Dapatkan notifikasi setiap hari\n'
                        'untuk mencatat transaksi',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.enabled,
                  onChanged: (val) async {
                    if (val) {
                      final granted = await NotificationService
                          .instance
                          .requestPermission();
                      if (granted) {
                        await ref
                            .read(notificationProvider.notifier)
                            .setEnabled(true);
                      } else {
                        if (context.mounted) {
                          ErrorSnackbar.showMessage(
                            context,
                            'Izin notifikasi diperlukan. '
                            'Aktifkan di Pengaturan perangkat Anda.',
                          );
                        }
                      }
                    } else {
                      await ref
                          .read(notificationProvider.notifier)
                          .setEnabled(false);
                    }
                  },
                ),
              ],
            ),
            if (settings.enabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Waktu pengingat',
                      style: AppTheme.caption),
                  const Spacer(),
                  TextButton.icon(
                    icon: Text(
                      settings.time.format(context),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    label: const Icon(Icons.edit_calendar_rounded, size: 18),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: settings.time,
                        helpText: 'Pilih Waktu Pengingat',
                      );
                      if (picked != null) {
                        await ref
                            .read(notificationProvider.notifier)
                            .setTime(picked);
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
