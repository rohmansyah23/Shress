import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';

class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unsynced = LocalDatabase.instance.getUnsyncedTransactions();
    return Scaffold(
      appBar: AppBar(title: const Text('Status Sinkronisasi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pending items', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Text('Transaksi belum disinkron: ${unsynced.length}', style: AppTheme.bodyText),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync sekarang - coming soon'))), child: const Text('Sinkronisasi Manual')),
          ],
        ),
      ),
    );
  }
}
