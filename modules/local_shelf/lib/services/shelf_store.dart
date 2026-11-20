import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/services/shelf_names.dart';
import 'package:path/path.dart' as p;

/// What is on the shelf, newest first, kept in [folder] across restarts:
/// an index, and the files Ferret keeps for text, links and pictures. The
/// person's own files are only pointed at, never copied, and never
/// deleted. Nothing here leaves this computer.
class ShelfStore {
  ShelfStore(this.folder, {DateTime Function()? clock, this.limit = 50})
    : _clock = clock ?? DateTime.now;

  /// Such as `~/.sofluffy/ferret/cache/shelf`.
  final String folder;

  /// How many items the shelf keeps. Copies beyond it go, oldest first;
  /// what the person dropped stays until they take it off.
  final int limit;

  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final Random _random = Random.secure();
  List<ShelfItem> _items = const [];
  Future<void> _queue = Future.value();

  List<ShelfItem> get items => _items;

  /// Fires whenever [items] changed.
  Stream<void> get changes => _changes.stream;

  String get _indexPath => p.join(folder, 'shelf.json');

  /// Reads what was on the shelf, then checks it is all still there.
  Future<void> load() => _serial(() async {
    final index = File(_indexPath);
    if (await index.exists()) {
      try {
        final stored = jsonDecode(await index.readAsString());
        _items = [
          if (stored case {'items': final List<Object?> items})
            for (final json in items) ?ShelfItem.fromJson(json),
        ];
      } on Object catch (error) {
        printWarning('Could not read the shelf', error);
      }
    }

    await _check();
  });

  /// Looks again whether every file is still there: one of the person's
  /// own that moved shows as missing, and a kept file that is gone takes
  /// its item with it.
  Future<void> refresh() => _serial(_check);

  /// Keeps [paths]: files and folders are pointed at where they are, and
  /// those in a temporary folder are copied in first.
  Future<List<ShelfItem>> keepFiles(
    List<String> paths, {
    required ShelfSource source,
  }) => _serial(() async {
    final kept = <ShelfItem>[];
    for (final path in paths) {
      final item = await _fileItem(path, source: source);
      if (item != null) {
        kept.add(_put(item));
      }
    }

    await _finish();
    return kept;
  });

