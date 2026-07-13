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
import '../../providers/transaction_list_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/paginated_list_provider.dart';
import '../transaction/edit_transaction_page.dart';

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

enum OwnerTypeFilter {
  all('Semua'),
  income('Uang Masuk'),
  expense('Uang Keluar');

  final String label;
  const OwnerTypeFilter(this.label);
}

class OwnerHistoryScreen extends ConsumerStatefulWidget {
  final int? initialBusinessId;
  final OwnerDateFilter initialFilter;
  final bool showAppBar;

  const OwnerHistoryScreen({
    super.key,
    this.initialBusinessId,
    this.initialFilter = OwnerDateFilter.all,
    this.showAppBar = true,
  });

  @override
  ConsumerState<OwnerHistoryScreen> createState() => _OwnerHistoryScreenState();
}

class _OwnerHistoryScreenState extends ConsumerState<OwnerHistoryScreen> {
  final _scrollController = ScrollController();
  List<BusinessModel> _businesses = [];
  List<int> _allBusinessIds = [];
  bool _filterAllBusinesses = true;
  int? _selectedBusinessId;

  OwnerDateFilter _selectedFilter = OwnerDateFilter.all;
  OwnerTypeFilter _selectedType = OwnerTypeFilter.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    if (widget.initialBusinessId != null) {
      _filterAllBusinesses = false;
      _selectedBusinessId = widget.initialBusinessId;
    }
    _scrollController.addListener(_onScroll);
    _loadInitial();
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
      final state = _currentListState();
      if (!state.isLoading && !state.allLoaded) {
        _currentNotifier().loadNextPage();
      }
    }
  }

  PaginatedListState<TransactionModel> _currentListState() {
    if (_filterAllBusinesses && _allBusinessIds.isNotEmpty) {
      return ref.read(allTransactionsListProvider(_allBusinessIds));
    } else if (_selectedBusinessId != null) {
      return ref.read(transactionListProvider(_selectedBusinessId!));
    }
    return const PaginatedListState();
  }

  PaginatedListNotifier<TransactionModel> _currentNotifier() {
    if (_filterAllBusinesses && _allBusinessIds.isNotEmpty) {
      return ref.read(allTransactionsListProvider(_allBusinessIds).notifier);
    } else if (_selectedBusinessId != null) {
      return ref.read(transactionListProvider(_selectedBusinessId!).notifier);
    }
    throw UnimplementedError();
  }

  Future<void> _loadInitial() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final businesses = await SupabaseService.instance.getAccessibleBusinesses(
        user.userId,
        user.role,
      );

      if (!mounted) return;
      setState(() {
        _businesses = businesses;
        _allBusinessIds = businesses.map((b) => b.businessId).toList();
      });
      _applyFilter();
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  String _dateFilterToStart(OwnerDateFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case OwnerDateFilter.today:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case OwnerDateFilter.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      case OwnerDateFilter.thisMonth:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      case OwnerDateFilter.thisYear:
        return '${now.year}-01-01';
      case OwnerDateFilter.all:
      case OwnerDateFilter.custom:
        return _customStart != null
            ? '${_customStart!.year}-${_customStart!.month.toString().padLeft(2, '0')}-${_customStart!.day.toString().padLeft(2, '0')}'
            : '';
    }
  }

  String _dateFilterToEnd(OwnerDateFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case OwnerDateFilter.today:
      case OwnerDateFilter.thisWeek:
      case OwnerDateFilter.thisMonth:
      case OwnerDateFilter.thisYear:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case OwnerDateFilter.all:
        return '';
      case OwnerDateFilter.custom:
        return _customEnd != null
            ? '${_customEnd!.year}-${_customEnd!.month.toString().padLeft(2, '0')}-${_customEnd!.day.toString().padLeft(2, '0')}'
            : '';
    }
  }

  void _applyFilter() {
    final dateStart = _dateFilterToStart(_selectedFilter);
    final dateEnd = _dateFilterToEnd(_selectedFilter);
    final type = switch (_selectedType) {
      OwnerTypeFilter.income => AppConstants.typeIncome,
      OwnerTypeFilter.expense => AppConstants.typeExpense,
      OwnerTypeFilter.all => null,
    };

    if (_filterAllBusinesses && _allBusinessIds.isNotEmpty) {
      ref
          .read(allTransactionsListProvider(_allBusinessIds).notifier)
          .setFilters(
            typeFilter: type,
            dateStart: dateStart.isNotEmpty ? dateStart : null,
            dateEnd: dateEnd.isNotEmpty ? dateEnd : null,
            searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          );
    } else if (_selectedBusinessId != null) {
      ref
          .read(transactionListProvider(_selectedBusinessId!).notifier)
          .setFilters(
            typeFilter: type,
            dateStart: dateStart.isNotEmpty ? dateStart : null,
            dateEnd: dateEnd.isNotEmpty ? dateEnd : null,
            searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          );
    }
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
              end: DateTime.now(),
            ),
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
      orElse: () => null,
    );
    return b?.name ?? 'Bisnis #$businessId';
  }

  BusinessModel? _findBusiness(int businessId) {
    return _businesses.cast<BusinessModel?>().firstWhere(
      (b) => b?.businessId == businessId,
      orElse: () => null,
    );
  }

  Future<void> _handleEdit(TransactionModel tx) async {
    final biz = _findBusiness(tx.businessId);
    if (biz == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditTransactionPage(transaction: tx, business: biz),
      ),
    );
    if (result == true) {
      _currentNotifier().refresh();
    }
  }

  Future<void> _handleDelete(TransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
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
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.lossColorTheme(context),
            ),
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
          _currentNotifier().refresh();
          triggerTransactionRefresh(ref);
          if (!mounted) return;
          ErrorSnackbar.showSuccess(
            context,
            result.message ?? 'Berhasil dihapus',
          );
        } else {
          if (!mounted) return;
          ErrorSnackbar.showError(context, result.message ?? 'Gagal menghapus');
        }
      } catch (e) {
        if (!mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.toLowerCase().trim());
      _applyFilter();
    });
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight ? colorScheme.primary : AppTheme.accent)
              : (isLight
                    ? colorScheme.surfaceContainer
                    : AppTheme.darkBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isLight ? colorScheme.outlineVariant : AppTheme.accent),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? AppTheme.card
                : (isLight ? colorScheme.onSurfaceVariant : AppTheme.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canEdit =
        user != null &&
        (user.role == AppConstants.roleManager ||
            user.role == AppConstants.roleStaff ||
            user.role == AppConstants.roleOwner);

    PaginatedListState<TransactionModel> listState;
    if (_filterAllBusinesses && _allBusinessIds.isNotEmpty) {
      listState = ref.watch(allTransactionsListProvider(_allBusinessIds));
    } else if (_selectedBusinessId != null) {
      listState = ref.watch(transactionListProvider(_selectedBusinessId!));
    } else {
      listState = const PaginatedListState();
    }

    return Stack(
      children: [
        Column(
          children: [
            // Business filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Semua',
                      isSelected: _filterAllBusinesses,
                      onTap: () {
                        setState(() {
                          _filterAllBusinesses = true;
                          _selectedBusinessId = null;
                        });
                        _applyFilter();
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._businesses.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          label: b.name.length > 14
                              ? '${b.name.substring(0, 14)}...'
                              : b.name,
                          isSelected: _selectedBusinessId == b.businessId,
                          onTap: () {
                            setState(() {
                              _filterAllBusinesses = false;
                              _selectedBusinessId = b.businessId;
                            });
                            _applyFilter();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Date filter + Type filter dropdowns
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<OwnerDateFilter>(
                      initialValue: _selectedFilter,
                      isDense: true,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      items: OwnerDateFilter.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        if (value == OwnerDateFilter.custom) {
                          _pickCustomRange();
                        } else {
                          setState(() => _selectedFilter = value);
                          _applyFilter();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.s8),
                  Expanded(
                    child: DropdownButtonFormField<OwnerTypeFilter>(
                      initialValue: _selectedType,
                      isDense: true,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      items: OwnerTypeFilter.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: AppTheme.s8),
            // Transaction list
            Expanded(
              child: listState.isLoading && listState.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : listState.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppTheme.s12),
                          Text(
                            'Tidak ada transaksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (listState.error != null) ...[
                            const SizedBox(height: AppTheme.s8),
                            Text(
                              listState.error!,
                              style: TextStyle(
                                color: AppTheme.lossColorTheme(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _currentNotifier().refresh(),
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount:
                            listState.items.length +
                            (listState.isLoading ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppTheme.s8),
                        itemBuilder: (context, index) {
                          if (index >= listState.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppTheme.s16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final tx = listState.items[index];
                          final isIncome = tx.type == AppConstants.typeIncome;
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Card(
                            child: InkWell(
                              onTap: () => _showTransactionDetail(tx),
                              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                              hoverColor: (isDark ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.04),
                              highlightColor: (isDark ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.08),
                              splashColor: (isDark ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          (isIncome
                                                  ? AppTheme.profitColorTheme(
                                                      context,
                                                    )
                                                  : AppTheme.lossColorTheme(
                                                      context,
                                                    ))
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isIncome
                                          ? Icons.trending_up_rounded
                                          : Icons.trending_down_rounded,
                                      color: isIncome
                                          ? AppTheme.profitColorTheme(context)
                                          : AppTheme.lossColorTheme(context),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.s12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final isLight =
                                                Theme.of(context).brightness ==
                                                Brightness.light;
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isLight
                                                    ? const Color(0xFFEDEDEF)
                                                    : const Color(0xFF2E2E2E),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _findBusinessName(
                                                  tx.businessId,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: isLight
                                                      ? const Color(0xFF3D404D)
                                                      : const Color(0xFFD2D2D2),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          FormatHelpers.displayDate(
                                            tx.transactionDate,
                                          ),
                                          style: AppTheme.caption.copyWith(
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          FormatHelpers.rupiah(tx.amount),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isIncome
                                                ? AppTheme.profitColorTheme(
                                                    context,
                                                  )
                                                : AppTheme.lossColorTheme(
                                                    context,
                                                  ),
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
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => _handleEdit(tx),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: AppTheme.lossColorTheme(context),
                                      ),
                                      onPressed: () => _handleDelete(tx),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(transactionRefreshProvider, (prev, next) {
      if (prev != null && prev != next) {
        _currentNotifier().refresh();
      }
    });
    final body = _buildBody(context);
    if (!widget.showAppBar) return body;

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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: () => _currentNotifier().refresh(),
          ),
        ],
      ),
      body: body,
    );
  }

  void _showTransactionDetail(TransactionModel tx) async {
    final businessId = tx.businessId;
    final catName = await SupabaseService.instance
        .getCategoryName(businessId, tx.categoryId);
    if (!mounted) return;
    final isIncome = tx.type == AppConstants.typeIncome;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: Row(
          children: [
            Icon(
              isIncome
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: isIncome
                  ? AppTheme.profitColorTheme(context)
                  : AppTheme.lossColorTheme(context),
            ),
            const SizedBox(width: AppTheme.s8),
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
            child:
                Text(label, style: AppTheme.caption.copyWith(fontSize: 12)),
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
        return method;
    }
  }

}
