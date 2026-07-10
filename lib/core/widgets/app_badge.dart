import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A small badge/chip component for labels like roles, status, or tags.
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.borderRadius = 4,
  });

  factory AppBadge.role(String role, {double fontSize = 11}) {
    final color = switch (role) {
      'owner' => AppTheme.primaryColor,
      'manager' => AppTheme.infoColor,
      'staff' => AppTheme.secondaryColor,
      _ => Colors.grey,
    };
    final label = switch (role) {
      'owner' => 'Owner',
      'manager' => 'Manager',
      'staff' => 'Staff',
      _ => role,
    };
    return AppBadge(label: label, color: color, fontSize: fontSize);
  }

  factory AppBadge.profitLoss(double netProfit, {double fontSize = 11}) {
    final isProfit = netProfit >= 0;
    return AppBadge(
      label: isProfit ? 'LABA' : 'RUGI',
      color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
