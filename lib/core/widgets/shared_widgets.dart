import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/format_helpers.dart';
import '../constants/constants.dart';

// ═══════════════════════════════════════════════════════════════
// POCKETFUND DESIGN SYSTEM — Reusable Components
// ═══════════════════════════════════════════════════════════════

// ── Modern Button ─────────────────────────────────────────────
class PfButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final PfButtonVariant variant;
  final double? height;

  const PfButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.variant = PfButtonVariant.primary,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final btn = FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : (icon != null ? Icon(icon, size: 20) : null),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: isExpanded ? Size(double.infinity, height ?? 52) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.s24,
          vertical: AppTheme.s16,
        ),
      ),
    );

    if (!isExpanded) return btn;

    return SizedBox(width: double.infinity, height: height ?? 52, child: btn);
  }
}

enum PfButtonVariant { primary, secondary, ghost }

// ── Modern Card ───────────────────────────────────────────────
class PfCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? radius;

  const PfCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius ?? AppTheme.radiusLarge),
      child: card,
    );
  }
}

// ── Section Header ────────────────────────────────────────────
class PfSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PfSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.s4, bottom: AppTheme.s12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.title),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.s4),
                  Text(subtitle!, style: AppTheme.caption),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class PfEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PfEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Icon(
                icon,
                size: 36,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppTheme.s20),
            Text(title, textAlign: TextAlign.center, style: AppTheme.title),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.s8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(height: 1.5),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.s24),
              PfButton(
                label: actionLabel!,
                onPressed: onAction,
                isExpanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Net Profit Card ───────────────────────────────────────────
class NetProfitCard extends StatelessWidget {
  final double netProfit;
  final NetProfitCardStyle style;
  final String? title;

  const NetProfitCard({
    super.key,
    required this.netProfit,
    this.style = NetProfitCardStyle.row,
    this.title,
  });

  bool get isProfit => netProfit >= 0;
  Color profitColor(BuildContext c) => AppTheme.profitColorTheme(c);
  Color lossColor(BuildContext c) => AppTheme.lossColorTheme(c);

  @override
  Widget build(BuildContext context) {
    final c = context;
    switch (style) {
      case NetProfitCardStyle.column:
        return _buildColumn(c);
      case NetProfitCardStyle.accentBar:
        return _buildAccentBar(c);
      case NetProfitCardStyle.row:
        return _buildRow(c);
    }
  }

  Widget _buildRow(BuildContext context) {
    final pc = isProfit ? profitColor(context) : lossColor(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: pc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                isProfit
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: pc,
              ),
            ),
            const SizedBox(width: AppTheme.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Laba / Rugi Bersih',
                    style: AppTheme.labelSmall.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: AppTheme.s4),
                  Text(
                    FormatHelpers.rupiah(netProfit),
                    style: AppTheme.amountMedium.copyWith(color: pc),
                  ),
                ],
              ),
            ),
            _buildBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(BuildContext context) {
    final pc = isProfit ? profitColor(context) : lossColor(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s20),
        child: Column(
          children: [
            Text(title ?? 'Laba / Rugi Bersih', style: AppTheme.labelSmall),
            const SizedBox(height: AppTheme.s8),
            Text(
              FormatHelpers.rupiah(netProfit),
              style: AppTheme.amountLarge.copyWith(color: pc),
            ),
            const SizedBox(height: AppTheme.s8),
            _buildBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentBar(BuildContext context) {
    final pc = isProfit ? profitColor(context) : lossColor(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s20),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(
                color: pc,
                borderRadius: BorderRadius.circular(AppTheme.s4),
              ),
            ),
            const SizedBox(width: AppTheme.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Laba / Rugi Bersih',
                    style: AppTheme.labelSmall.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: AppTheme.s4),
                  Text(
                    FormatHelpers.rupiah(netProfit),
                    style: AppTheme.amountMedium.copyWith(color: pc),
                  ),
                ],
              ),
            ),
            _buildBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final pc = isProfit ? profitColor(context) : lossColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s12,
        vertical: AppTheme.s8,
      ),
      decoration: BoxDecoration(
        color: pc.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        isProfit ? 'LABA' : 'RUGI',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: pc,
        ),
      ),
    );
  }
}

enum NetProfitCardStyle { row, column, accentBar }

// ── Summary Card ──────────────────────────────────────────────
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
        padding: const EdgeInsets.all(AppTheme.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppTheme.s8),
                Text(title, style: AppTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppTheme.s12),
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

// ── Quick Action Button ───────────────────────────────────────
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.s12,
            horizontal: AppTheme.s8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: AppTheme.s8),
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
                      color: colorScheme.onSurface,
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

// ── Transaction Card ──────────────────────────────────────────
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
        padding: const EdgeInsets.all(AppTheme.s12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppTheme.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.s2),
                      child: Text(
                        title,
                        style: AppTheme.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  Text(
                    subtitle,
                    style: AppTheme.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: AppTheme.s4),
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
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppTheme.lossColorTheme(context),
                ),
                onPressed: onDelete,
                tooltip: 'Hapus',
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Item (for detail rows) ───────────────────────────────
class PfStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const PfStatRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.s4),
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton Loader ───────────────────────────────────────────
class PfSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const PfSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppTheme.radiusSmall,
  });

  @override
  State<PfSkeleton> createState() => _PfSkeletonState();
}

