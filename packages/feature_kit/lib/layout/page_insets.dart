import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The rhythm every page shares, on the 4-point grid.
abstract final class PageInsets {
  /// Between a page's edge and its content: 16 in one column (a phone, the
  /// popover), 20 where there is more room.
  static double side(ScreenSize screenSize) => switch (screenSize) {
    .small => Spacing.d16,
    .normal || .large || .larger || .extraLarge => Spacing.d20,
  };

  /// Between a card's edge and the text of its rows. Headings above the
  /// card and the lines between its rows start at the same place.
  static double get row => Spacing.d12;

  /// Between two groups of rows.
  static double get group => Spacing.d24;
}
