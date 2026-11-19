import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Thumbnails from phones, kept on this computer so a grid opens fast and
/// the phone isn't asked twice. One folder per phone under [root]; the
/// least recently used ones go once they pass [maxBytes] in all.
class ThumbnailCache {
  ThumbnailCache(this.root, {this.maxBytes = defaultMaxBytes});

  static const defaultMaxBytes = 64 * 1024 * 1024;

  final String root;
  final int maxBytes;

  Map<String, _CachedFile>? _index;
  int _total = 0;
  int _clock = 0;

  /// Bytes held right now.
  Future<int> get totalBytes async {
    await _load();
    return _total;
  }

  Future<Uint8List?> read(String deviceId, String photoId, int maxPx) async {
    final index = await _load();
    final path = _pathOf(deviceId, photoId, maxPx);
    final cached = index[path];
    if (cached == null) {
      return null;
    }

    try {
      final bytes = await File(path).readAsBytes();
      cached.used = ++_clock;
      return bytes;
    } on FileSystemException {
      _drop(path);
      return null;
    }
  }

  Future<void> write(
    String deviceId,
    String photoId,
    int maxPx,
    Uint8List bytes,
  ) async {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      return;
    }

    final index = await _load();
    final path = _pathOf(deviceId, photoId, maxPx);
    try {
      await File(path).parent.create(recursive: true);
      await File(path).writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (error) {
      printWarning('Photos: could not cache a thumbnail: ${error.osError}');
      return;
    }

    _drop(path);
    index[path] = _CachedFile(bytes.length, ++_clock);
    _total += bytes.length;
    await _evict();
  }

  /// Deletes everything from [deviceId], such as once it is unpaired.
  Future<void> clearDevice(String deviceId) async {
    final index = await _load();
    final folder = _folderOf(deviceId);
    for (final path in [...index.keys]) {
      if (p.isWithin(folder, path)) {
        _drop(path);
      }
    }

    await _deleteFolder(folder);
  }

  /// Deletes the folders of phones that aren't in [deviceIds].
  Future<void> keepOnly(Set<String> deviceIds) async {
    final directory = Directory(root);
    if (!await directory.exists()) {
      return;
    }

    final kept = {for (final id in deviceIds) _folderOf(id)};
    await for (final entity in directory.list()) {
      if (entity is! Directory || kept.contains(entity.path)) {
        continue;
      }

      final index = await _load();
      for (final path in [...index.keys]) {
        if (p.isWithin(entity.path, path)) {
          _drop(path);
        }
      }
      await _deleteFolder(entity.path);
    }
  }

  Future<Map<String, _CachedFile>> _load() async {
    if (_index case final index?) {
      return index;
    }

    final index = <String, _CachedFile>{};
    _index = index;
    final directory = Directory(root);
    if (!await directory.exists()) {
      return index;
    }

    final found = <(String, int, DateTime)>[];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }

      final stat = await entity.stat();
      found.add((entity.path, stat.size, stat.modified));
    }
    found.sort((a, b) => a.$3.compareTo(b.$3));
    for (final (path, size, _) in found) {
      index[path] = _CachedFile(size, ++_clock);
      _total += size;
    }
    await _evict();
    return index;
  }

  Future<void> _evict() async {
    final index = _index;
    if (index == null || _total <= maxBytes) {
      return;
    }

    final byAge = index.entries.toList()
      ..sort((a, b) => a.value.used.compareTo(b.value.used));
    for (final entry in byAge) {
      if (_total <= maxBytes) {
        return;
      }

      _drop(entry.key);
      try {
        await File(entry.key).delete();
      } on FileSystemException {
        continue;
      }
    }
  }

  void _drop(String path) {
    final removed = _index?.remove(path);
    if (removed == null) {
      return;
    }

    _total -= removed.size;
  }

  String _folderOf(String deviceId) => p.join(root, _key(deviceId));

  String _pathOf(String deviceId, String photoId, int maxPx) =>
      p.join(_folderOf(deviceId), '${_key(photoId)}_$maxPx.jpg');

  static String _key(String value) =>
      sha256.convert(utf8.encode(value)).toString().substring(0, 32);

  static Future<void> _deleteFolder(String path) async {
    try {
      await Directory(path).delete(recursive: true);
    } on FileSystemException {
      return;
    }
  }
}

class _CachedFile {
  _CachedFile(this.size, this.used);

  final int size;
  int used;
}
