import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// Widget that automatically reduces font size when the formatted
/// rupiah amount would overflow the available horizontal space.
///
/// Steps down through: [amountLarge (32)] → [amountMedium (20)] →
/// [amountSmall (15)] → 14pt → 12pt → 10pt until the text fits.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final TextStyle baseStyle = style ?? AppTypography.amountMedium;
        final String text = _formatAmount(amount);

        final double fittedSize = _findFittingSize(text, baseStyle, maxWidth);

        final TextStyle finalStyle =
            baseStyle.copyWith(fontSize: fittedSize);

        return Text(
          text,
          style: finalStyle,
          maxLines: maxLines,
          textAlign: textAlign,
          overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
        );
      },
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

  double _findFittingSize(String text, TextStyle baseStyle, double maxWidth) {
    const List<double> allSizes = [32, 20, 15, 14, 12, 10];
    final double baseFontSize = baseStyle.fontSize ?? 20;

    final List<double> sizes =
        allSizes.where((s) => s <= baseFontSize).toList();

    if (sizes.isEmpty) return baseFontSize;

    for (final double size in sizes) {
      final TextStyle testStyle = baseStyle.copyWith(fontSize: size);
      final TextPainter painter = TextPainter(
        text: TextSpan(text: text, style: testStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0);

      final bool fits = painter.width <= maxWidth;
      painter.dispose();

      if (fits) return size;
    }

    return sizes.last;
  }
}
