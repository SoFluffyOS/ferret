import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/services/services.dart';
import 'package:local_shelf/ui/frames/shelf_panel_frame.dart';
import 'package:local_shelf/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Joins [ShelfReach] to the computer: drags in other apps go in, the
/// floating panel comes out, and drags are watched only while one of the
/// ways that need it is on.
class ShelfReachHost {
  ShelfReachHost({
    required SystemDrags drags,
    required FloatingPanel panel,
    required ShelfSettings settings,
    required ShelfViewModel viewModel,
    required VoidCallback onOpenList,
  }) : _drags = drags,
       _panel = panel,
       _settings = settings,
       _viewModel = viewModel,
       _onOpenList = onOpenList;

  final SystemDrags _drags;
  final FloatingPanel _panel;
  final ShelfSettings _settings;
  final ShelfViewModel _viewModel;
  final VoidCallback _onOpenList;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool? _watching;

  late final ShelfReach reach = ShelfReach(
    options: () => _settings.reach,
    panelSize: _panelSize,
    show: (frame, motion) => _panel.show(
      frame: frame,
      motion: motion,
      radius: ShelfPanelFrame.radius,
      builder: _build,
    ),
    hide: _panel.hide,
  );

  /// The panel's size at the text size the system asks for now.
  static Size get _panelSize => ShelfPanelFrame.sizeFor(
    TextScaler.linear(
      WidgetsBinding.instance.platformDispatcher.textScaleFactor,
    ),
  );

  Future<void> start() async {
    if (!_panel.canShow) {
      return;
    }

    _subscriptions
      ..add(
        _drags.events.listen((event) {
          reach.panelSize = _panelSize;
          reach.handle(event);
        }),
      )
      ..add(_viewModel.taken.listen((_) => reach.dropped()))
      ..add(_settings.changes.listen((_) => unawaited(_sync())));
    await _sync();
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    reach.dispose();
    if (_watching ?? false) {
      await _drags.watch(on: false);
    }
  }

  Future<void> _sync() async {
    final watches = _settings.reach.watchesDrags;
    if (!watches) {
      reach.dismiss();
    }

    if (watches == _watching) {
      return;
    }

    _watching = watches;
    await _drags.watch(on: watches);
  }

  Widget _build(BuildContext context) => ChangeNotifierProvider.value(
    value: _viewModel,
    child: ShelfPanelFrame(
      onOpenList: () {
        reach.dismiss();
        _onOpenList();
      },
      onHover: (over) => reach.hovering(over: over),
    ),
  );
}
