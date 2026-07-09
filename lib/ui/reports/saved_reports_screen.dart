import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';

class SavedReportsScreen extends StatelessWidget {
  const SavedReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = LocalDatabase.instance.getReportsByBusiness(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Tersimpan')),
      body: reports.isEmpty
          ? Center(child: Text('Belum ada laporan tersimpan', style: AppTheme.heading3.copyWith(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final r = reports[index];
                return Card(
                  child: ListTile(
                    title: Text('Periode ${r.period}'),
                    subtitle: Text('Net: ${r.netProfit.toStringAsFixed(0)} • Status: ${r.status}'),
                    trailing: IconButton(icon: const Icon(Icons.open_in_new_rounded), onPressed: () {}),
                  ),
                );
              },
            ),
    );
  }
}
