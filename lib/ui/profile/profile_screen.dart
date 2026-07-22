import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../widgetbook/widgetbook_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';




class ProfileScreen extends ConsumerWidget {
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = _buildBody(context, ref);
    if (!showAppBar) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        automaticallyImplyLeading: false,
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasDisplayName = user.displayName?.isNotEmpty == true;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        // Avatar & Info
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primaryColorTheme(context),
                child: Text(
                  hasDisplayName
                      ? user.displayName![0].toUpperCase()
                      : (user.username.isNotEmpty ? user.username[0].toUpperCase() : '?'),
                  style: AppTheme.heading1.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                hasDisplayName ? user.displayName! : user.username,
                style: AppTheme.heading2,
              ),
              if (hasDisplayName) ...[
                const SizedBox(height: AppSpacing.s2),
                Text('@${user.username}', style: AppTheme.caption),
              ],
              const SizedBox(height: AppSpacing.s8),
              AppBadge.role(user.role, fontSize: 12),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),

        // Info Akun
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppTheme.primaryColorTheme(context),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      'Informasi Akun',
                      style: AppTheme.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 0.5,
                color: AppTheme.outlineColorTheme(context).withValues(alpha: 0.3),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Nama Tampilan',
                      value: user.displayName?.isNotEmpty == true ? user.displayName! : '-',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppTheme.outlineColorTheme(context).withValues(alpha: 0.3),
                      ),
                    ),
                    _InfoRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Username',
                      value: user.username,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppTheme.outlineColorTheme(context).withValues(alpha: 0.3),
                      ),
                    ),
                    _InfoRow(
                      icon: Icons.shield_outlined,
                      label: 'Role',
                      value: user.role,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),

        // Menu & Pengaturan
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(
                  'Ubah Nama Tampilan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceColorTheme(context),
                  ),
                ),
                subtitle: Text(
                  'Ganti nama panggilan/lengkap Anda',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.onSurfaceVariantColorTheme(context),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showEditDisplayNameDialog(context, ref, user),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceColorTheme(context),
                  ),
                ),
                subtitle: Text(
                  'Tema, notifikasi, keamanan akun',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.onSurfaceVariantColorTheme(context),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              if (kDebugMode) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.widgets_outlined,
                      color: AppTheme.infoColorTheme(context)),
                  title: Text(
                    'WidgetBook',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                  ),
                  subtitle: Text(
                    'Dokumentasi komponen design system',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WidgetBookScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Card(
          child: ListTile(
            leading: Icon(Icons.logout_rounded, color: AppTheme.lossColorTheme(context)),
            title: Text(
              'Keluar',
              style: AppTheme.subtitle.copyWith(
                color: AppTheme.lossColorTheme(context),
              ),
            ),
            subtitle: Text(
              'Logout dari akun Anda',
              style: AppTheme.caption.copyWith(
                color: AppTheme.lossColorTheme(context),
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.lossColorTheme(context)),
            hoverColor: AppTheme.lossColorTheme(context).withValues(alpha: 0.08),
            splashColor: AppTheme.lossColorTheme(context).withValues(alpha: 0.12),
            onTap: () => _showLogoutConfirmation(context, ref),
          ),
        ),
      ],
    );
  }

  void _showEditDisplayNameDialog(
      BuildContext context, WidgetRef ref, UserModel user) {
    final nameCtrl = TextEditingController(text: user.displayName ?? '');
    var isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ubah Nama Tampilan',
                    style: AppTheme.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Masukkan nama tampilan baru Anda',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Nama Tampilan',
                      labelStyle: TextStyle(fontSize: 14),
                      floatingLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      hintText: 'Nama lengkap Anda',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                            child: const Text('Batal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (nameCtrl.text.trim().isEmpty) {
                                      ErrorSnackbar.showMessage(
                                        ctx,
                                        'Nama tampilan tidak boleh kosong',
                                      );
                                      return;
                                    }
                                    setDialogState(() => isSubmitting = true);
                                    try {
                                      await ref
                                          .read(authProvider.notifier)
                                          .updateUserDisplayName(
                                              user.userId, nameCtrl.text.trim());
                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);
                                      ErrorSnackbar.showMessage(
                                        context,
                                        'Nama tampilan berhasil diubah',
                                        isError: false,
                                      );
                                    } catch (e) {
                                      setDialogState(() => isSubmitting = false);
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
                                : const Text('Simpan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun saat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          PfButton(
            label: 'Keluar',
            variant: PfButtonVariant.danger,
            isExpanded: false,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColorTheme(context).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColorTheme(context),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.onSurfaceVariantColorTheme(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                value,
                style: AppTheme.subtitle.copyWith(
                  color: AppTheme.onSurfaceColorTheme(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

