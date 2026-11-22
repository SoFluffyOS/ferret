import 'package:flutter/foundation.dart';

/// Whether this computer shows Ferret's tray icon. A Mac always has its
/// menu bar; Windows always has a tray; on Linux it depends on the desktop
/// (GNOME has none without the AppIndicator extension).
abstract final class TrayStatus {
  /// Kept up to date by the desktop binding, also when a tray turns up or
  /// goes away after start.
  static final ValueNotifier<bool> shows = ValueNotifier(true);
}
