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
import '../transaction/transaction_sheet.dart';
import '../transaction/edit_transaction_page.dart';
import '../dashboard/qris_display_screen.dart';

enum OwnerDateFilter {
  today('Hari Ini'),
  thisWeek('Minggu Ini'),
  thisMonth('Bulan Ini'),
  thisYear('Tahun Ini'),
  all('Semua'),
  custom('Custom');

  final String label;
  const OwnerDateFilter(this.label);
}

class OwnerHistoryScreen extends ConsumerStatefulWidget {
  final int? initialBusinessId;
  final OwnerDateFilter initialFilter;

  const OwnerHistoryScreen({
    super.key,
    this.initialBusinessId,
    this.initialFilter = OwnerDateFilter.all,
  });

  @override
  ConsumerState<OwnerHistoryScreen> createState() =>
      _OwnerHistoryScreenState();
}

class _OwnerHistoryScreenState
    extends ConsumerState<OwnerHistoryScreen> {
  List<BusinessModel> _businesses = [];
  bool _filterAllBusinesses = true;
  int? _selectedBusinessId;

  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];
  bool _isLoading = true;
  OwnerDateFilter _selectedFilter = OwnerDateFilter.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    if (widget.initialBusinessId != null) {
      _filterAllBusinesses = false;
      _selectedBusinessId = widget.initialBusinessId;
    }
    _loadInitial();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.watch(transactionRefreshProvider);
  }

  Future<void> _loadInitial() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final businesses = await SupabaseService.instance
          .getAccessibleBusinesses(user.userId, user.role);

      if (!mounted) return;
      setState(() => _businesses = businesses);
      await _loadTransactions();
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final supa = SupabaseService.instance;
      List<TransactionModel> transactions;

      if (_filterAllBusinesses) {
        final allIds = _businesses.map((b) => b.businessId).toList();
        if (allIds.isEmpty) {
          transactions = [];
        } else {
          transactions = await supa.getAllTransactions(allIds);
        }
      } else if (_selectedBusinessId != null) {
        transactions = await supa
            .getTransactionsByBusiness(_selectedBusinessId!);
      } else {
        transactions = [];
      }

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
        case OwnerDateFilter.today:
          start = DateTime(now.year, now.month, now.day);
          end = start;
        case OwnerDateFilter.thisWeek:
          start = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          end = now;
        case OwnerDateFilter.thisMonth:
          start = DateTime(now.year, now.month, 1);
          end = now;
        case OwnerDateFilter.thisYear:
          start = DateTime(now.year, 1, 1);
          end = now;
        case OwnerDateFilter.all:
          start = null;
          end = null;
        case OwnerDateFilter.custom:
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
          final txDay =
              DateTime(txDate.year, txDate.month, txDate.day);
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
              start: DateTime(
                  DateTime.now().year, DateTime.now().month, 1),
              end: DateTime.now()),
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _selectedFilter = OwnerDateFilter.custom;
      });
      _applyFilter();
    }
  }

  String _findBusinessName(int businessId) {
    final b = _businesses.cast<BusinessModel?>().firstWhere(
        (b) => b?.businessId == businessId,
        orElse: () => null);
    return b?.name ?? 'Bisnis #$businessId';
  }

  BusinessModel? _findBusiness(int businessId) {
    return _businesses.cast<BusinessModel?>().firstWhere(
        (b) => b?.businessId == businessId,
        orElse: () => null);
  }

  Future<void> _handleEdit(TransactionModel tx) async {
    final biz = _findBusiness(tx.businessId);
    if (biz == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditTransactionPage(
          transaction: tx,
          business: biz,
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canEdit = user != null &&
        (user.role == AppConstants.roleManager ||
            user.role == AppConstants.roleStaff ||
            user.role == AppConstants.roleOwner);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _filterAllBusinesses
              ? 'Riwayat Semua Bisnis'
              : _selectedBusinessId != null
                  ? _findBusinessName(_selectedBusinessId!)
                  : 'Riwayat Transaksi',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'QRIS Pembayaran',
            onPressed: () => _showQrisPicker(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: _loadTransactions,
          ),
        ],
      ),
      floatingActionButton: _selectedBusinessId != null
          ? FloatingActionButton(
              heroTag: 'owner_add_tx',
              onPressed: () {
                final biz = _businesses.cast<BusinessModel?>().firstWhere(
                    (b) => b?.businessId == _selectedBusinessId,
                    orElse: () => null);
                if (biz != null) {
                  TransactionSheet.show(context, biz);
                }
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: Column(
        children: [
          // Business filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: _filterAllBusinesses,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filterAllBusinesses = true;
                          _selectedBusinessId = null;
                        });
                        _loadTransactions();
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  ..._businesses.map((b) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(b.name.length > 12
                              ? '${b.name.substring(0, 12)}...'
                              : b.name),
                          selected:
                              _selectedBusinessId == b.businessId,
                          onSelected: (selected) {
                            setState(() {
                              _filterAllBusinesses = false;
                              _selectedBusinessId = selected
                                  ? b.businessId
                                  : null;
                            });
                            _loadTransactions();
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),
          // Date filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in OwnerDateFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(filter.label,
                            style: const TextStyle(fontSize: 12)),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          if (filter == OwnerDateFilter.custom) {
                            _pickCustomRange();
                          } else {
                            setState(
                                () => _selectedFilter = filter);
                            _applyFilter();
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Transaction list
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
                                size: 64,
                                color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Tidak ada transaksi',
                                style: AppTheme.heading3.copyWith(
                                    color: Colors.grey)),
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
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: (isIncome
                                                ? AppTheme
                                                    .profitColor
                                                : AppTheme
                                                    .lossColor)
                                            .withValues(
                                                alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(
                                                12),
                                      ),
                                      child: Icon(
                                        isIncome
                                            ? Icons
                                                .trending_up_rounded
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
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            _findBusinessName(
                                                tx.businessId),
                                            style: AppTheme
                                                .caption
                                                .copyWith(
                                              fontSize: 10,
                                              color: Theme.of(
                                                      context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: 2),
                                          Text(
                                            FormatHelpers.displayDate(
                                                tx.transactionDate),
                                            style: AppTheme
                                                .caption
                                                .copyWith(
                                                fontSize:
                                                    11),
                                          ),
                                          const SizedBox(
                                              height: 4),
                                          Text(
                                            FormatHelpers.rupiah(
                                                tx.amount),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: isIncome
                                                  ? AppTheme
                                                      .profitColor
                                                  : AppTheme
                                                      .lossColor,
                                            ),
                                          ),
                                            if (tx.description
                                                    ?.isNotEmpty ==
                                                true)
                                              Text(
                                                tx.description!,
                                                style: AppTheme
                                                    .caption,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
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
                              );
                            },
                          ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showQrisPicker() {
    if (_businesses.isEmpty) return;

    if (_businesses.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              QrisDisplayScreen(business: _businesses.first),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Bisnis'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _businesses.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.store_rounded),
              title: Text(_businesses[i].name),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QrisDisplayScreen(
                        business: _businesses[i]),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}
