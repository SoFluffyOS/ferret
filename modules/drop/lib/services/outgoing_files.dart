import 'dart:io';

import 'package:drop/services/outgoing_file.dart';
import 'package:drop/services/send_sources.dart';
import 'package:path/path.dart' as p;

/// What a list of dropped, shared or picked paths sends: every file, and
/// for each folder the whole tree inside it.
class OutgoingFiles {
  const OutgoingFiles(this.files, {this.skipped = 0});

  static const empty = OutgoingFiles([]);

  /// Litter the system leaves in folders, never worth sending.
  static const _litter = {'.DS_Store', 'Thumbs.db', 'desktop.ini'};

  final List<OutgoingFile> files;

  /// Links and special files inside folders, left out on purpose: a link
  /// may point anywhere, even outside the folder.
  final int skipped;

  bool get hasFolders => files.any((file) => file.folder != null);

  bool get isEmpty => files.isEmpty;

  /// Reads [paths] in order. Files go as they are; a folder goes as its
  /// tree, sorted by path. Links to folders, missing paths and special
  /// files at the top are ignored. Android `content://` URIs are read
  /// through [sources].
  static Future<OutgoingFiles> fromPaths(
    List<String> paths, {
    SendSources sources = const SendSources(),
  }) async {
    final files = <OutgoingFile>[];
    var skipped = 0;

    for (final path in paths) {
      if (SendSources.isContent(path)) {
        if (await sources.describe(path) case final file?) {
          files.add(file);
        }

        continue;
      }

      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        final tree = await _tree(path);
        files.addAll(tree.files);
        skipped += tree.skipped;
        continue;
      }

      if (await OutgoingFile.fromPath(path) case final file?) {
        files.add(file);
      }
    }

    return OutgoingFiles(files, skipped: skipped);
  }

  static Future<OutgoingFiles> _tree(String root) async {
    final base = p.normalize(root);
    final name = p.basename(base);
    final entries = <FileSystemEntity>[];
    var skipped = 0;

    await for (final entity in Directory(base).list(
      recursive: true,
      followLinks: false,
    )) {
      if (_litter.contains(p.basename(entity.path))) {
        continue;
      }

      switch (entity) {
        case Directory():
          continue;
        case File():
          entries.add(entity);
        default:
          skipped++;
      }
    }

    entries.sort((first, second) => first.path.compareTo(second.path));
    final files = <OutgoingFile>[];
    for (final entry in entries) {
      final inside = p.relative(p.dirname(entry.path), from: base);
      final folder = switch (inside) {
        '.' => name,
        _ => [name, ...p.split(inside)].join('/'),
      };
      if (await OutgoingFile.fromPath(entry.path, folder: folder)
          case final file?) {
        files.add(file);
        continue;
      }

      skipped++;
    }

    return OutgoingFiles(files, skipped: skipped);
  }
}
