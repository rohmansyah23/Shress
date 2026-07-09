import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/database.dart';
import '../../data/local/models/business_model.dart';

/// Service to upload QRIS images to Supabase Storage and link them
/// to the business records in the database.
///
/// Usage (from CLI):
///   await QrisUploadService.instance.uploadAll();
///
/// Or upload a single business:
///   await QrisUploadService.instance.uploadForBusiness(businessId: 1);
class QrisUploadService {
  QrisUploadService._();
  static final QrisUploadService instance = QrisUploadService._();

  /// The Supabase storage bucket name for QRIS images.
  static const String _bucketName = 'qris-images';

  /// Map of business ID → local asset path for QRIS SVGs.
  static const Map<int, String> _localAssets = {
    1: 'assets/images/qris/business_1_qris.svg',
    2: 'assets/images/qris/business_2_qris.svg',
    3: 'assets/images/qris/business_3_qris.svg',
  };

  /// Upload all local QRIS SVG files to Supabase Storage
  /// and update each business record with the public Storage URL.
  ///
  /// Returns a list of results (businessId, success, error?).
  Future<List<Map<String, dynamic>>> uploadAll() async {
    final results = <Map<String, dynamic>>[];
    for (final businessId in _localAssets.keys) {
      try {
        await uploadForBusiness(businessId: businessId);
        results.add({
          'businessId': businessId,
          'success': true,
        });
      } catch (e) {
        results.add({
          'businessId': businessId,
          'success': false,
          'error': e.toString(),
        });
      }
    }
    return results;
  }

  /// Upload QRIS image for a specific business to Supabase Storage
  /// and update the business record with the public Storage URL.
  Future<String> uploadForBusiness({
    required int businessId,
  }) async {
    final assetPath = _localAssets[businessId];
    if (assetPath == null) {
      throw Exception('Tidak ada asset QRIS lokal untuk bisnis ID $businessId');
    }

    final supabase = Supabase.instance.client;

    // Read the SVG file from the asset bundle
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    final fileName = assetPath.split('/').last;

    // Write to temp file (Supabase Storage API expects a File object)
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    // Upload to Supabase Storage (upsert in case it already exists)
    await supabase.storage.from(_bucketName).upload(
      fileName,
      tempFile,
      fileOptions: const FileOptions(
        contentType: 'image/svg+xml',
        upsert: true,
      ),
    );

    // Clean up temp file
    try {
      await tempFile.delete();
    } catch (_) {}

    // Get the public URL
    final publicUrl = supabase.storage.from(_bucketName).getPublicUrl(fileName);

    // Update the business record in Supabase
    await supabase
        .from('businesses')
        .update({'qris_image_url': publicUrl})
        .eq('id', businessId);

    // Also update the local Hive cache
    final cachedBusiness = LocalDatabase.instance.getBusinessById(businessId);
    if (cachedBusiness != null) {
      final updated = BusinessModel(
        businessId: cachedBusiness.businessId,
        name: cachedBusiness.name,
        description: cachedBusiness.description,
        qrisImageUrl: publicUrl,
        lastSyncedAt: cachedBusiness.lastSyncedAt,
        createdAt: cachedBusiness.createdAt,
      );
      await LocalDatabase.instance.saveBusiness(updated);
    }

    return publicUrl;
  }

  /// Get the public Storage URL for a QRIS image by filename.
  static String getPublicUrl(String fileName) {
    final supabase = Supabase.instance.client;
    return supabase.storage.from(_bucketName).getPublicUrl(fileName);
  }

  /// Check if a URL is a Supabase Storage URL (vs local asset).
  static bool isStorageUrl(String url) {
    return url.contains('/storage/v1/object/public/');
  }
}
