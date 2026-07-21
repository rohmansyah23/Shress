import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// Widget that displays a formatted rupiah amount with single-line layout
/// and ellipsis overflow. Long amounts that don't fit will be truncated
/// with "..." instead of shrinking the font size.
class AdaptiveAmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final int maxLines;
  final TextAlign textAlign;

  const AdaptiveAmountText({
    super.key,
    required this.amount,
    this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = style ?? AppTypography.amountMedium;
    final String text = _formatAmount(amount);

    return Text(
      text,
      style: baseStyle,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble() && amount.abs() < 1e15) {
      final int intAmount = amount.toInt();
      final String formatted = intAmount.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
      return 'Rp $formatted';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
}
