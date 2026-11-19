import 'package:flutter/painting.dart';

/// Where the mirror toolbar sits. Wherever it is, it is next to the
/// picture, never on it.
enum ToolbarPlace {
  /// A row under the picture. Its menus open upward.
  below,

  /// A column beside the picture, with words. Its menus open sideways.
  beside,

  /// The top bar of the picture's own window, next to the title bar's
  /// buttons. Its menus open downward.
  bar;

  Axis get axis => switch (this) {
    .beside => .vertical,
    _ => .horizontal,
  };
}
