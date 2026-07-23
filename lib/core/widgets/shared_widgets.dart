import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'adaptive_amount_text.dart';

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
    // Resolve variant-specific colors
    Color? bgOverride;
    Color? fgOverride;

    switch (variant) {
      case PfButtonVariant.danger:
        bgOverride = AppTheme.lossColorTheme(context);
        fgOverride = AppTheme.onDangerColorTheme(context);
      case PfButtonVariant.primary:
      case PfButtonVariant.secondary:
      case PfButtonVariant.ghost:
        break;
    }

    final btn = FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fgOverride ?? Colors.white,
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
        backgroundColor: bgOverride,
        foregroundColor: fgOverride,
      ),
    );

    if (!isExpanded) return btn;

    return SizedBox(width: double.infinity, height: height ?? 52, child: btn);
  }
}

enum PfButtonVariant { primary, secondary, ghost, danger }

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
                color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.s20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceColorTheme(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.s8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.onSurfaceVariantColorTheme(context),
                  height: 1.4,
                ),
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
  final Widget? trailing;

  const NetProfitCard({
    super.key,
    required this.netProfit,
    this.style = NetProfitCardStyle.row,
    this.title,
    this.trailing,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: LinearGradient(
          colors: [
            pc.withValues(alpha: 0.12),
            pc.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: pc.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.s20,
          vertical: AppTheme.s16,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pc.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isProfit
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: pc,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Laba / Rugi Bersih',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
                  const SizedBox(height: AppTheme.s4),
                  AdaptiveAmountText(
                    amount: netProfit,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: pc,
                    ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: LinearGradient(
          colors: [
            pc.withValues(alpha: 0.12),
            pc.withValues(alpha: 0.04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: pc.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s20),
        child: Column(
          children: [
            Text(
              title ?? 'Laba / Rugi Bersih',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariantColorTheme(context),
              ),
            ),
            const SizedBox(height: AppTheme.s8),
            AdaptiveAmountText(
              amount: netProfit,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: pc,
              ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        color: AppTheme.surfaceColorTheme(context),
        border: Border.all(
          color: AppTheme.outlineVariantColorTheme(context).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s16),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 52,
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
                  const SizedBox(height: AppTheme.s4),
                  AdaptiveAmountText(
                    amount: netProfit,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: pc,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppTheme.s8),
              trailing!,
            ],
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
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: pc.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pc.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        isProfit ? 'LABA' : 'RUGI',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
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
  final Widget? trailing;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColorTheme(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.outlineVariantColorTheme(context).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppTheme.s8),
                if (trailing != null)
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (trailing != null) ...[
                  const SizedBox(width: AppTheme.s4),
                  Flexible(child: trailing!),
                ],
              ],
            ),
            const SizedBox(height: 10),
            AdaptiveAmountText(
              amount: amount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
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
    // Strip manual \n linebreaks for fluid modern layout
    final cleanLabel = label.replaceAll('\n', ' ');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: AppTheme.surfaceColorTheme(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: AppTheme.outlineVariantColorTheme(context).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.s12,
            horizontal: AppTheme.s8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: AppTheme.s8),
              Text(
                cleanLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Item Model & All Actions Bottom Sheet ───────
class QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

void showAllActionsBottomSheet(
  BuildContext context, {
  required String title,
  required List<QuickActionItem> items,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceColorTheme(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.s20,
        AppTheme.s12,
        AppTheme.s20,
        AppTheme.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariantColorTheme(context)
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.s16),
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: AppTheme.primaryColorTheme(context),
                size: 22,
              ),
              const SizedBox(width: AppTheme.s8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.s20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (ctx, i) {
              final item = items[i];
              return QuickActionButton(
                icon: item.icon,
                label: item.label,
                color: item.color,
                onTap: () {
                  Navigator.pop(ctx);
                  item.onTap();
                },
              );
            },
          ),
        ],
      ),
    ),
  );
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Text(
                    subtitle,
                    style: AppTheme.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.s4),
                  Text(
                    amount,
                    style: AppTheme.amountMedium.copyWith(
                      fontSize: 15,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            child: Text(label, style: AppTheme.caption.copyWith(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
          color: AppTheme.onSurfaceColorTheme(context).withValues(alpha: _animation.value * 0.15),
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
                Flexible(
                  child: Text(
                    title,
                    style: AppTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.s8),
            AdaptiveAmountText(
              amount: amount,
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
  final VoidCallback? onAddPressed;
  final bool showCenterAddButton;
  final List<PfNavItemData> items;

  const PfBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onAddPressed,
    this.showCenterAddButton = true,
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
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkDivider : AppTheme.divider,
            width: 1.0,
          ),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ]
            : AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (showCenterAddButton) ...[
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
                  if (onAddPressed != null)
                    _PfCenterActionButton(
                      icon: Icons.add_rounded,
                      label: 'Tambah',
                      onPressed: onAddPressed!,
                      isSelected: false,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
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
                ] else ...[
                  // Render 5 items for Owner, with the middle item (index 2) as a floating gradient button
                  for (int i = 0; i < items.length; i++)
                    if (i == 2)
                      _PfCenterActionButton(
                        icon: items[i].icon,
                        label: items[i].label,
                        onPressed: () => onItemSelected(i),
                        isSelected: selectedIndex == i,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      )
                    else
                      _PfNavItem(
                        icon: items[i].icon,
                        activeIcon: items[i].activeIcon,
                        label: items[i].label,
                        isSelected: selectedIndex == i,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => onItemSelected(i),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single navigation item with icon active pill container & clear text label.
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
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(1.0).clamp(0.85, 1.35);
    final baseIconSize = isSelected ? 24.0 : 22.0;
    final adaptiveIconSize = baseIconSize * scaleFactor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: isSelected ? 52 : 38,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: adaptiveIconSize,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSelected ? 12.0 : 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prominent gradient action button placed in the center of the nav with clear text label.
class _PfCenterActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const _PfCenterActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(1.0).clamp(0.85, 1.35);
    final adaptiveIconSize = 24.0 * scaleFactor;

    return Expanded(
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                    buttonColor,
                    buttonColor.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.1, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.28),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.22),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: adaptiveIconSize,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSelected ? 12.0 : 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

