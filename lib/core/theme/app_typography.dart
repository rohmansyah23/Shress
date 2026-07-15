import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography design tokens for the Sheress design system.
///
/// All text styles used across the app are defined here as getters,
/// using the Inter font family via Google Fonts.
///
/// ## Usage
/// ```dart
/// AppTypography.titleMedium
/// AppTypography.bodyLarge
/// AppTypography.labelSmall
/// ```
///
/// ## Text Theme Integration
/// The getters can be mapped directly into Material 3's [TextTheme]:
/// ```
/// textTheme: GoogleFonts.interTextTheme().copyWith(
///   displayLarge: AppTypography.displayLarge,
///   headlineLarge: AppTypography.headlineLarge,
///   ...
/// )
/// ```
class AppTypography {
  AppTypography._();

  /// Font family identifier (Inter via Google Fonts)
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  // ═══════════════════════════════════════════════════════════════
  // DISPLAY
  // ═══════════════════════════════════════════════════════════════

  /// 48pt / Bold / -1.0 tracking / 1.1 height
  ///
  /// Use for hero/display text sparingly.
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
        height: 1.1,
      );

  // ═══════════════════════════════════════════════════════════════
  // HEADLINES (Material 3 mapping: headlineLarge/Small)
  // ═══════════════════════════════════════════════════════════════

  /// 36pt / Bold / -0.8 tracking / 1.15 height
  ///
  /// Page-level headlines (e.g., "Selamat Datang").
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.8,
        height: 1.15,
      );

  /// 28pt / SemiBold / -0.5 tracking / 1.2 height
  ///
  /// Section-level headlines.
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
      );

  /// 24pt / SemiBold / -0.3 tracking / 1.25 height
  ///
  /// Card titles, sub-section headlines.
  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.25,
      );

  // ═══════════════════════════════════════════════════════════════
  // TITLES
  // ═══════════════════════════════════════════════════════════════

  /// 20pt / SemiBold / 1.3 height
  ///
  /// AppBar titles, prominent card titles.
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  /// 16pt / Medium / 1.4 height
  ///
  /// List tile titles, medium emphasis text.
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  /// 14pt / Medium / 1.4 height (alias, same as titleMedium substyle)
  ///
  /// Small titles, subheadings.
  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
      );

  // ═══════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════

  /// 15pt / Normal / 1.5 height
  ///
  /// Primary body text, descriptions, paragraphs.
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  /// 14pt / Normal / 1.5 height
  ///
  /// Secondary body text, form field values.
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  /// 13pt / Normal / 1.4 height
  ///
  /// Captions, helper text, metadata labels.
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  // ═══════════════════════════════════════════════════════════════
  // LABELS
  // ═══════════════════════════════════════════════════════════════

  /// 15pt / SemiBold / 0.3 tracking / 1.2 height
  ///
  /// Button text, action labels.
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.2,
      );

  /// 13pt / SemiBold / 0.3 tracking / 1.2 height
  ///
  /// Small buttons, segmented control labels.
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.2,
      );

  /// 11pt / Medium / 0.5 tracking / 1.3 height
  ///
  /// Smallest labels, badge text, stats, timestamps.
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
      );

  // ═══════════════════════════════════════════════════════════════
  // FINANCIAL / AMOUNT STYLES
  // ═══════════════════════════════════════════════════════════════

  /// 32pt / Bold / -1.0 tracking / 1.1 height
  ///
  /// Large financial amounts (dashboard net profit).
  static TextStyle get amountLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
        height: 1.1,
      );

  /// 20pt / SemiBold / -0.5 tracking / 1.2 height
  ///
  /// Medium financial amounts (summary cards, transaction items).
  static TextStyle get amountMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
      );

  /// 15pt / SemiBold / 1.3 height
  ///
  /// Small financial amounts (inline or compact contexts).
  static TextStyle get amountSmall => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // ═══════════════════════════════════════════════════════════════
  // BACKWARD-COMPATIBLE ALIASES
  // ═══════════════════════════════════════════════════════════════

  /// @deprecated Use [displayLarge] instead.
  static TextStyle get display => displayLarge;
  /// @deprecated Use [headlineLarge] instead.
  static TextStyle get heading1 => headlineLarge;
  /// @deprecated Use [headlineMedium] instead.
  static TextStyle get heading2 => headlineMedium;
  /// @deprecated Use [headlineSmall] instead.
  static TextStyle get heading3 => headlineSmall;
  /// @deprecated Use [titleLarge] instead.
  static TextStyle get title => titleLarge;
  /// @deprecated Use [titleMedium] instead.
  static TextStyle get subtitle => titleMedium;
  /// @deprecated Use [bodyLarge] instead.
  static TextStyle get bodyText => bodyLarge;
  /// @deprecated Use [bodySmall] instead.
  static TextStyle get caption => bodySmall;
  /// @deprecated Use [labelLarge] instead.
  static TextStyle get buttonText => labelLarge;
}
