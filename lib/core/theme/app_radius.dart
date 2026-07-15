/// Centralized border radius design tokens for the app.
/// Provides consistent rounded corner values across all components.
class AppRadius {
  AppRadius._();

  // ── Base Scale ──────────────────────────────────────────────────────────
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;

  // ── Semantic Aliases ────────────────────────────────────────────────────
  /// Small radius (12px) for chips, small badges, inputs
  static const double sm = s12;
  /// Medium radius (12px) for cards, dialogs, bottom sheets
  static const double md = s12;
  /// Large radius (16px) for elevated cards, containers
  static const double lg = s16;
  /// Extra large radius (24px) for modals, sheets
  static const double xl = s24;
  /// Pill radius (999) for buttons, tags
  static const double pill = 999;

  // ── Backward Compatibility ──────────────────────────────────────────────
  static const double radiusSmall = s12;
  static const double radiusMedium = s16;
  static const double radiusLarge = s20;
  static const double radiusXL = s24;
  static const double radiusPill = pill;
}
