import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/services/engine_host.dart';
import 'package:shell/view_models/window_nav_view_model.dart';
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

  /// Whether the view has room for the Activity pane next to the content:
  /// a `larger` view whose content, once the device list and the pane
  /// take theirs, still fits the Overview's two columns at the person's
  /// text size. Room is counted in text, not pixels, as em breakpoints do
  /// on the web: at 200% text the content needs twice the width, so a
  /// 1280 dp tablet folds the pane away (what is going on now moves to the
  /// top of the Overview, and Activity stays in the device list) while a
  /// 1920 dp window keeps it. Hiding the device list gives the room back.
  static bool showsActivityPane(BuildContext context) {
    if (!splits(context) || context.screenSize < ScreenSize.larger) {
      return false;
    }

    final isSidebarHidden = context.select<WindowNavViewModel?, bool>(
      (viewModel) => viewModel?.isSidebarHidden ?? false,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final sidebar = switch (isSidebarHidden) {
      true => 0.0,
      false => sidebarWidth(context.screenSize, textScaler: textScaler),
    };

    return activityPaneFits(
      width: MediaQuery.sizeOf(context).width - sidebar,
      textScale: context.textScale,
    );
  }

  /// Whether [width] holds the Activity pane and, next to it, content as
  /// wide as the Overview's two columns at [textScale] times the usual
  /// text size.
  static bool activityPaneFits({
    required double width,
    double textScale = 1,
  }) => width - PaneWidths.activity >= PaneWidths.twoColumns * textScale;

  /// The Mac window's title bar, which its content runs under: the device
  /// list reaches the top edge, and the traffic lights sit over it.
  static const double macTitleBarHeight = 28;

  /// How wide the device list is on a [screenSize] view. Large text
  /// widens it a quarter at most, so "Notifications" fits at 200%.
  static double sidebarWidth(
    ScreenSize screenSize, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final base = switch (screenSize) {
      .small || .normal => PaneWidths.narrowSidebar,
      .large || .larger || .extraLarge => PaneWidths.sidebar,
    };
    final grow = ((textScaler.scale(1) - 1) / 4).clamp(0.0, 0.25);

    return base * (1 + grow);
  }
}
