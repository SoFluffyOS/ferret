import 'dart:async';

import 'package:engine/engine.dart';
import 'package:ferret_photos/ferret_photos.dart';
import 'package:flutter/foundation.dart';
import 'package:photos/feature/feature.dart';

/// Photos on the phone itself: what the system lets Ferret read, and which
/// computers its owner shares photos with.
class PhonePhotosViewModel extends ChangeNotifier {
  PhonePhotosViewModel(this._feature) {
    _settings = _feature.settings.changes.listen((_) => _notify());
  }

  final PhotosFeature _feature;
  late final StreamSubscription<String> _settings;
  PhotoLibraryAccess _access = .notAsked;
  bool _disposed = false;

  PhotoLibraryAccess get access => _access;

  bool sharesWith(String deviceId) => _feature.settings.sharesWith(deviceId);

  /// Names of the paired computers that see the photos.
  List<String> get sharedWith => [
    for (final device in _feature.host.trustStore.devices)
      if (_feature.settings.sharesWith(device.id))
        _feature.host.displayNameOf(device.id),
  ];

  Future<void> refresh() async {
    _access = await _feature.library.access();
    _notify();
  }

  /// Turns sharing with [deviceId] on or off, asking the system for photo
  /// access first when turning it on without any.
  Future<void> setSharesWith(String deviceId, {required bool shared}) async {
    _access = await _feature.setSharesWith(deviceId, shared: shared);
    _notify();
  }

  /// Asks the system for photo access, or lets the person pick more.
  Future<void> allow() async {
    _access = await _feature.library.requestAccess();
    _notify();
  }

  Future<void> openSettings() => _feature.library.openSettings();

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_settings.cancel());
    super.dispose();
  }
}
