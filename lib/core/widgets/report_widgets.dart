import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/format_helpers.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

// ==================== Period Comparison Badge ====================

class PeriodComparisonBadge extends StatelessWidget {
  final double currentValue;
  final double previousValue;
  final bool compact;

  const PeriodComparisonBadge({
    super.key,
    required this.currentValue,
    required this.previousValue,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    if (previousValue == 0) return const SizedBox.shrink();

    final change = currentValue - previousValue;
    final percent = (change / previousValue.abs()) * 100;
    final isPositive = change >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color arrowColor =
        isPositive ? AppTheme.profitColorTheme(context) : AppTheme.lossColorTheme(context);
    final Color bgColor = arrowColor.withValues(alpha: isDark ? 0.15 : 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.s4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: arrowColor,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: arrowColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Category Breakdown Pie Chart ====================

class CategoryBreakdownChart extends StatelessWidget {
  final Map<String, double> data; // categoryName -> amount
  final String emptyMessage;

  const CategoryBreakdownChart({
    super.key,
    required this.data,
    this.emptyMessage = 'Belum ada data kategori',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Center(
            child: Text(emptyMessage,
                style: AppTheme.caption),
          ),
        ),
      );
    }

    final colors = AppTheme.categoryChartColors(context);
    final total = data.values.fold<double>(0, (a, b) => a + b);
    final entries = data.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: List.generate(entries.length, (i) {
                          final pct = (entries[i].value / total) * 100;
                          return PieChartSectionData(
                            value: entries[i].value,
                            color: colors[i % colors.length],
                            radius: 50,
                            title: pct < 5 ? '' : '${pct.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(entries.length, (i) {
                          final pct = (entries[i].value / total) * 100;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors[i % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    entries[i].key,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.onSurfaceVariantColorTheme(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurfaceColorTheme(context),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Transaction Section ====================

class TransactionSection extends StatefulWidget {
  final List<TransactionItem> transactions;
  final bool isLoading;

  const TransactionSection({
    super.key,
    required this.transactions,
    this.isLoading = false,
  });

  @override
  State<TransactionSection> createState() => _TransactionSectionState();
}

class _TransactionSectionState extends State<TransactionSection> {
  String _typeFilter = 'all';
  int? _limit = 25;

  List<TransactionItem> get _filtered {
    final filtered = _typeFilter == 'all'
        ? widget.transactions
        : widget.transactions.where((t) => t.type == _typeFilter).toList();
    if (_limit != null && filtered.length > _limit!) {
      return filtered.take(_limit!).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalFiltered = _typeFilter == 'all'
        ? widget.transactions.length
        : widget.transactions.where((t) => t.type == _typeFilter).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Transaksi',
                style: AppTheme.subtitle.copyWith(fontSize: 15)),
            const Spacer(),
            Text(
              '$totalFiltered transaksi',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.onSurfaceVariantColorTheme(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _typeFilter,
                isDense: true,
                borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                  ),
                  isDense: true,
                  filled: true,
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
                dropdownColor: AppTheme.surfaceColorTheme(context),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Semua')),
                  DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _typeFilter = v);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Flexible(
              child: DropdownButtonFormField<int?>(
                initialValue: _limit,
                isDense: true,
                borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                  ),
                  isDense: true,
                  filled: true,
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
                dropdownColor: AppTheme.surfaceColorTheme(context),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 25, child: Text('25')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                  DropdownMenuItem(value: 100, child: Text('100')),
                  DropdownMenuItem(value: null, child: Text('Semua')),
                ],
                onChanged: (v) => setState(() => _limit = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        if (widget.isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Center(
                child: Text(
                  'Belum ada transaksi',
                  style: AppTheme.caption,
                ),
              ),
            ),
          )
        else
          ...filtered.map((tx) => _TransactionTile(tx: tx)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionItem tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = tx.type == 'income';
    final Color amountColor = isIncome
        ? AppTheme.profitColorTheme(context)
        : AppTheme.lossColorTheme(context);
    final Color bgColor = isDark ? AppTheme.darkSurface : AppTheme.surface;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        side: BorderSide(
          color: AppTheme.outlineVariantColorTheme(context).withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.s6),
              ),
              child: Icon(
                isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 16,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceColorTheme(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.date,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              FormatHelpers.rupiah(tx.amount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionItem {
  final String type;
  final String category;
  final double amount;
  final String date;
  final String? description;

  const TransactionItem({
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
  });
}
