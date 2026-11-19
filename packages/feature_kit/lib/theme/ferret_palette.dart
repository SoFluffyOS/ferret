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

  /// Secondary text, at least 4.5:1 against [surface] in both modes.
  Color get mutedText => switch (_dark) {
    true => _theme.colors.neutral4,
    false => const Color(0xFF6C6C70),
  };

  /// The hairline between two rows of a card.
  Color get separator => switch (_dark) {
    true => text.withValues(alpha: 0.15),
    false => text.withValues(alpha: 0.1),
  };

  Color get accent => _theme.colors.primary;

  /// [accent] as text or a thin icon: links, "new" markers. On dark the
  /// accent itself is too dim to read, so this is a lighter blue there.
  Color get link => switch (_dark) {
    true => const Color(0xFF4C9AFF),
    false => _theme.colors.primary,
  };

  // The three below are text as often as dots, so on light they are the
  // darker shades that keep 4.5:1 against [surface]. The bright ones only
  // pass on dark.
  Color get success => switch (_dark) {
    true => const Color(0xFF34C759),
    false => const Color(0xFF1F7A36),
  };

  Color get warning => switch (_dark) {
    true => const Color(0xFFFF9F0A),
    false => const Color(0xFFB25000),
  };

  Color get danger => switch (_dark) {
    true => const Color(0xFFFF453A),
    false => const Color(0xFFD70015),
  };
}

extension FerretPaletteContext on BuildContext {
  FerretPalette get palette => FerretPalette.of(this);
}
