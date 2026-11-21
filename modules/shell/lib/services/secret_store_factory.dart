import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Picks where the device key and pairings live: the platform keystore on
/// phones; on computers a file only this user can read in [paths]' secrets
/// folder, with the device key itself in the login keychain on a Mac.
///
/// Windows (DPAPI) and Linux (Secret Service) keep the key in the file for
/// now.
Future<SecretStore> createSecretStore(FerretPaths paths) async {
  if (Platform.isAndroid || Platform.isIOS) {
    return const KeystoreSecretStore();
  }

  final directory = await paths.create(paths.secrets);
  final file = FileSecretStore(directory.path);
  if (!Platform.isMacOS) {
    return file;
  }

  return KeychainIdentityStore(
    file: file,
    keychain: const MacKeychainStore(),
    // A debug build's signature changes with every build, and the keychain
    // asks about each new one.
    moves: !kDebugMode,
  );
}

/// A [SecretStore] in the Android Keystore or the iOS Keychain.
class KeystoreSecretStore implements SecretStore {
  const KeystoreSecretStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Generic passwords in the Mac's login keychain, under the service
/// `io.sofluffy.ferret`, one account per key: never synced to iCloud, never
/// moved to another Mac, readable after the first unlock.
///
/// It's the login keychain, not the data protection one: that one needs a
/// provisioning profile, which a Developer ID app outside the App Store
/// doesn't have. The login keychain lets the app that wrote an item read it
/// without a question, and asks before any other app may.
class MacKeychainStore implements SecretStore {
  const MacKeychainStore();

  static const service = 'io.sofluffy.ferret';

  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(
      accountName: service,
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
      usesDataProtectionKeychain: false,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
