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

enum PeriodFilter {
  today('Hari Ini'),
  thisWeek('Minggu Ini'),
  thisMonth('Bulan Ini'),
  thisYear('Tahun Ini'),
  custom('Custom');

  final String label;
  const PeriodFilter(this.label);
}

class ManagerReportScreen extends ConsumerStatefulWidget {
  final BusinessModel business;
  final bool showAppBar;

  const ManagerReportScreen({super.key, required this.business, this.showAppBar = true});

  @override
  ConsumerState<ManagerReportScreen> createState() =>
      _ManagerReportScreenState();
}

class _ManagerReportScreenState extends ConsumerState<ManagerReportScreen> {
  PeriodFilter _selectedPeriod = PeriodFilter.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _isLoading = true;
  AppError? _error;

  Map<String, double> _summary = {
    'totalIncome': 0,
    'totalCogs': 0,
    'grossProfit': 0,
    'totalExpense': 0,
    'netProfit': 0,
  };

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _prevTransactions = [];
  Map<int, String> _categoryNames = {};
  String _categoryTypeFilter = 'all';

  double _prevIncomeVal = 0;
  double _prevCogsVal = 0;
  double _prevExpenseVal = 0;

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        return _formatDate(now);
      case PeriodFilter.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return _formatDate(weekStart);
      case PeriodFilter.thisMonth:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      case PeriodFilter.thisYear:
        return '${now.year}-01-01';
      case PeriodFilter.custom:
        if (_customStart == null) return null;
        return _formatDate(_customStart!);
    }
  }

  String? get _endDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        return _formatDate(now);
      case PeriodFilter.thisWeek:
        return _formatDate(now);
      case PeriodFilter.thisMonth:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${FormatHelpers.daysInMonth(now.year, now.month)}';
      case PeriodFilter.thisYear:
        return '${now.year}-12-31';
      case PeriodFilter.custom:
        if (_customEnd == null) return null;
        return _formatDate(_customEnd!);
    }
  }

  String? get _prevStartDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        return _formatDate(now.subtract(const Duration(days: 1)));
      case PeriodFilter.thisWeek:
        return _formatDate(now.subtract(Duration(days: now.weekday - 1 + 7)));
      case PeriodFilter.thisMonth:
        final prev = DateTime(now.year, now.month - 1, 1);
        return _formatDate(prev);
      case PeriodFilter.thisYear:
        return '${now.year - 1}-01-01';
      case PeriodFilter.custom:
        if (_customStart == null || _customEnd == null) return null;
        final prevRange = _customEnd!.difference(_customStart!).inDays + 1;
        return _formatDate(_customStart!.subtract(Duration(days: prevRange)));
    }
  }

  String? get _prevEndDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        return _formatDate(now.subtract(const Duration(days: 1)));
      case PeriodFilter.thisWeek:
        return _formatDate(now.subtract(const Duration(days: 7)));
      case PeriodFilter.thisMonth:
        final prev = DateTime(now.year, now.month, 0);
        return _formatDate(prev);
      case PeriodFilter.thisYear:
        return '${now.year - 1}-12-31';
      case PeriodFilter.custom:
        if (_customStart == null || _customEnd == null) return null;
        return _formatDate(_customStart!.subtract(const Duration(days: 1)));
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        return 'Hari Ini';
      case PeriodFilter.thisWeek:
        return 'Minggu Ini';
      case PeriodFilter.thisMonth:
        return FormatHelpers.displayPeriod(
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');
      case PeriodFilter.thisYear:
        return 'Tahun ${DateTime.now().year}';
      case PeriodFilter.custom:
        if (_customStart == null || _customEnd == null) return 'Pilih Tanggal';
        return '${FormatHelpers.displayDate('${_customStart!.year}-${_customStart!.month.toString().padLeft(2, '0')}-${_customStart!.day.toString().padLeft(2, '0')}')} - ${FormatHelpers.displayDate('${_customEnd!.year}-${_customEnd!.month.toString().padLeft(2, '0')}-${_customEnd!.day.toString().padLeft(2, '0')}')}';
    }
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
        _selectedPeriod = PeriodFilter.custom;
      });
      _loadData();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.watch(transactionRefreshProvider);
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
          widget.business.name,
          _categoryNames[tx.categoryId] ?? 'Kategori #${tx.categoryId}',
          isIncome ? 'Uang Masuk' : 'Uang Keluar',
          tx.amount,
          isIncome ? tx.cogs : 0,
          tx.paymentMethod,
          tx.description ?? '',
        ]);
      }

      final filename = 'laporan_${widget.business.name.replaceAll(' ', '_')}';
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final supa = SupabaseService.instance;
      final businessId = widget.business.businessId;

      // Fetch current period
      if (_startDate != null && _endDate != null) {
        _transactions = await supa.getTransactionsByDateRange(
          businessId, _startDate!, _endDate!,
        );
        _summary = _computeSummary(_transactions);
      } else {
        _transactions = [];
        _summary = await supa.getBusinessSummary(businessId);
      }

      // Fetch previous period
      _prevTransactions = [];
      if (_startDate != null && _endDate != null && _prevStartDate != null && _prevEndDate != null) {
        try {
          _prevTransactions = await supa.getTransactionsByDateRange(
            businessId, _prevStartDate!, _prevEndDate!,
          );
        } catch (_) {
          _prevTransactions = [];
        }
      }

      _computePrevSummary();

      // Fetch categories
      _categoryNames = {};
      try {
        final cats = await supa.getCategoriesByBusiness(businessId);
        for (final c in cats) {
          _categoryNames[c.categoryId] = c.name;
        }
      } catch (_) {}

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

  @override
  Widget build(BuildContext context) {
    final netProfit = _summary['netProfit'] ?? 0;
    final user = ref.read(currentUserProvider);
    final isStaff = user?.role == AppConstants.roleStaff;

    final body = _buildBody(netProfit, isStaff);

    if (!widget.showAppBar) {
      return SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s12),
            _buildPeriodSelector(),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          if (!isStaff)
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildPeriodSelector(),
        ),
      ),
      body: body,
    );
  }

  Widget _buildBody(double netProfit, bool isStaff) {
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
                  Text(_periodLabel,
                      style: AppTheme.subtitle.copyWith(fontSize: 14)),
                  const SizedBox(height: AppSpacing.s16),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    NetProfitCard(
                      netProfit: netProfit,
                      style: NetProfitCardStyle.row,
                      trailing: _prevNetProfit != 0
                          ? PeriodComparisonBadge(
                              currentValue: netProfit,
                              previousValue: _prevNetProfit,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.s12),

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

                    // Category breakdown (hidden for Staff)
                    if (!isStaff) ...[
                      const SizedBox(height: AppSpacing.s20),
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
                    ],

                    const SizedBox(height: AppSpacing.s20),

                    // Transaction list (visible to all)
                    TransactionSection(transactions: _toTransactionItems()),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final period in PeriodFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: GestureDetector(
                  onTap: () {
                    if (period == PeriodFilter.custom) {
                      _pickCustomRange();
                    } else {
                      setState(() => _selectedPeriod = period);
                      _loadData();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == period
                          ? (isLight ? AppTheme.primaryColorTheme(context) : AppTheme.accent)
                          : (isLight
                                ? AppTheme.surfaceContainerColorTheme(context)
                                : AppTheme.darkBackground),
                      borderRadius: BorderRadius.circular(AppRadius.s20),
                      border: Border.all(
                        color: _selectedPeriod == period
                            ? Colors.transparent
                            : AppTheme.outlineVariantColorTheme(context),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      period.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedPeriod == period ? FontWeight.w600 : FontWeight.normal,
                            color: _selectedPeriod == period
                                ? AppTheme.card
                                : AppTheme.onSurfaceVariantColorTheme(context),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
