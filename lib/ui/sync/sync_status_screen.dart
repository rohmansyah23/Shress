import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Sync status screen — V1 cloud-only, offline sync deferred to V2.
class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Sinkronisasi')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.s12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.s16),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_rounded,
                        color: AppTheme.profitColor, size: 32),
                    const SizedBox(width: AppTheme.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cloud Mode Aktif',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppTheme.s4),
                          Text(
                            'Semua data tersimpan langsung ke cloud.',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.s16),
            Text(
              'Mode offline akan tersedia di V2.',
              style: AppTheme.caption,
            ),
          ],
        ),
      ),
    );
  }
}
