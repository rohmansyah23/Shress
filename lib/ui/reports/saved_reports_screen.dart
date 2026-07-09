import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

/// Saved financial reports — cloud-only version
/// Fetches pre-calculated financial reports from Supabase.
class SavedReportsScreen extends ConsumerWidget {
  const SavedReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Tersimpan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Laporan tersimpan akan tersedia di sini',
                style: AppTheme.caption),
          ],
        ),
      ),
    );
  }
}
