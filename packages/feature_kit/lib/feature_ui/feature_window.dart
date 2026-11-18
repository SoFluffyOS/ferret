import 'package:flutter/widgets.dart';

/// A window of a feature's own, in the shape of what it shows, such as a
/// phone's screen. It keeps that shape while it is resized, and remembers
/// its size for each [id].
class FeatureWindow {
  const FeatureWindow({
    required this.id,
    required this.title,
    required this.contentSize,
    required this.builder,
  });

  /// What the remembered size and place go by, such as a device's id.
  final String id;

  /// What the title bar says, such as "Pixel 9 — Screen".
  final String title;

  /// The picture's size in its own pixels. The window takes its shape, and
  /// is never bigger than this unless the person makes it so.
  final Size contentSize;

  /// What fills the window. It sits under the app's theme and strings,
  /// with a navigator of its own.
  final WidgetBuilder builder;
}

/// Opens a [FeatureWindow] where the platform has one to give: one at a
/// time. Listeners hear it open and close.
abstract interface class FeatureWindows implements Listenable {
  /// False where no second window can open: a phone, or a computer whose
  /// windows Ferret doesn't manage yet.
  bool get canOpen;

  /// The [FeatureWindow.id] of the window that is open.
  String? get openId;

  /// Opens [window] in place of the one that is open, or brings it to the
  /// front when it is the one. False when no window could open.
  Future<bool> open(FeatureWindow window);

  /// The picture changed size, such as when a phone was turned: the window
  /// turns with it and keeps its long side.
  Future<void> setContentSize(Size contentSize);

  Future<void> bringToFront();

  /// Closes the window. Its content is disposed like after the person
  /// closed it.
  Future<void> close();
}
