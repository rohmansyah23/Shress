import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/qris/qris_resolver.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/models/business_model.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

/// Full-screen QRIS display for the QRIS tab in bottom navigation.
class QrisDisplayScreen extends StatelessWidget {
  final BusinessModel business;

  const QrisDisplayScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    final qrisSource = QrisResolver.getQrisSource(business);
    final isLocal = qrisSource != null && QrisResolver.isLocalAsset(qrisSource);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRIS Pembayaran'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, size: AppIconSize.s48, color: AppTheme.primaryColorTheme(context)),
                  const SizedBox(height: AppSpacing.s16),
                  Text(business.name, style: AppTheme.heading2, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Scan QRIS untuk melakukan pembayaran',
                    style: AppTheme.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  if (qrisSource != null) ...[
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
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowColorTheme(context),
                        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                        border: Border.all(color: AppTheme.outlineVariantColorTheme(context), width: 1),
                      ),
                      child: _buildFallback(context),
                    ),
                    const SizedBox(height: AppSpacing.s16),                      Text(
                      'QRIS belum tersedia untuk bisnis ini',
                      style: AppTheme.caption.copyWith(color: AppTheme.warningColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
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
