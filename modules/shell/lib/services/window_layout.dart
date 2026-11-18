import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/services/engine_host.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// How a view arranges the app, decided by its size and never by the kind
/// of device.
abstract final class WindowLayout {
  /// Whether the view shows the device list next to a content pane. A
  /// small view is one column, and so is any view while nothing is paired:
  /// a list with nothing in it is furniture.
  static bool splits(BuildContext context) {
    final hasDevices = context.select<EngineHost, bool>(
      (host) => host.devices.isNotEmpty,
    );

    return context.screenSize != .small && hasDevices;
  }

  /// Whether the view has room for the Activity pane next to the content.
  static bool showsActivityPane(BuildContext context) =>
      splits(context) && context.screenSize >= ScreenSize.larger;

  /// How wide the device list is on a [screenSize] view.
  static double sidebarWidth(ScreenSize screenSize) => switch (screenSize) {
    .small || .normal => PaneWidths.narrowSidebar,
    .large || .larger || .extraLarge => PaneWidths.sidebar,
  };
}
