import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/services/backup_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/font_size_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          // === Info Akun ===
          Text('Akun', style: AppTheme.heading3),
          const SizedBox(height: AppSpacing.s12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColorTheme(context),
                    child: Text(
                      user?.username.isNotEmpty == true
                          ? user!.username[0].toUpperCase()
                          : '?',
                      style: AppTheme.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'User',
                          style: AppTheme.subtitle,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        AppBadge.role(user?.role ?? ''),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppTheme.onSurfaceVariantColorTheme(context)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),

          // === Tampilan ===
          Text('Tampilan', style: AppTheme.heading3),
          const SizedBox(height: AppSpacing.s12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppTheme.warningColorTheme(context),
                        size: AppIconSize.s20,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        'Tema Aplikasi',
                        style: AppTheme.subtitle.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _ThemeSegmentedButton(
                    currentMode: themeMode,
                    onSelectionChanged: (selectedMode) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(selectedMode);
                    },
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    themeMode == ThemeMode.system
                        ? 'Mengikuti pengaturan tema perangkat'
                        : (themeMode == ThemeMode.dark
                            ? 'Tampilan gelap aktif'
                            : 'Tampilan terang aktif'),
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields_rounded,
                        color: AppTheme.primaryColorTheme(context),
                        size: AppIconSize.s20,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        'Ukuran Teks',
                        style: AppTheme.subtitle.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _FontSizeSegmentedButton(
                    currentSize: fontSize,
                    onSelectionChanged: (selectedSize) {
                      ref
                          .read(fontSizeProvider.notifier)
                          .setFontSize(selectedSize);
                    },
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    fontSize == FontSize.small
                        ? 'Ukuran teks kecil aktif'
                        : (fontSize == FontSize.large
                            ? 'Ukuran teks besar aktif'
                            : 'Ukuran teks sedang aktif'),
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),

          // === Notifikasi ===
          Text('Notifikasi', style: AppTheme.heading3),
          const SizedBox(height: AppSpacing.s12),
          const _NotificationReminderCard(),
          const SizedBox(height: AppSpacing.s24),

          // === Keamanan ===
          Text('Keamanan', style: AppTheme.heading3),
          const SizedBox(height: AppSpacing.s12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outlined),
              title: Text(
                'Ubah Password',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              subtitle: Text(
                'Ganti password akun Anda',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.onSurfaceVariantColorTheme(context),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showChangePasswordDialog(context, ref),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),

          if (user?.role == AppConstants.roleOwner) ...[
            // === Backup ===
            Text('Backup & Restore', style: AppTheme.heading3),
            const SizedBox(height: AppSpacing.s12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.backup_rounded,
                        color: AppTheme.infoColorTheme(context)),
                    title: Text(
                      'Backup Data',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                    ),
                    subtitle: Text(
                      'Ekspor data ke JSON atau SQL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceVariantColorTheme(context),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'json':
                            _backupData(context, ref, asSql: false);
                          case 'sql':
                            _backupData(context, ref, asSql: true);
                          case 'csv':
                          case 'xlsx':
                            _exportAllData(context, value);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'json', child: Text('Ekspor JSON')),
                        PopupMenuItem(value: 'sql', child: Text('Ekspor SQL')),
                        PopupMenuDivider(),
                        PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                        PopupMenuItem(value: 'xlsx', child: Text('Export Excel')),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.storage_rounded,
                        color: AppTheme.warningColorTheme(context)),
                    title: Text(
                      'Backup Schema',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                    ),
                    subtitle: Text(
                      'Ekspor skema database ke file SQL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceVariantColorTheme(context),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _backupSchema(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
          ],

          // === Tentang ===
          Text('Tentang', style: AppTheme.heading3),
          const SizedBox(height: AppSpacing.s12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline,
                      color: AppTheme.primaryColorTheme(context)),
                  title: Text(
                    'Versi Aplikasi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                  ),
                  trailing: Text(
                    AppConstants.appVersion,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: Text(
                    'Mode',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                  ),
                  subtitle: Text(
                    'Cloud (Online)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
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
                  title: Text(
                    'Laporkan Masalah',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                  ),
                  subtitle: Text(
                    'Hubungi pengembang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
                  trailing:
                      const Icon(Icons.open_in_new_rounded, size: AppIconSize.s18),
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
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

  Future<void> _backupData(BuildContext context, WidgetRef ref, {required bool asSql}) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Flexible(child: Text('Mengambil data...')),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final file = asSql
          ? await BackupService.instance.exportDataAsSql(Supabase.instance.client)
          : await BackupService.instance.backupData(Supabase.instance.client);
      scaffold.clearSnackBars();
      await BackupService.instance.shareFile(file);
      if (context.mounted) {
        ErrorSnackbar.showMessage(
          context,
          'File backup siap dibagikan',
          isError: false,
        );
      }
    } catch (e) {
      scaffold.clearSnackBars();
      if (context.mounted) {
        ErrorSnackbar.showError(context, 'Gagal backup: ${e.toString()}');
      }
    }
  }

  Future<void> _backupSchema(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Flexible(child: Text('Menyiapkan skema...')),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final file = await BackupService.instance.backupSchema();
      scaffold.clearSnackBars();
      await BackupService.instance.shareFile(file);
      if (context.mounted) {
        ErrorSnackbar.showMessage(
          context,
          'File schema siap dibagikan',
          isError: false,
        );
      }
    } catch (e) {
      scaffold.clearSnackBars();
      if (context.mounted) {
        ErrorSnackbar.showError(context, 'Gagal backup schema: ${e.toString()}');
      }
    }
  }

  Future<void> _exportAllData(BuildContext context, String format) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Flexible(child: Text('Menyiapkan data...')),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final supabase = Supabase.instance.client;

      final busResponse = await supabase.from('businesses').select('id, name');
      final busList = busResponse as List<dynamic>;
      final busMap = <int, String>{};
      for (final b in busList) {
        final m = b as Map<String, dynamic>;
        busMap[m['id'] as int] = m['name'] as String;
      }

      final catResponse = await supabase.from('categories').select().order('id', ascending: true);
      final cats = catResponse as List<dynamic>;
      final catMap = <int, String>{};
      for (final c in cats) {
        final m = c as Map<String, dynamic>;
        catMap[m['id'] as int] = m['name'] as String;
      }

      final txResponse = await supabase
          .from('transactions')
          .select('*, users!inner (username, display_name)')
          .order('transaction_date', ascending: false);
      final transactions = txResponse as List<dynamic>;

      if (transactions.isEmpty) throw ExportException('Tidak ada data transaksi');

      final headers = ['Tanggal', 'Bisnis', 'Kategori', 'Tipe', 'Jumlah', 'HPP', 'Metode Bayar', 'Deskripsi', 'Oleh'];
      final rows = <List<dynamic>>[];

      for (final tx in transactions) {
        final m = tx as Map<String, dynamic>;
        final isIncome = m['type'] as String == AppConstants.typeIncome;
        final userData = m['users'] as Map<String, dynamic>?;
        final userName = userData?['display_name'] as String? ?? userData?['username'] as String? ?? '';

        rows.add([
          m['transaction_date'] as String? ?? '',
          busMap[m['business_id'] as int?] ?? 'Bisnis #${m['business_id']}',
          catMap[m['category_id'] as int?] ?? 'Kategori #${m['category_id']}',
          isIncome ? 'Uang Masuk' : 'Uang Keluar',
          (m['amount'] as num?)?.toDouble() ?? 0,
          isIncome ? ((m['cogs'] as num?)?.toDouble() ?? 0) : 0,
          m['payment_method'] as String? ?? '',
          m['description'] as String? ?? '',
          userName,
        ]);
      }

      final filename = 'semua_transaksi';
      final service = ExportService.instance;
      final File file;
      if (format == 'csv') {
        file = await service.toCsv(
          headers: headers,
          rows: rows.map((r) => r.map((e) => e.toString()).toList()).toList(),
          filename: filename,
        );
      } else {
        file = await service.toExcel(
          headers: headers,
          rows: rows,
          filename: filename,
        );
      }

      scaffold.clearSnackBars();
      await service.shareFile(file, text: 'Export Semua Transaksi');
    } catch (e) {
      scaffold.clearSnackBars();
      if (context.mounted) {
        ErrorSnackbar.showError(context, 'Gagal export: ${e.toString()}');
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    var obscureNewPwd = true;
    var obscureConfirmPwd = true;
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
                    'Ubah Password',
                    style: AppTheme.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Masukkan password baru minimal 6 karakter',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  TextFormField(
                    controller: newPwdCtrl,
                    obscureText: obscureNewPwd,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      labelStyle: const TextStyle(fontSize: 14),
                      floatingLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPwd ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppTheme.onSurfaceVariantColorTheme(context),
                        ),
                        onPressed: () => setDialogState(() => obscureNewPwd = !obscureNewPwd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  TextFormField(
                    controller: confirmPwdCtrl,
                    obscureText: obscureConfirmPwd,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      labelStyle: const TextStyle(fontSize: 14),
                      floatingLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPwd ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppTheme.onSurfaceVariantColorTheme(context),
                        ),
                        onPressed: () => setDialogState(() => obscureConfirmPwd = !obscureConfirmPwd),
                      ),
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
}

class _FontSizeSegmentedButton extends StatefulWidget {
  final FontSize currentSize;
  final ValueChanged<FontSize> onSelectionChanged;

  const _FontSizeSegmentedButton({
    required this.currentSize,
    required this.onSelectionChanged,
  });

  @override
  State<_FontSizeSegmentedButton> createState() =>
      _FontSizeSegmentedButtonState();
}

class _FontSizeSegmentedButtonState extends State<_FontSizeSegmentedButton> {
  late FontSize _localSize;

  @override
  void initState() {
    super.initState();
    _localSize = widget.currentSize;
  }

  @override
  void didUpdateWidget(covariant _FontSizeSegmentedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSize != widget.currentSize) {
      _localSize = widget.currentSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final segmentsWidth = totalWidth - 2;
        final selectedWidth = segmentsWidth * 0.50;
        final unselectedWidth = segmentsWidth * 0.25;

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: totalWidth,
                child: Row(
                  children: [
                    _buildSegment(
                      context,
                      size: FontSize.small,
                      label: 'Kecil',
                      iconSize: 14,
                      width: _localSize == FontSize.small
                          ? selectedWidth
                          : unselectedWidth,
                      isSelected: _localSize == FontSize.small,
                    ),
                    _buildDivider(isDark),
                    _buildSegment(
                      context,
                      size: FontSize.medium,
                      label: 'Sedang',
                      iconSize: 18,
                      width: _localSize == FontSize.medium
                          ? selectedWidth
                          : unselectedWidth,
                      isSelected: _localSize == FontSize.medium,
                    ),
                    _buildDivider(isDark),
                    _buildSegment(
                      context,
                      size: FontSize.large,
                      label: 'Besar',
                      iconSize: 24,
                      width: _localSize == FontSize.large
                          ? selectedWidth
                          : unselectedWidth,
                      isSelected: _localSize == FontSize.large,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: double.infinity,
      color: isDark ? Colors.grey[800] : Colors.grey[300],
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required FontSize size,
    required String label,
    required double iconSize,
    required double width,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBgColor = AppTheme.primaryColorTheme(context);
    final selectedFgColor = Colors.white;
    final unselectedFgColor =
        isDark ? Colors.white70 : AppTheme.primaryColorTheme(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      height: double.infinity,
      color: isSelected ? selectedBgColor : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (size == _localSize) return;
            setState(() {
              _localSize = size;
            });
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) {
                widget.onSelectionChanged(size);
              }
            });
          },
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.text_fields_rounded,
                    size: iconSize,
                    color: isSelected ? selectedFgColor : unselectedFgColor,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: isSelected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: AppSpacing.s8),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selectedFgColor,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationReminderCard extends ConsumerStatefulWidget {
  const _NotificationReminderCard();

  @override
  ConsumerState<_NotificationReminderCard> createState() =>
      _NotificationReminderCardState();
}

class _NotificationReminderCardState
    extends ConsumerState<_NotificationReminderCard> {
  /// Menampilkan feedback ke user berdasarkan jenis izin yang ditolak.
  ///
  /// - [notificationDenied]: Snackbar — arahkan ke Settings > Notifikasi
  /// - [exactAlarmDenied]: Dialog — jelaskan konsekuensi + tombol buka Settings
  /// - [schedulingBlocked]: Snackbar — informatif saja
  void _showPermissionDeniedFeedback(
    BuildContext context,
    PermissionResult result,
  ) {
    switch (result) {
      case PermissionResult.notificationDenied:
        ErrorSnackbar.showMessage(
          context,
          'Izin notifikasi diperlukan. Aktifkan di Pengaturan perangkat '
          'Anda > Notifikasi > Sheress.',
        );

      case PermissionResult.exactAlarmDenied:
        _showExactAlarmDialog(context);

      case PermissionResult.schedulingBlocked:
        ErrorSnackbar.showMessage(
          context,
          'Pengingat akan berjalan, namun mungkin tidak tepat waktu '
          'saat perangkat dalam mode hemat daya.',
          isError: false,
        );

      case PermissionResult.granted:
        break;
    }
  }

  /// Dialog khusus untuk izin [SCHEDULE_EXACT_ALARM] yang ditolak.
  ///
  /// Izin ini diperlukan agar notifikasi tetap terkirim tepat waktu meskipun
  /// perangkat dalam mode Doze / hemat daya.
  void _showExactAlarmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        ),
        icon: Icon(
          Icons.alarm_rounded,
          size: AppIconSize.s40,
          color: AppTheme.primaryColorTheme(ctx),
        ),
        title: const Text('Izin Alarm Presisi'),
        content: const Text(
          'Agar notifikasi pengingat tetap terkirim tepat waktu meskipun '
          'perangkat dalam mode hemat daya (Doze), aplikasi memerlukan '
          'izin "Alarms & reminders" khusus.\n\n'
          'Anda dapat mengaktifkannya melalui:\n'
          'Pengaturan > Aplikasi > Sheress > Alarms & reminders\n\n'
          'Tanpa izin ini, notifikasi mungkin tertunda saat perangkat '
          'sedang tidak digunakan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti Saja'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColorTheme(context),
                    borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: AppIconSize.s20,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengingat Transaksi Harian',
                        style: AppTheme.subtitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        'Dapatkan notifikasi setiap hari\n'
                        'untuk mencatat transaksi',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.onSurfaceVariantColorTheme(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.enabled,
                  onChanged: (val) async {
                    final result = await ref
                        .read(notificationProvider.notifier)
                        .setEnabled(val);

                    if (!val) return; // disabling always succeeds

                    if (context.mounted &&
                        result != PermissionResult.granted) {
                      _showPermissionDeniedFeedback(
                        context,
                        result,
                      );
                    }
                  },
                ),
              ],
            ),
            if (settings.enabled) ...[
              const SizedBox(height: AppSpacing.s16),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: AppIconSize.s18,
                    color: AppTheme.onSurfaceVariantColorTheme(context),
                  ),
                  const SizedBox(width: AppSpacing.s8),
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
                    label: const Icon(Icons.edit_calendar_rounded, size: AppIconSize.s18),
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
              const SizedBox(height: AppSpacing.s12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Kirim Notifikasi Test'),
                  onPressed: () async {
                    final success =
                        await NotificationService.instance.showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Notifikasi test dikirim! Cek panel notifikasi Anda.'
                                : 'Gagal mengirim notifikasi test. Periksa izin notifikasi.',
                          ),
                          backgroundColor:
                              success ? Colors.green.shade600 : Colors.red.shade600,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeSegmentedButton extends StatefulWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onSelectionChanged;

  const _ThemeSegmentedButton({
    required this.currentMode,
    required this.onSelectionChanged,
  });

  @override
  State<_ThemeSegmentedButton> createState() => _ThemeSegmentedButtonState();
}

class _ThemeSegmentedButtonState extends State<_ThemeSegmentedButton> {
  late ThemeMode _localMode;

  @override
  void initState() {
    super.initState();
    _localMode = widget.currentMode;
  }

  @override
  void didUpdateWidget(covariant _ThemeSegmentedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMode != widget.currentMode) {
      _localMode = widget.currentMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        // Subtract 2 pixels for the two dividers of width 1
        final segmentsWidth = totalWidth - 2;

        final selectedWidth = segmentsWidth * 0.50;
        final unselectedWidth = segmentsWidth * 0.25;

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: totalWidth,
                child: Row(
                  children: [
                    _buildSegment(
                      context,
                      mode: ThemeMode.light,
                      icon: Icons.light_mode_rounded,
                      label: 'Terang',
                      width: _localMode == ThemeMode.light ? selectedWidth : unselectedWidth,
                      isSelected: _localMode == ThemeMode.light,
                    ),
                    _buildDivider(isDark),
                    _buildSegment(
                      context,
                      mode: ThemeMode.system,
                      icon: Icons.settings_brightness_rounded,
                      label: 'Sistem',
                      width: _localMode == ThemeMode.system ? selectedWidth : unselectedWidth,
                      isSelected: _localMode == ThemeMode.system,
                    ),
                    _buildDivider(isDark),
                    _buildSegment(
                      context,
                      mode: ThemeMode.dark,
                      icon: Icons.dark_mode_rounded,
                      label: 'Gelap',
                      width: _localMode == ThemeMode.dark ? selectedWidth : unselectedWidth,
                      isSelected: _localMode == ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: double.infinity,
      color: isDark ? Colors.grey[800] : Colors.grey[300],
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required ThemeMode mode,
    required IconData icon,
    required String label,
    required double width,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBgColor = AppTheme.primaryColorTheme(context);
    final selectedFgColor = Colors.white;
    final unselectedFgColor = isDark ? Colors.white70 : AppTheme.primaryColorTheme(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      height: double.infinity,
      color: isSelected ? selectedBgColor : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (mode == _localMode) return;
            setState(() {
              _localMode = mode;
            });
            // Delay global theme change to let selection animation finish smoothly (matches 250ms duration)
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) {
                widget.onSelectionChanged(mode);
              }
            });
          },
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? selectedFgColor : unselectedFgColor,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: isSelected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: AppSpacing.s8),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selectedFgColor,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
