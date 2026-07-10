import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../providers/auth_provider.dart';

/// Screen for creating a new business (Owner only).
class CreateBusinessScreen extends ConsumerStatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  ConsumerState<CreateBusinessScreen> createState() =>
      _CreateBusinessScreenState();
}

class _CreateBusinessScreenState
    extends ConsumerState<CreateBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted) {
          ErrorSnackbar.showMessage(context, 'Sesi tidak valid');
        }
        return;
      }

      final repo = ref.read(authRepositoryProvider);
      await repo.createBusinessWithOwner(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        ownerUserId: user.userId,
      );

      if (!mounted) return;
      ref.invalidate(allBusinessesProvider);

      ErrorSnackbar.showSuccess(context, 'Bisnis berhasil dibuat');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Bisnis Baru'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleCreate,
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
          padding: const EdgeInsets.all(20),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.profitColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.profitColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_business_rounded,
                      size: 32, color: AppTheme.profitColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BISNIS BARU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppTheme.profitColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lengkapi data bisnis untuk memulai',
                          style: AppTheme.caption.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Business Name
            const Text('Nama Bisnis*',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.store_outlined),
                hintText: 'Contoh: Warung Makmur',
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Nama bisnis harus diisi' : null,
            ),
            const SizedBox(height: 20),

            // Description
            const Text('Deskripsi (opsional)',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.description_outlined),
                hintText: 'Jenis usaha, alamat, atau informasi lainnya',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _handleCreate,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_business_rounded),
                label: Text(
                    _isSaving ? 'Menyimpan...' : 'Buat Bisnis'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
