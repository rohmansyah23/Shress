import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/user_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/qris_display_screen.dart';
import '../settings/settings_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'QRIS Pembayaran',
            onPressed: () => _showQrisBusinessPicker(context, ref),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasDisplayName = user.displayName?.isNotEmpty == true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar & Info
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  hasDisplayName
                      ? user.displayName![0].toUpperCase()
                      : (user.username.isNotEmpty ? user.username[0].toUpperCase() : '?'),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasDisplayName ? user.displayName! : user.username,
                style: AppTheme.heading2,
              ),
              if (hasDisplayName) ...[
                const SizedBox(height: 2),
                Text('@${user.username}', style: AppTheme.caption),
              ],
              const SizedBox(height: 8),
              AppBadge.role(user.role, fontSize: 12),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Info Akun
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informasi Akun', style: AppTheme.heading3),
                const SizedBox(height: 16),
                _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Nama Tampilan',
                    value: user.displayName?.isNotEmpty == true ? user.displayName! : '-'),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.person_outlined, label: 'Username', value: user.username),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.badge_outlined, label: 'Role', value: user.role),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Aksi Akun
        Card(
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Ubah Nama Tampilan'),
            subtitle: const Text('Ganti nama panggilan/lengkap Anda'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showEditDisplayNameDialog(context, ref, user),
          ),
        ),
        const SizedBox(height: 16),

        // Menu Pengaturan
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Pengaturan'),
            subtitle: const Text('Tema, notifikasi, keamanan akun'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
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
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Ubah Nama Tampilan'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Tampilan',
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: 'Nama lengkap Anda',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
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
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQrisBusinessPicker(
      BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final businesses = await SupabaseService.instance
          .getAccessibleBusinesses(user.userId, user.role);
      if (!context.mounted) return;

      if (businesses.isEmpty) {
        ErrorSnackbar.showMessage(
          context,
          'Tidak ada bisnis tersedia',
        );
        return;
      }

      if (businesses.length == 1) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                QrisDisplayScreen(business: businesses.first),
          ),
        );
        return;
      }

      final selected = await showDialog<BusinessModel>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Bisnis'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: businesses.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.store_rounded),
                title: Text(businesses[i].name),
                onTap: () => Navigator.pop(ctx, businesses[i]),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
          ],
        ),
      );

      if (selected != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QrisDisplayScreen(business: selected),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
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
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text('$label: ', style: AppTheme.caption),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

