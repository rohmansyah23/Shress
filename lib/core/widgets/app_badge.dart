import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

/// Hierarchy level for badge visual weight
enum BadgeHierarchy {
  /// Primary badges — most prominent, used for main status/role indicators
  primary,
  /// Secondary badges — used for tags, labels
  secondary,
  /// Subtle badges — used for minimal visual weight
  subtle,
}

/// A small badge/chip component for labels like roles, status, or tags.
///
/// ## Hierarchy
/// - **primary**: Filled background with white text — for key statuses
/// - **secondary**: Light tinted background with colored text (default)
/// - **subtle**: Transparent background with border — minimal weight
///
/// ## Usage
/// ```dart
/// AppBadge.role('owner')
/// AppBadge.profitLoss(500000)
/// AppBadge(label: 'Aktif', color: AppTheme.statusColor(context, 'success'))
/// ```
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;
  final BadgeHierarchy hierarchy;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
    this.borderRadius = AppRadius.radiusSmall,
    this.hierarchy = BadgeHierarchy.secondary,
  });

  /// Role badges with distinct semantic colors.
  ///
  /// Owner = amber/warm, Manager = blue, Staff = teal.
  static Color roleColor(String role) {
    return switch (role) {
      'owner' => AppTheme.warning,      // Amber — premium/warm
      'manager' => AppTheme.info,       // Blue — professional
      'staff' => AppTheme.success,      // Green — fresh/approachable
      _ => AppTheme.textSecondary,      // Grey — neutral
    };
  }

  /// Dark mode role colors (lighter variants for contrast on dark bg).
  static Color roleColorDark(String role) {
    return switch (role) {
      'owner' => AppTheme.darkWarning,
      'manager' => AppTheme.darkInfo,
      'staff' => AppTheme.darkSuccess,
      _ => AppTheme.darkTextSecondary,
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

  /// Factory for role badges with automatic color and hierarchy.
  factory AppBadge.role(String role, {double fontSize = 11}) {
    return AppBadge(
      label: roleLabel(role),
      color: roleColor(role),
      fontSize: fontSize,
      hierarchy: role == 'owner' ? BadgeHierarchy.primary : BadgeHierarchy.secondary,
    );
  }

  /// Factory for profit/loss badges with automatic color.
  factory AppBadge.profitLoss(double netProfit, {double fontSize = 11}) {
    final isProfit = netProfit >= 0;
    return AppBadge(
      label: isProfit ? 'LABA' : 'RUGI',
      color: isProfit ? AppTheme.profitColor : AppTheme.lossColor,
      fontSize: fontSize,
      hierarchy: BadgeHierarchy.primary,
    );
  }

  /// Get the theme-aware color based on the badge's static color.
  Color _themeAwareColor(BuildContext context, Color staticColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) return staticColor;

    // Map static colors to dark mode variants using AppTheme semantic helpers
    if (staticColor == AppTheme.warning || staticColor == AppTheme.warningColor) {
      return AppTheme.darkWarning;
    }
    if (staticColor == AppTheme.info || staticColor == AppTheme.infoColor) {
      return AppTheme.darkInfo;
    }
    if (staticColor == AppTheme.success || staticColor == AppTheme.profitColor) {
      return AppTheme.darkSuccess;
    }
    if (staticColor == AppTheme.danger || staticColor == AppTheme.lossColor) {
      return AppTheme.darkDanger;
    }
    if (staticColor == AppTheme.textSecondary) {
      return AppTheme.darkTextSecondary;
    }
    return staticColor;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _themeAwareColor(context, color);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: switch (hierarchy) {
          BadgeHierarchy.primary => themeColor,
          BadgeHierarchy.secondary => themeColor.withValues(alpha: 0.18),
          BadgeHierarchy.subtle => Colors.transparent,
        },
        borderRadius: BorderRadius.circular(borderRadius),
        border: hierarchy == BadgeHierarchy.subtle
            ? Border.all(color: themeColor.withValues(alpha: 0.5))
            : null,
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(
          fontSize: fontSize,
          color: switch (hierarchy) {
            BadgeHierarchy.primary => Colors.white,
            BadgeHierarchy.secondary => themeColor,
            BadgeHierarchy.subtle => themeColor,
          },
          fontWeight: switch (hierarchy) {
            BadgeHierarchy.primary => FontWeight.w700,
            BadgeHierarchy.secondary => FontWeight.w600,
            BadgeHierarchy.subtle => FontWeight.normal,
          },
        ),
      ),
    );
  }
}
