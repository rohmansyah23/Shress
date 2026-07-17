import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/widgets/error_widgets.dart';
import '../../providers/auth_provider.dart';

/// Template pesan cepat yang bisa dipilih owner.
class _NotificationPreset {
  final String title;
  final String body;
  final IconData icon;

  const _NotificationPreset({
    required this.title,
    required this.body,
    required this.icon,
  });

  /// Daftar preset yang tersedia.
  static const List<_NotificationPreset> presets = [
    _NotificationPreset(
      title: 'Laporan Tutup Toko',
      body: 'Jangan lupa lakukan rekonsiliasi kas dan upload laporan penjualan hari ini setelah toko tutup ya. Batas akhir jam 22.00 WIB.',
      icon: Icons.assignment_rounded,
    ),
    _NotificationPreset(
      title: 'Cek Bahan & Stok Cup',
      body: 'Mohon cek sisa stok cup plastik, teh solo, kopi, dan gula. Laporkan jika ada yang kritis untuk di-restock besok pagi.',
      icon: Icons.inventory_2_rounded,
    ),
    _NotificationPreset(
      title: 'Rekap Barang Titipan',
      body: 'Tolong hitung penjualan snack/makanan titipan (konsinyasi) hari ini. Siapkan uang setoran untuk supplier.',
      icon: Icons.assignment_turned_in_rounded,
    ),
    _NotificationPreset(
      title: 'Pemeriksaan Piutang',
      body: 'Tolong periksa catatan piutang pelanggan hari ini. Ingatkan pelanggan yang memiliki piutang jatuh tempo secara sopan.',
      icon: Icons.account_balance_wallet_rounded,
    ),
    _NotificationPreset(
      title: 'Setoran Kas Fisik',
      body: 'Harap hitung kas fisik di laci sebelum pulang dan pastikan nominal uang tunai sama dengan catatan transaksi di aplikasi.',
      icon: Icons.payments_rounded,
    ),
    _NotificationPreset(
      title: 'Pengumuman Libur Toko',
      body: 'Besok toko libur sementara. Sebelum pulang malam ini, pastikan semua listrik (kecuali kulkas) dimatikan dan pintu dikunci rapat.',
      icon: Icons.celebration_rounded,
    ),
  ];
}

