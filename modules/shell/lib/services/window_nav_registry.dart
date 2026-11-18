import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/app_views.dart';
import 'package:shell/view_models/window_nav_view_model.dart';

/// Every view's navigation, so something that happens outside a view (a
/// feature opening its page, a notification, the menubar's Settings) lands
/// in the right one: the desktop window where there is one to open, since a
/// popover has no room for a page, and otherwise the view in front.
class WindowNavRegistry {
  WindowNavRegistry(this._featureContext, {AppViews? views})
    : _appViews = views {
    _featureContext.onOpenSection = openSection;
  }

  final FeatureContext _featureContext;
  final AppViews? _appViews;
  final List<WindowNavViewModel> _views = [];

  /// Where the window goes once it has opened.
  WindowDestination? _awaited;

  /// The navigation of the view in front, or null before any view shows.
  WindowNavViewModel? get active {
    final navigator = _featureContext.navigatorKey.currentState;
    for (final view in _views) {
      if (navigator != null && view.navigatorKey.currentState == navigator) {
        return view;
      }
    }

    return _views.firstOrNull;
  }

  void add(WindowNavViewModel view) {
    _views.add(view);
    final awaited = _awaited;
    if (awaited == null || !_isWindow(view)) {
      return;
    }

    _awaited = null;
    view.land(awaited);
  }

  void remove(WindowNavViewModel view) => _views.remove(view);

  /// Shows [destination]: in the desktop window on a Mac, opening it when
  /// it is closed, and in the view in front everywhere else.
  void open(WindowDestination destination) {
    final appViews = _appViews;
    if (appViews == null || !appViews.canOpenWindow) {
      active?.open(destination);
      return;
    }

    final window = _views.where(_isWindow).firstOrNull;
    if (window == null) {
      _awaited = destination;
    }

    window?.open(destination);
    unawaited(appViews.moveToWindow());
  }

  Future<void> openSection(String deviceId, String sectionId) async =>
      open(DeviceDestination(deviceId, sectionId: sectionId));

  bool _isWindow(WindowNavViewModel view) =>
      view.navigatorKey == _appViews?.windowNavigatorKey;
}
