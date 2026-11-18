import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:engine/trust/forgotten_device.dart';
import 'package:engine/trust/trusted_device.dart';

/// The devices this one is paired with, and the ones the user removed, kept
/// in the [SecretStore].
class TrustStore {
  TrustStore._(this._store, this._devices, this._forgotten);

  static const _storageKey = 'ferret.trusted_devices';
  static const _forgottenKey = 'ferret.forgotten_devices';

  static Future<TrustStore> open(SecretStore store) async {
    final devices = <String, TrustedDevice>{};
    for (final json in await _readList(store, _storageKey)) {
      final device = TrustedDevice.fromJson(json);
      devices[device.id] = device;
    }

    final forgotten = <String, ForgottenDevice>{};
    for (final json in await _readList(store, _forgottenKey)) {
      final device = ForgottenDevice.fromJson(json);
      forgotten[device.id] = device;
    }

    return TrustStore._(store, devices, forgotten);
  }

  static Future<List<Map<String, dynamic>>> _readList(
    SecretStore store,
    String key,
  ) async {
    final saved = await store.read(key);
    if (saved == null) {
      return const [];
    }

    return (jsonDecode(saved) as List).cast<Map<String, dynamic>>();
  }

  final SecretStore _store;
  final Map<String, TrustedDevice> _devices;
  final Map<String, ForgottenDevice> _forgotten;
  final StreamController<List<TrustedDevice>> _changes = .broadcast();

  List<TrustedDevice> get devices => List.unmodifiable(_devices.values);

  /// Devices the user removed, newest decision per device.
  List<ForgottenDevice> get forgotten => List.unmodifiable(_forgotten.values);

  Stream<List<TrustedDevice>> get changes => _changes.stream;

  TrustedDevice? operator [](String deviceId) => _devices[deviceId];

  bool isTrusted(String deviceId) => _devices.containsKey(deviceId);

  /// When and how the user removed [deviceId], or null when they didn't.
  ForgottenDevice? forgottenOf(String deviceId) => _forgotten[deviceId];

  Future<void> save(TrustedDevice device) async {
    _devices[device.id] = device;
    await _persist();
  }

  Future<void> remove(String deviceId) async {
    if (_devices.remove(deviceId) == null) {
      return;
    }

    await _persist();
  }

  /// Remembers that the user removed a device. An older record of the same
  /// device is replaced, a newer one is kept.
  Future<void> forget(ForgottenDevice device) async {
    final known = _forgotten[device.id];
    if (known != null && !known.at.isBefore(device.at)) {
      return;
    }

    _forgotten[device.id] = device;
    await _persistForgotten();
  }

  /// Lets [deviceId] back in, for when the user pairs it again.
  Future<void> unforget(String deviceId) async {
    if (_forgotten.remove(deviceId) == null) {
      return;
    }

    await _persistForgotten();
  }

  /// Lifts every record of a device having dropped this one, for when the
  /// user pairs by hand again and so rejoins their devices.
  Future<void> unforgetDroppedBy() async {
    final before = _forgotten.length;
    _forgotten.removeWhere((_, device) => device.by == .them);
    if (_forgotten.length == before) {
      return;
    }

    await _persistForgotten();
  }

  Future<void> _persist() async {
    final json = [for (final device in _devices.values) device.toJson()];
    await _store.write(_storageKey, jsonEncode(json));
    _changes.add(devices);
  }

  Future<void> _persistForgotten() async {
    final json = [for (final device in _forgotten.values) device.toJson()];
    await _store.write(_forgottenKey, jsonEncode(json));
  }
}
