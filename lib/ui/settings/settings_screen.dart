import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(title: const Text('Tema'), subtitle: const Text('Light / Dark - coming soon')),
          ListTile(title: const Text('Sinkronisasi'), subtitle: const Text('Otomatis / Manual - coming soon')),
          ListTile(title: const Text('Bahasa'), subtitle: const Text('ID / EN - coming soon')),
        ],
      ),
    );
  }
}
