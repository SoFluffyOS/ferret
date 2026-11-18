import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:path/path.dart' as p;

/// Drop's own secrets, in a file only this user can read inside Ferret's
/// secrets folder. Opened on first use, so nothing touches the disk until
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
    final paths = await AppPaths.get();
    final folder = await paths.create(p.join(paths.secrets, _folder));
    return FileSecretStore(folder.path);
  }
}
