import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// A local file to send.
class OutgoingFile {
  const OutgoingFile({
    required this.path,
    required this.name,
    required this.size,
    required this.mime,
    this.folder,
    this.modified,
  });

  final String path;
  final String name;
  final int size;
  final String mime;

  /// The folder the file sits in when a whole folder is sent, relative and
  /// separated by `/`, starting with the sent folder's name: `Photos/2024`.
  /// Null for a file sent on its own.
  final String? folder;

  /// When the file was last modified, for the receiver to keep.
  final DateTime? modified;

  /// Describes the file at [path], or returns null when it isn't a readable
  /// file, such as a folder. [folder] places it inside a sent folder.
  static Future<OutgoingFile?> fromPath(String path, {String? folder}) async {
    final file = File(path);
    if (await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.file) {
      return null;
    }

    final stat = await file.stat();
    return OutgoingFile(
      path: path,
      name: p.basename(path),
      size: stat.size,
      mime: lookupMimeType(path) ?? '',
      folder: folder,
      modified: stat.modified,
    );
  }
}
