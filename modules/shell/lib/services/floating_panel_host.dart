import 'dart:async';
import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The floating panel on a Mac: one more Flutter view, made the first
/// time it shows and kept, so it comes back at once. This says which view
/// it is and what a feature wants drawn in it.
class FloatingPanelHost extends ChangeNotifier
    with WidgetsBindingObserver
    implements FloatingPanel {
  FloatingPanelHost({
    required FerretMenubar menubar,
    PlatformDispatcher? dispatcher,
  }) : _menubar = menubar,
       _dispatcher = dispatcher ?? PlatformDispatcher.instance;

  final FerretMenubar _menubar;
  final PlatformDispatcher _dispatcher;
  bool _observing = false;
  int? _viewId;
  FlutterView? _view;
  WidgetBuilder? _builder;

  @override
  bool get canShow => _menubar.isSupported;

  /// The panel's view, once Flutter has it.
  FlutterView? get view => _view;

  /// What the panel shows.
  WidgetBuilder? get builder => _builder;

  @override
  Future<bool> show({
    required Rect frame,
    required PanelMotion motion,
    required double radius,
    required WidgetBuilder builder,
  }) async {
    if (!canShow) {
      return false;
    }

    if (!_observing) {
      _observing = true;
      WidgetsBinding.instance.addObserver(this);
    }

    final int? viewId;
    try {
      viewId = await _menubar.showFloatingPanel(
        frame,
        radius: radius,
        motion: switch (motion) {
          .fromRight => .fromRight,
          .fromLeft => .fromLeft,
          .inPlace => .inPlace,
        },
      );
    } on PlatformException {
      return false;
    }

    if (viewId == null) {
      return false;
    }

    final changed = !identical(_builder, builder);
    _builder = builder;
    _viewId = viewId;
    _sync();
    if (changed) {
      notifyListeners();
    }

    return true;
  }

  @override
  Future<void> hide() => _menubar.hideFloatingPanel();

  /// The view appears through the engine a moment after the plugin
  /// answers.
  @override
  void didChangeMetrics() => _sync();

  void _sync() {
    final viewId = _viewId;
    if (viewId == null) {
      return;
    }

    final view = _dispatcher.view(id: viewId);
    if (view == _view) {
      return;
    }

    _view = view;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
    }

    super.dispose();
  }
}
