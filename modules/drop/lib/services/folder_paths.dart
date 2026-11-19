import 'package:drop/services/file_names.dart';

/// Rules for the folder a received file sits in. The path comes from
/// another device, so every part is cleaned and nothing may climb out of
/// the receive folder.
abstract final class FolderPaths {
  static const maxDepth = 32;
  static const maxLength = 1024;

  static final _separator = RegExp(r'[/\\]');
  static final _drive = RegExp(r'^[A-Za-z]:');

  /// The safe parts of [remote], such as `['Photos', '2024']`, or an empty
  /// list for a file sent on its own. Null when the path is hostile: it
  /// starts at a root or a drive, climbs with `..`, nests too deep or runs
  /// too long. Each part follows [FileNames.safe].
  static List<String>? parts(String remote) {
    if (remote.isEmpty) {
      return const [];
    }

    if (remote.length > maxLength ||
        remote.startsWith('/') ||
        remote.startsWith(r'\') ||
        _drive.hasMatch(remote)) {
      return null;
    }

    final raw = [
      for (final part in remote.split(_separator))
        if (part.isNotEmpty && part != '.') part,
    ];
    if (raw.any((part) => part.trim() == '..') || raw.length > maxDepth) {
      return null;
    }

    return [for (final part in raw) FileNames.safe(part)];
  }

  /// Splits a sender's file name that carries its folder, as LocalSend's
  /// `Photos/2024/a.jpg`, into the folder and the name.
  static ({String folder, String name}) split(String path) {
    final cut = path.lastIndexOf(_separator);
    if (cut < 0) {
      return (folder: '', name: path);
    }

    return (folder: path.substring(0, cut), name: path.substring(cut + 1));
  }

  /// [parts] joined with `/`, or null when there are none.
  static String? join(List<String> parts) => switch (parts.isEmpty) {
    true => null,
    false => parts.join('/'),
  };

  /// [parts] with the first one, the folder that was sent, renamed to
  /// [root], the name it got here.
  static List<String> rooted(List<String> parts, String root) => [
    root,
    ...parts.skip(1),
  ];
}
