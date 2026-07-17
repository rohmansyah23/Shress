import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_icon_size.dart';
import 'adaptive_amount_text.dart';

/// Widget reusable untuk menampilkan ringkasan data keuangan (seperti Piutang, Titipan).
class SummaryCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Color titleIconColor;
  final double unpaidAmount;
  final String unpaidLabel;
  final double paidAmount;
  final String paidLabel;
  final int countValue;
  final String countLabel;
  final String countSuffix;

  const SummaryCard({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.titleIconColor,
    required this.unpaidAmount,
    required this.unpaidLabel,
    required this.paidAmount,
    required this.paidLabel,
    required this.countValue,
    required this.countLabel,
    required this.countSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: titleIconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                    border: Border.all(
                      color: titleIconColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    titleIcon,
                    size: AppIconSize.s20,
                    color: titleIconColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.heading3.copyWith(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF1E293B) // Premium Slate/Navy
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    unpaidLabel,
                    unpaidAmount,
                    AppTheme.warningColorTheme(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    paidLabel,
                    paidAmount,
                    AppTheme.profitColorTheme(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            _buildCountItem(
              context,
              countLabel,
              countValue,
              countSuffix,
              AppTheme.infoColorTheme(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.onSurfaceVariantColorTheme(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        AdaptiveAmountText(
          amount: amount,
          style: AppTheme.amountMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCountItem(
    BuildContext context,
    String label,
    int count,
    String suffix,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.onSurfaceVariantColorTheme(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(
          '$count $suffix',
          style: AppTheme.amountMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}