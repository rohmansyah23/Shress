import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';

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
      Map<String, double> summary;

      List<int> targetIds;
      if (_filterAllBusinesses) {
        targetIds = _businesses.map((b) => b.businessId).toList();
      } else if (_selectedBusinessId != null) {
        targetIds = [_selectedBusinessId!];
      } else {
        targetIds = [];
      }

      if (targetIds.isEmpty) {
        summary = {
          'totalIncome': 0,
          'totalCogs': 0,
          'grossProfit': 0,
          'totalExpense': 0,
          'netProfit': 0,
        };
      } else if (_startDate != null && _endDate != null) {
        final transactions = await supa.getAllTransactionsByDateRange(
          targetIds,
          _startDate!,
          _endDate!,
        );
        summary = _computeSummary(transactions);
      } else {
        if (_filterAllBusinesses) {
          summary = await supa.getAllBusinessesSummary(targetIds);
        } else {
          summary = await supa.getBusinessSummary(targetIds.first);
        }
      }

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business filter (selalu tampak, tidak hanya di AppBar)
                  _buildBusinessFilter(),
                  const SizedBox(height: 6),

                  // Period filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final period in OwnerPeriodFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(period.label),
                              selected: _selectedPeriod == period,
                              onSelected: (selected) {
                                if (period == OwnerPeriodFilter.custom) {
                                  _pickCustomRange();
                                } else if (selected) {
                                  setState(
                                      () => _selectedPeriod = period);
                                  _loadSummary();
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_isLoading)
                    const SkeletonReportFull()
                  else if (_error != null)
                    const SizedBox.shrink()
                  else ...[
                    NetProfitCard(
                      netProfit: netProfit,
                      style: NetProfitCardStyle.accentBar,
                      title: _filterAllBusinesses
                          ? 'Total Laba / Rugi Bersih'
                          : 'Laba / Rugi Bersih',
                    ),
                    const SizedBox(height: 12),

                    // Detail cards
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Pendapatan',
                            amount: _summary['totalIncome'] ?? 0,
                            icon: Icons.trending_up_rounded,
                            color: AppTheme.profitColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            title: 'HPP',
                            amount: _summary['totalCogs'] ?? 0,
                            icon: Icons.inventory_rounded,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Laba Kotor',
                            amount: _summary['grossProfit'] ?? 0,
                            icon: Icons.monetization_on_rounded,
                            color: AppTheme.infoColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            title: 'Pengeluaran',
                            amount: _summary['totalExpense'] ?? 0,
                            icon: Icons.trending_down_rounded,
                            color: AppTheme.lossColor,
                          ),
                        ),
                      ],
                    ),
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
          FilterChip(
            label: const Text('Semua'),
            selected: _filterAllBusinesses,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _filterAllBusinesses = true;
                  _selectedBusinessId = null;
                });
                _loadSummary();
              }
            },
          ),
          const SizedBox(width: 6),
          ..._businesses.map((b) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                    label: Text(
                        b.name.length > 15 ? '${b.name.substring(0, 15)}...' : b.name),
                    selected: _selectedBusinessId == b.businessId,
                    onSelected: (selected) {
                      setState(() {
                        _filterAllBusinesses = false;
                        _selectedBusinessId =
                            selected ? b.businessId : null;
                      });
                      _loadSummary();
                    },
                  ),
                )),
        ],
      ),
    );
  }
}


