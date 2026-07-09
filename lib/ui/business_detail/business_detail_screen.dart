import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/models/business_model.dart';
import '../transaction/transaction_history_screen.dart';

class BusinessDetailScreen extends StatelessWidget {
  final BusinessModel business;

  const BusinessDetailScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    final db = LocalDatabase.instance;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(business.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informasi Bisnis', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: AppTheme.heading2),
                    const SizedBox(height: 8),
                    if (business.description != null && business.description!.isNotEmpty)
                      Text(business.description!, style: AppTheme.bodyText),
                    const SizedBox(height: 8),
                    Text('ID: ${business.businessId}', style: AppTheme.caption),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit bisnis - coming soon')),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text('Upload QRIS'),
                          onPressed: () async {
                            final ctrl = TextEditingController(text: business.qrisImageUrl ?? '');
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Upload QRIS'),
                                content: TextField(
                                  controller: ctrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Image URL atau path lokal',
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
                                  ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Simpan')),
                                ],
                              ),
                            );
                            if (!context.mounted) return;
                            if (ok == true) {
                              final updated = BusinessModel(
                                businessId: business.businessId,
                                name: business.name,
                                description: business.description,
                                qrisImageUrl: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
                                lastSyncedAt: business.lastSyncedAt,
                                createdAt: business.createdAt,
                              );
                              await LocalDatabase.instance.saveBusiness(updated);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QRIS disimpan')));
                              if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: updated)));
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text('Ringkasan Transaksi', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total transaksi: ${db.getTransactionsByBusiness(business.businessId).length}', style: AppTheme.bodyText),
                    const SizedBox(height: 8),
                    Text('Last sync: -', style: AppTheme.caption),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TransactionHistoryScreen(business: business),
                        ));
                      },
                      child: const Text('Lihat Riwayat Transaksi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                      ),
                    ),
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