/// Screen untuk owner mengirim pesan notifikasi push ke staff/manager.
class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends ConsumerState<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;
  int? _selectedPresetIndex;
  String _targetMode = 'all'; // 'all', 'role', 'specific'
  String _selectedRole = 'staff';
  List<Map<String, dynamic>> _allStaff = [];
  final Set<String> _selectedUserIds = {};

  /// Terapkan preset pesan: isi title & body, lalu fokus ke body agar bisa diedit.
  void _applyPreset(int index) {
    final preset = _NotificationPreset.presets[index];
    _titleController.text = preset.title;
    _bodyController.text = preset.body;
    setState(() => _selectedPresetIndex = index);
    // Fokus ke body field agar user langsung bisa edit
    Future.delayed(const Duration(milliseconds: 100), () {
      _bodyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _bodyController.text.length),
      );
    });
  }

  /// Reset preset selection jika user mengedit title/body secara manual.
  void _onTextChanged() {
    if (_selectedPresetIndex == null) return;
    final preset = _NotificationPreset.presets[_selectedPresetIndex!];
    final currentTitle = _titleController.text;
    final currentBody = _bodyController.text;
    // Jika teks sudah berbeda dari preset, reset seleksi
    if (currentTitle != preset.title || currentBody != preset.body) {
      setState(() => _selectedPresetIndex = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _bodyController.removeListener(_onTextChanged);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('id, display_name, username, role')
          .inFilter('role', ['staff', 'manager'])
          .eq('is_active', true)
          .order('display_name');

      if (mounted) {
        setState(() => _allStaff = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showMessage(context, 'Gagal memuat daftar staff');
      }
    }
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final userId = ref.read(currentUserProvider)?.userId;
      if (userId == null) throw Exception('Tidak terautentikasi');

      final response = await Supabase.instance.client.functions.invoke(
        'send-owner-notification',
        body: {
          'user_id': userId,
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'target_role': _targetMode == 'role' ? _selectedRole : 'all',
          'target_user_ids': _targetMode == 'specific'
              ? _selectedUserIds.toList()
              : null,
        },
      );

      if (response.status != 200) {
        final error = response.data;
        throw Exception(error?['error'] ?? 'Gagal mengirim notifikasi');
      }

      final data = response.data;
      if (mounted) {
        ErrorSnackbar.showSuccess(
          context,
          'Notifikasi terkirim ke ${data['sent']} device',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showError(context, 'Gagal mengirim: $e');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kirim Pesan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppTheme.infoColorTheme(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                border: Border.all(
                  color: AppTheme.infoColorTheme(context).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: AppIconSize.s24,
                    color: AppTheme.infoColorTheme(context),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PUSH NOTIFICATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppTheme.infoColorTheme(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          'Pesan akan dikirim sebagai push notification ke HP staff/manager',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.s24),

            // Title field
            Text('Judul *', style: AppTheme.subtitle.copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.s8),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.title),
                hintText: 'Contoh: Pengingat Upload Laporan',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.s8),

            // === Quick Preset Messages ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pesan Cepat',
                  style: AppTheme.subtitle.copyWith(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariantColorTheme(context),
                  ),
                ),
                if (_selectedPresetIndex != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.clear_rounded, size: 14),
                    label: const Text('Batal Pilih', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      _titleController.clear();
                      _bodyController.clear();
                      setState(() => _selectedPresetIndex = null);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                itemCount: _NotificationPreset.presets.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
                itemBuilder: (context, index) {
                  final preset = _NotificationPreset.presets[index];
                  final isSelected = _selectedPresetIndex == index;
                  return _PresetChip(
                    icon: preset.icon,
                    label: preset.title,
                    isSelected: isSelected,
                    onTap: () => _applyPreset(index),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.s20),

            // Body field
            Text('Pesan *', style: AppTheme.subtitle.copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.s8),
            TextFormField(
              controller: _bodyController,
              textInputAction: TextInputAction.newline,
              maxLines: 3,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.message_outlined),
                hintText: 'Contoh: Jangan lupa input transaksi hari ini',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Pesan wajib diisi';
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.s24),
            const Divider(),
            const SizedBox(height: AppSpacing.s16),

            // Target selection
            Text('Penerima', style: AppTheme.heading3),
            const SizedBox(height: AppSpacing.s12),

            // Target mode: All staff
            _TargetOption(
              icon: Icons.people_outline_rounded,
              label: 'Semua Staff & Manager',
              subtitle: 'Kirim ke semua staff dan manager aktif',
              isSelected: _targetMode == 'all',
              onTap: () => setState(() => _targetMode = 'all'),
            ),

            const SizedBox(height: AppSpacing.s8),

            // Target mode: By role
            _TargetOption(
              icon: Icons.group_outlined,
              label: 'Berdasarkan Role',
              subtitle: 'Pilih: hanya staff atau hanya manager',
              isSelected: _targetMode == 'role',
              onTap: () => setState(() => _targetMode = 'role'),
            ),

            if (_targetMode == 'role') ...[
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  Expanded(
                    child: _RoleChip(
                      icon: Icons.badge_rounded,
                      label: 'Staff',
                      isSelected: _selectedRole == 'staff',
                      onTap: () => setState(() => _selectedRole = 'staff'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: _RoleChip(
                      icon: Icons.manage_accounts_rounded,
                      label: 'Manager',
                      isSelected: _selectedRole == 'manager',
                      onTap: () => setState(() => _selectedRole = 'manager'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.s8),

            // Target mode: Specific users
            _TargetOption(
              icon: Icons.person_outline_rounded,
              label: 'Staff Tertentu',
              subtitle: 'Pilih dari daftar staff',
              isSelected: _targetMode == 'specific',
              onTap: () => setState(() => _targetMode = 'specific'),
            ),

            if (_targetMode == 'specific') ...[
              const SizedBox(height: AppSpacing.s8),
              ..._allStaff.map((staff) {
                final isSelected = _selectedUserIds.contains(staff['id']);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedUserIds.add(staff['id']);
                      } else {
                        _selectedUserIds.remove(staff['id']);
                      }
                    });
                  },
                  title: Text(
                    staff['display_name'] ?? staff['username'] ?? 'Staff',
                    style: AppTheme.subtitle.copyWith(fontSize: 14),
                  ),
                  subtitle: Text(
                    staff['role'] == 'manager' ? 'Manager' : 'Staff',
                    style: AppTheme.caption,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],

            const SizedBox(height: AppSpacing.s32),

            // Send button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSending ? null : _handleSend,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isSending ? 'Mengirim...' : 'Kirim Notifikasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip preset pesan cepat — horizontal scrollable.
class _PresetChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bgColor = isSelected
        ? (isLight ? AppTheme.primaryColorTheme(context) : AppTheme.accent)
        : (isLight
            ? AppTheme.surfaceContainerColorTheme(context)
            : AppTheme.darkBackground);

    final borderColor = isSelected
        ? Colors.transparent
        : AppTheme.outlineVariantColorTheme(context);

    final contentColor = isSelected
        ? AppTheme.card
        : AppTheme.onSurfaceVariantColorTheme(context);

    final fontWeight = isSelected ? FontWeight.w600 : FontWeight.normal;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s14,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.s20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIconSize.s16,
              color: contentColor,
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: fontWeight,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget opsi target selection (radio-like card).
class _TargetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TargetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColorTheme(context).withValues(alpha: 0.05)
              : AppTheme.surfaceContainerColorTheme(context),
          borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColorTheme(context)
                : AppTheme.outlineVariantColorTheme(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppIconSize.s20,
              color: isSelected
                  ? AppTheme.primaryColorTheme(context)
                  : AppTheme.onSurfaceVariantColorTheme(context),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.subtitle.copyWith(fontSize: 14)),
                  const SizedBox(height: AppSpacing.s2),
                  Text(subtitle, style: AppTheme.caption),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: AppIconSize.s20,
                color: AppTheme.primaryColorTheme(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chip kustom untuk seleksi role.
/// Menggunakan visual chip yang rapi, membagi lebar layar secara dinamis (Expanded).
class _RoleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bgColor = isSelected
        ? (isLight ? AppTheme.primaryColorTheme(context) : AppTheme.accent)
        : (isLight
            ? AppTheme.surfaceContainerColorTheme(context)
            : AppTheme.darkBackground);

    final borderColor = isSelected
        ? Colors.transparent
        : AppTheme.outlineVariantColorTheme(context);

    final contentColor = isSelected
        ? AppTheme.card
        : AppTheme.onSurfaceVariantColorTheme(context);

    final fontWeight = isSelected ? FontWeight.w600 : FontWeight.normal;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.s20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: contentColor,
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: fontWeight,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
