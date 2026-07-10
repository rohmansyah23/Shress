import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';

class QrisUploadScreen extends StatefulWidget {
  const QrisUploadScreen({super.key});

  @override
  State<QrisUploadScreen> createState() => _QrisUploadScreenState();
}

class _QrisUploadScreenState extends State<QrisUploadScreen> {
  List<BusinessModel> _businesses = [];
  bool _isLoading = true;
  bool _isUploading = false;
  File? _selectedImage;
  String? _previewUrl;
  final _urlController = TextEditingController();
  bool _useUrl = false;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final businesses =
          await SupabaseService.instance.getAllBusinesses();
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
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
        setState(() {
          _selectedImage = File(picked.path);
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

  Future<void> _uploadQris() async {
    setState(() => _isUploading = true);
    try {
      String publicUrl;

      if (_useUrl) {
        publicUrl = _urlController.text.trim();
        if (publicUrl.isEmpty) {
          ErrorSnackbar.showMessage(context, 'Masukkan URL QRIS');
          setState(() => _isUploading = false);
          return;
        }
      } else {
        if (_selectedImage == null) {
          ErrorSnackbar.showMessage(
              context, 'Pilih gambar atau masukkan URL');
          setState(() => _isUploading = false);
          return;
        }

        final supabase = Supabase.instance.client;
        final ext = _selectedImage!.path.split('.').last;
        final fileName = 'qris_shared.$ext';
        final contentType = ext == 'png'
            ? 'image/png'
            : ext == 'jpg' || ext == 'jpeg'
                ? 'image/jpeg'
                : 'image/webp';

        try {
          await supabase.storage.from('qris-images').upload(
            fileName,
            _selectedImage!,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isUploading = false);
          ErrorSnackbar.showMessage(
            context,
            'Gagal upload ke penyimpanan. Gunakan opsi URL manual.',
          );
          return;
        }

        publicUrl =
            supabase.storage.from('qris-images').getPublicUrl(fileName);
      }

      // Update all businesses
      final supabase = Supabase.instance.client;
      for (final business in _businesses) {
        await supabase
            .from('businesses')
            .update({'qris_image_url': publicUrl})
            .eq('id', business.businessId);
      }

      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QRIS berhasil diperbarui untuk semua bisnis'),
          backgroundColor: AppTheme.profitColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        title: const Text('Upload QRIS'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.qr_code_scanner_rounded,
                            size: 48, color: AppTheme.primaryColor),
                        const SizedBox(height: 12),
                        Text('Upload QRIS',
                            style: AppTheme.heading3),
                        const SizedBox(height: 8),
                        Text(
                          'Gambar QRIS akan digunakan untuk SEMUA bisnis.\n'
                          'Bisa upload dari galeri atau masukkan URL manual.',
                          textAlign: TextAlign.center,
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Option toggle
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
                const SizedBox(height: 20),

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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 260,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant, width: 1),
                      ),
                      child: _previewUrl != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text('Ketuk untuk pilih gambar',
                                    style: AppTheme.caption
                                        .copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Text(
                  '${_businesses.length} bisnis akan menggunakan QRIS ini',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption,
                ),
                const SizedBox(height: 24),
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
