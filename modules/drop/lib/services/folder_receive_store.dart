import 'dart:io';

import 'package:drop/models/models.dart';
import 'package:drop/services/file_names.dart';
import 'package:drop/services/receive_store.dart';
import 'package:path/path.dart' as p;

/// Saves received files into a plain folder, such as ~/Downloads/Ferret.
/// Parts live in a hidden folder inside it, so the final move is a rename.
class FolderReceiveStore implements ReceiveStore {
  FolderReceiveStore(this.folder);

  /// Resolves the receive folder each time, so a changed setting applies to
  /// the next file.
  final Future<String> Function() folder;

  static const _partsFolder = '.ferret-partial';
  static const _maxAttempts = 10000;

  @override
  Future<Directory> partsDirectory() async {
    final parts = Directory(p.join(await folder(), _partsFolder));
    await parts.create(recursive: true);
    return parts;
  }

  @override
  Future<ReceivedFile> save(
    File part, {
    required String name,
    required String mime,
  }) async {
    final target = Directory(await folder());
    await target.create(recursive: true);

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final candidate = FileNames.numbered(name, attempt);
      final path = p.join(target.path, candidate);
      if (!await _reserve(path)) {
        continue;
      }

      await _move(part, path);
      return ReceivedFile(location: path, name: candidate);
    }

    throw FileSystemException('No free name for the received file', name);
  }

  /// Creates an empty placeholder so two files saved at once never pick the
  /// same name. Returns false when the name is taken.
  Future<bool> _reserve(String path) async {
    if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
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
}
