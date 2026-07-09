import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = LocalDatabase.instance.getAllUsers().isNotEmpty ? LocalDatabase.instance.getAllUsers().first : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Akun', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.username ?? 'Pengguna', style: AppTheme.heading2),
                    const SizedBox(height: 8),
                    Text(user?.userId ?? '-', style: AppTheme.bodyText),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit profil - coming soon'))), child: const Text('Edit Profil')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
