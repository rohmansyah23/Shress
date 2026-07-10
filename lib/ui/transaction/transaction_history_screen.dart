import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import 'dart:async';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
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

enum TypeFilter {
  all('Semua'),
  income('Uang Masuk'),
  expense('Uang Keluar');

  final String label;
  const TypeFilter(this.label);
}

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final BusinessModel business;
  final bool isOwnerView;
  final bool showAppBar;

  const TransactionHistoryScreen({
    super.key,
    required this.business,
    this.isOwnerView = false,
    this.showAppBar = true,
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
  DateFilter _selectedFilter = DateFilter.all;
  TypeFilter _selectedType = TypeFilter.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  bool _matchesSearch(TransactionModel tx) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();

    // Search by description
    if (tx.description?.toLowerCase().contains(q) == true) return true;

    // Search by formatted amount (e.g. "Rp50.000")
    final amountStr = FormatHelpers.rupiah(tx.amount).toLowerCase();
    if (amountStr.contains(q)) return true;

    // Search by formatted date (e.g. "15 Jan 2024")
    final dateStr = FormatHelpers.displayDate(tx.transactionDate).toLowerCase();
    if (dateStr.contains(q)) return true;

    // Search by raw date (e.g. "2024-01-15")
    if (tx.transactionDate.toLowerCase().contains(q)) return true;

    // Search by payment method label
    final paymentLabel = _paymentLabel(tx.paymentMethod).toLowerCase();
    if (paymentLabel.contains(q)) return true;

    // Search by type
    if ((tx.type == AppConstants.typeIncome ? 'uang masuk' : 'uang keluar').contains(q)) return true;

    return false;
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

      Iterable<TransactionModel> filtered = _all;

      // Apply date filter
      if (start != null && end != null) {
        filtered = filtered.where((t) {
          final txDate = DateTime.tryParse(t.transactionDate);
          if (txDate == null) return false;
          final txDay = DateTime(txDate.year, txDate.month, txDate.day);
          return !txDay.isBefore(start!) && !txDay.isAfter(end!);
        });
      }

      // Apply type filter
      if (_selectedType == TypeFilter.income) {
        filtered = filtered.where((t) => t.type == AppConstants.typeIncome);
      } else if (_selectedType == TypeFilter.expense) {
        filtered = filtered.where((t) => t.type == AppConstants.typeExpense);
      }

      // Apply search query
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where(_matchesSearch);
      }

      _filtered = filtered.toList();
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
          'Yakin ingin menghapus transaksi ${FormatHelpers.rupiah(tx.amount)} tanggal ${FormatHelpers.displayDate(tx.transactionDate)}?',
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
          ErrorSnackbar.showSuccess(
              context, result.message ?? 'Berhasil dihapus');
        } else {
          if (!mounted) return;
          ErrorSnackbar.showError(
              context, result.message ?? 'Gagal menghapus');
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
    ref.listen<int>(transactionRefreshProvider, (prev, next) {
      if (prev != null && prev != next) _loadTransactions();
    });
    final user = ref.watch(currentUserProvider);
    final canEdit = user != null &&
        (user.role == AppConstants.roleManager ||
            user.role == AppConstants.roleStaff ||
            user.role == AppConstants.roleOwner);

    final body = RefreshIndicator(
      onRefresh: _loadTransactions,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  // ignore: deprecated_member_use
                  Expanded(
                    child: DropdownButtonFormField<DateFilter>(
                      value: _selectedFilter,
                      isDense: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: DateFilter.values.map((f) =>
                        DropdownMenuItem(value: f, child: Text(f.label, style: const TextStyle(fontSize: 12))),
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        if (value == DateFilter.custom) {
                          _pickCustomRange();
                        } else {
                          setState(() => _selectedFilter = value);
                          _applyFilter();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ignore: deprecated_member_use
                  Expanded(
                    child: DropdownButtonFormField<TypeFilter>(
                      value: _selectedType,
                      isDense: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: TypeFilter.values.map((f) =>
                        DropdownMenuItem(value: f, child: Text(f.label, style: const TextStyle(fontSize: 12))),
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedType = value);
                        _applyFilter();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _applyFilter();
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                  _applyFilter();
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
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
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text('Tidak ada transaksi',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                )),
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
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: (isIncome ? AppTheme.profitColor : AppTheme.lossColor)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  color: isIncome ? AppTheme.profitColor : AppTheme.lossColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      FormatHelpers.displayDate(tx.transactionDate),
                                      style: AppTheme.caption.copyWith(fontSize: 11),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      FormatHelpers.rupiah(tx.amount),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isIncome ? AppTheme.profitColor : AppTheme.lossColor,
                                      ),
                                    ),
                                    if (tx.description?.isNotEmpty == true)
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
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _handleEdit(tx),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.lossColor),
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
    );

    if (!widget.showAppBar) return body;

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
      body: body,
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
      case AppConstants.paymentCash:
        return 'Tunai';
      case AppConstants.paymentTransfer:
        return 'Transfer Bank';
      case AppConstants.paymentQris:
        return 'QRIS';
      default:
        return 'Lainnya';
    }
  }
}


