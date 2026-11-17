import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Picks where the device key and pairings live: the platform keystore on
/// phones, a file only this user can read in the app's private folder on
/// desktops.
Future<SecretStore> createSecretStore() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return const KeystoreSecretStore();
  }

  final directory = await getApplicationSupportDirectory();
  return FileSecretStore(directory.path);
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
