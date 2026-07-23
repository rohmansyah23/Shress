import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/services/export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/recent_transaction_tile.dart';
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

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};
  OverlayEntry? _selectionOverlayEntry;

  void _showSelectionOverlay() {
    if (_selectionOverlayEntry != null) {
      _selectionOverlayEntry!.markNeedsBuild();
      return;
    }
    _selectionOverlayEntry = OverlayEntry(
      builder: (context) {
        final user = ref.watch(currentUserProvider);
        final canEdit = user != null &&
            (user.role == AppConstants.roleManager ||
                user.role == AppConstants.roleStaff ||
                user.role == AppConstants.roleOwner);

        final listState =
            ref.watch(transactionListProvider(widget.business.businessId));
        final items = listState.items;
        final allSelected = items.isNotEmpty &&
            _selectedIds.length ==
                items.where((e) => e.transactionId != null).length;
        final topPadding = MediaQuery.of(context).padding.top;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            elevation: 4,
            color: AppTheme.surfaceColorTheme(context),
            child: Container(
              height: kToolbarHeight + topPadding,
              padding: EdgeInsets.only(
                top: topPadding,
                left: AppSpacing.s4,
                right: AppSpacing.s4,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _exitSelectionMode,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      '${_selectedIds.length} dipilih',
                      style: TextStyle(
                        color: AppTheme.onSurfaceColorTheme(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: allSelected ? 'Batalkan Semua' : 'Pilih Semua',
                    icon: Icon(
                      allSelected
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                    onPressed: () => _selectAll(items),
                  ),
                  if (canEdit && _selectedIds.length == 1)
                    IconButton(
                      tooltip: 'Edit Transaksi',
                      icon: Icon(
                        Icons.edit_outlined,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      onPressed: () => _editSelected(items),
                    ),
                  if (canEdit)
                    IconButton(
                      tooltip: 'Hapus Terpilih',
                      icon: Icon(
                        Icons.delete_rounded,
                        color: AppTheme.lossColorTheme(context),
                      ),
                      onPressed: () => _deleteSelected(items),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_selectionOverlayEntry!);
  }

  void _removeSelectionOverlay() {
    _selectionOverlayEntry?.remove();
    _selectionOverlayEntry = null;
  }

  void _enterSelectionMode(int txId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
      _selectedIds.add(txId);
    });
    _showSelectionOverlay();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    _removeSelectionOverlay();
  }

  void _toggleSelection(int txId) {
    setState(() {
      if (_selectedIds.contains(txId)) {
        _selectedIds.remove(txId);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(txId);
      }
    });
    if (_isSelectionMode) {
      _showSelectionOverlay();
    } else {
      _removeSelectionOverlay();
    }
  }

  void _selectAll(List<TransactionModel> items) {
    setState(() {
      final validIds = items
          .map((e) => e.transactionId)
          .whereType<int>()
          .toList();
      if (_selectedIds.length == validIds.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.addAll(validIds);
      }
    });
    if (_isSelectionMode) {
      _showSelectionOverlay();
    } else {
      _removeSelectionOverlay();
    }
  }

  void _editSelected(List<TransactionModel> items) {
    if (_selectedIds.length != 1) return;
    final txId = _selectedIds.first;
    final tx = items.firstWhere(
      (element) => element.transactionId == txId,
      orElse: () => items.first,
    );
    _exitSelectionMode();
    _handleEdit(tx);
  }

  Future<void> _deleteSelected(List<TransactionModel> items) async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String input = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isConfirmed = input.trim().toUpperCase() == 'HAPUS';
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.lossColorTheme(context),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  const Expanded(
                    child: Text('Konfirmasi Hapus'),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s10),
                      decoration: BoxDecoration(
                        color: AppTheme.lossColorTheme(context)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusSmall),
                        border: Border.all(
                          color: AppTheme.lossColorTheme(context)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: AppIconSize.s18,
                            color: AppTheme.lossColorTheme(context),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(
                            child: Text(
                              'Tindakan ini permanen dan mempengaruhi laporan keuangan!',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.lossColorTheme(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      count == 1
                          ? 'Yakin ingin menghapus 1 transaksi ini?'
                          : 'Yakin ingin menghapus $count transaksi terpilih?',
                      style: TextStyle(
                        color: AppTheme.onSurfaceColorTheme(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      'Ketik "HAPUS" pada kolom di bawah ini untuk mengonfirmasi:',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariantColorTheme(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Ketik HAPUS disini...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.s12,
                          vertical: AppSpacing.s10,
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          input = val;
                        });
                      },
                    ),
                  ],
                ),
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
                  onPressed: isConfirmed
                      ? () => Navigator.pop(ctx, true)
                      : null,
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      int successCount = 0;
      final idsToDelete = _selectedIds.toList();
      for (final txId in idsToDelete) {
        try {
          final res = await deleteTransaction(transactionId: txId);
          if (res.success) {
            successCount++;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      ref.read(transactionListProvider(widget.business.businessId).notifier).refresh();
      triggerTransactionRefresh(ref);
      _exitSelectionMode();

      if (successCount > 0) {
        ErrorSnackbar.showSuccess(
            context, 'Berhasil menghapus $successCount transaksi');
      } else {
        ErrorSnackbar.showError(context, 'Gagal menghapus transaksi');
      }
    }
  }

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
    _removeSelectionOverlay();
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
                  final isSelected = tx.transactionId != null &&
                      _selectedIds.contains(tx.transactionId);

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
                      isSelectionMode: _isSelectionMode,
                      isSelected: isSelected,
                      onLongPress: () {
                        if (!canEdit || tx.transactionId == null) return;
                        if (!_isSelectionMode) {
                          _enterSelectionMode(tx.transactionId!);
                        } else {
                          _toggleSelection(tx.transactionId!);
                        }
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          if (tx.transactionId != null) {
                            _toggleSelection(tx.transactionId!);
                          }
                        } else {
                          _showTransactionDetail(tx);
                        }
                      },
                    ),
                  );
                },
                childCount: listState.items.length + (listState.isLoading ? 1 : 0),
              ),
            ),
        ],
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isOwnerView
              ? 'Riwayat - ${widget.business.name}'
              : 'Riwayat Transaksi'),
        ),
        body: body,
      );
    }

    return body;
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
