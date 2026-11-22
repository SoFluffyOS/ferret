import 'dart:io';

import 'package:crypto/crypto.dart';

/// A release's SHA256SUMS: one `<sha256>  <file name>` line per file, as
/// `shasum -a 256` and `sha256sum` write it.
class Checksums {
  const Checksums(this.byName);

  /// Reads [text]; lines that aren't a checksum and a name are skipped.
  factory Checksums.parse(String text) {
    final line = RegExp(r'^([0-9a-fA-F]{64}) [ *]?(.+)$');
    return Checksums({
      for (final row in text.split('\n'))
        if (line.firstMatch(row.trimRight()) case final match?)
          if ((match.group(1), match.group(2)) case (
            final hash?,
            final name?,
          ))
            _baseName(name.trim()): hash.toLowerCase(),
    });
  }

  /// Lowercase hex SHA-256 by file name.
  final Map<String, String> byName;

  String? operator [](String name) => byName[name];

  /// The SHA-256 of the file at [path], as lowercase hex, read in chunks.
  static Future<String> sha256Of(String path) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  }

  static String _baseName(String name) {
    final slash = name.lastIndexOf('/');
    return switch (slash) {
      -1 => name,
      _ => name.substring(slash + 1),
    };
  }
}
