import 'package:core/core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Drop's own secrets, in a file only this user can read inside the app's
/// support folder. Opened on first use, so nothing touches the disk until
/// LocalSend is used.
class SupportSecretStore implements SecretStore {
  static const _folder = 'drop';

  Future<SecretStore>? _store;

  @override
  Future<String?> read(String key) async => (await _open()).read(key);

  @override
  Future<void> write(String key, String value) async =>
      (await _open()).write(key, value);

  @override
  Future<void> delete(String key) async => (await _open()).delete(key);

  Future<SecretStore> _open() => _store ??= _create();

  Future<SecretStore> _create() async {
    final support = await getApplicationSupportDirectory();
    return FileSecretStore(p.join(support.path, _folder));
  }
}
