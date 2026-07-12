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
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadQris,
            child: _isUploading
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
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.s20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.s20),
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      size: 48, color: AppTheme.primaryColor),
                  const SizedBox(height: AppTheme.s12),
                  Text('Upload QRIS',
                      style: AppTheme.heading3),
                  const SizedBox(height: AppTheme.s8),
                  Text(
                    'QRIS ini khusus untuk bisnis "${widget.business.name}".\n'
                    'Bisa upload dari galeri atau masukkan URL manual.',
                    textAlign: TextAlign.center,
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.s20),

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
          const SizedBox(height: AppTheme.s20),

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
                height: 260,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant, width: 1),
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
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(height: AppTheme.s12),
                          Text('Ketuk untuk pilih gambar',
                              style: AppTheme.caption
                                  .copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
              ),
            ),
          ],

          const SizedBox(height: AppTheme.s24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isUploading ? null : _uploadQris,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white),
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
