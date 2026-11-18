import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Ferret's colours by role, picked from the Fluffy theme for light and dark.
class FerretPalette {
  const FerretPalette._(this._theme);

  factory FerretPalette.of(BuildContext context) =>
      FerretPalette._(context.fluffyTheme);

  final FluffyThemeData _theme;

  bool get _dark => _theme.isDark;

  Color get background => switch (_dark) {
    true => _theme.colors.neutral7,
    false => _theme.colors.neutral1,
  };

  /// Cards and grouped rows. Filled, never outlined.
  Color get surface => switch (_dark) {
    true => _theme.colors.neutral6,
    false => _theme.colors.neutral2,
  };

  Color get text => switch (_dark) {
    true => _theme.colors.neutral1,
    false => _theme.colors.neutral7,
  };

  Color get mutedText => _theme.colors.neutral4;

  Color get accent => _theme.colors.primary;

  Color get success => const Color(0xFF34C759);

  Color get warning => const Color(0xFFFF9F0A);

  Color get danger => const Color(0xFFFF453A);
}

extension FerretPaletteContext on BuildContext {
  FerretPalette get palette => FerretPalette.of(this);
}