class _PfSkeletonState extends State<PfSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: _animation.value * 0.15),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ── Skeleton Card ─────────────────────────────────────────────
class PfSkeletonCard extends StatelessWidget {
  final int lines;

  const PfSkeletonCard({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            lines,
            (i) => Padding(
              padding: EdgeInsets.only(
                bottom: i < lines - 1 ? AppTheme.s12 : 0,
              ),
              child: PfSkeleton(
                width: i == 0 ? 0.6 : (i == lines - 1 ? 0.4 : 0.9),
                height: i == 0 ? 14 : 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fade In Entrance Animation ────────────────────────────────
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
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(
      begin: 16.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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

// ── Balanced Card (used in dashboard rows) ────────────────────
class PfBalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final int activeCount;

  const PfBalanceCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppTheme.s8),
                Text(title, style: AppTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppTheme.s8),
            Text(
              FormatHelpers.rupiah(amount),
              style: AppTheme.amountMedium.copyWith(color: color),
            ),
            const SizedBox(height: AppTheme.s4),
            Text('$activeCount aktif', style: AppTheme.caption),
          ],
        ),
      ),
    );
  }
}

// ── Financial Calculator ──────────────────────────────────────
class FinancialCalculator {
  const FinancialCalculator._();

  static Map<String, double> computeSummary(
    List<({String type, double amount, double cogs})> transactions,
  ) {
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

  static bool isProfit(double netProfit) => netProfit >= 0;

  static String periodLabel(String periodKey) {
    final parts = periodKey.split('-');
    if (parts.length != 2) return periodKey;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return periodKey;
    return '${months[month - 1]} ${parts[0]}';
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE TRANSITION — Horizontal slide for tab-based navigation
// ═══════════════════════════════════════════════════════════════

/// Wraps [AnimatedSwitcher] with a horizontal slide transition that
/// slides left when navigating to a higher index and right when
/// navigating to a lower index.
///
/// This gives a natural "page turn" feel for bottom navigation bars.
class PfSlidePageView extends StatefulWidget {
  final int index;
  final Widget child;

  const PfSlidePageView({super.key, required this.index, required this.child});

  @override
  State<PfSlidePageView> createState() => _PfSlidePageViewState();
}

class _PfSlidePageViewState extends State<PfSlidePageView> {
  int _previousIndex = 0;

  @override
  void didUpdateWidget(PfSlidePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _previousIndex = oldWidget.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Slide left (offset: -1 → 0) when going forward, right (offset: 1 → 0) when going back
    final slideDirection = widget.index > _previousIndex ? -1.0 : 1.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final slideAnimation =
            Tween<Offset>(
              begin: Offset(slideDirection * 0.3, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM NAVIGATION — Shared component for Owner & Manager shells
// ═══════════════════════════════════════════════════════════════

/// Data model for a bottom navigation item.
class PfNavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const PfNavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Shared bottom navigation bar used by OwnerShell and ManagerShell.
///
/// Features:
/// - Animated icon container on selection
/// - Gradient add button with shadow
/// - Theme-aware colors (light/dark)
/// - Rounded top corners with soft shadow
class PfBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onAddPressed;
  final List<PfNavItemData> items;

  const PfBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onAddPressed,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.darkPrimaryText : AppTheme.primary;
    final inactiveColor = isDark
        ? AppTheme.darkSecondaryText
        : AppTheme.secondaryText;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXL),
          topRight: Radius.circular(AppTheme.radiusXL),
        ),
        boxShadow: isDark ? null : AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // First two items (indices 0, 1)
              for (int i = 0; i < 2; i++)
                _PfNavItem(
                  icon: items[i].icon,
                  activeIcon: items[i].activeIcon,
                  label: items[i].label,
                  isSelected: selectedIndex == i,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onItemSelected(i),
                ),
              // Center add button
              _PfAddNavButton(
                onPressed: onAddPressed,
                activeColor: activeColor,
              ),
              // Last two items (indices 2, 3)
              for (int i = 2; i < 4; i++)
                _PfNavItem(
                  icon: items[i].icon,
                  activeIcon: items[i].activeIcon,
                  label: items[i].label,
                  isSelected: selectedIndex == (i + 1),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onItemSelected(i + 1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single navigation item with animated icon container.
class _PfNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _PfNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 40 : 24,
              height: isSelected ? 40 : 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient add button with shadow, placed in the center of the nav.
class _PfAddNavButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color activeColor;

  const _PfAddNavButton({required this.onPressed, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use accent/green for the + button in both themes, not nav text color
    final buttonColor = isDark ? AppTheme.darkPrimary : AppTheme.primary;

    return Expanded(
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [buttonColor, buttonColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 10,
                color: activeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── IDR Currency Input Formatter ──────────────────────────────
class IdrInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    final value = int.tryParse(text) ?? 0;
    final formatted = _formatIdr(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatIdr(int value) {
    final s = value.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(s[i]);
    }
    return result.toString();
  }
}
