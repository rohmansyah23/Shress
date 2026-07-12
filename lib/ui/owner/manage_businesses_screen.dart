import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../ui/dashboard/qris_upload_screen.dart';
import '../../ui/dashboard/qris_display_screen.dart';
import 'create_business_screen.dart';

class ManageBusinessesScreen extends ConsumerStatefulWidget {
  const ManageBusinessesScreen({super.key});

  @override
  ConsumerState<ManageBusinessesScreen> createState() =>
      _ManageBusinessesScreenState();
}

class _ManageBusinessesScreenState extends ConsumerState<ManageBusinessesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditDialog(BusinessModel business) {
    final nameCtrl = TextEditingController(text: business.name);
    final descCtrl = TextEditingController(text: business.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Edit Bisnis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Bisnis',
                hintText: 'Masukkan nama bisnis',
              ),
            ),
            const SizedBox(height: AppTheme.s12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Masukkan deskripsi',
              ),
              maxLines: 2,
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

              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              try {
                await SupabaseService.instance.updateBusiness(
                  businessId: business.businessId,
                  name: name,
                  description: descCtrl.text.trim(),
                );
                ref.invalidate(allBusinessesProvider);
                ref.invalidate(transactionRefreshProvider);
                if (mounted) {
                  ErrorSnackbar.showSuccess(
                      context, 'Bisnis berhasil diperbarui');
                }
              } catch (e) {
                if (mounted) {
                  ErrorSnackbar.show(context, ErrorHandler.classify(e));
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BusinessModel business) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
        title: const Text('Hapus Bisnis'),
        content: Text(
          'Apakah Anda yakin ingin menghapus bisnis "${business.name}"? Semua transaksi dan data terkait akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              try {
                await SupabaseService.instance.deleteBusiness(business.businessId);
                ref.invalidate(allBusinessesProvider);
                ref.invalidate(transactionRefreshProvider);
                if (mounted) {
                  ErrorSnackbar.showSuccess(
                      context, 'Bisnis berhasil dihapus');
                }
              } catch (e) {
                if (mounted) {
                  ErrorSnackbar.show(context, ErrorHandler.classify(e));
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _openQrisUpload(BusinessModel business) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QrisUploadScreen(business: business),
      ),
    );
    if (result == true) {
      ref.invalidate(allBusinessesProvider);
    }
  }

  void _viewQris(BusinessModel business) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrisDisplayScreen(business: business),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(allBusinessesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Bisnis'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari bisnis...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const CreateBusinessScreen(),
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(allBusinessesProvider);
                          ref.invalidate(transactionRefreshProvider);
                        }
                      },
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: const Text('Tambah Bisnis'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: businessesAsync.when(
                  data: (businesses) {
                    final filtered = businesses.where((b) {
                      if (_searchQuery.isEmpty) return true;
                      return b.name.toLowerCase().contains(_searchQuery) ||
                          (b.description?.toLowerCase().contains(_searchQuery) ?? false);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_rounded,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: AppTheme.s16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada bisnis ditemukan'
                                  : 'Belum ada bisnis terdaftar',
                              style: AppTheme.caption.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(allBusinessesProvider);
                        ref.invalidate(transactionRefreshProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final b = filtered[index];
                          return _BusinessItemCard(
                            business: b,
                            onEdit: () => _showEditDialog(b),
                            onQris: () => _openQrisUpload(b),
                            onViewQris: () => _viewQris(b),
                            onDelete: () => _confirmDelete(b),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => ErrorRetryWidget.fromAppError(
                    ErrorHandler.classify(err),
                    onRetry: () => ref.invalidate(allBusinessesProvider),
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BusinessItemCard extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback onEdit;
  final VoidCallback onQris;
  final VoidCallback onViewQris;
  final VoidCallback onDelete;

  const _BusinessItemCard({
    required this.business,
    required this.onEdit,
    required this.onQris,
    required this.onViewQris,
    required this.onDelete,
  });

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasQris = business.qrisImageUrl != null &&
        business.qrisImageUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                _initials(business.name),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: AppTheme.heading3),
                  if (business.description != null && business.description!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.s4),
                    Text(
                      business.description!,
                      style: AppTheme.caption,
                    ),
                  ],
                  const SizedBox(height: AppTheme.s4),
                  Row(
                    children: [
                      Icon(
                        hasQris ? Icons.qr_code_2_rounded : Icons.qr_code_2_outlined,
                        size: 14,
                        color: hasQris ? AppTheme.profitColorTheme(context) : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasQris ? 'QRIS aktif' : 'Belum ada QRIS',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasQris ? AppTheme.profitColorTheme(context) : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'viewQris':
                    onViewQris();
                    break;
                  case 'qris':
                    onQris();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit Bisnis'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (hasQris)
                  const PopupMenuItem<String>(
                    value: 'viewQris',
                    child: ListTile(
                      leading: Icon(Icons.qr_code_rounded),
                      title: Text('Lihat QRIS'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem<String>(
                  value: 'qris',
                  child: ListTile(
                    leading: Icon(Icons.qr_code_2_rounded),
                    title: Text('Kelola QRIS'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: AppTheme.lossColor),
                    title: Text('Hapus Bisnis',
                        style: TextStyle(color: AppTheme.lossColor)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
