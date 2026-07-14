import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// PocketFund Design System v2 — Sheress
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Light Theme Colors ──────────────────────────────────────
  static const Color background = Color(
    0xFFF1F5F9,
  ); // Slate 100 // Slate 200 // Background utama
  static const Color secondaryBackground = Color(0xFFE2E8F0); // Section/list
  // Menggunakan putih yang sedikit bergeser ke arah warna background (sangat bersih & premium)
  static const Color card = Color(0xFFF8FAFC); // Slate 50

  static const Color primary = Color(0xFF1E293B); // Slate 800
  static const Color accent = Color(0xFF22C55E); // Green modern

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color primaryText = Color(0xFF0F172A); // Hampir hitam
  static const Color secondaryText = Color(0xFF64748B); // Slate 500

  static const Color divider = Color(0xFFE2E8F0);

  // ── Backward Compatible Constants ───────────────────────────
  /// Old name for [primary] — use [primary] for new code
  static const Color primaryColor = primary;

  /// Old secondary/teal — kept for backward compat; use [accent] for green accent
  static const Color secondaryColor = Color(0xFF00897B);

  /// Old name — use [profitColorTheme(context)] for theme-aware
  static const Color profitColor = Color(0xFF2E7D32);

  /// Old name — use [lossColorTheme(context)] for theme-aware
  static const Color lossColor = Color(0xFFC62828);

  /// Old name — use [warningColorTheme(context)] for theme-aware
  static const Color warningColor = Color(0xFFF57F17);

  /// Old name — use [infoColorTheme(context)] for theme-aware
  static const Color infoColor = Color(0xFF1565C0);

  // ── Dark Theme Colors ───────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSecondaryBackground = Color(0xFF181818);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkElevatedCard = Color(0xFF303030);
  static const Color darkPrimary = Color(0xFF2ECC71);
  static const Color darkAccent = Color(0xFF00E676);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFA0A0A0);
  static const Color darkDivider = Color(0x14FFFFFF);

  // ── Spacing (8-point grid) ──────────────────────────────────
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;

  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s64 = 64;

  // ── Border Radius ───────────────────────────────────────────
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusXL = 24;
  static const double radiusPill = 999;

  // ── Status Colors (theme-aware helpers) ─────────────────────
  static Color profitColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF81C784)
      : const Color(0xFF22C55E);

  static Color lossColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFE57373)
      : const Color(0xFFC62828);

  static Color warningColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFFB74D)
      : warning;

  static Color infoColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF64B5F6)
      : const Color(0xFF1565C0);

  static Color primaryColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF9FA8DA)
      : primary;

  static Color secondaryColorTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF80CBC4)
      : secondaryColor;

  // ── Typography (Inter via Google Fonts) ────────────────────
  /// Runtime-downloaded Inter font family identifier
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  // Display
  static TextStyle get display => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
    height: 1.1,
  );

  // H1
  static TextStyle get heading1 => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.8,
    height: 1.15,
  );

  // H2
  static TextStyle get heading2 => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // H3
  static TextStyle get heading3 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
  );

  // Title
  static TextStyle get title =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);

  // Subtitle
  static TextStyle get subtitle =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4);

  // Body
  static TextStyle get bodyText => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // Caption
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // Button
  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
  );

  // Amount (large)
  static TextStyle get amountLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
    height: 1.1,
  );

  // Amount (medium)
  static TextStyle get amountMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // Label (small)
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // ── Elevated / Shadow ───────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ── ThemeData ───────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primary,
      primaryContainer: Color(0xFFE3E8F4),
      onPrimaryContainer: primary,
      secondary: accent,
      surface: background,
      error: danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: primaryText,
      onError: Colors.white,
      outline: divider,
      surfaceContainerHighest: secondaryBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      hoverColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.12),
      splashColor: primary.withValues(alpha: 0.16),

      // ── Text Theme (Inter via Google Fonts) ─────────────────
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
        labelMedium: buttonText.copyWith(fontSize: 13),
        labelSmall: labelSmall,
      ),

      // ── AppBar ──────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: primaryText,
        titleTextStyle: title.copyWith(color: primaryText),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: divider, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        color: card,
        margin: const EdgeInsets.symmetric(vertical: s4),
      ),

      // ── Bottom Sheet ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Buttons ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: s24, vertical: s16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
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
          padding: const EdgeInsets.symmetric(horizontal: s24, vertical: s16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: buttonText,
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: s24, vertical: s16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          side: BorderSide(color: divider, width: 1),
          textStyle: buttonText,
          foregroundColor: primaryText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: s16, vertical: s12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: buttonText,
          foregroundColor: primary,
        ),
      ),

      // ── Input ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: s16,
          vertical: s16,
        ),
        labelStyle: bodyText.copyWith(color: secondaryText),
        hintStyle: caption.copyWith(color: secondaryText),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
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
          horizontal: s24,
          vertical: s16,
        ),
        extendedTextStyle: buttonText,
      ),

      // ── Bottom Navigation ───────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: secondaryText,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: caption.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: caption.copyWith(fontSize: 11),
      ),

      // ── Chip ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: s12, vertical: s8),
        labelStyle: caption.copyWith(color: primaryText),
        secondaryLabelStyle: caption.copyWith(
          color: card,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: primary,
        backgroundColor: secondaryBackground,
        brightness: Brightness.light,
        side: BorderSide.none,
      ),

      // ── Segmented Button ────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
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
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        contentTextStyle: bodyText.copyWith(color: Colors.white),
        elevation: 0,
      ),

      // ── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: accent.withValues(alpha: 0.2),
      ),

      // ── Divider ─────────────────────────────────────────────
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),

      // ── Progress Indicator ──────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: accent.withValues(alpha: 0.2),
      ),

      // ── Switch ──────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.3);
          }
          return divider;
        }),
      ),

      // ── Scrollbar ───────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(radiusPill),
        thickness: WidgetStateProperty.all(4),
        thumbColor: WidgetStateProperty.all(
          secondaryText.withValues(alpha: 0.3),
        ),
      ),

      // ── Popup Menu ──────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        elevation: 8,
        color: card,
        surfaceTintColor: Colors.transparent,
        shadowColor: accent.withValues(alpha: 0.2),
      ),

      // ── Dropdown Menu ────────────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
          ),
          elevation: WidgetStateProperty.all(8),
          shadowColor: WidgetStateProperty.all(
            accent.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // DARK THEME
  // ═════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: darkPrimary,
      primaryContainer: Color(0xFF224A2E),
      onPrimaryContainer: Colors.white,
      secondary: darkAccent,
      surface: darkBackground,
      error: danger,
      onPrimary: const Color(0xFF121212),
      onSecondary: const Color(0xFF121212),
      onSurface: darkPrimaryText,
      onError: Colors.white,
      outline: darkDivider,
      surfaceContainerHighest: darkSecondaryBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      hoverColor: Colors.white.withValues(alpha: 0.06),
      highlightColor: Colors.white.withValues(alpha: 0.10),
      splashColor: Colors.white.withValues(alpha: 0.14),

      // ── Text Theme (Inter via Google Fonts) ─────────────────
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
        labelMedium: buttonText.copyWith(fontSize: 13),
        labelSmall: labelSmall,
      ),

      // ── AppBar ──────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: darkBackground,
        foregroundColor: darkPrimaryText,
        titleTextStyle: title.copyWith(color: darkPrimaryText),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: darkDivider, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        color: darkCard,
        margin: const EdgeInsets.symmetric(vertical: s4),
      ),

      // ── Bottom Sheet ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        ),
        elevation: 0,
        shadowColor: darkAccent.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        backgroundColor: darkCard,
      ),

      // ── Buttons ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: s24, vertical: s16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: buttonText,
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF121212),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: s24, vertical: s16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: buttonText,
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF121212),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: s24, vertical: s16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          side: BorderSide(color: darkDivider, width: 1),
          textStyle: buttonText,
          foregroundColor: darkPrimaryText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: s16, vertical: s12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: buttonText,
          foregroundColor: darkPrimary,
        ),
      ),

      // ── Input ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSecondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: darkAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: s16,
          vertical: s16,
        ),
        labelStyle: bodyText.copyWith(color: darkSecondaryText),
        hintStyle: caption.copyWith(color: darkSecondaryText),
        prefixIconColor: darkSecondaryText,
        suffixIconColor: darkSecondaryText,
      ),

      // ── FAB ─────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: darkPrimary,
        foregroundColor: const Color(0xFF121212),
        shape: const CircleBorder(),
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: s24,
          vertical: s16,
        ),
        extendedTextStyle: buttonText,
      ),

      // ── Bottom Navigation ───────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: darkCard,
        selectedItemColor: darkPrimaryText,
        unselectedItemColor: darkSecondaryText,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: caption.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: caption.copyWith(fontSize: 11),
      ),

      // ── Chip ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: s12, vertical: s8),
        labelStyle: caption.copyWith(color: darkPrimaryText),
        secondaryLabelStyle: caption.copyWith(color: darkSecondaryText),
        selectedColor: darkPrimary.withValues(alpha: 0.2),
        backgroundColor: darkSecondaryBackground,
        brightness: Brightness.dark,
      ),

      // ── Segmented Button ────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: buttonText.copyWith(fontSize: 13),
        ),
      ),

      // ── SnackBar ────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        contentTextStyle: bodyText.copyWith(color: Colors.white),
        elevation: 0,
      ),

      // ── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: darkElevatedCard,
        shadowColor: darkAccent.withValues(alpha: 0.4),
        titleTextStyle: heading3.copyWith(color: darkPrimaryText),
        contentTextStyle: bodyText.copyWith(color: darkPrimaryText),
      ),

      // ── Divider ─────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),

      // ── Progress Indicator ──────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: darkAccent,
        linearTrackColor: darkAccent.withValues(alpha: 0.2),
      ),

      // ── Switch ──────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkAccent;
          return darkSecondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkAccent.withValues(alpha: 0.3);
          }
          return darkDivider;
        }),
      ),

      // ── Scrollbar ───────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(radiusPill),
        thickness: WidgetStateProperty.all(4),
        thumbColor: WidgetStateProperty.all(
          darkSecondaryText.withValues(alpha: 0.3),
        ),
      ),

      // ── Popup Menu ──────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        elevation: 6,
        color: darkSecondaryBackground,
        surfaceTintColor: Colors.transparent,
        shadowColor: darkAccent.withValues(alpha: 0.25),
      ),

      // ── Dropdown Menu ────────────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
          ),
          elevation: WidgetStateProperty.all(6),
          shadowColor: WidgetStateProperty.all(
            darkAccent.withValues(alpha: 0.25),
          ),
          backgroundColor: WidgetStateProperty.all(
            darkSecondaryBackground,
          ),
        ),
      ),
    );
  }
}
