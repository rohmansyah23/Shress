import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/user_model.dart';
import '../../providers/auth_provider.dart';

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
        title: Text(isEdit ? 'Edit User' : 'Tambah User'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.s20),
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.s20),
              decoration: BoxDecoration(
                color: isEdit
                    ? AppTheme.infoColor.withValues(alpha: 0.05)
                    : AppTheme.profitColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                    size: 32,
                    color:
                        isEdit ? AppTheme.infoColor : AppTheme.profitColor,
                  ),
                  const SizedBox(width: AppTheme.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'EDIT USER' : 'USER BARU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: isEdit
                              ? AppTheme.infoColor
                              : AppTheme.profitColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEdit
                            ? 'Perbarui data user ${widget.user!.username}'
                            : 'Buat akun user baru',
                        style: AppTheme.caption.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.s24),

            const Text('Nama Tampilan (Display Name)',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.s8),
            TextFormField(
              controller: _displayNameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: 'Nama lengkap user',
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Nama tampilan harus diisi' : null,
            ),
            const SizedBox(height: AppTheme.s20),

            const Text('Nama Pengguna (Username)',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.s8),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Username untuk login',
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Username harus diisi' : null,
            ),
            const SizedBox(height: AppTheme.s20),

            if (!isEdit) ...[
              const Text('Email',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'user@contoh.com',
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Email harus diisi' : null,
              ),
              const SizedBox(height: AppTheme.s20),
            ],

            if (!isEdit) ...[
              const Text('Password',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _pwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outlined),
                  hintText: 'Minimal 6 karakter',
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
              ),
              const SizedBox(height: AppTheme.s20),
            ],

            if (isEdit) ...[
              const Text('Email Baru (opsional)',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'Kosongkan jika tidak diubah',
                ),
              ),
              const SizedBox(height: AppTheme.s20),

              const Text('Password Baru (opsional)',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _pwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outlined),
                  hintText: 'Kosongkan jika tidak diubah',
                ),
              ),
              const SizedBox(height: AppTheme.s20),

              const Text('Konfirmasi Password Baru',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _confirmPwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outlined),
                  hintText: 'Ulangi password baru',
                ),
                validator: (v) {
                  if (_pwdCtrl.text.isNotEmpty &&
                      v != _pwdCtrl.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.s20),
            ],

            const Text('Role',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.s8),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [
                if (_selectedRole == 'owner')
                  const DropdownMenuItem(value: 'owner', child: Text('👑 Owner')),
                const DropdownMenuItem(value: 'staff', child: Text('👤 Staff')),
                const DropdownMenuItem(
                    value: 'manager', child: Text('📋 Manager')),
              ],
              onChanged: _selectedRole == 'owner'
                  ? null
                  : (v) => setState(() => _selectedRole = v ?? _selectedRole),
            ),
            const SizedBox(height: AppTheme.s32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
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
