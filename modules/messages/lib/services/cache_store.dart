import 'dart:io';

/// Where a computer saves each phone's texts between runs.
abstract interface class CacheStore {
  /// Phones with saved texts.
  Future<List<String>> deviceIds();

  Future<String?> read(String deviceId);

  Future<void> write(String deviceId, String contents);

  Future<void> delete(String deviceId);
}

/// Saves into `messages/<device id>.json` under a directory such as the
/// app's support folder, readable only by this user.
class FileCacheStore implements CacheStore {
  FileCacheStore(this._directory);

  static const _extension = '.json';

  final Future<String> Function() _directory;
  Directory? _folder;

  @override
  Future<List<String>> deviceIds() async {
    final folder = await _resolve();
    if (!await folder.exists()) {
      return const [];
    }

    return [
      await for (final entry in folder.list())
        if (entry is File && entry.path.endsWith(_extension))
          _deviceIdOf(entry.uri.pathSegments.last),
    ];
  }

  @override
  Future<String?> read(String deviceId) async {
    final file = await _fileFor(deviceId);
    if (!await file.exists()) {
      return null;
    }

    return file.readAsString();
  }

  @override
  Future<void> write(String deviceId, String contents) async {
    final file = await _fileFor(deviceId);
    await file.parent.create(recursive: true);

    final partial = File('${file.path}.partial');
    await partial.writeAsString(contents, flush: true);
    await partial.rename(file.path);
  }

  @override
  Future<void> delete(String deviceId) async {
    final file = await _fileFor(deviceId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _resolve() async {
    if (_folder case final folder?) {
      return folder;
    }

    final folder = Directory('${await _directory()}/messages');
    _folder = folder;
    return folder;
  }

  Future<File> _fileFor(String deviceId) async {
    final folder = await _resolve();
    return File('${folder.path}/${_safeName(deviceId)}$_extension');
  }

  /// Device ids are hex today; anything else is kept out of the path.
  static String _safeName(String deviceId) =>
      deviceId.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');

  static String _deviceIdOf(String fileName) =>
      fileName.substring(0, fileName.length - _extension.length);
}

/// Keeps saved texts in memory, for tests and devices that shouldn't save.
class MemoryCacheStore implements CacheStore {
  final Map<String, String> files = {};

  @override
  Future<List<String>> deviceIds() async => files.keys.toList();

  @override
  Future<String?> read(String deviceId) async => files[deviceId];

  @override
  Future<void> write(String deviceId, String contents) async =>
      files[deviceId] = contents;

  @override
  Future<void> delete(String deviceId) async => files.remove(deviceId);
}
