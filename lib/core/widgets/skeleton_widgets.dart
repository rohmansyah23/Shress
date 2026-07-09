import 'package:flutter/material.dart';

/// Base shimmer effect that wraps any child with a loading animation.
/// Uses a gradient sweep across the content to create the shimmer effect.
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? Colors.grey.shade200;
    final highlight = widget.highlightColor ?? Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton rectangle (rounded)
class SkeletonRect extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonRect({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

/// Skeleton text line
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      width: width,
      height: height,
      borderRadius: 4,
      margin: margin,
    );
  }
}

/// Skeleton card — mimics a Card with loading content
class SkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;
  final Widget? child;

  const SkeletonCard({
    super.key,
    this.height = 100,
    this.margin,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child ??
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLine(width: 80, height: 12),
                const SizedBox(height: 12),
                const SkeletonLine(width: 150, height: 24),
                const SizedBox(height: 8),
                const SkeletonLine(width: 100, height: 12),
              ],
            ),
      ),
    );
  }
}

/// Skeleton for summary cards (Pendapatan, HPP, etc.)
class SkeletonSummaryCard extends StatelessWidget {
  const SkeletonSummaryCard({super.key});

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
                ShimmerWidget(width: 18, height: 18, borderRadius: 9),
                const SizedBox(width: 6),
                const SkeletonLine(width: 60, height: 11),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonLine(width: 120, height: 20),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for the net profit card (large, prominent)
class SkeletonNetProfitCard extends StatelessWidget {
  const SkeletonNetProfitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SkeletonLine(width: 100, height: 11),
            const SizedBox(height: 12),
            const SkeletonLine(width: 180, height: 32),
            const SizedBox(height: 12),
            ShimmerWidget(width: 60, height: 22, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for the net profit card (colored variant for dashboard)
class SkeletonNetProfitCardColored extends StatelessWidget {
  const SkeletonNetProfitCardColored({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SkeletonLine(width: 100, height: 11),
              const SizedBox(height: 12),
              const SkeletonLine(width: 180, height: 32),
              const SizedBox(height: 12),
              ShimmerWidget(width: 60, height: 22, borderRadius: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a row of summary cards (2-column grid)
class SkeletonSummaryGrid extends StatelessWidget {
  const SkeletonSummaryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: SkeletonSummaryCard()),
            const SizedBox(width: 12),
            const Expanded(child: SkeletonSummaryCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: SkeletonSummaryCard()),
            const SizedBox(width: 12),
            const Expanded(child: SkeletonSummaryCard()),
          ],
        ),
      ],
    );
  }
}

/// Skeleton for a list of business cards
class SkeletonBusinessList extends StatelessWidget {
  final int itemCount;

  const SkeletonBusinessList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => SkeletonCard(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              ShimmerWidget(width: 48, height: 48, borderRadius: 12),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonLine(width: 140, height: 16),
                    SizedBox(height: 6),
                    SkeletonLine(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a transaction list item
class SkeletonTransactionItem extends StatelessWidget {
  const SkeletonTransactionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ShimmerWidget(width: 44, height: 44, borderRadius: 12),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 80, height: 11),
                  SizedBox(height: 6),
                  SkeletonLine(width: 100, height: 15),
                ],
              ),
            ),
            const SkeletonLine(width: 60, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for the chart area
class SkeletonChart extends StatelessWidget {
  final double height;

  const SkeletonChart({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerWidget(width: 18, height: 18, borderRadius: 9),
                const SizedBox(width: 8),
                const SkeletonLine(width: 100, height: 12),
              ],
            ),
            const SizedBox(height: 20),
            ShimmerWidget(width: double.infinity, height: height - 80, borderRadius: 8),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (_) => const SkeletonLine(width: 80, height: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen skeleton for dashboard loading
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 120, height: 22),
          const SizedBox(height: 16),
          const SkeletonNetProfitCardColored(),
          const SkeletonSummaryGrid(),
          const SizedBox(height: 24),
          const SkeletonLine(width: 100, height: 18),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              3,
              (_) => const Expanded(
                child: SkeletonCard(height: 80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for P&L report loading
class SkeletonReport extends StatelessWidget {
  const SkeletonReport({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 80, height: 12),
          const SizedBox(height: 16),
          const SkeletonChart(height: 250),
          const SizedBox(height: 24),
          const SkeletonLine(width: 120, height: 14),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => const SkeletonCard(height: 60)),
        ],
      ),
    );
  }
}

/// Skeleton for transaction list loading
class SkeletonTransactionList extends StatelessWidget {
  final int itemCount;

  const SkeletonTransactionList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: SkeletonLine(width: double.infinity, height: 48),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: List.generate(
                itemCount,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SkeletonTransactionItem(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for report screen detail cards
class SkeletonDetailRow extends StatelessWidget {
  const SkeletonDetailRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Expanded(child: SkeletonLine(width: 120, height: 13)),
          const SizedBox(width: 12),
          SkeletonLine(width: 100, height: 13),
        ],
      ),
    );
  }
}

/// Skeleton for a full report breakdown section
class SkeletonReportBreakdown extends StatelessWidget {
  const SkeletonReportBreakdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: 100, height: 14),
        const SizedBox(height: 12),
        ...List.generate(3, (_) => const SkeletonDetailRow()),
        const Divider(height: 24),
        const SkeletonDetailRow(),
      ],
    );
  }
}

/// Skeleton for business selection list in ManagerShell
class SkeletonBusinessSelector extends StatelessWidget {
  const SkeletonBusinessSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonLine(width: 140, height: 22),
        const SizedBox(height: 16),
        ...List.generate(3, (_) => const SkeletonCard(height: 88)),
      ],
    );
  }
}

/// Skeleton for user list in UserManagementPanel
class SkeletonUserList extends StatelessWidget {
  final int itemCount;

  const SkeletonUserList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLine(width: double.infinity, height: 48),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: List.generate(
              itemCount,
              (_) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ShimmerWidget(width: 44, height: 44, borderRadius: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(width: 120, height: 16),
                            SizedBox(height: 6),
                            SkeletonLine(width: 80, height: 12),
                          ],
                        ),
                      ),
                      ShimmerWidget(width: 80, height: 32, borderRadius: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
