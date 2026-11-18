import 'dart:async';
import 'dart:io';

import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter/foundation.dart';
import 'package:iphone/feature/iphone_feature.dart';
import 'package:iphone/models/models.dart';

/// Which pairing steps and notes Settings shows.
enum IphoneHostKind {
  windows,
  macos,
  linux;

  static IphoneHostKind get current {
    if (Platform.isMacOS) {
      return macos;
    }

    if (Platform.isLinux) {
      return linux;
    }

    return windows;
  }
}

/// The iPhone section in Settings: turning it on, pairing and picking the
/// iPhone, and what to show from it.
class IphoneSettingsViewModel extends ChangeNotifier {
  IphoneSettingsViewModel(this._feature, {IphoneHostKind? host})
    : host = host ?? IphoneHostKind.current {
    _subscription = _feature.changes.listen((_) => _onChanged());
    if (needsDevice) {
      unawaited(loadDevices());
    }
  }

  final IphoneFeature _feature;
  final IphoneHostKind host;
  late final StreamSubscription<void> _subscription;

  List<BondedDevice> _devices = const [];
  bool _openFailed = false;
  bool _disposed = false;
  bool _neededDevice = false;

  bool get enabled => _feature.settings.enabled;

  LinkState get link => _feature.link;

  bool get showNotifications => _feature.settings.showNotifications;

  bool get showMedia => _feature.settings.showMedia;

  bool get hidePreviews => _feature.settings.hidePreviews;

  /// On, able to use Bluetooth, and no iPhone picked yet.
  bool get needsDevice => enabled && link.phase == .noDevice;

  /// The paired devices to pick from, connected ones first.
  List<BondedDevice> get devices => _devices;

  /// The system's Bluetooth settings could not be opened.
  bool get openFailed => _openFailed;

  /// Connected, wanted, but the iPhone doesn't share its notifications.
  bool get notificationsNotShared =>
      link.isConnected && showNotifications && !link.hasNotifications;

  bool get mediaNotShared => link.isConnected && showMedia && !link.hasMedia;

  Future<void> setEnabled(bool value) => _feature.settings.setEnabled(value);

  Future<void> setShowNotifications(bool value) =>
      _feature.settings.setShowNotifications(value);

  Future<void> setShowMedia(bool value) =>
      _feature.settings.setShowMedia(value);

  Future<void> setHidePreviews(bool value) =>
      _feature.settings.setHidePreviews(value);

  Future<void> choose(BondedDevice device) => _feature.chooseDevice(device);

  Future<void> forget() => _feature.forgetDevice();

  Future<void> retry() => _feature.refresh(force: true);

  Future<void> openBluetoothSettings() async {
    final opened = await _feature.openBluetoothSettings();
    _openFailed = !opened;
    _notify();
  }

  Future<void> loadDevices() async {
    final found = await _feature.devices();
    _devices = [
      ...found.where((device) => device.connected),
      ...found.where((device) => !device.connected),
    ];
    _notify();
  }

  /// Call when the app comes back to the front, such as from the system's
  /// Bluetooth settings: the iPhone may be paired now.
  Future<void> onResumed() async {
    await _feature.refresh();
    if (needsDevice) {
      await loadDevices();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _onChanged() {
    final needsDeviceNow = needsDevice;
    if (needsDeviceNow && !_neededDevice) {
      unawaited(loadDevices());
    }

    _neededDevice = needsDeviceNow;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
