import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// A standardized text field wrapper that enforces a consistent 36px height,
/// neutral border color, and compact padding across the entire app.
///
/// Wraps [TextField] with consistent theming. For form validation, use
/// [AppTextFormField] instead.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final TextStyle? style;
  final TextInputAction? textInputAction;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final EdgeInsets? scrollPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.style,
    this.textInputAction,
    this.onTap,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
    this.scrollPadding,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = AppTheme.outlineColorTheme(context);
    final radius = BorderRadius.circular(AppRadius.radiusSmall);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      style: style ??
          TextStyle(
            fontSize: 13,
            color: AppTheme.onSurfaceColorTheme(context),
          ),
      textInputAction: textInputAction,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onFieldSubmitted,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      scrollPadding: scrollPadding ?? const EdgeInsets.all(20),
      focusNode: focusNode,
      autofocus: autofocus,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: 10,
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
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        isDense: true,
        filled: true,
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
    );
  }
}

/// A standardized [TextFormField] wrapper with the same 36px height enforcement
/// as [AppTextField], but with form validation support.
class AppTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final TextStyle? style;
  final TextInputAction? textInputAction;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final String? Function(String?)? onSaved;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final EdgeInsets? scrollPadding;

  const AppTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.style,
    this.textInputAction,
    this.onTap,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.focusNode,
    this.autofocus = false,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
    this.scrollPadding,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = AppTheme.outlineColorTheme(context);
    final radius = BorderRadius.circular(AppRadius.radiusSmall);

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      style: style ??
          TextStyle(
            fontSize: 13,
            color: AppTheme.onSurfaceColorTheme(context),
          ),
      textInputAction: textInputAction,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      validator: validator,
      onSaved: onSaved,
      scrollPadding: scrollPadding ?? const EdgeInsets.all(20),
      focusNode: focusNode,
      autofocus: autofocus,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: 10,
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
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        isDense: true,
        filled: true,
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
    );
  }
}
