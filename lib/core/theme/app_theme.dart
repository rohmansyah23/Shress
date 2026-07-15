import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_spacing.dart';
import 'app_radius.dart';
import 'app_typography.dart';

// ═══════════════════════════════════════════════════════════════
// Sheress Design System — v4 (2026)
// Modern, harmonious, accessible color system with semantic tokens
// ═══════════════════════════════════════════════════════════════

/// Font family identifier (Google Fonts Inter)
const String kFontFamily = 'Inter';

// ═══════════════════════════════════════════════════════════════
// LIGHT THEME — Primary: 0xFF1E293B (Slate 800)
// Elegant, professional, calm — untuk aplikasi produktivitas
// ═══════════════════════════════════════════════════════════════

// ── Slate Palette (Primary Scale) ─────────────────────────────
const Color _slate50 = Color(0xFFF8FAFC);
const Color _slate100 = Color(0xFFF1F5F9);
const Color _slate200 = Color(0xFFE2E8F0);
const Color _slate300 = Color(0xFFCBD5E1);
const Color _slate400 = Color(0xFF94A3B8);
const Color _slate500 = Color(0xFF64748B);
const Color _slate600 = Color(0xFF475569);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate900 = Color(0xFF0F172A);

// ── Emerald / Green Palette (Secondary / Profit) ────────────
const Color _emerald50 = Color(0xFFECFDF5);
const Color _emerald100 = Color(0xFFD1FAE5);
const Color _emerald500 = Color(0xFF10B981);
const Color _emerald600 = Color(0xFF059669);
const Color _emerald900 = Color(0xFF064E3B);

// ── Amber Palette (Warning) ──────────────────────────────────
const Color _amber50 = Color(0xFFFFFBEB);
const Color _amber500 = Color(0xFFF59E0B);
const Color _amber700 = Color(0xFFB45309);

// ── Red Palette (Danger / Loss) ──────────────────────────────
const Color _red50 = Color(0xFFFEF2F2);
const Color _red500 = Color(0xFFEF4444);
const Color _red600 = Color(0xFFDC2626);
const Color _red900 = Color(0xFF7F1D1D);

// ── Blue Palette (Info) ──────────────────────────────────────
const Color _blue50 = Color(0xFFEFF6FF);
const Color _blue500 = Color(0xFF3B82F6);
const Color _blue700 = Color(0xFF1D4ED8);

// ── Teal Palette (Tertiary) ──────────────────────────────────
const Color _teal50 = Color(0xFFF0FDFA);
const Color _teal600 = Color(0xFF0D9488);
const Color _teal900 = Color(0xFF134E4A);

// ═══════════════════════════════════════════════════════════════
// DARK THEME — Primary: 0xFF22C55E (Green 500)
// Fresh, vibrant, easy-on-eyes untuk penggunaan malam hari
// ═══════════════════════════════════════════════════════════════

const Color _darkSurface = Color(0xFF111111);
const Color _darkSurfaceDim = Color(0xFF0A0A0A);
const Color _darkSurfaceBright = Color(0xFF2A2A2A);
const Color _darkSurfaceLow = Color(0xFF151515);
const Color _darkSurfaceContainer = Color(0xFF1A1A1A);
const Color _darkSurfaceHigh = Color(0xFF252525);
const Color _darkSurfaceHighest = Color(0xFF333333);

const Color _darkText = Color(0xFFF1F1F1);
const Color _darkTextSecondary = Color(0xFFA0A0A0);
const Color _darkTextDisabled = Color(0xFF666666);
const Color _darkOutline = Color(0xFF333333);
const Color _darkOutlineVariant = Color(0xFF2A2A2A);

// Dark mode green (primary)
const Color _green500 = Color(0xFF22C55E);
const Color _green800 = Color(0xFF166534);
const Color _green950 = Color(0xFF052E16);

// Dark mode semantic colors (lighter for dark bg readability)
const Color _darkGreen = Color(0xFF2ECC71);
const Color _darkGreenAccent = Color(0xFF00E676);
const Color _darkRed = Color(0xFFE57373);

