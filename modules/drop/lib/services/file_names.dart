import 'package:path/path.dart' as p;

/// File name rules for received files. Names come from another device, so
/// they are never trusted as paths.
abstract final class FileNames {
  static const _maxLength = 200;
  static const _fallback = 'file';
  static final _unsafe = RegExp(r'[\x00-\x1f<>:"/\\|?*\x7f]');
  static final _reserved = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(\..*)?$',
    caseSensitive: false,
  );

  /// A name that is safe on every platform: no folders, no characters
  /// Windows refuses, no reserved device names, and not too long.
  static String safe(String remote) {
    final base = remote.split(RegExp(r'[/\\]')).last;
    var cleaned = base.replaceAll(_unsafe, '_').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[. ]+$'), '');
    if (cleaned.isEmpty || cleaned.replaceAll('.', '').isEmpty) {
      return _fallback;
    }

    if (_reserved.hasMatch(cleaned)) {
      cleaned = '_$cleaned';
    }

    if (cleaned.length <= _maxLength) {
      return cleaned;
    }

    final extension = p.extension(cleaned);
    final keep = switch (extension.length < 20) {
      true => extension,
      false => '',
    };
    return '${cleaned.substring(0, _maxLength - keep.length)}$keep';
  }

  /// The [attempt]th alternative to [name]: `photo.jpg`, then
  /// `photo (1).jpg`, `photo (2).jpg`, and so on.
  static String numbered(String name, int attempt) {
    if (attempt == 0) {
      return name;
    }

    final extension = _extension(name);
    final stem = name.substring(0, name.length - extension.length);
    return '$stem ($attempt)$extension';
  }

  /// The [attempt]th alternative to the folder [name]: `Photos`, then
  /// `Photos (2)`, `Photos (3)`, as Finder and Explorer name copies.
  static String numberedFolder(String name, int attempt) {
    if (attempt == 0) {
      return name;
    }

    return '$name (${attempt + 1})';
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0) {
      return '';
    }

    final lower = name.toLowerCase();
    for (final compound in const ['.tar.gz', '.tar.bz2', '.tar.xz']) {
      if (lower.endsWith(compound) && name.length > compound.length) {
        return name.substring(name.length - compound.length);
      }
    }

    return name.substring(dot);
  }
}
