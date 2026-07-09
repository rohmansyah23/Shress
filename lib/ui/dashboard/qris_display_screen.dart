import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/qris/qris_resolver.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/models/business_model.dart';

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
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 48, color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(business.name, style: AppTheme.heading2, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Scan QRIS untuk melakukan pembayaran',
                    style: AppTheme.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  if (qrisSource != null) ...[
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
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
                                errorBuilder: (_, _, _) => _buildFallback(),
                              ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: _buildFallback(),
                    ),
                    const SizedBox(height: 16),
                    Text(
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

  Widget _buildFallback() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.qr_code, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text('QRIS Tidak Tersedia',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ],
    );
  }
}
