/// Keeps small secrets such as the device's private key and the list of
/// paired devices. Apps back it with the platform keychain; the CLI uses a
/// file only the user can read.
abstract interface class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// A [SecretStore] kept in memory, for tests.
class MemorySecretStore implements SecretStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
