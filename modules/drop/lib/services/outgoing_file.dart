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
  });

  final String path;
  final String name;
  final int size;
  final String mime;

  /// Describes the file at [path], or returns null when it isn't a readable
  /// file, such as a folder.
  static Future<OutgoingFile?> fromPath(String path) async {
    final file = File(path);
    if (await FileSystemEntity.type(path) != FileSystemEntityType.file) {
      return null;
    }

    final size = await file.length();
    return OutgoingFile(
      path: path,
      name: p.basename(path),
      size: size,
      mime: lookupMimeType(path) ?? '',
    );
  }
}
