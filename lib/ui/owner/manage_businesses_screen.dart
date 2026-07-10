import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const SizedBox(height: 12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            const SizedBox(height: 16),
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
  final VoidCallback onDelete;

  const _BusinessItemCard({
    required this.business,
    required this.onEdit,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: AppTheme.heading3),
                  if (business.description != null && business.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      business.description!,
                      style: AppTheme.caption,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.infoColor),
              tooltip: 'Edit Bisnis',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.lossColor),
              tooltip: 'Hapus Bisnis',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
