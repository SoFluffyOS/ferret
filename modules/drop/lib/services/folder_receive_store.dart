import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:drop/services/file_names.dart';
import 'package:drop/services/receive_part.dart';
import 'package:drop/services/receive_store.dart';
import 'package:path/path.dart' as p;

/// Saves received files into a plain folder, such as ~/Downloads/Ferret.
/// Parts live in a hidden folder inside it, so the final move is a rename.
class FolderReceiveStore implements ReceiveStore {
  FolderReceiveStore(this.folder, {this.freeSpace});

  /// Resolves the receive folder each time, so a changed setting applies to
  /// the next file.
  final Future<String> Function() folder;

  /// Reads the bytes free on the volume that holds a path. Without it the
  /// free space is unknown and every offer may go ahead.
  final Future<int?> Function(String path)? freeSpace;

  static const _partsFolder = '.ferret-partial';
  static const _maxAttempts = 10000;

  /// Folders claimed by transfers under way, so two that arrive at once
  /// never share one, even before either wrote a file.
  final Set<String> _claimed = {};

  @override
  Future<Directory> partsDirectory() async {
    final parts = Directory(p.join(await folder(), _partsFolder));
    await parts.create(recursive: true);
    return parts;
  }

  @override
  Future<String> reserveFolder(String name) async {
    final base = await folder();
    await Directory(base).create(recursive: true);

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final candidate = FileNames.numberedFolder(name, attempt);
      final path = p.join(base, candidate);
      final taken =
          candidate == _partsFolder ||
          _claimed.contains(path) ||
          await FileSystemEntity.type(path, followLinks: false) !=
              FileSystemEntityType.notFound;
      if (taken) {
        continue;
      }

      _claimed.add(path);
      await Directory(path).create();
      return candidate;
    }

    throw FileSystemException('No free name for the received folder', name);
  }

  @override
  Future<ReceivedFile> save(
    File part, {
    required String name,
    required String mime,
    String? folder,
    DateTime? modified,
  }) async {
    final base = await this.folder();
    final target = Directory(
      p.normalize(p.joinAll([base, ...?folder?.split('/')])),
    );
    if (folder != null && !p.isWithin(base, target.path)) {
      throw FileSystemException('A received folder points outside', folder);
    }

    await target.create(recursive: true);

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final candidate = FileNames.numbered(name, attempt);
      final path = p.join(target.path, candidate);
      if (!await _reserve(path)) {
        continue;
      }

      await _move(part, path);
      await _touch(path, modified);
      return ReceivedFile(location: path, name: candidate);
    }

    throw FileSystemException('No free name for the received file', name);
  }

  @override
  Future<List<ReceivePart>> partsFor(String id, List<PartTarget> files) async {
    final parts = await partsDirectory();
    return [
      for (final (index, target) in files.indexed)
        FilePart(
          File(p.join(parts.path, '$id-$index.part')),
          onSave: (part, {modified}) => save(
            part,
            name: target.name,
            mime: target.mime,
            folder: target.folder,
            modified: modified,
          ),
        ),
    ];
  }

  @override
  Future<int?> freeBytes() async => switch (freeSpace) {
    final read? => read(await folder()),
    null => null,
  };

  /// Creates an empty placeholder so two files saved at once never pick the
  /// same name. Returns false when the name is taken.
  Future<bool> _reserve(String path) async {
    if (await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      return false;
    }

    try {
      await File(path).create(exclusive: true);
      return true;
    } on FileSystemException {
      return false;
    }
  }

  Future<void> _move(File part, String path) async {
    try {
      await part.rename(path);
    } on FileSystemException {
      await part.copy(path);
      await part.delete();
    }
  }

  Future<void> _touch(String path, DateTime? modified) async {
    if (modified == null) {
      return;
    }

    try {
      await File(path).setLastModified(modified);
    } on FileSystemException catch (error) {
      printDebug('Drop kept the arrival time: ${error.osError?.message}');
    }
  }
}
