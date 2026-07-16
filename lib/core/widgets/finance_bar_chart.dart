import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/format_helpers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

class FinanceBarDataPoint {
  final String period;
  final double value;

  const FinanceBarDataPoint({required this.period, required this.value});
}

class FinanceBarChart extends StatelessWidget {
  final List<FinanceBarDataPoint> data;
  final String title;
  final Color? barColor;
  final Color Function(double value)? tooltipColorBuilder;
  final bool isWeekly;

  const FinanceBarChart({
    super.key,
    required this.data,
    required this.title,
    this.barColor,
    this.tooltipColorBuilder,
    this.isWeekly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final values = data.map((d) => d.value).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    
    double minY = minVal < 0 ? minVal * 1.35 : 0.0;
    double maxY = maxVal > 0 ? maxVal * 1.35 : 0.0;
    
    // Fallback if all values are zero
    if (minY == 0 && maxY == 0) {
      maxY = 1000000.0;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final double chartWidth = screenWidth - 32;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s12, AppSpacing.s4, AppSpacing.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: AppIconSize.s20, color: AppTheme.primaryColorTheme(context)),
                const SizedBox(width: AppSpacing.s8),
                Text(title,
                    style: AppTheme.labelSmall.copyWith(fontSize: 12)),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            SizedBox(
              height: 220,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth,
                      height: constraints.maxHeight,
                      child: BarChart(
                        BarChartData(
                          minY: minY,
                          maxY: maxY,
                          alignment: BarChartAlignment.spaceAround,
                          groupsSpace: 4,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              if (value == 0) {
                                return FlLine(
                                  color: AppTheme.primaryColorTheme(context).withValues(alpha: 0.5),
                                  strokeWidth: 1.5,
                                );
                              }
                              return FlLine(
                                color: AppTheme.outlineVariantColorTheme(context).withValues(alpha: 0.4),
                                strokeWidth: 0.8,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 24,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= data.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final period = data[idx].period;
                                  String label;
                                  try {
                                    final date = DateTime.parse(period);
                                    if (isWeekly && period.length == 10) {
                                      final endDate = date.add(const Duration(days: 6));
                                      if (date.month == endDate.month) {
                                        label = "${date.day}-${endDate.day} ${DateFormat('MMM', 'id_ID').format(date)}";
                                      } else {
                                        label = "${date.day} ${DateFormat('MMM', 'id_ID').format(date)} - ${endDate.day} ${DateFormat('MMM', 'id_ID').format(endDate)}";
                                      }
                                    } else if (period.length == 10) {
                                      label = DateFormat('dd MMM', 'id_ID').format(date);
                                    } else if (period.length == 7) {
                                      label = DateFormat('MMM', 'id_ID').format(date);
                                    } else {
                                      label = period;
                                    }
                                  } catch (_) {
                                    label = period;
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: isWeekly ? 8 : 9,
                                         color: AppTheme.onSurfaceVariantColorTheme(context),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 0),
                                    child: Text(
                                      _compactAmount(value),
                                      style: TextStyle(
                                        fontSize: 9,
                                         color: AppTheme.onSurfaceVariantColorTheme(context)
                                             .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => AppTheme.surfaceContainerHighestColorTheme(context),
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final d = data[groupIndex];
                                String tooltipLabel;
                                try {
                                  final date = DateTime.parse(d.period);
                                  if (isWeekly && d.period.length == 10) {
                                    final endDate = date.add(const Duration(days: 6));
                                    final endDateStr = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
                                    tooltipLabel = "${FormatHelpers.displayDate(d.period)} - ${FormatHelpers.displayDate(endDateStr)}";
                                  } else if (d.period.length == 10) {
                                    tooltipLabel = FormatHelpers.displayDate(d.period);
                                  } else if (d.period.length == 7) {
                                    tooltipLabel = FormatHelpers.displayPeriod(d.period);
                                  } else {
                                    tooltipLabel = d.period;
                                  }
                                } catch (_) {
                                  tooltipLabel = d.period;
                                }
                                final textColor = tooltipColorBuilder != null
                                    ? tooltipColorBuilder!(d.value)
                                    : (d.value >= 0                                ? AppTheme.profitChartColor(context)
                                : AppTheme.lossChartColor(context));
                                return BarTooltipItem(
                                  '$tooltipLabel\n${FormatHelpers.rupiah(d.value)}',
                                  TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          barGroups: List.generate(data.length, (i) {
                            final val = data[i].value;
                            final isNegative = val < 0;
                            final color = barColor ??
                                (isNegative
                                    ? AppTheme.lossChartColor(context)
                                    : AppTheme.profitChartColor(context));
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: val,
                                  color: color,
                                  width: 36,
                                  borderRadius: isNegative
                                      ? const BorderRadius.vertical(bottom: Radius.circular(AppRadius.s4))
                                      : const BorderRadius.vertical(top: Radius.circular(AppRadius.s4)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compactAmount(double amount) {
    final abs = amount.abs();
    if (abs >= 1_000_000_000) {
      return '${(amount / 1_000_000_000).toStringAsFixed(1)}M';
    } else if (abs >= 1_000_000) {
      return '${(amount / 1_000_000).toStringAsFixed(0)}jt';
    } else if (abs >= 1_000) {
      return '${(amount / 1_000).toStringAsFixed(0)}rb';
    }
    return amount.toStringAsFixed(0);
  }
}
