import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/services/export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/recent_transaction_tile.dart';
import '../../core/utils/error_handler.dart';
import 'dart:async';
import 'dart:io';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';

import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_list_provider.dart';
import '../../providers/transaction_provider.dart';
import 'edit_transaction_page.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

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
  final _scrollController = ScrollController();
  Map<int, String> _categoriesMap = {};
  DateFilter _selectedFilter = DateFilter.all;
  TypeFilter _selectedType = TypeFilter.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      _applyFilter();
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await SupabaseService.instance
          .getCategoriesByBusiness(widget.business.businessId);
      final map = <int, String>{
        for (final c in cats) c.categoryId: c.name,
      };
      if (mounted) {
        setState(() => _categoriesMap = map);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(transactionListProvider(widget.business.businessId));
      if (!state.isLoading && !state.allLoaded) {
        ref.read(transactionListProvider(widget.business.businessId).notifier).loadNextPage();
      }
    }
  }

  String _dateFilterToStart(DateFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case DateFilter.today:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case DateFilter.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      case DateFilter.thisMonth:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      case DateFilter.thisYear:
        return '${now.year}-01-01';
      case DateFilter.all:
      case DateFilter.custom:
        return _customStart != null
            ? '${_customStart!.year}-${_customStart!.month.toString().padLeft(2, '0')}-${_customStart!.day.toString().padLeft(2, '0')}'
            : '';
    }
  }

  String _dateFilterToEnd(DateFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case DateFilter.today:
      case DateFilter.thisWeek:
      case DateFilter.thisMonth:
      case DateFilter.thisYear:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case DateFilter.all:
        return '';
      case DateFilter.custom:
        return _customEnd != null
            ? '${_customEnd!.year}-${_customEnd!.month.toString().padLeft(2, '0')}-${_customEnd!.day.toString().padLeft(2, '0')}'
            : '';
    }
  }

  void _applyFilter() {
    final dateStart = _dateFilterToStart(_selectedFilter);
    final dateEnd = _dateFilterToEnd(_selectedFilter);
    final type = switch (_selectedType) {
      TypeFilter.income => AppConstants.typeIncome,
      TypeFilter.expense => AppConstants.typeExpense,
      TypeFilter.all => null,
    };

    ref.read(transactionListProvider(widget.business.businessId).notifier).setFilters(
      typeFilter: type,
      dateStart: dateStart.isNotEmpty ? dateStart : null,
      dateEnd: dateEnd.isNotEmpty ? dateEnd : null,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
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
      ref.read(transactionListProvider(widget.business.businessId).notifier).refresh();
    }
  }

  Future<void> _handleDelete(TransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Hapus Transaksi'),
        content: Text(
          'Yakin ingin menghapus transaksi ${FormatHelpers.rupiah(tx.amount)} tanggal ${FormatHelpers.displayDateWithTime(tx.transactionDate, tx.createdAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          PfButton(
            label: 'Hapus',
            variant: PfButtonVariant.danger,
            isExpanded: false,
            onPressed: () => Navigator.pop(ctx, true),
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
          ref.read(transactionListProvider(widget.business.businessId).notifier).refresh();
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

  Future<void> _exportTransactions(BuildContext context, String format) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Menyiapkan file...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final listState = ref.read(transactionListProvider(widget.business.businessId));
      final transactions = listState.items.toList();
      if (transactions.isEmpty) throw ExportException('Tidak ada data untuk diexport');

      // Fetch category names
      final cats = await SupabaseService.instance
          .getCategoriesByBusiness(widget.business.businessId);
      final catMap = {for (final c in cats) c.categoryId: c.name};

      final headers = ['Tanggal', 'Kategori', 'Tipe', 'Jumlah', 'HPP', 'Metode Bayar', 'Deskripsi'];
      final rows = <List<dynamic>>[];

      for (final tx in transactions) {
        final isIncome = tx.type == AppConstants.typeIncome;
        rows.add([
          FormatHelpers.displayDate(tx.transactionDate),
          catMap[tx.categoryId] ?? 'Kategori #${tx.categoryId}',
          isIncome ? 'Uang Masuk' : 'Uang Keluar',
          tx.amount,
          isIncome ? tx.cogs : 0,
          _paymentLabel(tx.paymentMethod),
          tx.description ?? '',
        ]);
      }

      final filename = 'transaksi_${widget.business.name.replaceAll(' ', '_')}';
      final service = ExportService.instance;
      final File file;
      if (format == 'csv') {
        file = await service.toCsv(
          headers: headers,
          rows: rows.map((r) => r.map((e) => e.toString()).toList()).toList(),
          filename: filename,
        );
      } else {
        file = await service.toExcel(
          headers: headers,
          rows: rows,
          filename: filename,
        );
      }

      scaffold.clearSnackBars();
      await service.shareFile(file, text: 'Export Transaksi - ${widget.business.name}');
    } catch (e) {
      scaffold.clearSnackBars();
      if (context.mounted) {
        ErrorSnackbar.showError(context, 'Gagal export: ${e.toString()}');
      }
    }
  }

  Future<String> _getCategoryName(int categoryId) async {
    return SupabaseService.instance
        .getCategoryName(widget.business.businessId, categoryId);
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.toLowerCase().trim());
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(transactionListProvider(widget.business.businessId));
    ref.listen<int>(transactionRefreshProvider, (prev, next) {
      if (prev != null && prev != next) {
        ref.read(transactionListProvider(widget.business.businessId).notifier).refresh();
      }
    });
    final user = ref.watch(currentUserProvider);
    final canEdit = user != null &&
        (user.role == AppConstants.roleManager ||
            user.role == AppConstants.roleStaff ||
            user.role == AppConstants.roleOwner);
    final canExport = user != null &&
        (user.role == AppConstants.roleOwner ||
            user.role == AppConstants.roleManager);

    final body = RefreshIndicator(
      onRefresh: () => ref.read(transactionListProvider(widget.business.businessId).notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s12, AppSpacing.s12, AppSpacing.s12, 0),
              child: Row(
                children: [
                  // ignore: deprecated_member_use
                  Expanded(
                    child: DropdownButtonFormField<DateFilter>(
                      initialValue: _selectedFilter,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      iconEnabledColor: AppTheme.onSurfaceColorTheme(context),
                      dropdownColor: AppTheme.surfaceColorTheme(context),
                      borderRadius: BorderRadius.circular(16),
                      items: DateFilter.values.map((f) =>
                        DropdownMenuItem(
                          value: f,
                          child: Text(
                            f.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.onSurfaceColorTheme(context),
                            ),
                          ),
                        ),
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
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: DropdownButtonFormField<TypeFilter>(
                      initialValue: _selectedType,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      iconEnabledColor: AppTheme.onSurfaceColorTheme(context),
                      dropdownColor: AppTheme.surfaceColorTheme(context),
                      borderRadius: BorderRadius.circular(16),
                      items: TypeFilter.values.map((f) =>
                        DropdownMenuItem(
                          value: f,
                          child: Text(
                            f.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.onSurfaceColorTheme(context),
                            ),
                          ),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedType = value);
                        _applyFilter();
                      },
                    ),
                  ),
                  if (canExport) ...[
                    const SizedBox(width: AppSpacing.s8),
                    Container(
                      height: AppSpacing.s36,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                      ),
                      child: PopupMenuButton<String>(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                        icon: const Icon(Icons.file_download_rounded, size: 20),
                        tooltip: 'Export',
                        onSelected: (value) => _exportTransactions(context, value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                          PopupMenuItem(value: 'xlsx', child: Text('Export Excel')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s12, AppSpacing.s8, AppSpacing.s12, AppSpacing.s4),
              child: TextField(
                controller: _searchController,                  decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  prefixIcon: const Icon(Icons.search_rounded, size: AppIconSize.s20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: AppIconSize.s18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _applyFilter();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s4)),
          if (listState.isLoading && listState.items.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s40),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (listState.items.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: AppIconSize.s64,
                          color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.4)),
                      const SizedBox(height: AppSpacing.s12),
                      Text('Tidak ada transaksi',
                          style: AppTheme.title.copyWith(
                            fontSize: 18,
                            color: AppTheme.onSurfaceVariantColorTheme(context),
                          )),
                      if (listState.error != null) ...[
                        const SizedBox(height: AppSpacing.s8),
                        Text(listState.error!, style: TextStyle(color: AppTheme.lossColorTheme(context), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= listState.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.s16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final tx = listState.items[index];
                  final catName = _categoriesMap[tx.categoryId];

                  final popupMenu = canEdit
                      ? PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: AppTheme.onSurfaceVariantColorTheme(context),
                            size: AppIconSize.s20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _handleEdit(tx);
                                break;
                              case 'delete':
                                _handleDelete(tx);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined,
                                    color: AppTheme.onSurfaceColorTheme(context)),
                                title: Text('Edit',
                                    style: TextStyle(
                                        color: AppTheme.onSurfaceColorTheme(context))),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline_rounded,
                                    color: AppTheme.lossColorTheme(context)),
                                title: Text('Hapus',
                                    style: TextStyle(
                                        color: AppTheme.lossColorTheme(context))),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        )
                      : null;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.s12,
                      right: AppSpacing.s12,
                      bottom: AppSpacing.s8,
                      top: index == 0 ? 4 : 0,
                    ),
                    child: RecentTransactionTile(
                      transaction: tx,
                      categoryName: catName,
                      trailing: popupMenu,
                      onTap: () => _showTransactionDetail(tx),
                    ),
                  );
                },
                childCount: listState.items.length + (listState.isLoading ? 1 : 0),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: Row(
          children: [
            Icon(
              isIncome
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: isIncome ? AppTheme.profitColorTheme(context) : AppTheme.lossColorTheme(context),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(isIncome ? 'Uang Masuk' : 'Uang Keluar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Tanggal',
                FormatHelpers.displayDateWithTime(tx.transactionDate, tx.createdAt)),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTheme.caption.copyWith(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(value,
                style: AppTheme.subtitle.copyWith(fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
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
