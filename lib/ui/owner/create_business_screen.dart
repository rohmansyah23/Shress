import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../providers/auth_provider.dart';

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
  final _urlController = TextEditingController();
  bool _isSaving = false;

  Uint8List? _selectedImageBytes;
  String? _selectedMimeType;
  String? _previewUrl;
  bool _useUrl = false;
  bool _hasQris = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _inferMimeType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 2 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/png';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedMimeType = picked.mimeType ?? _inferMimeType(bytes);
          _previewUrl = picked.path;
          _useUrl = false;
          _hasQris = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showMessage(context, 'Gagal memilih gambar');
      }
    }
  }

  Future<String?> _uploadQrisImage(int businessId) async {
    if (!_hasQris) return null;

    if (_useUrl) {
      final url = _urlController.text.trim();
      return url.isEmpty ? null : url;
    }

    if (_selectedImageBytes == null) return null;

    final supabase = Supabase.instance.client;
    final ext = _selectedMimeType == 'image/jpeg' ? 'jpg' : 'png';
    final fileName = 'qris_business_$businessId.$ext';

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(_selectedImageBytes!);

    try {
      await supabase.storage.from('qris-images').upload(
        fileName,
        tempFile,
        fileOptions: FileOptions(
          contentType: _selectedMimeType!,
          upsert: true,
        ),
      );
      try {
        await tempFile.delete();
      } catch (_) {}

      return supabase.storage.from('qris-images').getPublicUrl(fileName);
    } catch (e) {
      try {
        await tempFile.delete();
      } catch (_) {}
      rethrow;
    }
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
      final business = await repo.createBusinessWithOwner(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        ownerUserId: user.userId,
      );

      if (_hasQris) {
        try {
          final qrisUrl = await _uploadQrisImage(business.businessId);
          if (qrisUrl != null) {
            await Supabase.instance.client
                .from('businesses')
                .update({'qris_image_url': qrisUrl})
                .eq('id', business.businessId);
          }
        } catch (_) {
          // Bisnis sudah dibuat, QRIS gagal upload — tidak fatal
        }
      }

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
          padding: const EdgeInsets.all(AppTheme.s20),
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.s20),
              decoration: BoxDecoration(
                color: AppTheme.profitColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppTheme.profitColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_business_rounded,
                      size: 32, color: AppTheme.profitColor),
                  const SizedBox(width: AppTheme.s12),
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
            const SizedBox(height: AppTheme.s24),

            const Text('Nama Bisnis*',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.s8),
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
            const SizedBox(height: AppTheme.s20),

            const Text('Deskripsi (opsional)',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.s8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.description_outlined),
                hintText: 'Jenis usaha, alamat, atau informasi lainnya',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppTheme.s24),

            Row(
              children: [
                const Expanded(
                  child: Text('QRIS (opsional)',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                if (_hasQris)
                  TextButton(
                    onPressed: () => setState(() {
                      _hasQris = false;
                      _selectedImageBytes = null;
                      _previewUrl = null;
                      _urlController.clear();
                    }),
                    child: const Text('Hapus'),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.s8),
            Text(
              'Upload QRIS untuk bisnis ini. Bisa dilewati dan diatur nanti.',
              style: AppTheme.caption.copyWith(fontSize: 12),
            ),
            const SizedBox(height: AppTheme.s12),

            if (!_hasQris) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _hasQris = true),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Tambah QRIS'),
                ),
              ),
            ] else ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false, label: Text('Dari Galeri')),
                  ButtonSegment(
                      value: true, label: Text('URL Manual')),
                ],
                selected: {_useUrl},
                onSelectionChanged: (v) =>
                    setState(() => _useUrl = v.first),
              ),
              const SizedBox(height: AppTheme.s12),

              if (_useUrl)
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL Gambar QRIS',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  keyboardType: TextInputType.url,
                )
              else ...[
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 1),
                    ),
                    child: _previewUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            child: Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: AppTheme.s8),
                              Text('Ketuk untuk pilih gambar',
                                  style: AppTheme.caption.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                            ],
                          ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppTheme.s32),

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
