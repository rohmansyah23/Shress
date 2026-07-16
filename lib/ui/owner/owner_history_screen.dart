import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/services/export_service.dart';
import '../../core/theme/app_theme.dart';
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
import '../../providers/paginated_list_provider.dart';
import '../transaction/edit_transaction_page.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

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
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        title: const Text('Hapus Transaksi'),
        content: Text(
          'Yakin ingin menghapus transaksi ${FormatHelpers.rupiah(tx.amount)} tanggal ${FormatHelpers.displayDateWithTime(tx.transactionDate, tx.createdAt)}?',
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
              foregroundColor: AppTheme.onDangerColorTheme(context),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s14,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight ? AppTheme.primaryColorTheme(context) : AppTheme.accent)
              : (isLight
                    ? AppTheme.surfaceContainerColorTheme(context)
                    : AppTheme.darkBackground),
          borderRadius: BorderRadius.circular(AppRadius.s20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.outlineVariantColorTheme(context),
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
                : AppTheme.onSurfaceVariantColorTheme(context),
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
    final canExport = user != null &&
        (user.role == AppConstants.roleOwner ||
            user.role == AppConstants.roleManager);

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s12,
                AppSpacing.s12,
                AppSpacing.s12,
                0,
              ),
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
                    const SizedBox(width: AppSpacing.s8),
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s12,
                AppSpacing.s8,
                AppSpacing.s12,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<OwnerDateFilter>(
                      initialValue: _selectedFilter,
                      isDense: true,
                      borderRadius: BorderRadius.circular(
                        AppRadius.radiusSmall,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.s12,
                          vertical: AppSpacing.s8,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      items: OwnerDateFilter.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceColorTheme(context),
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
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: DropdownButtonFormField<OwnerTypeFilter>(
                      initialValue: _selectedType,
                      isDense: true,
                      borderRadius: BorderRadius.circular(
                        AppRadius.radiusSmall,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.s12,
                          vertical: AppSpacing.s8,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      items: OwnerTypeFilter.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceColorTheme(context),
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
                  if (canExport) ...[
                    const SizedBox(width: AppSpacing.s8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                      ),
                      child: PopupMenuButton<String>(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        icon: const Icon(Icons.file_download_rounded, size: 20),
                        tooltip: 'Export',
                        onSelected: (value) => _exportTransactions(value),
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
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s12,
                AppSpacing.s8,
                AppSpacing.s12,
                0,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: AppIconSize.s20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: AppIconSize.s18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _applyFilter();
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s12,
                  ),
                ),
                style: AppTheme.caption.copyWith(fontSize: 14),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
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
                            size: AppIconSize.s64,
                            color: AppTheme.onSurfaceVariantColorTheme(context)
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          Text(
                            'Tidak ada transaksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariantColorTheme(context),
                            ),
                          ),
                          if (listState.error != null) ...[
                            const SizedBox(height: AppSpacing.s8),
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
                        padding: const EdgeInsets.fromLTRB(AppSpacing.s12, AppSpacing.s4, AppSpacing.s12, AppSpacing.s12),
                        itemCount:
                            listState.items.length +
                            (listState.isLoading ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s8),
                        itemBuilder: (context, index) {
                          if (index >= listState.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.s16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final tx = listState.items[index];
                          final isIncome = tx.type == AppConstants.typeIncome;
                          return Card(
                            child: InkWell(
                              onTap: () => _showTransactionDetail(tx),
                              borderRadius: BorderRadius.circular(
                                AppRadius.radiusLarge,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.s12),
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
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.radiusSmall,
                                        ),
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
                                    const SizedBox(width: AppSpacing.s12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final isLight =
                                                  Theme.of(
                                                    context,
                                                  ).brightness ==
                                                  Brightness.light;
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal:
                                                          AppSpacing.s12,
                                                      vertical: AppSpacing.s4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  border: Border.all(
                                                    color: isLight
                                                        ? const Color(
                                                            0xFFD1D5DB,
                                                          ).withValues(
                                                            alpha: 1.0,
                                                          )
                                                        : const Color(
                                                            0xFF4B5563,
                                                          ).withValues(
                                                            alpha: 0.5,
                                                          ),
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppRadius.s6,
                                                      ),
                                                ),
                                                child: Text(
                                                  _findBusinessName(
                                                    tx.businessId,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: isLight
                                                        ? const Color(
                                                            0xFF3D404D,
                                                          )
                                                        : const Color(
                                                            0xFFD2D2D2,
                                                          ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: AppSpacing.s4),
                                          Text(
                                            FormatHelpers.displayDateWithTime(
                                              tx.transactionDate,
                                              tx.createdAt,
                                            ),
                                            style: AppTheme.caption.copyWith(
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.s4),
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
                                    if (canEdit)
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert_rounded,
                                          color: AppTheme.onSurfaceVariantColorTheme(context),
                                          size: AppIconSize.s20,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.radiusSmall,
                                          ),
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
                                              leading: Icon(
                                                Icons.edit_outlined,
                                                color: AppTheme.onSurfaceColorTheme(context),
                                              ),
                                              title: Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color: AppTheme.onSurfaceColorTheme(context),
                                                ),
                                              ),
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          const PopupMenuDivider(),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.delete_outline_rounded,
                                                color: AppTheme.lossColorTheme(
                                                  context,
                                                ),
                                              ),
                                              title: Text(
                                                'Hapus',
                                                style: TextStyle(
                                                  color:
                                                      AppTheme.lossColorTheme(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
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
    final catName = await SupabaseService.instance.getCategoryName(
      businessId,
      tx.categoryId,
    );
    if (!mounted) return;
    final isIncome = tx.type == AppConstants.typeIncome;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
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
            const SizedBox(width: AppSpacing.s8),
            Text(isIncome ? 'Uang Masuk' : 'Uang Keluar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(
              'Tanggal',
              FormatHelpers.displayDateWithTime(tx.transactionDate, tx.createdAt),
            ),
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
            child: Text(label, style: AppTheme.caption.copyWith(fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
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

  Future<void> _exportTransactions(String format) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Menyiapkan data...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      PaginatedListState<TransactionModel> listState;
      if (_filterAllBusinesses && _allBusinessIds.isNotEmpty) {
        listState = ref.read(allTransactionsListProvider(_allBusinessIds));
      } else if (_selectedBusinessId != null) {
        listState = ref.read(transactionListProvider(_selectedBusinessId!));
      } else {
        throw ExportException('Tidak ada data transaksi');
      }

      final transactions = listState.items.toList();
      if (transactions.isEmpty) throw ExportException('Tidak ada data transaksi');

      // Fetch category names for all unique business IDs
      final businessIds = transactions.map((t) => t.businessId).toSet();
      final catMap = <int, String>{};
      for (final bid in businessIds) {
        final cats = await SupabaseService.instance.getCategoriesByBusiness(bid);
        for (final c in cats) {
          catMap[c.categoryId] = c.name;
        }
      }

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
          tx.paymentMethod,
          tx.description ?? '',
        ]);
      }

      final filename = 'riwayat_transaksi';
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
      await service.shareFile(file, text: 'Export Riwayat Transaksi');
    } catch (e) {
      scaffold.clearSnackBars();
      if (context.mounted) {
        ErrorSnackbar.showError(context, 'Gagal export: ${e.toString()}');
      }
    }
  }
}
