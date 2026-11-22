import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/logging/logging.dart';
import 'package:path/path.dart' as p;

/// User settings as JSON values under snake_case keys, such as
/// `clipboard.sync_images`. Values that are enums are stored by name.
abstract interface class SettingsStore {
  T? get<T>(String key);

  Future<void> set(String key, Object? value);

  /// Fires with the key that changed.
  Stream<String> get changes;
}

/// A [SettingsStore] kept in memory, for tests.
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, Object?>? initial])
    : _values = {...?initial};

  final Map<String, Object?> _values;
  final StreamController<String> _changes = .broadcast();

  @override
  T? get<T>(String key) => switch (_values[key]) {
    final T value => value,
    _ => null,
  };

  @override
  Future<void> set(String key, Object? value) async {
    _values[key] = value;
    _changes.add(key);
  }

  @override
  Stream<String> get changes => _changes.stream;
}

/// A [SettingsStore] saved as `settings.json` in [directory].
class JsonFileSettingsStore implements SettingsStore {
  JsonFileSettingsStore._(this._file, this._values);

  static Future<JsonFileSettingsStore> open(String directory) async {
    final file = File(p.join(directory, 'settings.json'));
    if (!await file.exists()) {
      return JsonFileSettingsStore._(file, {});
    }

    Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FormatException catch (error) {
      // Settings are preferences: a file cut short starts them over
      // instead of keeping Ferret from starting. The old one stays beside.
      printWarning('settings.json did not read; starting it over', error);
      await file.copy('${file.path}.unreadable');
    }

    final values = switch (decoded) {
      final Map<String, dynamic> map => map,
      _ => <String, dynamic>{},
    };
    return JsonFileSettingsStore._(file, values);
  }

  final File _file;
  final Map<String, dynamic> _values;
  final StreamController<String> _changes = .broadcast();

  /// Saves one at a time, each through a temporary file, so two settings
  /// changed at once never leave the file half written.
  Future<void> _writing = Future.value();

  @override
  T? get<T>(String key) => switch (_values[key]) {
    final T value => value,
    _ => null,
  };

  @override
  Future<void> set(String key, Object? value) async {
    _values[key] = value;
    _changes.add(key);

    final write = _writing.then((_) => _save());
    _writing = write.then<void>((_) {}, onError: (Object _) {});
    await write;
  }

  Future<void> _save() async {
    await _file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(encoder.convert(_values), flush: true);
    await temporary.rename(_file.path);
  }

  @override
  Stream<String> get changes => _changes.stream;
}
