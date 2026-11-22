import 'dart:convert';

import 'package:core/core.dart';
import 'package:engine/connection/known_networks.dart';
import 'package:engine/identity/device_identity.dart';
import 'package:engine/trust/trust_store.dart';
import 'package:protocol/protocol.dart' show Platform;
import 'package:transport/transport.dart';

/// Ties this device's key to the computer it was made on.
///
/// Migration Assistant, a restored backup or a copied data folder brings
/// the key along to another computer. Two computers with one key would both
/// answer as the same device, and the paired devices could not tell them
/// apart. So the copy starts over as a new device: a new key, no pairings,
/// and a note of what was paired, for pairing those again.
///
/// The same computer after a reinstall keeps its key: the machine id comes
/// from the hardware (Mac) or the system install (Windows, Linux).
abstract final class IdentityHome {
  /// The machine the key was made on, hashed. Kept beside the pairings, so
  /// a copy brings it along.
  static const storageKey = 'ferret.identity.home';

  /// What was paired when this copy started over: a [MovedFrom].
  static const movedKey = 'identity.moved_from';

  /// Checks [machineId] against the one saved with the key. On another
  /// computer it forgets the key and the pairings here and returns what was
  /// paired. Without a machine id (phones, where the system keeps keys from
  /// moving) it does nothing.
  static Future<MovedFrom?> settle({
    required SecretStore secrets,
    required SettingsStore settings,
    required String? machineId,
    DateTime Function() now = DateTime.now,
  }) async {
    final id = machineId?.trim() ?? '';
    if (id.isEmpty) {
      return null;
    }

    final home = await homeOf(id);
    final saved = await secrets.read(storageKey);
    if (saved == home) {
      return null;
    }

    if (saved == null) {
      // First start with this check, such as after an update: this is home.
      await secrets.write(storageKey, home);
      return null;
    }

    final trust = await TrustStore.open(secrets);
    final moved = MovedFrom(
      at: now(),
      devices: [
        for (final device in trust.devices)
          MovedDevice(
            id: device.id,
            name: device.name,
            platform: device.platform,
          ),
      ],
    );
    await secrets.delete(DeviceIdentity.storageKey);
    await trust.clear();
    await secrets.write(storageKey, home);
    await settings.set(KnownNetworks.settingsKey, const <String>[]);
    await settings.set(KnownNetworks.learningUntilKey, null);
    await settings.set(movedKey, moved.toJson());
    printWarning(
      'Ferret was copied from another computer; starting as a new device',
    );
    return moved;
  }

  /// What [machineId] is saved as: never the id itself.
  static Future<String> homeOf(String machineId) async {
    final digest = await NoiseCrypto.hash(
      utf8.encode('ferret.home:$machineId'),
    );
    return base64UrlEncode(digest.sublist(0, 18));
  }

  /// What was paired before this copy started over, or null.
  static MovedFrom? movedFrom(SettingsStore settings) =>
      switch (settings.get<Object>(movedKey)) {
        final Map<dynamic, dynamic> json => MovedFrom.tryParse(json),
        _ => null,
      };

  /// Puts the note away.
  static Future<void> dismiss(SettingsStore settings) =>
      settings.set(movedKey, null);
}

/// What a copied Ferret had paired, for pairing those devices again.
class MovedFrom {
  const MovedFrom({required this.at, required this.devices});

  static MovedFrom? tryParse(Map<dynamic, dynamic> json) {
    final at = DateTime.tryParse('${json['at']}');
    final devices = json['devices'];
    if (at == null || devices is! List) {
      return null;
    }

    return MovedFrom(
      at: at,
      devices: [
        for (final device in devices)
          if (device is Map) ?MovedDevice.tryParse(device),
      ],
    );
  }

  final DateTime at;
  final List<MovedDevice> devices;

  Map<String, Object?> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'devices': [for (final device in devices) device.toJson()],
  };
}

/// One device a copied Ferret had paired.
class MovedDevice {
  const MovedDevice({
    required this.id,
    required this.name,
    required this.platform,
  });

  static MovedDevice? tryParse(Map<dynamic, dynamic> json) {
    final (id, name) = (json['id'], json['name']);
    if (id is! String || name is! String) {
      return null;
    }

    final platform = switch (json['platform']) {
      final int value => Platform.valueOf(value),
      _ => null,
    };
    return MovedDevice(
      id: id,
      name: name,
      platform: platform ?? .PLATFORM_UNSPECIFIED,
    );
  }

  final String id;
  final String name;
  final Platform platform;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'platform': platform.value,
  };
}
