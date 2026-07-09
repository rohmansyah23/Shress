import '../../data/local/models/business_model.dart';
import 'qris_upload_service.dart';

/// Resolves QRIS image sources for a given business.
///
/// Resolution priority:
///   1. Supabase Storage URL (from `business.qrisImageUrl` if it's a Storage URL)
///   2. Local SVG asset (offline-first, bundled with the app)
///   3. Network URL fallback (from `business.qrisImageUrl` if it's an external URL)
///   4. `null` (UI shows fallback icon)
///
/// Note: The local SVGs are placeholder images. For production,
/// upload actual QRIS images using [QrisUploadService].
class QrisResolver {
  QrisResolver._();

  /// Map of business ID → local asset path for QRIS SVG images.
  /// These are bundled with the app as offline-first placeholders.
  static const Map<int, String> _localAssets = {
    1: 'assets/images/qris/business_1_qris.svg',
    2: 'assets/images/qris/business_2_qris.svg',
    3: 'assets/images/qris/business_3_qris.svg',
  };

  /// Get the local asset path for a business, or null if not available.
  static String? getLocalAssetPath(int businessId) {
    return _localAssets[businessId];
  }

  /// Get the best available QRIS image source for a business.
  ///
  /// Returns:
  ///   - Supabase Storage URL (if `business.qrisImageUrl` points to Storage)
  ///   - Local SVG asset path (if available, offline-first)
  ///   - External network URL (fallback from `business.qrisImageUrl`)
  ///   - `null` (no QRIS available)
  static String? getQrisSource(BusinessModel business) {
    final url = business.qrisImageUrl;

    // Priority 1: Supabase Storage URL (already synced)
    if (url != null &&
        url.isNotEmpty &&
        QrisUploadService.isStorageUrl(url)) {
      return url;
    }

    // Priority 2: Local asset (offline-first placeholder)
    final local = _localAssets[business.businessId];
    if (local != null) return local;

    // Priority 3: External network URL fallback
    if (url != null && url.isNotEmpty && !url.startsWith('assets/')) {
      return url;
    }

    // Priority 4: Nothing available
    return null;
  }

  /// Check if the source is a local asset (vs network URL).
  static bool isLocalAsset(String source) {
    return source.startsWith('assets/');
  }

  /// Check if the source is a Supabase Storage URL.
  static bool isStorageUrl(String source) {
    return QrisUploadService.isStorageUrl(source);
  }

  /// Get list of business IDs that have local QRIS assets.
  static List<int> getBusinessesWithLocalQris() {
    return _localAssets.keys.toList();
  }

  /// Build the expected Supabase Storage URL for a business.
  /// Useful for showing the expected URL before upload.
  static String? getExpectedStorageUrl(int businessId) {
    final localPath = _localAssets[businessId];
    if (localPath == null) return null;
    final fileName = localPath.split('/').last;
    try {
      return QrisUploadService.getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }
}
