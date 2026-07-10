import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/format_helpers.dart';

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
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    size: 18, color: AppTheme.infoColor),
                const SizedBox(width: 8),
                Text(title,
                    style: AppTheme.labelSmall.copyWith(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
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
                      color: Theme.of(context).colorScheme.outlineVariant,
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
                          final monthStr = data[idx].month;
                          final parts = monthStr.split('-');
                          final label = parts.length >= 2
                              ? _shortMonth(int.parse(parts[1]))
                              : monthStr;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Theme.of(context).colorScheme.surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) =>
                          touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final monthLabel = idx >= 0 && idx < data.length
                            ? data[idx].month
                            : '';
                        return LineTooltipItem(
                          '$monthLabel\n${FormatHelpers.rupiah(spot.y)}',
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
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: isProfit
                                ? AppTheme.profitColor
                                : AppTheme.lossColor,
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

  String _shortMonth(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return month >= 1 && month <= 12 ? months[month] : '$month';
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
