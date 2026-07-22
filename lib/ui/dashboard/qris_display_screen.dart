import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/qris/qris_resolver.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/models/business_model.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_icon_size.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import 'qris_upload_screen.dart';

/// Full-screen QRIS display for the QRIS tab in bottom navigation.
/// Rewritten as a ConsumerStatefulWidget to watch user roles and support auto-refresh.
class QrisDisplayScreen extends ConsumerStatefulWidget {
  final BusinessModel business;

  const QrisDisplayScreen({super.key, required this.business});

  @override
  ConsumerState<QrisDisplayScreen> createState() => _QrisDisplayScreenState();
}

class _QrisDisplayScreenState extends ConsumerState<QrisDisplayScreen> {
  late BusinessModel _currentBusiness;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentBusiness = widget.business;
  }

  Future<void> _refreshBusiness() async {
    setState(() => _isLoading = true);
    try {
      final updated = await SupabaseService.instance.getBusinessById(_currentBusiness.businessId);
      if (updated != null && mounted) {
        setState(() {
          _currentBusiness = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToUpload(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QrisUploadScreen(business: _currentBusiness),
      ),
    );
    if (result == true) {
      _refreshBusiness();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isOwner = user?.role == 'owner';

    final qrisSource = (_currentBusiness.qrisImageUrl != null && _currentBusiness.qrisImageUrl!.isNotEmpty)
        ? QrisResolver.getQrisSource(_currentBusiness)
        : null;
    final isLocal = qrisSource != null && QrisResolver.isLocalAsset(qrisSource);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRIS Pembayaran'),
        actions: [
          if (qrisSource != null && isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _navigateToUpload(context),
              tooltip: 'Edit QRIS',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (qrisSource != null) ...[
                          Icon(Icons.qr_code, size: AppIconSize.s48, color: AppTheme.primaryColorTheme(context)),
                          const SizedBox(height: AppSpacing.s16),
                          Text(_currentBusiness.name, style: AppTheme.heading2, textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            'Scan QRIS untuk melakukan pembayaran',
                            style: AppTheme.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowColorTheme(context),
                              borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                              border: Border.all(color: AppTheme.outlineVariantColorTheme(context), width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                              child: isLocal
                                  ? SvgPicture.asset(
                                      qrisSource,
                                      fit: BoxFit.contain,
                                      placeholderBuilder: (_) =>
                                          const CircularProgressIndicator(),
                                    )
                                  : Image.network(
                                      qrisSource,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (_, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (_, _, _) => _buildFallback(context),
                                    ),
                            ),
                          ),
                        ] else ...[
                          _buildEmptyState(context, isOwner),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isOwner) {
    final themeColor = AppTheme.primaryColorTheme(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.s16),
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowColorTheme(context),
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            border: Border.all(
              color: AppTheme.outlineVariantColorTheme(context),
              width: 1.5,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.s24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
              border: Border.all(
                color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 48,
                      color: themeColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'Belum Ada QRIS',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s32),
        Text(
          isOwner ? 'QRIS Pembayaran Belum Diunggah' : 'QRIS Pembayaran Belum Tersedia',
          style: AppTheme.heading2.copyWith(
            color: AppTheme.primaryColorTheme(context),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Text(
            isOwner
                ? 'Unggah kode QRIS toko Anda agar pelanggan dapat membayar secara digital dengan cepat dan mudah.'
                : 'Pemilik usaha belum mengunggah QRIS. Silakan hubungi pemilik usaha (Owner) agar pembayaran digital dapat diaktifkan.',
            style: AppTheme.caption.copyWith(
              height: 1.5,
              color: AppTheme.onSurfaceVariantColorTheme(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (isOwner) ...[
          const SizedBox(height: AppSpacing.s32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _navigateToUpload(context),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text(
                'Unggah QRIS Toko',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.qr_code, size: AppIconSize.s80,
            color: AppTheme.onSurfaceVariantColorTheme(context)),
        const SizedBox(height: AppSpacing.s8),
        Text('QRIS Tidak Tersedia',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariantColorTheme(context))),
      ],
    );
  }
}
