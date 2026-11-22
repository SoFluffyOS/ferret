import 'dart:convert';
import 'dart:io';

import 'package:core/storage/secret_store.dart';
import 'package:path/path.dart' as p;

/// A [SecretStore] in one JSON file readable only by the current user.
class FileSecretStore implements SecretStore {
  FileSecretStore(String directory)
    : _file = File(p.join(directory, 'secrets.json'));

  final File _file;
  Future<Map<String, String>>? _loading;

  /// Writes one at a time: two at once shared the temporary file, and the
  /// second rename failed after the first had moved it.
  Future<void> _writing = Future.value();

  @override
  Future<String?> read(String key) async {
    final values = await _load();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    final values = await _load();
    values[key] = value;
    await _save(values);
  }

  @override
  Future<void> delete(String key) async {
    final values = await _load();
    values.remove(key);
    await _save(values);
  }

  /// Read once: calls at the same moment share the same map, so no write
  /// lands in a map that another read replaced.
  Future<Map<String, String>> _load() => _loading ??= _read();

  Future<Map<String, String>> _read() async {
    if (!await _file.exists()) {
      return {};
    }

    final decoded =
        jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> _save(Map<String, String> values) {
    final write = _writing.then((_) => _write(values));
    _writing = write.then<void>((_) {}, onError: (Object _) {});
    return write;
  }

  Future<void> _write(Map<String, String> values) async {
    await _file.parent.create(recursive: true);

    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(jsonEncode(values), flush: true);
    // Phones keep app files private already, and iOS can't start `chmod`.
    if (Platform.isMacOS || Platform.isLinux) {
      await Process.run('chmod', ['600', temporary.path]);
    }

    await temporary.rename(_file.path);
  }
}
