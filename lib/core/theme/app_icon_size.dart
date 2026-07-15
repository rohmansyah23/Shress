/// Centralized icon size design tokens for the app.
///
/// Provides consistent icon dimensions across all components.
/// All standard icon sizes are defined here as named constants.
///
/// ## Usage
/// ```dart
/// Icon(Icons.add_rounded, size: AppIconSize.s20)
/// ```
///
/// ## Size Reference
/// | Token | Value | Use Case |
/// |-------|-------|----------|
/// | s16   | 16    | Inline icons, chips, badge icons |
/// | s18   | 18    | Action icon buttons, small trailing icons |
/// | s20   | 20    | Leading icons, prefix icons, medium action icons |
/// | s24   | 24    | Default icon size, navigation items |
/// | s28   | 28    | Elevated icon buttons, feature icons |
/// | s32   | 32    | Section header icons, empty state icons |
/// | s36   | 36    | Medium-large decorative icons |
/// | s40   | 40    | Large feature icons |
/// | s48   | 48    | Hero icons, QR code icons |
/// | s52   | 52    | Welcome/onboarding hero icons |
/// | s64   | 64    | Large empty state icons, avatar placeholders |
/// | s72   | 72    | Error/forgot password hero icons |
/// | s80   | 80    | QR display icons |
class AppIconSize {
  AppIconSize._();

  // ── Base Scale ──────────────────────────────────────────────────────────
  static const double s10 = 10;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s22 = 22;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s36 = 36;
  static const double s40 = 40;
  static const double s44 = 44;
  static const double s48 = 48;
  static const double s52 = 52;
  static const double s64 = 64;
  static const double s72 = 72;
  static const double s80 = 80;
}
