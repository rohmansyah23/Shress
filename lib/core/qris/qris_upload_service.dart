import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to upload QRIS images to Supabase Storage.
class QrisUploadService {
  QrisUploadService._();
  static final QrisUploadService instance = QrisUploadService._();

  static const String _bucketName = 'qris-images';

  static const Map<int, String> _localAssets = {
    1: 'assets/images/qris/business_1_qris.svg',
    2: 'assets/images/qris/business_2_qris.svg',
    3: 'assets/images/qris/business_3_qris.svg',
  };

  Future<List<Map<String, dynamic>>> uploadAll() async {
    final results = <Map<String, dynamic>>[];
    for (final businessId in _localAssets.keys) {
      try {
        await uploadForBusiness(businessId: businessId);
        results.add({'businessId': businessId, 'success': true});
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

  Future<String> uploadForBusiness({required int businessId}) async {
    final assetPath = _localAssets[businessId];
    if (assetPath == null) {
      throw Exception('Tidak ada asset QRIS lokal untuk bisnis ID $businessId');
    }

    final supabase = Supabase.instance.client;

    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    final fileName = assetPath.split('/').last;

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    await supabase.storage.from(_bucketName).upload(
      fileName,
      tempFile,
      fileOptions: const FileOptions(
        contentType: 'image/svg+xml',
        upsert: true,
      ),
    );

    try {
      await tempFile.delete();
    } catch (_) {}

    final publicUrl = supabase.storage.from(_bucketName).getPublicUrl(fileName);

    await supabase
        .from('businesses')
        .update({'qris_image_url': publicUrl})
        .eq('id', businessId);

    return publicUrl;
  }

  static String getPublicUrl(String fileName) {
    final supabase = Supabase.instance.client;
    return supabase.storage.from(_bucketName).getPublicUrl(fileName);
  }

  static bool isStorageUrl(String url) {
    return url.contains('/storage/v1/object/public/');
  }
}