// Softer chart colors for dark mode (less saturated, easier on eyes)
const Color _darkAmber = Color(0xFFFFB74D);
const Color _darkBlue = Color(0xFF64B5F6);

// ═══════════════════════════════════════════════════════════════
// DESIGN SYSTEM CLASS
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Light Theme Semantic Colors ──────────────────────────────
  static const Color primary = _slate800;
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFDBE4F5);
  static const Color onPrimaryContainer = _slate800;

  static const Color secondary = _slate600;
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = _slate200;
  static const Color onSecondaryContainer = _slate900;

  static const Color tertiary = _teal600;
  static const Color onTertiary = Colors.white;
  static const Color tertiaryContainer = _teal50;
  static const Color onTertiaryContainer = _teal900;

  static const Color accent = _green500;
  static const Color onAccent = Colors.white;
  static const Color accentContainer = _emerald50;
  static const Color onAccentContainer = _emerald900;

  static const Color success = _emerald600;
  static const Color onSuccess = Colors.white;
  static const Color successContainer = _emerald50;
  static const Color onSuccessContainer = _emerald900;

  static const Color warning = _amber500;
  static const Color onWarning = Colors.white;
  static const Color warningContainer = _amber50;
  static const Color onWarningContainer = _amber700;

  static const Color danger = _red500;
  static const Color onDanger = Colors.white;
  static const Color dangerContainer = _red50;
  static const Color onDangerContainer = _red900;

  static const Color info = _blue500;
  static const Color onInfo = Colors.white;
  static const Color infoContainer = _blue50;
  static const Color onInfoContainer = _blue700;

  // ── Surface Colors ──────────────────────────────────────────
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceDim = _slate200;
  static const Color surfaceBright = Colors.white;
  static const Color surfaceContainerLowest = Colors.white;
  static const Color surfaceContainerLow = Color(0xFFF5F5F5);
  static const Color surfaceContainer = _slate100;
  static const Color surfaceContainerHigh = _slate200;
  static const Color surfaceContainerHighest = _slate300;

  static const Color card = Colors.white;
  static const Color cardElevated = Colors.white;

  // ── Text Colors ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = _slate500;
  static const Color textTertiary = _slate400;
  static const Color textDisabled = _slate300;
  static const Color textOnPrimary = Colors.white;

  // ── Border & Divider ────────────────────────────────────────
  static const Color outline = _slate300;
  static const Color outlineVariant = Color(0xFFE8E8E8);
  static const Color dividerLight = Color(0xFFE8E8E8);
  static const Color divider = _slate300;

  // ── Shadows ─────────────────────────────────────────────────
  static Color shadowLight = Colors.black.withValues(alpha: 0.06);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.10);
  static Color shadowStrong = Colors.black.withValues(alpha: 0.15);

  // ── Backward Compatible Constants ────────────────────────────
  static const Color primaryColor = _slate800;
  static const Color secondaryColor = Color(0xFF0D9488);
  static const Color profitColor = _emerald600;
  static const Color lossColor = _red600;
  static const Color warningColor = _amber500;
  static const Color infoColor = _blue500;
  static const Color secondaryBackground = _slate100;

  // Removed/renamed getters — kept as aliases for backward compat
  static const Color primaryText = textPrimary;
  static const Color secondaryText = textSecondary;
  static const Color darkPrimaryText = _darkText;
  static const Color darkSecondaryText = _darkTextSecondary;
  static const Color darkSecondaryBackground = _darkSurfaceContainer;
  static const Color darkElevatedCard = _darkSurfaceHigh;

  // ── Dark Theme Semantic Colors ───────────────────────────────
  static const Color darkPrimary = _green500;
  static const Color darkOnPrimary = _green950;
  static const Color darkPrimaryContainer = _green800;
  static const Color darkOnPrimaryContainer = _emerald100;

  static const Color darkSecondary = _darkTextSecondary;
  static const Color darkOnSecondary = _darkSurface;
  static const Color darkSecondaryContainer = _darkSurfaceHigh;
  static const Color darkOnSecondaryContainer = _darkText;

  static const Color darkTertiary = _darkBlue;
  static const Color darkOnTertiary = _darkSurface;

  static const Color darkAccent = _darkGreenAccent;
  static const Color darkOnAccent = _darkSurface;

  static const Color darkSuccess = _darkGreen;
  static const Color darkWarning = _darkAmber;
  static const Color darkDanger = _darkRed;
  static const Color darkInfo = _darkBlue;

  static const Color darkBackground = _darkSurfaceDim;
  static const Color darkSurface = _darkSurfaceContainer;
  static const Color darkSurfaceHigh = _darkSurfaceHigh;
  static const Color darkSurfaceHighest = _darkSurfaceHighest;
  static const Color darkCard = _darkSurfaceContainer;
  static const Color darkCardElevated = _darkSurfaceHigh;

  static const Color darkTextPrimary = _darkText;
  static const Color darkTextSecondary = _darkTextSecondary;
  static const Color darkTextDisabled = _darkTextDisabled;
  static const Color darkDivider = _darkOutline;

  // ── Spacing (delegated to AppSpacing) ────────────────────────
  static const double s2 = AppSpacing.s2;
  static const double s4 = AppSpacing.s4;
  static const double s8 = AppSpacing.s8;
  static const double s12 = AppSpacing.s12;
  static const double s16 = AppSpacing.s16;
  static const double s20 = AppSpacing.s20;
  static const double s24 = AppSpacing.s24;
  static const double s32 = AppSpacing.s32;
  static const double s40 = AppSpacing.s40;
  static const double s48 = AppSpacing.s48;
  static const double s56 = AppSpacing.s56;
  static const double s64 = AppSpacing.s64;

  // ── Border Radius (delegated to AppRadius) ───────────────────
  static const double radiusSmall = AppRadius.radiusSmall;
  static const double radiusMedium = AppRadius.radiusMedium;
  static const double radiusLarge = AppRadius.radiusLarge;
  static const double radiusXL = AppRadius.radiusXL;
  static const double radiusPill = AppRadius.radiusPill;

  // ── Theme-aware Semantic Color Helpers ───────────────────────

  /// Get semantic status color based on brightness.
  static Color statusColor(BuildContext context, String semantic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (semantic) {
      'success' => isDark ? _darkGreen : _emerald600,
      'warning' => isDark ? _darkAmber : _amber500,
      'danger' => isDark ? _darkRed : _red500,
      'info' => isDark ? _darkBlue : _blue500,
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  /// Profit color (theme-aware)
  static Color profitColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _green500 : _emerald500;

  /// Loss color (theme-aware)
  static Color lossColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _red500 : _red600;

  /// Softer profit color for charts in dark mode (less saturated, easier on eyes)
  static Color profitChartColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _green500 : _emerald500;

  /// Softer loss color for charts in dark mode (less saturated, easier on eyes)
  static Color lossChartColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _red500 : _red500;

  /// Warning color (theme-aware)
  static Color warningColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkAmber : _amber500;

  /// Info color (theme-aware)
  static Color infoColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkBlue : _blue500;

  /// Primary color (theme-aware)
  static Color primaryColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _green500 : _slate800;

  /// Secondary color (theme-aware)
  static Color secondaryColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkTextSecondary : _slate600;

  /// Accent color (theme-aware)
  static Color accentColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkAccent : accent;

  /// Surface color (theme-aware)
  static Color surfaceColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkSurfaceContainer : surface;

  /// Background color (theme-aware)
  static Color backgroundColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : background;

  /// On surface color (theme-aware)
  static Color onSurfaceColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;

  /// On surface variant color (theme-aware)
  static Color onSurfaceVariantColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;

  /// Outline color (theme-aware)
  static Color outlineColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkOutline : outline;

  /// Outline variant color (theme-aware)
  static Color outlineVariantColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkOutlineVariant : outlineVariant;

  /// Surface container highest color (theme-aware)
  static Color surfaceContainerHighestColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkSurfaceHighest : surfaceContainerHighest;

  /// Surface container color (theme-aware)
  static Color surfaceContainerColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkSurfaceContainer : surfaceContainer;

  /// On primary color (theme-aware)
  static Color onPrimaryColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOnPrimary : onPrimary;

  /// Primary container color (theme-aware)
  static Color primaryContainerColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkPrimaryContainer : primaryContainer;

  /// On primary container color (theme-aware)
  static Color onPrimaryContainerColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOnPrimaryContainer : onPrimaryContainer;

  /// Secondary container color (theme-aware)
  static Color secondaryContainerColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkSurfaceHighest : secondaryContainer;

  /// On secondary container color (theme-aware)
  static Color onSecondaryContainerColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : onSecondaryContainer;

  /// On danger/error color (theme-aware)
  static Color onDangerColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkSurfaceDim : onDanger;

  /// Surface container low color (theme-aware)
  static Color surfaceContainerLowColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkSurfaceLow : surfaceContainerLow;

  // ── Typography (delegated to AppTypography) ─────────────────
  static String get fontFamily => AppTypography.fontFamily;
  static TextStyle get display => AppTypography.displayLarge;
  static TextStyle get heading1 => AppTypography.headlineLarge;
  static TextStyle get heading2 => AppTypography.headlineMedium;
  static TextStyle get heading3 => AppTypography.headlineSmall;
  static TextStyle get title => AppTypography.titleLarge;
  static TextStyle get subtitle => AppTypography.titleMedium;
  static TextStyle get bodyText => AppTypography.bodyLarge;
  static TextStyle get caption => AppTypography.bodySmall;
  static TextStyle get buttonText => AppTypography.labelLarge;
  static TextStyle get amountLarge => AppTypography.amountLarge;
  static TextStyle get amountMedium => AppTypography.amountMedium;
  static TextStyle get labelSmall => AppTypography.labelSmall;

  // ── Shadows ──────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: shadowLight,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: shadowMedium,
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ═════════════════════════════════════════════════════════════
  // LIGHT THEME — Primary: 0xFF1E293B (Slate 800)
  // ═════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: danger,
      onError: onDanger,
      errorContainer: dangerContainer,
      onErrorContainer: onDangerContainer,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      surfaceDim: surfaceDim,
      surfaceBright: surfaceBright,
      onSurfaceVariant: textSecondary,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: shadowStrong,
      inverseSurface: _slate800,
      onInverseSurface: _slate100,
      inversePrimary: _slate300,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      hoverColor: primary.withValues(alpha: 0.03),
      highlightColor: primary.withValues(alpha: 0.05),
      splashColor: primary.withValues(alpha: 0.08),

      // ── Text Theme ──────────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: display,
        headlineLarge: heading1,
        headlineMedium: heading2,
        headlineSmall: heading3,
        titleLarge: title,
        titleMedium: subtitle,
        titleSmall: subtitle,
        bodyLarge: bodyText,
        bodyMedium: bodyText,
        bodySmall: caption,
        labelLarge: buttonText,
        labelMedium: AppTypography.labelMedium,
        labelSmall: labelSmall,
      ),

      // ── AppBar ──────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        titleTextStyle: title.copyWith(color: textPrimary, fontSize: 18),
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // ── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: dividerLight, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        color: card,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Bottom Sheet ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        elevation: 8,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        backgroundColor: background,
        modalBackgroundColor: background,
        dragHandleColor: dividerLight,
        dragHandleSize: const Size(32, 4),
      ),

      // ── Buttons ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: buttonText,
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: buttonText,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: textDisabled,
          disabledForegroundColor: Colors.white70,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          side: BorderSide(color: dividerLight, width: 1),
          textStyle: buttonText,
          foregroundColor: textPrimary,
          disabledForegroundColor: textDisabled,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: buttonText,
          foregroundColor: primary,
          disabledForegroundColor: textDisabled,
        ),
      ),

      // ── Input ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: outline, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        labelStyle: bodyText.copyWith(color: textSecondary),
        hintStyle: caption.copyWith(color: textTertiary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        floatingLabelStyle: bodyText.copyWith(color: primary),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.2),
        selectionHandleColor: primary,
      ),

      // ── FAB ─────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.s16,
        ),
        extendedTextStyle: buttonText,
      ),

      // ── Navigation Bar (Material 3) ─────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }
          return caption.copyWith(fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 24, color: primary);
          }
          return IconThemeData(size: 24, color: textSecondary);
        }),
      ),

      // ── Bottom Navigation (legacy) ──────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: caption.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: caption.copyWith(fontSize: 11),
      ),

      // ─── Icon Theme ──────────────────────────────────────────
      iconTheme: IconThemeData(color: textSecondary, size: 24),

      // ── Chip ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        labelStyle: caption.copyWith(color: textPrimary),
        secondaryLabelStyle: caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: primary,
        backgroundColor: surfaceContainer,
        brightness: Brightness.light,
        side: BorderSide.none,
        iconTheme: IconThemeData(color: textSecondary, size: 16),
        deleteIconColor: textSecondary,
      ),

      // ── Segmented Button ────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: buttonText.copyWith(fontSize: 13),
          selectedBackgroundColor: primary,
          selectedForegroundColor: Colors.white,
        ),
      ),

      // ── SnackBar ────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        contentTextStyle: bodyText.copyWith(color: Colors.white),
        elevation: 0,
        backgroundColor: textPrimary,
        actionTextColor: Colors.white,
      ),

      // ── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        backgroundColor: surface,
      ),

      // ── Divider ─────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dividerLight,
        thickness: 1,
        space: 1,
      ),

      // ── Progress Indicator ──────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(alpha: 0.2),
        circularTrackColor: primary.withValues(alpha: 0.2),
      ),

      // ── Switch ──────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return dividerLight;
        }),
      ),

      // ── Checkbox ────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.s2),
        ),
        side: BorderSide(color: outline, width: 1.5),
      ),

      // ── Radio ───────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textSecondary;
        }),
      ),

      // ── Slider ──────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: dividerLight,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: caption.copyWith(color: Colors.white),
      ),

      // ── Tab Bar ─────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        labelStyle: buttonText,
        unselectedLabelStyle: buttonText,
      ),

      // ── Toggle Buttons ──────────────────────────────────────
      toggleButtonsTheme: ToggleButtonsThemeData(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        selectedColor: Colors.white,
        fillColor: primary,
        color: textSecondary,
        borderColor: dividerLight,
        selectedBorderColor: primary,
        textStyle: buttonText.copyWith(fontSize: 13),
      ),

      // ── Dropdown ────────────────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: outlineVariant, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: outlineVariant, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: outline, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
        ),
      ),

      // ── Menu / Popup ────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        elevation: 6,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
      ),

      // ── Menu Bar ────────────────────────────────────────────
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
      ),

      // ── Menu Item ───────────────────────────────────────────
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          elevation: WidgetStateProperty.all(6),
          shadowColor: WidgetStateProperty.all(Colors.black),
        ),
      ),

      // ── Tooltip ─────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: caption.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
      ),

      // ── Banner ──────────────────────────────────────────────
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: surfaceContainer,
        padding: const EdgeInsets.all(AppSpacing.s16),
        contentTextStyle: bodyText,
      ),

      // ── Time Picker ─────────────────────────────────────────
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        hourMinuteColor: surfaceContainer,
        hourMinuteTextColor: textPrimary,
        dayPeriodColor: surfaceContainer,
        dayPeriodTextColor: textPrimary,
        dialHandColor: primary,
        dialBackgroundColor: surfaceContainer,
        dialTextColor: textPrimary,
        entryModeIconColor: textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      // ── Date Picker ─────────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        headerBackgroundColor: primary,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return textDisabled;
          return textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(primary),
        todayBackgroundColor: WidgetStateProperty.all(
          primary.withValues(alpha: 0.12),
        ),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      // ── Expansion Tile ──────────────────────────────────────
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: textSecondary,
        collapsedIconColor: textSecondary,
        textColor: textPrimary,
        collapsedTextColor: textPrimary,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: Border(),
        collapsedShape: Border(),
      ),

      // ── Scrollbar ───────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(AppRadius.pill),
        thickness: WidgetStateProperty.all(4),
        thumbColor: WidgetStateProperty.all(
          textSecondary.withValues(alpha: 0.3),
        ),
        trackVisibility: WidgetStateProperty.all(false),
      ),

      // ── List Tile ───────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s4,
        ),
        titleTextStyle: bodyText,
        subtitleTextStyle: caption.copyWith(color: textSecondary),
        leadingAndTrailingTextStyle: caption,
        iconColor: textSecondary,
        textColor: textPrimary,
        tileColor: Colors.transparent,
        selectedTileColor: primary.withValues(alpha: 0.08),
        selectedColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      // ── Badge ───────────────────────────────────────────────
      badgeTheme: BadgeThemeData(
        backgroundColor: danger,
        textColor: Colors.white,
        textStyle: caption.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
        smallSize: 6,
        largeSize: 16,
      ),

      // ── Navigation Rail ─────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: primary, size: 24),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 24),
        selectedLabelTextStyle: caption.copyWith(
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        unselectedLabelTextStyle: caption.copyWith(color: textSecondary),
        indicatorColor: primary.withValues(alpha: 0.12),
      ),

      // ── Drawer ──────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // DARK THEME — Primary: 0xFF22C55E (Green 500)
  // Fresh, vibrant, easy on the eyes
  // ═════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      secondary: darkTextSecondary,
      onSecondary: _darkSurfaceDim,
      secondaryContainer: _darkSurfaceHighest,
      onSecondaryContainer: darkTextPrimary,
      tertiary: darkInfo,
      onTertiary: _darkSurfaceDim,
      tertiaryContainer: Color(0xFF1A2744),
      onTertiaryContainer: darkInfo,
      error: darkDanger,
      onError: _darkSurfaceDim,
      errorContainer: Color(0xFF3D1A1A),
      onErrorContainer: darkDanger,
      surface: _darkSurfaceContainer,
      onSurface: darkTextPrimary,
      surfaceContainerLowest: _darkSurfaceDim,
      surfaceContainerLow: _darkSurfaceLow,
      surfaceContainer: _darkSurfaceContainer,
      surfaceContainerHigh: _darkSurfaceHigh,
      surfaceContainerHighest: _darkSurfaceHighest,
      surfaceDim: _darkSurfaceDim,
      surfaceBright: _darkSurfaceBright,
      onSurfaceVariant: darkTextSecondary,
      outline: _darkOutline,
      outlineVariant: _darkOutlineVariant,
      shadow: Colors.black,
      inverseSurface: _slate100,
      onInverseSurface: _slate900,
      inversePrimary: _green500,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkSurfaceDim,
      hoverColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.08),
      splashColor: Colors.white.withValues(alpha: 0.12),

      // ── Text Theme ──────────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme(TextTheme()).copyWith(
        displayLarge: display,
        headlineLarge: heading1,
        headlineMedium: heading2,
        headlineSmall: heading3,
        titleLarge: title,
        titleMedium: subtitle,
        titleSmall: subtitle,
        bodyLarge: bodyText,
        bodyMedium: bodyText,
        bodySmall: caption,
        labelLarge: buttonText,
        labelMedium: AppTypography.labelMedium.copyWith(color: darkTextPrimary),
        labelSmall: labelSmall.copyWith(color: darkTextPrimary),
      ),

      // ── AppBar ──────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _darkSurfaceDim,
        foregroundColor: darkTextPrimary,
        titleTextStyle: title.copyWith(color: darkTextPrimary, fontSize: 18),
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),

      // ── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: _darkOutline, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        color: darkCard,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Bottom Sheet ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        elevation: 0,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        backgroundColor: darkBackground,
        modalBackgroundColor: darkBackground,
        dragHandleColor: _darkOutline,
        dragHandleSize: const Size(32, 4),
      ),

      // ── Buttons ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: buttonText.copyWith(color: darkOnPrimary),
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: buttonText.copyWith(color: darkOnPrimary),
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          disabledBackgroundColor: _darkTextDisabled,
          disabledForegroundColor: _darkTextDisabled,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          side: BorderSide(color: _darkOutline, width: 1),
          textStyle: buttonText,
          foregroundColor: darkTextPrimary,
          disabledForegroundColor: _darkTextDisabled,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: buttonText.copyWith(color: darkPrimary),
          foregroundColor: darkPrimary,
          disabledForegroundColor: _darkTextDisabled,
        ),
      ),

      // ── Input ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: _darkOutlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: _darkOutlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: _darkOutline, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: darkDanger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: darkDanger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        labelStyle: bodyText.copyWith(color: darkTextSecondary),
        hintStyle: caption.copyWith(color: _darkTextDisabled),
        prefixIconColor: darkTextSecondary,
        suffixIconColor: darkTextSecondary,
        floatingLabelStyle: bodyText.copyWith(color: darkPrimary),
      ),

      // ── FAB ─────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: darkPrimary,
        foregroundColor: darkOnPrimary,
        shape: const CircleBorder(),
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.s16,
        ),
        extendedTextStyle: buttonText.copyWith(color: darkOnPrimary),
      ),

      // ── Navigation Bar (Material 3) ─────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _darkSurfaceContainer,
        indicatorColor: darkPrimary.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: darkPrimary,
            );
          }
          return caption.copyWith(fontSize: 11, color: darkTextSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 24, color: darkPrimary);
          }
          return IconThemeData(size: 24, color: darkTextSecondary);
        }),
      ),

      // ── Bottom Navigation (legacy) ──────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: darkCard,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: caption.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: caption.copyWith(fontSize: 11),
      ),

      // ─── Icon Theme ──────────────────────────────────────────
      iconTheme: IconThemeData(color: darkTextSecondary, size: 24),

      // ── Chip ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        labelStyle: caption.copyWith(color: darkTextPrimary),
        secondaryLabelStyle: caption.copyWith(color: darkOnPrimary),
        selectedColor: darkPrimary.withValues(alpha: 0.25),
        backgroundColor: _darkSurfaceContainer,
        brightness: Brightness.dark,
        side: BorderSide.none,
        iconTheme: IconThemeData(color: darkTextSecondary, size: 16),
        deleteIconColor: darkTextSecondary,
      ),

      // ── Segmented Button ────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: buttonText.copyWith(fontSize: 13),
          selectedBackgroundColor: darkPrimary.withValues(alpha: 0.25),
          selectedForegroundColor: darkPrimary,
        ),
      ),

      // ── SnackBar ────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        contentTextStyle: bodyText.copyWith(color: Colors.white),
        elevation: 0,
        backgroundColor: _darkSurfaceHighest,
        actionTextColor: darkPrimary,
      ),

      // ── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: darkCard,
        shadowColor: Colors.black,
      ),

      // ── Divider ─────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: _darkOutline,
        thickness: 1,
        space: 1,
      ),

      // ── Progress Indicator ──────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: darkPrimary,
        linearTrackColor: darkPrimary.withValues(alpha: 0.2),
        circularTrackColor: darkPrimary.withValues(alpha: 0.2),
      ),

      // ── Switch ──────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimary;
          return darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkPrimary.withValues(alpha: 0.3);
          }
          return _darkOutline;
        }),
      ),

      // ── Checkbox ────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(darkOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.s2),
        ),
        side: BorderSide(color: _darkOutline, width: 1.5),
      ),

      // ── Radio ───────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimary;
          return darkTextSecondary;
        }),
      ),

      // ── Slider ──────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: darkPrimary,
        inactiveTrackColor: _darkOutline,
        thumbColor: darkPrimary,
        overlayColor: darkPrimary.withValues(alpha: 0.12),
        valueIndicatorColor: darkPrimary,
        valueIndicatorTextStyle: caption.copyWith(color: darkOnPrimary),
      ),

      // ── Tab Bar ─────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: darkPrimary,
        unselectedLabelColor: darkTextSecondary,
        indicatorColor: darkPrimary,
        labelStyle: buttonText,
        unselectedLabelStyle: buttonText,
      ),

      // ── Toggle Buttons ──────────────────────────────────────
      toggleButtonsTheme: ToggleButtonsThemeData(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        selectedColor: darkPrimary,
        fillColor: darkPrimary.withValues(alpha: 0.15),
        color: darkTextSecondary,
        borderColor: _darkOutline,
        selectedBorderColor: darkPrimary.withValues(alpha: 0.3),
        textStyle: buttonText.copyWith(fontSize: 13),
      ),

      // ── Dropdown ────────────────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: _darkOutlineVariant, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: _darkOutlineVariant, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: _darkOutline, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
        ),
      ),

      // ── Menu / Popup ────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        elevation: 4,
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
      ),

      // ── Tooltip ─────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _darkSurfaceHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: caption.copyWith(color: darkTextPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
      ),

      // ── Time Picker ─────────────────────────────────────────
      timePickerTheme: TimePickerThemeData(
        backgroundColor: _darkSurfaceContainer,
        hourMinuteColor: _darkSurfaceHigh,
        hourMinuteTextColor: darkTextPrimary,
        dayPeriodColor: _darkSurfaceHigh,
        dayPeriodTextColor: darkTextPrimary,
        dialHandColor: darkPrimary,
        dialBackgroundColor: _darkSurfaceHigh,
        dialTextColor: darkTextPrimary,
        entryModeIconColor: darkTextSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      // ── Date Picker ─────────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _darkSurfaceContainer,
        headerBackgroundColor: darkPrimary,
        headerForegroundColor: darkOnPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkOnPrimary;
          if (states.contains(WidgetState.disabled)) return _darkTextDisabled;
          return darkTextPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(darkPrimary),
        todayBackgroundColor: WidgetStateProperty.all(
          darkPrimary.withValues(alpha: 0.12),
        ),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      // ── Expansion Tile ──────────────────────────────────────
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: darkTextSecondary,
        collapsedIconColor: darkTextSecondary,
        textColor: darkTextPrimary,
        collapsedTextColor: darkTextPrimary,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: Border(),
        collapsedShape: Border(),
      ),

      // ── List Tile ───────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s4,
        ),
        titleTextStyle: bodyText.copyWith(color: darkTextPrimary),
        subtitleTextStyle: caption.copyWith(color: darkTextSecondary),
        leadingAndTrailingTextStyle: caption,
        iconColor: darkTextSecondary,
        textColor: darkTextPrimary,
        tileColor: Colors.transparent,
        selectedTileColor: darkPrimary.withValues(alpha: 0.1),
        selectedColor: darkPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      // ── Badge ───────────────────────────────────────────────
      badgeTheme: BadgeThemeData(
        backgroundColor: darkDanger,
        textColor: _darkSurfaceDim,
        textStyle: caption.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
        smallSize: 6,
        largeSize: 16,
      ),

      // ── Navigation Rail ─────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: darkPrimary, size: 24),
        unselectedIconTheme: IconThemeData(color: darkTextSecondary, size: 24),
        selectedLabelTextStyle: caption.copyWith(
          fontWeight: FontWeight.w600,
          color: darkPrimary,
        ),
        unselectedLabelTextStyle: caption.copyWith(color: darkTextSecondary),
        indicatorColor: darkPrimary.withValues(alpha: 0.15),
      ),

      // ── Drawer ──────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: _darkSurfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(),
      ),

      // ── Scrollbar ───────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(AppRadius.pill),
        thickness: WidgetStateProperty.all(4),
        thumbColor: WidgetStateProperty.all(
          darkTextSecondary.withValues(alpha: 0.3),
        ),
        trackVisibility: WidgetStateProperty.all(false),
      ),
    );
  }
}
