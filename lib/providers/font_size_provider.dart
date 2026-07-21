import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted font size provider.
/// Reads from SharedPreferences on init, writes on every change.
final fontSizeProvider =
    StateNotifierProvider<FontSizeNotifier, FontSize>((ref) {
  return FontSizeNotifier();
});

/// Font size options for the app.
enum FontSize {
  small,
  medium,
  large,
}

class FontSizeNotifier extends StateNotifier<FontSize> {
  FontSizeNotifier() : super(FontSize.medium) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('font_size') ?? 'medium';
    state = _fromString(value);
  }

  Future<void> setFontSize(FontSize size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_size', _toString(size));
  }

  /// Returns a [TextScaler] that composes the app's font size preference
  /// with the system's text scaler (from accessibility settings).
  ///
  /// - [systemScaler]: the device's text scaler from MediaQuery
  /// - small:  system × 0.85
  /// - medium: system (no change)
  /// - large:  system × 1.15
  TextScaler getTextScaler(TextScaler systemScaler) {
    final double systemScale = systemScaler.scale(1.0);
    switch (state) {
      case FontSize.small:
        return TextScaler.linear(systemScale * 0.85);
      case FontSize.medium:
        return systemScaler;
      case FontSize.large:
        return TextScaler.linear(systemScale * 1.15);
    }
  }

  FontSize _fromString(String value) {
    switch (value) {
      case 'small':
        return FontSize.small;
      case 'large':
        return FontSize.large;
      default:
        return FontSize.medium;
    }
  }

  String _toString(FontSize size) {
    switch (size) {
      case FontSize.small:
        return 'small';
      case FontSize.medium:
        return 'medium';
      case FontSize.large:
        return 'large';
    }
  }
}
