import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:local_shelf/models/models.dart';

/// Settings → Shelf on a Mac: the ways to reach the shelf while dragging,
/// and what a quick drop on the menubar icon does.
class ShelfReachViewModel extends ChangeNotifier {
  ShelfReachViewModel({required SettingsStore store, this.runningApps})
    : _shelf = ShelfSettings(store),
      _icon = MenubarDrops(store) {
    _changes = store.changes
        .where((key) => key.startsWith('shelf.') || MenubarDrops.owns(key))
        .listen((_) => notifyListeners());
  }

  final ShelfSettings _shelf;
  final MenubarDrops _icon;
  late final StreamSubscription<String> _changes;

  /// The apps running now, to pick ones to ignore; none to pick when null.
  final Future<List<SystemApp>> Function()? runningApps;

  List<SystemApp> _apps = const [];

  ShelfReachOptions get options => _shelf.reach;

  bool get springLoading => _icon.springLoading;

  IconDrop get iconDrop => _icon.iconDrop;

  /// Apps to offer for the ignore list: running now, not ignored yet.
  List<SystemApp> get pickableApps {
    final ignored = {for (final app in options.ignoredApps) app.id};
    return [
      for (final app in _apps)
        if (!ignored.contains(app.id)) app,
    ];
  }

  bool get canPickApps => runningApps != null;

  /// Asks which apps run now, such as when Settings opens.
  Future<void> loadApps() async {
    final runningApps = this.runningApps;
    if (runningApps == null) {
      return;
    }

    try {
      _apps = await runningApps();
    } on Object {
      _apps = const [];
    }

    notifyListeners();
  }

  Future<void> setSpringLoading(bool value) => _icon.setSpringLoading(value);

  Future<void> setIconDrop(IconDrop value) => _icon.setIconDrop(value);

  Future<void> setBoxOnDrag(bool value) => _shelf.setBoxOnDrag(value);

  Future<void> setBoxShows(ShelfBoxShows value) => _shelf.setBoxShows(value);

  Future<void> setShake(bool value) => _shelf.setShake(value);

  Future<void> setSensitivity(ShakeSensitivity value) =>
      _shelf.setShakeSensitivity(value);

  Future<void> setShiftSummons(bool value) => _shelf.setShiftSummons(value);

  Future<void> ignore(SystemApp app) => _shelf.setIgnoredApps([
    ...options.ignoredApps,
    IgnoredApp(id: app.id, name: app.name),
  ]);

  Future<void> unignore(IgnoredApp app) => _shelf.setIgnoredApps([
    for (final ignored in options.ignoredApps)
      if (ignored != app) ignored,
  ]);

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }
}
