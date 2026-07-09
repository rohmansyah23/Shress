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
import 'transaction_sheet.dart';
import 'edit_transaction_page.dart';
import '../dashboard/qris_display_screen.dart';

enum DateFilter {
  today('Hari Ini'),
  thisWeek('Minggu Ini'),
  thisMonth('Bulan Ini'),
  thisYear('Tahun Ini'),
  all('Semua'),
  custom('Custom');

  final String label;
  const DateFilter(this.label);
}

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
  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];
  bool _isLoading = true;
  bool _initialLoadDone = false;
  DateFilter _selectedFilter = DateFilter.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.watch(transactionRefreshProvider);
    if (_initialLoadDone) {
      _loadTransactions();
    }
    _initialLoadDone = true;
  }

  @override
  void dispose() {
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
          _isLoading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  void _applyFilter() {
    setState(() {
      final now = DateTime.now();
      DateTime? start;
      DateTime? end;

      switch (_selectedFilter) {
        case DateFilter.today:
          start = DateTime(now.year, now.month, now.day);
          end = start;
        case DateFilter.thisWeek:
          start = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          end = now;
        case DateFilter.thisMonth:
          start = DateTime(now.year, now.month, 1);
          end = now;
        case DateFilter.thisYear:
          start = DateTime(now.year, 1, 1);
          end = now;
        case DateFilter.all:
          start = null;
          end = null;
        case DateFilter.custom:
          if (_customStart != null && _customEnd != null) {
            start = _customStart;
            end = _customEnd;
          } else {
            start = null;
            end = null;
          }
      }

      if (start != null && end != null) {
        _filtered = _all.where((t) {
          final txDate = DateTime.tryParse(t.transactionDate);
          if (txDate == null) return false;
          final txDay = DateTime(txDate.year, txDate.month, txDate.day);
          return !txDay.isBefore(start!) && !txDay.isAfter(end!);
        }).toList();
      } else {
        _filtered = List.from(_all);
      }
    });
  }

  void _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(
              start: DateTime(DateTime.now().year, DateTime.now().month, 1),
              end: DateTime.now()),
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _selectedFilter = DateFilter.custom;
      });
      _applyFilter();
    }
  }

  Future<void> _handleEdit(TransactionModel tx) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditTransactionPage(
          transaction: tx,
          business: widget.business,
        ),
      ),
    );
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
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'QRIS Pembayaran',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      QrisDisplayScreen(business: widget.business),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: _loadTransactions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_transaction',
        onPressed: () => TransactionSheet.show(context, widget.business),
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in DateFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(filter.label, style: const TextStyle(fontSize: 12)),
                            selected: _selectedFilter == filter,
                            onSelected: (selected) {
                              if (filter == DateFilter.custom) {
                                _pickCustomRange();
                              } else {
                                setState(() => _selectedFilter = filter);
                                _applyFilter();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SkeletonTransactionList(),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_filtered.isEmpty) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: Center(
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
                        ),
                      );
                    }
                    final tx = _filtered[index];
                    final isIncome = tx.type == AppConstants.typeIncome;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 8,
                        top: index == 0 ? 4 : 0,
                      ),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showTransactionDetail(tx),
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
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
                                        FormatHelpers.rupiah(tx.amount),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isIncome
                                              ? AppTheme.profitColor
                                              : AppTheme.lossColor,
                                        ),
                                      ),
                                      if (tx.description?.isNotEmpty ==
                                          true)
                                        Text(
                                          tx.description!,
                                          style: AppTheme.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (canEdit) ...[
                                  IconButton(
                                    icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20),
                                    onPressed: () => _handleEdit(tx),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: AppTheme.lossColor,
                                    ),
                                    onPressed: () => _handleDelete(tx),
                                    tooltip: 'Hapus',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _filtered.isEmpty ? 1 : _filtered.length,
                ),
              ),
          ],
        ),
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


