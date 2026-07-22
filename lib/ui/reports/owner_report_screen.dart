import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/services/export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';

import '../../core/widgets/report_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

enum OwnerPeriodFilter {
  today('Hari Ini'),
  thisWeek('Minggu Ini'),
  thisMonth('Bulan Ini'),
  thisYear('Tahun Ini'),
  custom('Custom');

  final String label;
  const OwnerPeriodFilter(this.label);
}


class OwnerReportScreen extends ConsumerStatefulWidget {
  final int? initialBusinessId;
  final OwnerPeriodFilter initialPeriod;
  final bool showAppBar;

  const OwnerReportScreen({
    super.key,
    this.initialBusinessId,
    this.initialPeriod = OwnerPeriodFilter.thisMonth,
    this.showAppBar = true,
  });

  @override
  ConsumerState<OwnerReportScreen> createState() => _OwnerReportScreenState();
}

class _OwnerReportScreenState extends ConsumerState<OwnerReportScreen> {
  bool _filterAllBusinesses = true;
  int? _selectedBusinessId;
  List<BusinessModel> _businesses = [];
  bool _isLoading = true;
  AppError? _error;
  int? _lastRefresh;
  OwnerPeriodFilter _selectedPeriod = OwnerPeriodFilter.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  Map<String, double> _summary = {
    'totalIncome': 0,
    'totalCogs': 0,
    'grossProfit': 0,
    'totalExpense': 0,
    'netProfit': 0,
  };

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _prevTransactions = [];
  Map<int, String> _categoryNames = {}; // categoryId -> name
  String _categoryTypeFilter = 'all'; // 'income', 'expense', 'all'

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    if (widget.initialBusinessId != null) {
      _filterAllBusinesses = false;
      _selectedBusinessId = widget.initialBusinessId;
    }
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final refresh = ref.watch(transactionRefreshProvider);
    if (_lastRefresh != null && _lastRefresh != refresh) {
      _loadSummary();
    }
    _lastRefresh ??= refresh;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case OwnerPeriodFilter.today:
        return _fmt(now);
      case OwnerPeriodFilter.thisWeek:
        return _fmt(now.subtract(Duration(days: now.weekday - 1)));
      case OwnerPeriodFilter.thisMonth:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      case OwnerPeriodFilter.thisYear:
        return '${now.year}-01-01';
      case OwnerPeriodFilter.custom:
        return _customStart != null ? _fmt(_customStart!) : null;
    }
  }

  String? get _endDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case OwnerPeriodFilter.today:
        return _fmt(now);
      case OwnerPeriodFilter.thisWeek:
        return _fmt(now);
      case OwnerPeriodFilter.thisMonth:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${FormatHelpers.daysInMonth(now.year, now.month)}';
      case OwnerPeriodFilter.thisYear:
        return '${now.year}-12-31';
      case OwnerPeriodFilter.custom:
        return _customEnd != null ? _fmt(_customEnd!) : null;
    }
  }

  String? get _prevStartDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case OwnerPeriodFilter.today:
        return _fmt(now.subtract(const Duration(days: 1)));
      case OwnerPeriodFilter.thisWeek:
        return _fmt(now.subtract(Duration(days: now.weekday - 1 + 7)));
      case OwnerPeriodFilter.thisMonth:
        final prev = DateTime(now.year, now.month - 1, 1);
        return _fmt(prev);
      case OwnerPeriodFilter.thisYear:
        return '${now.year - 1}-01-01';
      case OwnerPeriodFilter.custom:
        if (_customStart == null || _customEnd == null) return null;
        final prevRange = _customEnd!.difference(_customStart!).inDays + 1;
        return _fmt(_customStart!.subtract(Duration(days: prevRange)));
    }
  }

  String? get _prevEndDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case OwnerPeriodFilter.today:
        return _fmt(now.subtract(const Duration(days: 1)));
      case OwnerPeriodFilter.thisWeek:
        return _fmt(now.subtract(const Duration(days: 7)));
      case OwnerPeriodFilter.thisMonth:
        final prev = DateTime(now.year, now.month, 0);
        return _fmt(prev);
      case OwnerPeriodFilter.thisYear:
        return '${now.year - 1}-12-31';
      case OwnerPeriodFilter.custom:
        if (_customStart == null || _customEnd == null) return null;
        return _fmt(_customStart!.subtract(const Duration(days: 1)));
    }
  }

  double _prevIncomeVal = 0;
  double _prevCogsVal = 0;
  double _prevExpenseVal = 0;

  void _computePrevSummary() {
    _prevIncomeVal = 0;
    _prevCogsVal = 0;
    _prevExpenseVal = 0;
    for (final tx in _prevTransactions) {
      if (tx.type == AppConstants.typeIncome) {
        _prevIncomeVal += tx.amount;
        _prevCogsVal += tx.cogs;
      } else {
        _prevExpenseVal += tx.amount;
      }
    }
  }

  double get _prevNetProfit {
    if (_prevTransactions.isEmpty) return 0;
    return (_prevIncomeVal - _prevCogsVal) - _prevExpenseVal;
  }

  double get _prevIncome => _prevIncomeVal;
  double get _prevCogs => _prevCogsVal;
  double get _prevGrossProfit => _prevIncomeVal - _prevCogsVal;
  double get _prevExpense => _prevExpenseVal;

  Map<String, double> _categoryBreakdown(String filter) {
    final Map<int, double> grouped = {};
    for (final tx in _transactions) {
      final isIncome = tx.type == AppConstants.typeIncome;
      if (filter == 'all') {
        if (isIncome) {
          grouped[tx.categoryId] = (grouped[tx.categoryId] ?? 0) + (tx.amount - tx.cogs);
        } else {
          grouped[tx.categoryId] = (grouped[tx.categoryId] ?? 0) + tx.amount;
        }
      } else if (filter == 'income' && isIncome) {
        grouped[tx.categoryId] = (grouped[tx.categoryId] ?? 0) + (tx.amount - tx.cogs);
      } else if (filter == 'expense' && !isIncome) {
        grouped[tx.categoryId] = (grouped[tx.categoryId] ?? 0) + tx.amount;
      }
    }
    final result = <String, double>{};
    for (final entry in grouped.entries) {
      final name = _categoryNames[entry.key] ?? 'Kategori #${entry.key}';
      result[name] = (result[name] ?? 0) + entry.value;
    }
    return result;
  }

  List<TransactionItem> _toTransactionItems() {
    return _transactions.map((tx) {
      final catName = _categoryNames[tx.categoryId] ?? 'Kategori #${tx.categoryId}';
      return TransactionItem(
        type: tx.type,
        category: catName,
        amount: tx.amount,
        date: FormatHelpers.displayDate(tx.transactionDate),
        description: tx.description,
      );
    }).toList();
  }

  Future<void> _pickCustomRange() async {
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
        _selectedPeriod = OwnerPeriodFilter.custom;
      });
      _loadSummary();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final businesses = await SupabaseService.instance
          .getAccessibleBusinesses(user.userId, user.role);

      if (!mounted) return;
      setState(() => _businesses = businesses);

      if (mounted) {
        await _loadSummary();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = ErrorHandler.classify(e);
        });
      }
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final supa = SupabaseService.instance;

      List<int> targetIds;
      if (_filterAllBusinesses) {
        targetIds = _businesses.map((b) => b.businessId).toList();
      } else if (_selectedBusinessId != null) {
        targetIds = [_selectedBusinessId!];
      } else {
        targetIds = [];
      }

      if (targetIds.isEmpty) {
        setState(() {
          _summary = {
            'totalIncome': 0,
            'totalCogs': 0,
            'grossProfit': 0,
            'totalExpense': 0,
            'netProfit': 0,
          };
          _transactions = [];
          _prevTransactions = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch current period
      if (_startDate != null && _endDate != null) {
        final transactions = await supa.getAllTransactionsByDateRange(
          targetIds,
          _startDate!,
          _endDate!,
        );
        _transactions = transactions;
        _summary = _computeSummary(transactions);
      } else {
        if (_filterAllBusinesses) {
          _summary = await supa.getAllBusinessesSummary(targetIds);
        } else {
          _summary = await supa.getBusinessSummary(targetIds.first);
        }
        _transactions = [];
      }

      // Fetch previous period for comparison
      _prevTransactions = [];
      if (_startDate != null && _endDate != null && _prevStartDate != null && _prevEndDate != null) {
        try {
          _prevTransactions = await supa.getAllTransactionsByDateRange(
            targetIds,
            _prevStartDate!,
            _prevEndDate!,
          );
        } catch (_) {
          _prevTransactions = [];
        }
      }
      _computePrevSummary();

      // Fetch category names
      _categoryNames = {};
      for (final bId in targetIds) {
        try {
          final cats = await supa.getCategoriesByBusiness(bId);
          for (final c in cats) {
            _categoryNames[c.categoryId] = c.name;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = ErrorHandler.classify(e);
        });
      }
    }
  }

  Map<String, double> _computeSummary(List<TransactionModel> transactions) {
    double totalIncome = 0, totalCogs = 0, totalExpense = 0;
    for (final tx in transactions) {
      if (tx.type == AppConstants.typeIncome) {
        totalIncome += tx.amount;
        totalCogs += tx.cogs;
      } else {
        totalExpense += tx.amount;
      }
    }
    final grossProfit = totalIncome - totalCogs;
    return {
      'totalIncome': totalIncome,
      'totalCogs': totalCogs,
      'grossProfit': grossProfit,
      'totalExpense': totalExpense,
      'netProfit': grossProfit - totalExpense,
    };
  }

  String _findBusinessName(int businessId) {
    final b = _businesses.cast<BusinessModel?>().firstWhere(
      (b) => b?.businessId == businessId,
      orElse: () => null,
    );
    return b?.name ?? 'Bisnis #$businessId';
  }

  Future<void> _exportReport(String format) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Menyiapkan laporan...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      if (_transactions.isEmpty) throw ExportException('Tidak ada data laporan');

      final headers = ['Tanggal', 'Bisnis', 'Kategori', 'Tipe', 'Jumlah', 'HPP', 'Metode Bayar', 'Deskripsi'];
      final rows = <List<dynamic>>[];

      for (final tx in _transactions) {
        final isIncome = tx.type == AppConstants.typeIncome;
        rows.add([
          FormatHelpers.displayDate(tx.transactionDate),
          _findBusinessName(tx.businessId),
          _categoryNames[tx.categoryId] ?? 'Kategori #${tx.categoryId}',
          isIncome ? 'Uang Masuk' : 'Uang Keluar',
          tx.amount,
          isIncome ? tx.cogs : 0,
          tx.paymentMethod,
          tx.description ?? '',
        ]);
      }

      final filename = 'laporan_${_filterAllBusinesses ? 'semua_bisnis' : 'bisnis_terpilih'}';
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
      await service.shareFile(file, text: 'Export Laporan');
    } catch (e) {
      scaffold.clearSnackBars();
      if (context.mounted) {
        ErrorSnackbar.showError(context, 'Gagal export: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = _summary['netProfit'] ?? 0;
    final isProfit = netProfit >= 0;

    final body = _buildReportContent(netProfit, isProfit);
    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(_filterAllBusinesses
            ? 'Laporan Semua Bisnis'
            : 'Laporan Bisnis'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Export',
            onSelected: (value) => _exportReport(value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              PopupMenuItem(value: 'xlsx', child: Text('Export Excel')),
            ],
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildReportContent(double netProfit, bool isProfit) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _error != null
          ? ErrorRetryWidget.fromAppError(
              _error!,
              onRetry: _loadData,
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business filter (selalu tampak, tidak hanya di AppBar)
                  _buildBusinessFilter(),
                  const SizedBox(height: AppSpacing.s6),

                  // Period filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final period in OwnerPeriodFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.s8),
                            child: _buildFilterChip(
                              label: period.label,
                              isSelected: _selectedPeriod == period,
                              onTap: () {
                                if (period == OwnerPeriodFilter.custom) {
                                  _pickCustomRange();
                                } else {
                                  setState(() => _selectedPeriod = period);
                                  _loadSummary();
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.s16),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    const SizedBox.shrink()
                  else ...[
                    NetProfitCard(
                      netProfit: netProfit,
                      style: NetProfitCardStyle.row,
                      title: _filterAllBusinesses
                          ? 'Total Laba / Rugi Bersih'
                          : 'Laba / Rugi Bersih',
                      trailing: _prevNetProfit != 0
                          ? PeriodComparisonBadge(
                              currentValue: netProfit,
                              previousValue: _prevNetProfit,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.s12),

                    // Detail cards with comparison
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Pendapatan',
                            amount: _summary['totalIncome'] ?? 0,
                            icon: Icons.trending_up_rounded,
                            color: AppTheme.profitColorTheme(context),
                            trailing: _prevTransactions.isNotEmpty
                                ? PeriodComparisonBadge(
                                    currentValue: _summary['totalIncome'] ?? 0,
                                    previousValue: _prevIncome,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: SummaryCard(
                            title: 'HPP',
                            amount: _summary['totalCogs'] ?? 0,
                            icon: Icons.inventory_rounded,
                            color: AppTheme.warningColorTheme(context),
                            trailing: _prevTransactions.isNotEmpty
                                ? PeriodComparisonBadge(
                                    currentValue: _summary['totalCogs'] ?? 0,
                                    previousValue: _prevCogs,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Laba Kotor',
                            amount: _summary['grossProfit'] ?? 0,
                            icon: Icons.monetization_on_rounded,
                            color: AppTheme.infoColorTheme(context),
                            trailing: _prevTransactions.isNotEmpty
                                ? PeriodComparisonBadge(
                                    currentValue: _summary['grossProfit'] ?? 0,
                                    previousValue: _prevGrossProfit,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: SummaryCard(
                            title: 'Pengeluaran',
                            amount: _summary['totalExpense'] ?? 0,
                            icon: Icons.trending_down_rounded,
                            color: AppTheme.lossColorTheme(context),
                            trailing: _prevTransactions.isNotEmpty
                                ? PeriodComparisonBadge(
                                    currentValue: _summary['totalExpense'] ?? 0,
                                    previousValue: _prevExpense,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s20),

                    // Category breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('Per Kategori',
                              style: AppTheme.subtitle.copyWith(fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Flexible(
                          child: DropdownButtonFormField<String>(
                            initialValue: _categoryTypeFilter,
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
                            items: [
                              DropdownMenuItem(
                                value: 'income',
                                child: Text(
                                  'Pemasukan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.onSurfaceColorTheme(context),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'expense',
                                child: Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.onSurfaceColorTheme(context),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(
                                  'Semua',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.onSurfaceColorTheme(context),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _categoryTypeFilter = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    CategoryBreakdownChart(data: _categoryBreakdown(_categoryTypeFilter)),

                    const SizedBox(height: AppSpacing.s20),

                    // Transaction list
                    TransactionSection(transactions: _toTransactionItems()),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBusinessFilter() {
    return SingleChildScrollView(
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
              _loadSummary();
            },
          ),
          const SizedBox(width: AppSpacing.s8),
          ..._businesses.map((b) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: _buildFilterChip(
                  label: b.name.length > 15 ? '${b.name.substring(0, 15)}...' : b.name,
                  isSelected: _selectedBusinessId == b.businessId,
                  onTap: () {
                    setState(() {
                      _filterAllBusinesses = false;
                      _selectedBusinessId = b.businessId;
                    });
                    _loadSummary();
                  },
                ),
              )),
        ],
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
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
}


