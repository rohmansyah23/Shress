import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/format_helpers.dart';
import '../../core/theme/app_spacing.dart';

import '../../core/theme/app_icon_size.dart';

/// Data point for the trend chart.
class TrendDataPoint {
  final String month; // YYYY-MM
  final double netProfit;

  const TrendDataPoint({required this.month, required this.netProfit});
}

/// Line chart showing net profit trend over months.
/// Green dots for profit, red dots for loss.
class TrendChart extends StatelessWidget {
  final List<TrendDataPoint> data;
  final String title;

  const TrendChart({
    super.key,
    required this.data,
    this.title = 'Tren Laba/Rugi 6 Bulan',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i].netProfit),
    );

    final values = data.map((d) => d.netProfit).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();
    final chartMinY = minVal < 0 ? minVal * 1.3 : minVal - range * 0.2;
    final chartMaxY = maxVal > 0 ? maxVal * 1.3 : maxVal + range * 0.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s8, AppSpacing.s16, AppSpacing.s16, AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    size: AppIconSize.s18, color: AppTheme.infoColor),
                const SizedBox(width: AppSpacing.s8),
                Text(title,
                    style: AppTheme.labelSmall.copyWith(fontSize: 12)),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: chartMinY,
                  maxY: chartMaxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.outlineVariantColorTheme(context),
                      strokeWidth: 1,
                    ),
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
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final period = data[idx].month;
                          String label;
                          try {
                            final date = DateTime.parse(period);
                            if (period.length == 10) {
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
                                fontSize: 10,
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
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              _compactAmount(value),
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.surfaceContainerHighestColorTheme(context),
                      getTooltipItems: (touchedSpots) =>
                          touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final period = idx >= 0 && idx < data.length
                            ? data[idx].month
                            : '';
                        String tooltipLabel;
                        try {
                          DateTime.parse(period);
                          if (period.length == 10) {
                            tooltipLabel = FormatHelpers.displayDate(period);
                          } else if (period.length == 7) {
                            tooltipLabel = FormatHelpers.displayPeriod(period);
                          } else {
                            tooltipLabel = period;
                          }
                        } catch (_) {
                          tooltipLabel = period;
                        }
                        return LineTooltipItem(
                          '$tooltipLabel\n${FormatHelpers.rupiah(spot.y)}',
                          TextStyle(
                            color: spot.y >= 0
                                ? AppTheme.profitColorTheme(context)
                                : AppTheme.lossColorTheme(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.infoColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isProfit = data[index].netProfit >= 0;
                          return FlDotCirclePainter(
                            radius: 3.5,
                            color: AppTheme.surfaceColorTheme(context),
                            strokeWidth: 2.5,
                            strokeColor: isProfit
                                ? AppTheme.profitChartColor(context)
                                : AppTheme.lossChartColor(context),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.infoColor.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                ),
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
