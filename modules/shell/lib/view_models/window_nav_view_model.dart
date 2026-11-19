import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Where one view of the app is: what its device list has selected, and
/// which of its panes the person hid. Each view has its own, so the popover
/// and the window on a Mac move apart.
class WindowNavViewModel extends ChangeNotifier {
  WindowNavViewModel({
    required EngineHost host,
    required this.navigatorKey,
    required Widget Function(WindowDestination destination) pageFor,
    SettingsStore? settings,
  }) : _host = host,
       _pageFor = pageFor,
       _settings = settings {
    _selection = WindowDestination.parse(settings?.get<String>(selectionKey));
    _isSidebarHidden = settings?.get<bool>(sidebarHiddenKey) ?? false;
    _isActivityPaneHidden = settings?.get<bool>(activityPaneHiddenKey) ?? false;
    _isNearbyCollapsed = settings?.get<bool>(nearbyCollapsedKey) ?? false;
    _host.addListener(notifyListeners);
  }

  /// Settings key for the last selection, as [WindowDestination.stored].
  static const selectionKey = 'shell.window.selection';

  /// Settings key that says the person hid the device list.
  static const sidebarHiddenKey = 'shell.window.sidebar_hidden';

  /// Settings key that says the person hid the Activity pane.
  static const activityPaneHiddenKey = 'shell.window.activity_pane_hidden';

  /// Settings key that says the person folded Nearby in the device list.
  static const nearbyCollapsedKey = 'shell.window.nearby_collapsed';

  /// The navigator of this view's content pane.
  final GlobalKey<NavigatorState> navigatorKey;

  final EngineHost _host;
  final Widget Function(WindowDestination destination) _pageFor;
  final SettingsStore? _settings;
  WindowDestination? _selection;
  bool _isSidebarHidden = false;
  bool _isActivityPaneHidden = false;
  bool _isNearbyCollapsed = false;

  /// What the pane shows first. With nothing chosen yet, or after the
  /// chosen device was forgotten, the first device's Overview. Null while
  /// nothing is paired.
  WindowDestination? get selection {
    final devices = _host.devices;
    if (devices.isEmpty) {
      return null;
    }

    return switch (_selection) {
      null => DeviceDestination(devices.first.device.id),
      DeviceDestination(:final deviceId)
          when _host.statusOf(deviceId) == null =>
        DeviceDestination(devices.first.device.id),
      final chosen => chosen,
    };
  }

  /// The device whose sections the list shows, or null on Activity and
  /// Settings.
  String? get selectedDeviceId => switch (selection) {
    DeviceDestination(:final deviceId) => deviceId,
    _ => null,
  };

  bool get isSidebarHidden => _isSidebarHidden;

  bool get isActivityPaneHidden => _isActivityPaneHidden;

  /// Whether Nearby in the device list shows only its heading.
  bool get isNearbyCollapsed => _isNearbyCollapsed;

  @override
  void dispose() {
    _host.removeListener(notifyListeners);
    super.dispose();
  }

  /// Shows [destination] as the pane's first page, closing whatever was
  /// opened on top of the last one.
  void select(WindowDestination destination) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _clearShown();
    if (destination == selection) {
      return;
    }

    _selection = destination;
    unawaited(_settings?.set(selectionKey, destination.stored));
    notifyListeners();
  }

  /// Moves [step] devices down the list (up when negative), around the
  /// ends, and opens that device's Overview.
  void selectDeviceBy(int step) {
    final devices = _host.devices;
    if (devices.isEmpty) {
      return;
    }

    final current = devices.indexWhere(
      (status) => status.device.id == selectedDeviceId,
    );
    final next = switch (current) {
      -1 => 0,
      _ => (current + step) % devices.length,
    };
    select(DeviceDestination(devices[next].device.id));
  }

  /// Goes to [destination] however this view is laid out right now: the
  /// selection when it has a device list, a pushed page when it is one
  /// column.
  void open(WindowDestination destination) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    if (_splits(context)) {
      select(destination);
      return;
    }

    _push(_pageFor(destination));
  }

  /// Starts a view that just opened at [destination], before it has drawn
  /// anything: its selection, or a page over the welcome while nothing is
  /// paired and there is no list to select in.
  void land(WindowDestination destination) {
    if (_host.devices.isNotEmpty) {
      _selection = destination;
      unawaited(_settings?.set(selectionKey, destination.stored));
      notifyListeners();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _push(_pageFor(destination)),
    );
  }

  /// The title of a page [show] opened that isn't about the selection,
  /// such as Add a device, while it is open. The toolbar says it, and the
  /// list stops pointing at a device the page has nothing to do with.
  String? get shownTitle => _shownTitle;
  String? _shownTitle;
  int _shownRun = 0;

  /// Opens [page] over the selection, alone: such as Add a device. With a
  /// [title], the page stands on its own rather than in the selection.
  void show(Widget page, {String? title}) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _clearShown();
    if (title == null) {
      _push(page);
      return;
    }

    final run = ++_shownRun;
    _shownTitle = title;
    notifyListeners();
    unawaited(
      navigatorKey.currentState?.push(ferretRoute<void>(page)).whenComplete(() {
        if (run == _shownRun) {
          _clearShown();
        }
      }),
    );
  }

  void _clearShown() {
    if (_shownTitle == null) {
      return;
    }

    _shownTitle = null;
    _shownRun++;
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarHidden = !_isSidebarHidden;
    unawaited(_settings?.set(sidebarHiddenKey, _isSidebarHidden));
    notifyListeners();
  }

  void toggleActivityPane() {
    _isActivityPaneHidden = !_isActivityPaneHidden;
    unawaited(_settings?.set(activityPaneHiddenKey, _isActivityPaneHidden));
    notifyListeners();
  }

  void toggleNearby() {
    _isNearbyCollapsed = !_isNearbyCollapsed;
    unawaited(_settings?.set(nearbyCollapsedKey, _isNearbyCollapsed));
    notifyListeners();
  }

  bool _splits(BuildContext context) {
    final screenSize =
        Provider.of<ScreenSizeNotifier?>(context, listen: false)?.screenSize ??
        ScreenSize.of(context);

    return screenSize != .small && _host.devices.isNotEmpty;
  }

  void _push(Widget page) {
    unawaited(navigatorKey.currentState?.push(ferretRoute<void>(page)));
  }
}
