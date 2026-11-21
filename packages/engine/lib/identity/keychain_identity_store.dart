import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/identity/device_identity.dart';

/// Keeps this device's private key in the system keychain and everything
/// else, such as the paired devices, in [file].
///
/// [file] then holds only a marker for the key: `keychain:` and the device
/// id, which names the keychain item and checks what comes back from it.
/// Each data folder's key gets its own item, so a second data folder (or a
/// test run) never touches another one's key.
///
/// A key still in [file] moves on the first read: written to the keychain,
/// read back and compared, and only then replaced by the marker. When any
/// step fails the key stays in [file] and Ferret tries again next start, so
/// the identity is never lost on the way.
class KeychainIdentityStore implements SecretStore {
  KeychainIdentityStore({
    required this.file,
    required this.keychain,
    this.moves = true,
    this.readRetries = const [
      Duration(milliseconds: 300),
      Duration(seconds: 1),
    ],
  });

  /// Where everything but the key lives, and the marker.
  final SecretStore file;

  /// The keychain, one item per account.
  final SecretStore keychain;

  /// Whether a key in [file] moves to the keychain, and a new key goes
  /// there. Off for builds whose signature changes with every build, which
  /// the keychain would ask about each time. A marker is read either way.
  final bool moves;

  /// The waits between keychain reads that failed, before giving up.
  final List<Duration> readRetries;

  static const markerPrefix = 'keychain:';

  /// Where the marker of a key that vanished from the keychain is kept.
  static const lostKey = '${DeviceIdentity.storageKey}.lost';

  /// The keychain account for the key of [deviceId].
  static String accountFor(String deviceId) => 'identity.$deviceId';

  /// The device id in [saved] when it is a marker, else null.
  static String? markedDeviceId(String saved) {
    if (!saved.startsWith(markerPrefix)) {
      return null;
    }

    final deviceId = saved.substring(markerPrefix.length);
    return deviceId.isEmpty ? null : deviceId;
  }

  static bool _isKey(String key) => key == DeviceIdentity.storageKey;

  @override
  Future<String?> read(String key) async {
    final saved = await file.read(key);
    if (!_isKey(key) || saved == null) {
      return saved;
    }

    if (markedDeviceId(saved) case final deviceId?) {
      final value = await _readKeychain(deviceId);
      if (value == null) {
        // Someone deleted the item: the key is gone, and only a new one
        // lets Ferret start. The marker stays beside it, for the record.
        printError(
          'The device key is gone from the keychain; making a new one',
        );
        await file.write(lostKey, saved);
      }

      return value;
    }

    if (moves) {
      await _move(saved);
    }

    return saved;
  }

  @override
  Future<void> write(String key, String value) async {
    if (!_isKey(key) || !moves) {
      return file.write(key, value);
    }

    if (await _store(value) case final deviceId?) {
      return file.write(key, '$markerPrefix$deviceId');
    }

    await file.write(key, value);
  }

  @override
  Future<void> delete(String key) async {
    if (_isKey(key)) {
      final saved = await file.read(key);
      if (saved != null) {
        if (markedDeviceId(saved) case final deviceId?) {
          await keychain.delete(accountFor(deviceId));
        }
      }
    }

    await file.delete(key);
  }

  /// Moves [saved] to the keychain; [file] keeps it when that fails.
  Future<void> _move(String saved) async {
    final deviceId = await _store(saved);
    if (deviceId == null) {
      return;
    }

    await file.write(DeviceIdentity.storageKey, '$markerPrefix$deviceId');
    printLog('The device key moved to the keychain');
  }

  /// Writes [saved] to the keychain and reads it back. Returns its device
  /// id when the keychain holds exactly [saved], else null.
  Future<String?> _store(String saved) async {
    try {
      final deviceId = (await DeviceIdentity.fromSaved(saved)).deviceId;
      final account = accountFor(deviceId);
      await keychain.write(account, saved);
      final back = await keychain.read(account);
      if (back != saved) {
        printWarning('The keychain gave back another key; keeping the file');
        return null;
      }

      return deviceId;
    } on Object catch (error) {
      printWarning('The device key stays in its file for now', error);
      return null;
    }
  }

  /// The key the marker for [deviceId] stands for, or null when the
  /// keychain has no such item. Throws when the keychain won't answer, or
  /// gives another key: making a new identity then would unpair every
  /// device for nothing, so Ferret stops instead.
  Future<String?> _readKeychain(String deviceId) async {
    final account = accountFor(deviceId);
    Object? failure;
    for (var attempt = 0; attempt <= readRetries.length; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(readRetries[attempt - 1]);
      }

      try {
        final value = await keychain.read(account);
        if (value == null) {
          return null;
        }

        final found = (await DeviceIdentity.fromSaved(value)).deviceId;
        if (found != deviceId) {
          throw KeychainIdentityException(
            'The keychain item $account holds the key of $found',
          );
        }

        return value;
      } on KeychainIdentityException {
        rethrow;
      } on Object catch (error) {
        failure = error;
      }
    }

    throw KeychainIdentityException(
      'The keychain did not give the device key: ${Log.describe(failure!)}',
    );
  }
}

/// The device key is in the keychain, but the keychain didn't give it.
class KeychainIdentityException implements Exception {
  const KeychainIdentityException(this.message);

  final String message;

  @override
  String toString() => 'KeychainIdentityException: $message';
}
