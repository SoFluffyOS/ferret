import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:protocol/notifications.dart';

/// Where the app picker stands.
enum AppPickerState { loading, failed, ready }

/// Picks which apps mirror, on this phone or on a connected one.
class AppPickerViewModel extends ChangeNotifier {
  AppPickerViewModel({
    required Future<List<AppEntry>> Function() load,
    required Future<void> Function(String package, bool allowed) save,
  }) : _load = load,
       _save = save {
    unawaited(reload());
  }

  final Future<List<AppEntry>> Function() _load;
  final Future<void> Function(String package, bool allowed) _save;

  AppPickerState _state = .loading;
  List<AppEntry> _apps = const [];
  String _query = '';
  bool _saveFailed = false;
  bool _disposed = false;

  AppPickerState get state => _state;

  String get query => _query;

  /// The last change could not be saved and was undone.
  bool get saveFailed => _saveFailed;

  /// Messaging apps matching the search.
  List<AppEntry> get messagingApps => [
    for (final app in _apps)
      if (app.isMessaging && _matches(app)) app,
  ];

  /// Other apps matching the search, picked ones first.
  List<AppEntry> get otherApps {
    final others = [
      for (final app in _apps)
        if (!app.isMessaging && _matches(app)) app,
    ];
    final picked = others.where((app) => app.allowed);
    final rest = others.where((app) => !app.allowed);
    return [...picked, ...rest];
  }

  Future<void> reload() async {
    _state = .loading;
    _notify();

    try {
      _apps = await _load();
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

  Future<void> setAllowed(String package, bool allowed) async {
    _saveFailed = false;
    _replace(package, allowed);

    try {
      await _save(package, allowed);
    } on Object catch (error) {
      printWarning('Saving an app choice failed', error);
      _replace(package, !allowed);
      _saveFailed = true;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _replace(String package, bool allowed) {
    _apps = [
      for (final app in _apps)
        switch (app.package == package) {
          true => app.deepCopy()..allowed = allowed,
          false => app,
        },
    ];
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
}
