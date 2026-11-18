import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/models/models.dart';
import 'package:protocol/notifications.dart';

/// Where the app picker stands.
enum AppPickerState { loading, failed, ready }

/// A phone's app filter and its apps, as the picker loads them.
typedef AppList = ({MirrorSettings settings, List<AppEntry> apps});

/// One app in the picker and whether its notifications come through.
typedef PickerApp = ({AppEntry app, bool forwards});

/// Chooses which apps mirror, on this phone or on a connected one: all of
/// them, all but a few, or only a few.
class AppPickerViewModel extends ChangeNotifier {
  AppPickerViewModel({
    required Future<AppList> Function() load,
    required Future<MirrorSettings> Function(UpdateMirrorSettings update)
    update,
  }) : _load = load,
       _update = update {
    unawaited(reload());
  }

  final Future<AppList> Function() _load;
  final Future<MirrorSettings> Function(UpdateMirrorSettings update) _update;

  AppPickerState _state = .loading;
  MirrorSettings _settings = MirrorSettings(appFilter: .APP_FILTER_ALL);
  List<AppEntry> _apps = const [];
  String _query = '';
  bool _saveFailed = false;
  bool _disposed = false;

  AppPickerState get state => _state;

  String get query => _query;

  AppFilter get filter => _settings.effectiveFilter;

  /// The last change could not be saved and was undone.
  bool get saveFailed => _saveFailed;

  /// Apps matching the search, the ones that posted most recently first.
  List<PickerApp> get apps => [
    for (final app in _apps)
      if (_matches(app)) (app: app, forwards: _settings.forwards(app.package)),
  ];

  Future<void> reload() async {
    _state = .loading;
    _notify();

    try {
      final (:settings, :apps) = await _load();
      _settings = settings;
      _apps = [...apps]..sort(_byRecentActivity);
      _state = .ready;
    } on Object catch (error) {
      printWarning('Loading the app list failed', error);
      _state = .failed;
    }

    _notify();
  }

  void search(String query) {
    _query = query.trim().toLowerCase();
    _notify();
  }

  Future<void> setFilter(AppFilter filter) async {
    if (filter == this.filter) {
      return;
    }

    await _apply(UpdateMirrorSettings(appFilter: filter));
  }

  Future<void> setAllowed(String package, bool allowed) => _apply(
    UpdateMirrorSettings(
      apps: [AppChoice(package: package, allowed: allowed)],
    ),
  );

  /// Turns every app matching the search on or off.
  Future<void> setAllShown(bool allowed) async {
    final shown = apps;
    if (shown.isEmpty) {
      return;
    }

    await _apply(
      UpdateMirrorSettings(
        apps: [
          for (final (:app, forwards: _) in shown)
            AppChoice(package: app.package, allowed: allowed),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _apply(UpdateMirrorSettings update) async {
    final previous = _settings;
    _saveFailed = false;
    _settings = previous.withUpdate(update);
    _notify();

    try {
      _settings = await _update(update);
    } on Object catch (error) {
      printWarning('Saving the app choice failed', error);
      _settings = previous;
      _saveFailed = true;
    }

    _notify();
  }

  bool _matches(AppEntry app) =>
      _query.isEmpty ||
      app.name.toLowerCase().contains(_query) ||
      app.package.toLowerCase().contains(_query);

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  static int _byRecentActivity(AppEntry first, AppEntry second) {
    final byRecent = second.lastPostedMs.compareTo(first.lastPostedMs);
    if (byRecent != 0) {
      return byRecent;
    }

    if (first.isMessaging != second.isMessaging) {
      return switch (first.isMessaging) {
        true => -1,
        false => 1,
      };
    }

    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  }
}
