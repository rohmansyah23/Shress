import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';

import '../../data/local/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';


import '../../core/theme/app_icon_size.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final UserModel? user; // null = create, non-null = edit

  const UserFormScreen({super.key, this.user});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  String _selectedRole = 'staff';
  bool _isSaving = false;
  bool _obscurePwd = true;
  bool _obscureConfirmPwd = true;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _usernameCtrl.text = widget.user!.username;
      _selectedRole = widget.user!.role;
      _displayNameCtrl.text = widget.user!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(authRepositoryProvider);

      if (_isEdit) {
        final user = widget.user!;

        // Update username & role in public.users
        await repo.updateUserRole(
          userId: user.userId,
          newRole: _selectedRole,
        );
        await ref.read(authRepositoryProvider).updateUserProfile(
              userId: user.userId,
              username: _usernameCtrl.text.trim(),
            );
        await ref.read(authRepositoryProvider).updateUserDisplayName(
              userId: user.userId,
              displayName: _displayNameCtrl.text.trim(),
            );

        // Update email if provided
        if (_emailCtrl.text.isNotEmpty) {
          await repo.updateUserEmail(
            userId: user.userId,
            email: _emailCtrl.text.trim(),
          );
        }

        // Update password if provided
        if (_pwdCtrl.text.isNotEmpty) {
          await repo.updateUserPassword(
            userId: user.userId,
            password: _pwdCtrl.text.trim(),
          );
        }

        if (!mounted) return;
        ErrorSnackbar.showSuccess(context, 'User berhasil diperbarui');
      } else {
        // Create
        await repo.createUser(
          email: _emailCtrl.text.trim(),
          password: _pwdCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          role: _selectedRole,
          displayName: _displayNameCtrl.text.trim(),
        );

        if (!mounted) return;
        ErrorSnackbar.showSuccess(context, 'User berhasil ditambahkan');
      }

      if (mounted) {
        ref.invalidate(allUsersProvider);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _isEdit;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Pengguna' : 'Tambah Pengguna'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Simpan',
                    style: AppTheme.subtitle.copyWith(fontSize: 14)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s20),
              decoration: BoxDecoration(
                color: isEdit
                    ? AppTheme.infoColor.withValues(alpha: 0.05)
                    : AppTheme.profitColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                border: Border.all(
                  color: isEdit
                      ? AppTheme.infoColor.withValues(alpha: 0.15)
                      : AppTheme.profitColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                    size: AppIconSize.s32,
                    color:
                        isEdit ? AppTheme.infoColor : AppTheme.profitColor,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'EDIT USER' : 'USER BARU',
                        style: AppTheme.labelSmall.copyWith(
                          letterSpacing: 1,
                          color: isEdit
                              ? AppTheme.infoColor
                              : AppTheme.profitColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        isEdit
                            ? 'Perbarui data user ${widget.user!.username}'
                            : 'Buat akun user baru',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            Text(
              'Nama Tampilan (Display Name)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceColorTheme(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextFormField(
              controller: _displayNameCtrl,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.onSurfaceColorTheme(context),
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Nama tampilan harus diisi' : null,
              decoration: const InputDecoration(
                hintText: 'Nama lengkap user',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),

            Text(
              'Nama Pengguna (Username)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceColorTheme(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextFormField(
              controller: _usernameCtrl,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.onSurfaceColorTheme(context),
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Username harus diisi' : null,
              decoration: const InputDecoration(
                hintText: 'Username untuk login',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),

            if (!isEdit) ...[
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Email harus diisi' : null,
                decoration: const InputDecoration(
                  hintText: 'user@contoh.com',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
            ],

            if (!isEdit) ...[
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextFormField(
                controller: _pwdCtrl,
                obscureText: _obscurePwd,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
                validator: (v) {
                  if (v?.trim().isEmpty == true) {
                    return 'Password harus diisi';
                  }
                  if ((v?.length ?? 0) < 6) {
                    return 'Minimal 6 karakter';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Minimal 6 karakter',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                    onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
            ],

            if (isEdit) ...[
              Text(
                'Email Baru (opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
                decoration: const InputDecoration(
                  hintText: 'Kosongkan jika tidak diubah',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),

              Text(
                'Password Baru (opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextFormField(
                controller: _pwdCtrl,
                obscureText: _obscurePwd,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Kosongkan jika tidak diubah',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                    onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),

              Text(
                'Konfirmasi Password Baru',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextFormField(
                controller: _confirmPwdCtrl,
                obscureText: _obscureConfirmPwd,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
                validator: (v) {
                  if (_pwdCtrl.text.isNotEmpty && v != _pwdCtrl.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Ulangi password baru',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPwd ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                    onPressed: () => setState(() => _obscureConfirmPwd = !_obscureConfirmPwd),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
            ],

            Text(
              'Role',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceColorTheme(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              isDense: true,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.onSurfaceColorTheme(context),
              ),
              iconEnabledColor: AppTheme.onSurfaceColorTheme(context),
              dropdownColor: AppTheme.surfaceColorTheme(context),
              borderRadius: BorderRadius.circular(16),
              items: [
                if (_selectedRole == 'owner')
                  DropdownMenuItem(
                    value: 'owner',
                    child: Text(
                      'Owner',
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                    ),
                  ),
                DropdownMenuItem(
                  value: 'staff',
                  child: Text(
                    'Staff',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'manager',
                  child: Text(
                    'Manager',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                  ),
                ),
              ],
              onChanged: _selectedRole == 'owner'
                  ? null
                  : (v) => setState(() => _selectedRole = v ?? _selectedRole),
            ),
            const SizedBox(height: AppSpacing.s32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.onPrimaryColorTheme(context)),
                      )
                    : Icon(isEdit ? Icons.save_rounded : Icons.person_add_rounded),
                label: Text(_isSaving
                    ? 'Menyimpan...'
                    : (isEdit ? 'Simpan Perubahan' : 'Tambah User')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
