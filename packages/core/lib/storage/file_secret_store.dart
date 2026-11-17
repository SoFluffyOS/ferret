import 'dart:convert';
import 'dart:io';

import 'package:core/storage/secret_store.dart';
import 'package:path/path.dart' as p;

/// A [SecretStore] in one JSON file readable only by the current user.
class FileSecretStore implements SecretStore {
  FileSecretStore(String directory)
    : _file = File(p.join(directory, 'secrets.json'));

  final File _file;
  Map<String, String>? _cache;

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

  Future<Map<String, String>> _load() async {
    if (_cache case final cache?) {
      return cache;
    }

    if (!await _file.exists()) {
      return _cache = {};
    }

    final decoded =
        jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
    return _cache = decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> _save(Map<String, String> values) async {
    await _file.parent.create(recursive: true);

    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(jsonEncode(values), flush: true);
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', temporary.path]);
    }

    await temporary.rename(_file.path);
  }
}
