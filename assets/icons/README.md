# App Icon Setup

## Quick Start (Custom Icon)

1. **Prepare your icon image** (1024×1024 PNG recommended):
   - Place at: `assets/icons/app_icon.png`
   - For adaptive icon foreground: `assets/icons/app_icon_foreground.png`

2. **Generate all icon sizes**:
   ```bash
   dart run flutter_launcher_icons
   ```

3. The script will automatically generate:
   - Android: mipmap-hdpi/mdpi/xhdpi/xxhdpi/xxxhdpi + adaptive icon
   - Android manifest already configured for `@mipmap/ic_launcher`

## Default Icons (Placeholder)

The project includes vector-based adaptive icons:
- **Background**: Deep Indigo (`#1A237E`) — SSRS brand color
- **Foreground**: White building icon with "Rp" symbol
- Located in `android/app/src/main/res/drawable/`

To replace with your own icon, either:
1. Use `flutter_launcher_icons` (recommended — just replace PNG files)
2. Or replace the vector drawables at `res/drawable/ic_launcher_*.xml`

## Design Guidelines

| Platform | Format | Size | Notes |
|---|---|---|---|
| Android (adaptive) | PNG 1024×1024 | Foreground + Background | Background color: `#1A237E` |
| Android (legacy) | PNG | 48×48 to 192×192 | Generated automatically |

## Material 3 Design Tips

- Use **simple shapes** with clear outlines
- **Avoid text** in the icon (already vector "Rp" is minimal)
- Brand color: `#1A237E` (Deep Indigo)
- Accent: `#FFB300` (Amber)
