import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../ui/dashboard/qris_upload_screen.dart';
import '../transaction/transaction_history_screen.dart';

class BusinessDetailScreen extends StatelessWidget {
  final BusinessModel business;

  const BusinessDetailScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
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
                    if (business.description != null &&
                        business.description!.isNotEmpty)
                      Text(business.description!, style: AppTheme.bodyText),
                    const SizedBox(height: 8),
                    Text('ID: ${business.businessId}',
                        style: AppTheme.caption),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                          onPressed: () {
                            _showEditDialog(context);
                          },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text('Upload QRIS'),
                          onPressed: () => _showQrisDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text('Riwayat Transaksi', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lihat semua transaksi bisnis ini',
                      style: AppTheme.bodyText,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TransactionHistoryScreen(
                                  business: business,
                                  isOwnerView: true),
                            ),
                          );
                        },
                        child: const Text('Lihat Riwayat Transaksi'),
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

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: business.name);
    final descCtrl =
        TextEditingController(text: business.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Bisnis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Bisnis'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await Supabase.instance.client
                    .from('businesses')
                    .update({
                      'name': name,
                      'description': descCtrl.text.trim(),
                    })
                    .eq('id', business.businessId);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ErrorSnackbar.showSuccess(
                    context, 'Bisnis berhasil diperbarui');
              } catch (e) {
                ErrorSnackbar.show(context, ErrorHandler.classify(e));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showQrisDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrisUploadScreen(business: business),
      ),
    );
  }
}
