import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:engine/trust/trusted_device.dart';

/// The devices this one is paired with, kept in the [SecretStore].
class TrustStore {
  TrustStore._(this._store, this._devices);

  static const _storageKey = 'ferret.trusted_devices';

  static Future<TrustStore> open(SecretStore store) async {
    final saved = await store.read(_storageKey);
    final devices = <String, TrustedDevice>{};
    if (saved != null) {
      for (final json
          in (jsonDecode(saved) as List).cast<Map<String, dynamic>>()) {
        final device = TrustedDevice.fromJson(json);
        devices[device.id] = device;
      }
    }

    return TrustStore._(store, devices);
  }

  final SecretStore _store;
  final Map<String, TrustedDevice> _devices;
  final StreamController<List<TrustedDevice>> _changes = .broadcast();

  List<TrustedDevice> get devices => List.unmodifiable(_devices.values);

  Stream<List<TrustedDevice>> get changes => _changes.stream;

  TrustedDevice? operator [](String deviceId) => _devices[deviceId];

  bool isTrusted(String deviceId) => _devices.containsKey(deviceId);

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

  Future<void> _persist() async {
    final json = [for (final device in _devices.values) device.toJson()];
    await _store.write(_storageKey, jsonEncode(json));
    _changes.add(devices);
  }
}