  /// Keeps [text], or a web link when [isLink], in a file of its own.
  Future<ShelfItem?> keepText(
    String text, {
    required bool isLink,
    required ShelfSource source,
    String? fromDeviceId,
  }) => _serial(() async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final kind = switch (isLink) {
      true => ShelfKind.link,
      false => ShelfKind.text,
    };
    final key = '${kind.name}:${_hash(utf8.encode(text))}';
    if (_bump(key, source)) {
      await _finish();
      return _items.first;
    }

    final id = _newId();
    final (fileName, contents) = switch (isLink) {
      true => (ShelfNames.linkFile(trimmed), ShelfNames.linkContents(trimmed)),
      false => (ShelfNames.textFile(text), text),
    };
    final file = File(p.join(_itemFolder(id), fileName));
    await file.parent.create(recursive: true);
    await file.writeAsString(contents, flush: true);

    final item = _put(
      ShelfItem(
        id: id,
        kind: kind,
        path: file.path,
        name: switch (isLink) {
          true => trimmed,
          false => ShelfNames.oneLine(text),
        },
        key: key,
        addedAt: _clock(),
        source: source,
        text: switch (isLink) {
          true => trimmed,
          false => ShelfNames.oneLine(text, length: 200),
        },
        fromDeviceId: fromDeviceId,
        isCached: true,
      ),
    );
    await _finish();
    return item;
  });

  /// Keeps a picture's [bytes], of type [mime], in a file of its own.
  Future<ShelfItem?> keepImage(
    Uint8List bytes, {
    required String mime,
    required ShelfSource source,
    required String name,
    String? fromDeviceId,
  }) => _serial(() async {
    if (bytes.isEmpty) {
      return null;
    }

    final key = 'image:${_hash(bytes)}';
    if (_bump(key, source)) {
      await _finish();
      return _items.first;
    }

    final id = _newId();
    final file = File(p.join(_itemFolder(id), ShelfNames.imageFile(mime)));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    final item = _put(
      ShelfItem(
        id: id,
        kind: .image,
        path: file.path,
        name: name,
        key: key,
        addedAt: _clock(),
        source: source,
        fromDeviceId: fromDeviceId,
        isCached: true,
      ),
    );
    await _finish();
    return item;
  });

  /// Takes [ids] off the shelf. Files Ferret kept for them go too; the
  /// person's own stay where they are.
  Future<void> remove(Iterable<String> ids) => _serial(() async {
    final gone = ids.toSet();
    final removed = [
      for (final item in _items)
        if (gone.contains(item.id)) item,
    ];
    if (removed.isEmpty) {
      return;
    }

    _items = [
      for (final item in _items)
        if (!gone.contains(item.id)) item,
    ];
    await _deleteKept(removed);
    await _finish();
  });

  /// Takes everything off the shelf.
  Future<void> clear() => _serial(() async {
    final removed = _items;
    if (removed.isEmpty) {
      return;
    }

    _items = const [];
    await _deleteKept(removed);
    await _finish();
  });

  Future<ShelfItem?> _fileItem(
    String path, {
    required ShelfSource source,
  }) async {
    final type = await FileSystemEntity.type(path);
    if (type == .notFound) {
      return null;
    }

    final isFolder = type == .directory;
    final kind = switch ((isFolder, ShelfNames.isImage(path))) {
      (true, _) => ShelfKind.folder,
      (false, true) => ShelfKind.image,
      (false, false) => ShelfKind.file,
    };
    final name = p.basename(path);
    if (!ShelfNames.isTemporary(path) || isFolder) {
      final key = 'path:${p.normalize(path)}';
      if (_bump(key, source)) {
        return null;
      }

      return ShelfItem(
        id: _newId(),
        kind: kind,
        path: path,
        name: name,
        key: key,
        addedAt: _clock(),
        source: source,
      );
    }

    final key = 'drop:$name:${await File(path).length()}';
    if (_bump(key, source)) {
      return null;
    }

    final id = _newId();
    final copy = File(p.join(_itemFolder(id), name));
    await copy.parent.create(recursive: true);
    await File(path).copy(copy.path);
    return ShelfItem(
      id: id,
      kind: kind,
      path: copy.path,
      name: name,
      key: key,
      addedAt: _clock(),
      source: source,
      isCached: true,
    );
  }

  /// Moves the item with [key] to the top, as if it were new. Something
  /// dropped that was a copy becomes the person's, kept until removed.
  bool _bump(String key, ShelfSource source) {
    final index = _items.indexWhere((item) => item.key == key);
    if (index < 0) {
      return false;
    }

    final item = _items[index];
    final bumped = item.copyWith(
      addedAt: _clock(),
      source: switch (source) {
        .dropped => ShelfSource.dropped,
        .copied => item.source,
      },
    );
    _items = [
      bumped,
      for (final (other, existing) in _items.indexed)
        if (other != index) existing,
    ];
    return true;
  }

  ShelfItem _put(ShelfItem item) {
    _items = [item, ..._items];
    return item;
  }

  /// Copies beyond [limit] go, oldest first.
  Future<void> _trim() async {
    final removed = <ShelfItem>[];
    var items = _items;
    while (items.length > limit) {
      final oldestCopy = items.lastIndexWhere(
        (item) => item.source == .copied,
      );
      if (oldestCopy < 0) {
        break;
      }

      removed.add(items[oldestCopy]);
      items = [
        for (final (index, item) in items.indexed)
          if (index != oldestCopy) item,
      ];
    }

    _items = items;
    await _deleteKept(removed);
  }

  Future<void> _check() async {
    final checked = <ShelfItem>[];
    final gone = <ShelfItem>[];
    for (final item in _items) {
      final exists = await FileSystemEntity.type(item.path) != .notFound;
      if (!exists && item.isCached) {
        gone.add(item);
        continue;
      }

      checked.add(item.copyWith(isMissing: !exists));
    }

    _items = checked;
    await _deleteKept(gone);
    if (gone.isNotEmpty) {
      await _save();
    }

    _changes.add(null);
  }

  Future<void> _finish() async {
    await _trim();
    await _save();
    _changes.add(null);
  }

  Future<void> _save() async {
    try {
      await Directory(folder).create(recursive: true);
      final temporary = File('$_indexPath.tmp');
      await temporary.writeAsString(
        jsonEncode({
          'items': [for (final item in _items) item.toJson()],
        }),
        flush: true,
      );
      await temporary.rename(_indexPath);
    } on Object catch (error) {
      printWarning('Could not save the shelf', error);
    }
  }

  Future<void> _deleteKept(List<ShelfItem> items) async {
    for (final item in items) {
      if (!item.isCached) {
        continue;
      }

      final itemFolder = Directory(_itemFolder(item.id));
      try {
        if (await itemFolder.exists()) {
          await itemFolder.delete(recursive: true);
        }
      } on Object catch (error) {
        printWarning('Could not delete a shelf file', error);
      }
    }
  }

  String _itemFolder(String id) => p.join(folder, 'items', id);

  String _newId() {
    final bytes = List<int>.generate(8, (_) => _random.nextInt(256));
    return [
      for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  static String _hash(List<int> bytes) => sha256.convert(bytes).toString();

  /// Runs [work] after whatever runs already, so changes never overlap.
  Future<T> _serial<T>(Future<T> Function() work) {
    final result = _queue.then((_) => work());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }
}
