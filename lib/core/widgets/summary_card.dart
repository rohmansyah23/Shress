import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

/// Widget reusable untuk menampilkan ringkasan data (misal: Piutang, Hutang, Laporan).
class SummaryCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Color titleIconColor;
  final Map<String, dynamic> summary;
  final bool showDebtorCount;
  final bool showPaidAmount;

  const SummaryCard({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.titleIconColor,
    required this.summary,
    this.showDebtorCount = true,
    this.showPaidAmount = true,
  });

  @override
  Widget build(BuildContext context) {
    final totalOwed = (summary['totalOwed'] as num?)?.toDouble() ?? 0;
    final debtorCount = (summary['debtorCount'] as num?)?.toInt() ?? 0;
    final totalPaid = (summary['totalPaid'] as num?)?.toDouble() ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(titleIcon, size: AppIconSize.s18, color: titleIconColor),
                const SizedBox(width: AppSpacing.s6),
                Text(title, style: AppTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Aktif', style: AppTheme.caption),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        FormatHelpers.rupiah(totalOwed),
                        style: AppTheme.amountMedium.copyWith(
                          color: AppTheme.lossColorTheme(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                if (showDebtorCount) ...[
                  Expanded(
                    child: _SummaryItem(
                      label: 'Penghutang',
                      value: '$debtorCount',
                      icon: Icons.people_outline_rounded,
                      color: AppTheme.infoColorTheme(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                ],
                if (showPaidAmount)
                  Expanded(
                    child: _SummaryItem(
                      label: 'Sudah Dibayar',
                      value: FormatHelpers.rupiah(totalPaid),
                      icon: Icons.check_circle_outline_rounded,
                      color: AppTheme.profitColorTheme(context),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.s16, color: color),
          const SizedBox(height: AppSpacing.s6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(label, style: AppTheme.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}