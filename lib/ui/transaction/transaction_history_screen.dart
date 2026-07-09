import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import 'dart:async';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';

/// Transaction History screen with full CRUD for Manager/Staff.
/// Read, Update, Delete operations directly on Supabase (cloud-only).
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final BusinessModel business;
  final bool isOwnerView;

  const TransactionHistoryScreen({
    super.key,
    required this.business,
    this.isOwnerView = false,
  });

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final _searchCtrl = TextEditingController();
  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await SupabaseService.instance
          .getTransactionsByBusiness(widget.business.businessId);
      if (mounted) {
        setState(() {
          _all = transactions;
          _filtered = List.from(transactions);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  void _applySearch(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _filtered = List.from(_all);
      } else {
        _filtered = _all
            .where((t) =>
                (t.description ?? '')
                    .toLowerCase()
                    .contains(q.toLowerCase()) ||
                FormatHelpers.rupiah(t.amount).contains(q))
            .toList();
      }
    });
  }

  Future<void> _handleEdit(TransactionModel tx) async {
    // Show edit dialog
    final result = await _showEditDialog(tx);
    if (result == true) {
      await _loadTransactions();
      triggerTransactionRefresh(ref);
    }
  }

  Future<void> _handleDelete(TransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi'),
        content: Text(
          'Yakin ingin menghapus transaksi ${FormatHelpers.rupiah(tx.amount)} tanggal ${tx.transactionDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.lossColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && tx.transactionId != null) {
      try {
        final result = await deleteTransaction(
          transactionId: tx.transactionId!,
        );
        if (!mounted) return;
        if (result.success) {
          await _loadTransactions();
          triggerTransactionRefresh(ref);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Berhasil dihapus'),
              backgroundColor: AppTheme.profitColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Gagal menghapus'),
              backgroundColor: AppTheme.lossColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  Future<bool?> _showEditDialog(TransactionModel tx) async {
    final amountCtrl =
        TextEditingController(text: tx.amount.toStringAsFixed(0));
    final descCtrl = TextEditingController(text: tx.description ?? '');
    final isIncome = tx.type == AppConstants.typeIncome;
    final cogsCtrl = TextEditingController(
        text: isIncome ? tx.cogs.toStringAsFixed(0) : '0');

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isIncome ? 'Edit Uang Masuk' : 'Edit Uang Keluar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
              ),
              if (isIncome) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: cogsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'HPP (Rp)',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final newAmount =
                  double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
              final newCogs =
                  double.tryParse(cogsCtrl.text.replaceAll(',', '')) ?? 0;
              final newDesc = descCtrl.text.trim();

              if (newAmount <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Jumlah harus lebih dari 0')),
                );
                return;
              }

              try {
                final result = await updateTransaction(
                  transactionId: tx.transactionId!,
                  amount: newAmount,
                  cogs: isIncome ? newCogs : null,
                  description: newDesc.isEmpty ? null : newDesc,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx, result.success);
                if (!result.success) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message ?? 'Gagal memperbarui'),
                      backgroundColor: AppTheme.lossColor,
                    ),
                  );
                }
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.pop(ctx, false);
                if (!mounted) return;
                ErrorSnackbar.show(context, ErrorHandler.classify(e));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<String> _getCategoryName(int categoryId) async {
    return SupabaseService.instance
        .getCategoryName(widget.business.businessId, categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canEdit = user != null &&
        (user.role == AppConstants.roleManager ||
            user.role == AppConstants.roleStaff ||
            user.role == AppConstants.roleOwner);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOwnerView
            ? 'Riwayat - ${widget.business.name}'
            : 'Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Cari transaksi...',
              ),
              onChanged: _applySearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SkeletonTransactionList(),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Tidak ada transaksi',
                                style: AppTheme.heading3
                                    .copyWith(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = _filtered[index];
                            final isIncome =
                                tx.type == AppConstants.typeIncome;
                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    _showTransactionDetail(tx),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: (isIncome
                                                  ? AppTheme.profitColor
                                                  : AppTheme.lossColor)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isIncome
                                              ? Icons.trending_up_rounded
                                              : Icons
                                                  .trending_down_rounded,
                                          color: isIncome
                                              ? AppTheme.profitColor
                                              : AppTheme.lossColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              FormatHelpers.displayDate(
                                                  tx.transactionDate),
                                              style: AppTheme.caption
                                                  .copyWith(fontSize: 11),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              FormatHelpers.rupiah(
                                                  tx.amount),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isIncome
                                                    ? AppTheme.profitColor
                                                    : AppTheme.lossColor,
                                              ),
                                            ),
                                            if (tx.description
                                                    ?.isNotEmpty ==
                                                true)
                                              Text(
                                                tx.description!,
                                                style: AppTheme.caption,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (canEdit) ...[
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 20),
                                          onPressed: () =>
                                              _handleEdit(tx),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: AppTheme.lossColor,
                                          ),
                                          onPressed: () =>
                                              _handleDelete(tx),
                                          tooltip: 'Hapus',
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetail(TransactionModel tx) async {
    final catName = await _getCategoryName(tx.categoryId);
    if (!mounted) return;
    final isIncome = tx.type == AppConstants.typeIncome;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isIncome
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: isIncome ? AppTheme.profitColor : AppTheme.lossColor,
            ),
            const SizedBox(width: 8),
            Text(isIncome ? 'Uang Masuk' : 'Uang Keluar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Tanggal',
                FormatHelpers.displayDate(tx.transactionDate)),
            _detailRow('Kategori', catName),
            _detailRow('Jumlah', FormatHelpers.rupiah(tx.amount)),
            if (isIncome && tx.cogs > 0)
              _detailRow('HPP', FormatHelpers.rupiah(tx.cogs)),
            _detailRow('Metode Bayar', _paymentLabel(tx.paymentMethod)),
            if (tx.description?.isNotEmpty == true)
              _detailRow('Deskripsi', tx.description!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTheme.caption.copyWith(fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS';
      default:
        return 'Lainnya';
    }
  }
}
