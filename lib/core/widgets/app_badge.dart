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
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = AppTheme.radiusSmall,
  });

  /// Get a distinct badge color for each role.
  /// Owner = amber/gold, Manager = blue, Staff = teal.
  static Color roleColor(String role) {
    return switch (role) {
      'owner' => AppTheme.warningColor,
      'manager' => AppTheme.infoColor,
      'staff' => AppTheme.secondaryColor,
      _ => AppTheme.secondaryText,
    };
  }

  static String roleLabel(String role) {
    return switch (role) {
      'owner' => 'Owner',
      'manager' => 'Manager',
      'staff' => 'Staff',
      _ => role,
    };
  }

  factory AppBadge.role(String role, {double fontSize = 11}) {
    return AppBadge(
      label: roleLabel(role),
      color: roleColor(role),
      fontSize: fontSize,
    );
  }

  factory AppBadge.profitLoss(double netProfit, {double fontSize = 11}) {
    final isProfit = netProfit >= 0;
    return AppBadge(
      label: isProfit ? 'LABA' : 'RUGI',
      color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
      fontSize: fontSize,
    );
  }
  

  Color _themeAwareColor(BuildContext context, Color staticColor, String labelText) {
    final cleanLabel = labelText.toLowerCase();
    if (cleanLabel == 'owner') {
      return AppTheme.warningColorTheme(context);
    } else if (cleanLabel == 'manager') {
      return AppTheme.infoColorTheme(context);
    } else if (cleanLabel == 'staff') {
      return AppTheme.secondaryColorTheme(context);
    } else if (cleanLabel == 'laba') {
      return AppTheme.profitColorTheme(context);
    } else if (cleanLabel == 'rugi') {
      return AppTheme.lossColorTheme(context);
    }

    if (staticColor == AppTheme.warningColor) return AppTheme.warningColorTheme(context);
    if (staticColor == AppTheme.infoColor) return AppTheme.infoColorTheme(context);
    if (staticColor == AppTheme.secondaryColor) return AppTheme.secondaryColorTheme(context);
    if (staticColor == AppTheme.profitColor) return AppTheme.profitColorTheme(context);
    if (staticColor == AppTheme.lossColor) return AppTheme.lossColorTheme(context);
    return staticColor;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _themeAwareColor(context, color, label);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: themeColor,
        ),
      ),
    );
  }
}
