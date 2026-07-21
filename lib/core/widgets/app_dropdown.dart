import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// A standardized [DropdownButtonFormField] wrapper that enforces
/// a fixed height of 36px, consistent padding, border-radius,
/// and theming across the entire app.
class AppDropdown<T> extends StatelessWidget {
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final String? Function(T?)? validator;
  final TextStyle? style;
  final bool isExpanded;
  final bool isEnabled;
  final Color? dropdownColor;
  final BorderRadius? borderRadius;
  final FloatingLabelBehavior? labelBehavior;

  const AppDropdown({
    super.key,
    this.initialValue,
    required this.items,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.style,
    this.isExpanded = true,
    this.isEnabled = true,
    this.dropdownColor,
    this.borderRadius,
    this.labelBehavior,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.radiusSmall);
    final borderColor = AppTheme.outlineColorTheme(context);

    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      isDense: true,
      isExpanded: isExpanded,
      borderRadius: radius,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: 6,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        isDense: true,
        filled: true,
        floatingLabelBehavior: labelBehavior ?? FloatingLabelBehavior.never,
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
      ),
      style: style ??
          TextStyle(
            fontSize: 13,
            color: AppTheme.onSurfaceColorTheme(context),
          ),
      dropdownColor: dropdownColor ?? AppTheme.surfaceColorTheme(context),
      items: items,
      onChanged: isEnabled ? onChanged : null,
      validator: validator,
    );
  }
}
