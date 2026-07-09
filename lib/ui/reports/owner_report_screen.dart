import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';

/// Owner Financial Report Screen.
/// Can filter by ALL businesses (accumulated) or a specific business.
/// Shows: Revenue, COGS, Gross Profit, Expenses, Net Profit.
class OwnerReportScreen extends ConsumerStatefulWidget {
  const OwnerReportScreen({super.key});

  @override
  ConsumerState<OwnerReportScreen> createState() => _OwnerReportScreenState();
}

class _OwnerReportScreenState extends ConsumerState<OwnerReportScreen> {
  bool _filterAllBusinesses = true;
  int? _selectedBusinessId;
  List<BusinessModel> _businesses = [];
  bool _isLoading = true;
  AppError? _error;
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
    _loadData();
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
      Map<String, double> summary;

      if (_filterAllBusinesses) {
        // Get all business IDs
        final allIds = _businesses.map((b) => b.businessId).toList();
        summary = await SupabaseService.instance
            .getAllBusinessesSummary(allIds);
      } else if (_selectedBusinessId != null) {
        summary = await SupabaseService.instance
            .getBusinessSummary(_selectedBusinessId!);
      } else {
        summary = {
          'totalIncome': 0,
          'totalCogs': 0,
          'grossProfit': 0,
          'totalExpense': 0,
          'netProfit': 0,
        };
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

  @override
  Widget build(BuildContext context) {
    final netProfit = _summary['netProfit'] ?? 0;
    final isProfit = netProfit >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_filterAllBusinesses
            ? 'Laporan Semua Bisnis'
            : 'Laporan Bisnis'),
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
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
              // Filter chips: All / Specific Business
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Semua Bisnis'),
                      selected: _filterAllBusinesses,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _filterAllBusinesses = true;
                            _selectedBusinessId = null;
                          });
                          unawaited(_loadSummary());
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._businesses.map((b) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(b.name.length > 15
                                ? '${b.name.substring(0, 15)}...'
                                : b.name),
                            selected: _selectedBusinessId == b.businessId,
                            onSelected: (selected) {
                              setState(() {
                                _filterAllBusinesses = false;
                                _selectedBusinessId =
                                    selected ? b.businessId : null;
                              });
                              unawaited(_loadSummary());
                            },
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_isLoading)
                const SkeletonSummaryGrid()
              else if (_error != null)
                const SizedBox.shrink()
              else ...[
                // Net Profit (large, prominent)
                Card(
                  color: isProfit
                      ? AppTheme.profitColor.withValues(alpha: 0.1)
                      : AppTheme.lossColor.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          _filterAllBusinesses
                              ? 'Total Laba / Rugi Bersih'
                              : 'Laba / Rugi Bersih',
                          style: AppTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          FormatHelpers.rupiah(netProfit),
                          style: AppTheme.amountLarge.copyWith(
                            color: isProfit
                                ? AppTheme.profitColor
                                : AppTheme.lossColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isProfit
                                ? AppTheme.profitColor
                                : AppTheme.lossColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isProfit ? 'LABA' : 'RUGI',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Detail cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pendapatan',
                        amount: _summary['totalIncome'] ?? 0,
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.profitColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
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
                      child: _SummaryCard(
                        title: 'Laba Kotor',
                        amount: _summary['grossProfit'] ?? 0,
                        icon: Icons.monetization_on_rounded,
                        color: AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pengeluaran',
                        amount: _summary['totalExpense'] ?? 0,
                        icon: Icons.trending_down_rounded,
                        color: AppTheme.lossColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Business-specific info
                if (!_filterAllBusinesses && _selectedBusinessId != null)
                  Text(
                    'Menampilkan data untuk bisnis terpilih',
                    style: AppTheme.caption,
                  )
                else if (_filterAllBusinesses && _businesses.isNotEmpty)
                  Text(
                    'Menampilkan data akumulasi dari ${_businesses.length} bisnis',
                    style: AppTheme.caption,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(title, style: AppTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              FormatHelpers.rupiah(amount),
              style: AppTheme.amountMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
