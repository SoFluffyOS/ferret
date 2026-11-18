import 'package:path/path.dart' as p;

/// A folder path as people read it: "Downloads › Ferret" instead of
/// "/Users/me/Downloads/Ferret".
abstract final class FolderLabel {
  static const _separator = ' › ';
  static const _tailSegments = 2;

  /// [path] relative to [home] when it is inside it, otherwise its last two
  /// folders.
  static String of(String path, {String? home, p.Context? style}) {
    final context = style ?? p.context;
    if (path.isEmpty) {
      return path;
    }

    final segments = switch (home) {
      final homePath? when context.isWithin(homePath, path) => context.split(
        context.relative(path, from: homePath),
      ),
      _ => context.split(path),
    };
    final named = [
      for (final segment in segments)
        if (segment.isNotEmpty && segment != context.separator) segment,
    ];
    final shown = switch (named.length > _tailSegments) {
      true => named.sublist(named.length - _tailSegments),
      false => named,
    };

    return shown.join(_separator);
  }
}
