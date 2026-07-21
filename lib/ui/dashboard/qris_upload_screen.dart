import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/widgets/app_text_field.dart';

class QrisUploadScreen extends StatefulWidget {
  final BusinessModel business;

  const QrisUploadScreen({super.key, required this.business});

  @override
  State<QrisUploadScreen> createState() => _QrisUploadScreenState();
}

class _QrisUploadScreenState extends State<QrisUploadScreen> {
  bool _isUploading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedMimeType;
  String? _previewUrl;
  final _urlController = TextEditingController();
  bool _useUrl = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
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
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.showMessage(context, 'Gagal memilih gambar');
      }
    }
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

  Future<void> _uploadQris() async {
    setState(() => _isUploading = true);
    try {
      String publicUrl;

      if (_useUrl) {
        publicUrl = _urlController.text.trim();
        if (publicUrl.isEmpty) {
          if (mounted) {
            ErrorSnackbar.showMessage(context, 'Masukkan URL QRIS');
          }
          setState(() => _isUploading = false);
          return;
        }
      } else {
        if (_selectedImageBytes == null) {
          if (mounted) {
            ErrorSnackbar.showMessage(
                context, 'Pilih gambar atau masukkan URL');
          }
          setState(() => _isUploading = false);
          return;
        }

        final supabase = Supabase.instance.client;
        final ext = _selectedMimeType == 'image/jpeg' ? 'jpg' : 'png';
        final fileName = 'qris_business_${widget.business.businessId}.$ext';

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
        } catch (e) {
          if (!mounted) return;
          setState(() => _isUploading = false);
          final msg = e.toString();
          ErrorSnackbar.showMessage(
            context,
            'Gagal upload: ${msg.length > 120 ? msg.substring(0, 120) : msg}',
          );
          return;
        }

        publicUrl =
            supabase.storage.from('qris-images').getPublicUrl(fileName);
      }

      final supabase = Supabase.instance.client;
      await supabase
          .from('businesses')
          .update({'qris_image_url': publicUrl})
          .eq('id', widget.business.businessId);

      if (!mounted) return;
      setState(() => _isUploading = false);
      ErrorSnackbar.showSuccess(
          context, 'QRIS berhasil diperbarui untuk ${widget.business.name}');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ErrorSnackbar.show(context, ErrorHandler.classify(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QRIS - ${widget.business.name}'),

      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: AppIconSize.s48,
                    color: AppTheme.primaryColorTheme(context),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'Upload QRIS',
                    style: AppTheme.heading3.copyWith(
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.onSurfaceVariantColorTheme(context),
                      ),
                      children: [
                        const TextSpan(text: 'QRIS ini khusus untuk bisnis '),
                        TextSpan(
                          text: '"${widget.business.name}"',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColorTheme(context),
                          ),
                        ),
                        const TextSpan(
                          text: '.\nBisa upload dari galeri atau masukkan URL manual.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),

          SegmentedButton<bool>(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.accentColorTheme(context);
                }
                return Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.surfaceContainerColorTheme(context)
                    : null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                return Colors.white;
              }),
              textStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
                return const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
              }),
            ),
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
          const SizedBox(height: AppSpacing.s20),

          if (_useUrl)
            AppTextField(
              controller: _urlController,
              labelText: 'URL Gambar QRIS',
              hintText: 'https://...',
              prefixIcon: const Icon(Icons.link_rounded),
              keyboardType: TextInputType.url,
            )
          else ...[
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
              child: Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerColorTheme(context),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                  border: Border.all(
                      color: AppTheme.outlineVariantColorTheme(context), width: 1),
                ),
                child: _previewUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
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
                              size: AppIconSize.s64,
                              color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.5)),
                          const SizedBox(height: AppSpacing.s12),
                          Text('Ketuk untuk pilih gambar',
                              style: AppTheme.caption
                                  .copyWith(
                                      color: AppTheme.onSurfaceVariantColorTheme(context))),
                        ],
                      ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.s24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isUploading ? null : _uploadQris,
              icon: _isUploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.onPrimaryColorTheme(context)),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(_isUploading
                  ? 'Menyimpan...'
                  : 'Simpan QRIS'),
            ),
          ),
        ],
      ),
    );
  }
}
