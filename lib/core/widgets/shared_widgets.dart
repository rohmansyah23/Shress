import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/format_helpers.dart';
import '../constants/constants.dart';

// ====================================================================
// QuickActionButton — icon + label card, used in dashboards
// ====================================================================

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// SummaryCard — icon + title + amount, used in reports and dashboards
// ====================================================================

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
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

// ====================================================================
// NetProfitCard — prominent card with icon, amount, and LABA/RUGI badge
//
// Variants:
//   - Row layout (dashboard): icon left, text center, badge right
//   - Column layout (reports): text top, large amount, badge below
//   - Accent bar layout (BusinessOwnerShell dashboard): colored left bar
// ====================================================================

enum NetProfitCardStyle { row, column, accentBar }

class NetProfitCard extends StatelessWidget {
  final double netProfit;
  final NetProfitCardStyle style;
  final String? title;
  final bool isProfit;

  const NetProfitCard({
    super.key,
    required this.netProfit,
    this.style = NetProfitCardStyle.row,
    this.title,
  }) : isProfit = netProfit >= 0;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case NetProfitCardStyle.column:
        return _buildColumnStyle();
      case NetProfitCardStyle.accentBar:
        return _buildAccentBarStyle();
      case NetProfitCardStyle.row:
        return _buildRowStyle();
    }
  }

  Widget _buildRowStyle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isProfit ? AppTheme.profitColor : AppTheme.lossColor)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isProfit
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Laba / Rugi Bersih',
                    style: AppTheme.labelSmall.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FormatHelpers.rupiah(netProfit),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
                    ),
                  ),
                ],
              ),
            ),
            _buildBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnStyle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title ?? 'Laba / Rugi Bersih',
              style: AppTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Text(
              FormatHelpers.rupiah(netProfit),
              style: AppTheme.amountLarge.copyWith(
                color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentBarStyle() {
    return Card(
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(
                color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Laba / Rugi Bersih',
                    style: AppTheme.labelSmall.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FormatHelpers.rupiah(netProfit),
                    style: AppTheme.amountMedium.copyWith(
                      color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
                    ),
                  ),
                ],
              ),
            ),
            _buildBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isProfit ? AppTheme.profitColor : AppTheme.lossColor)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isProfit ? 'LABA' : 'RUGI',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
        ),
      ),
    );
  }
}

// ====================================================================
// TransactionCard — compact row for transaction list items
// ====================================================================

class TransactionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;
  final IconData icon;
  final Color color;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    this.icon = Icons.trending_up_rounded,
    required this.color,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        title,
                        style: AppTheme.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  Text(
                    subtitle,
                    style: AppTheme.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppTheme.lossColor),
                onPressed: onDelete,
                tooltip: 'Hapus',
              ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// FinancialCalculator — helper utilities for financial computations
// ====================================================================

class FinancialCalculator {
  const FinancialCalculator._();

  /// Compute summary from a list of transactions.
  /// Returns a map with keys: totalIncome, totalCogs, grossProfit,
  /// totalExpense, netProfit.
  static Map<String, double> computeSummary(List<({String type, double amount, double cogs})> transactions) {
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

  /// Check if a net profit value indicates profit.
  static bool isProfit(double netProfit) => netProfit >= 0;

  /// Get period label for display.
  static String periodLabel(String periodKey) {
    final parts = periodKey.split('-');
    if (parts.length != 2) return periodKey;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return periodKey;
    return '${months[month - 1]} ${parts[0]}';
  }
}

// ====================================================================
// FadeInEntrance — micro-animation to slide and fade items in
// ====================================================================

class FadeInEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeInEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<FadeInEntrance> createState() => _FadeInEntranceState();
}

class _FadeInEntranceState extends State<FadeInEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0.0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
