/// Centralized spacing design tokens for the app.
/// Based on an 8-point grid system for visual consistency.
class AppSpacing {
  AppSpacing._();

  // ── Base Scale (2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64) ─────────
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
  static const double s36 = 36;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s64 = 64;
  static const double s72 = 72;
  static const double s80 = 80;

  // ── Semantic Aliases ────────────────────────────────────────────────────
  /// Extra small spacing (2px)
  static const double xs = s2;
  /// Small spacing (4px)
  static const double sm = s4;
  /// Medium-small spacing (8px)
  static const double mdSm = s8;
  /// Medium spacing (12px)
  static const double md = s12;
  /// Medium-large spacing (16px)
  static const double mdLg = s16;
  /// Large spacing (24px)
  static const double lg = s24;
  /// Extra large spacing (32px)
  static const double xl = s32;
  /// 2x large spacing (48px)
  static const double xxl = s48;
  /// 3x large spacing (64px)
  static const double xxxl = s64;

  // ── Common Insets ───────────────────────────────────────────────────────
  /// Standard padding for Cards and Containers
  static const double cardPadding = s16;
  /// Standard padding for ListTiles
  static const double listTilePadding = s16;
  /// Standard page horizontal padding
  static const double pageHorizontal = s16;
  /// Standard page vertical padding
  static const double pageVertical = s16;
  /// Section spacing between major UI blocks
  static const double sectionSpacing = s24;
  /// Small gap between related elements
  static const double elementGap = s8;
  /// Large gap between sections
  static const double sectionGap = s16;
}
