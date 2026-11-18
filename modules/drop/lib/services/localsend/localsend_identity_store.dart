import 'package:core/core.dart';
import 'package:interop_localsend/interop_localsend.dart';

/// Keeps this device's LocalSend certificate, so its fingerprint stays the
/// same and LocalSend devices recognise it next time.
class LocalSendIdentityStore {
  LocalSendIdentityStore(this._secrets);

  static const _key = 'drop.localsend_identity';

  /// Without a secret store the identity lives until the app closes.
  final SecretStore? _secrets;
  Future<LocalSendIdentity>? _identity;

  /// The stored identity, or a new one. Making one takes a moment.
  Future<LocalSendIdentity> load() => _identity ??= _loadOrCreate();

  Future<LocalSendIdentity> _loadOrCreate() async {
    final stored = await _read();
    if (stored != null) {
      return stored;
    }

    final identity = await LocalSendIdentity.generate();
    await _write(identity);
    return identity;
  }

  Future<LocalSendIdentity?> _read() async {
    try {
      final stored = await _secrets?.read(_key);
      if (stored == null) {
        return null;
      }

      return LocalSendIdentity.decode(stored);
    } on Object catch (error) {
      printWarning(
        'Could not read the LocalSend identity: ${error.runtimeType}',
      );
      return null;
    }
  }

  Future<void> _write(LocalSendIdentity identity) async {
    try {
      await _secrets?.write(_key, identity.encode());
    } on Object catch (error) {
      printWarning(
        'Could not store the LocalSend identity: ${error.runtimeType}',
      );
    }
  }
}
