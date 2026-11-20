import 'dart:io';

import 'package:path/path.dart' as p;

/// File names and kinds for what goes on the shelf.
abstract final class ShelfNames {
  static const _nameLength = 40;

  static const imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'heic',
    'heif',
    'webp',
    'tiff',
    'tif',
    'bmp',
  };

  /// Whether [path] names a picture, by its extension.
  static bool isImage(String path) => imageExtensions.contains(
    p.extension(path).replaceFirst('.', '').toLowerCase(),
  );

  /// Whether [text] is a lone http or https address.
  static bool isWebAddress(String text) {
    final trimmed = text.trim();
    final uri = Uri.tryParse(trimmed);

    return !trimmed.contains(RegExp(r'\s')) &&
        uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }

  /// [text] on one line, at most [length] characters.
  static String oneLine(String text, {int length = _nameLength}) {
    final line = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (line.length <= length) {
      return line;
    }

    return '${line.substring(0, length).trimRight()}…';
  }

  /// A safe file name made from [name], or [fallback] when nothing is
  /// left of it.
  static String safe(String name, {required String fallback}) {
    final cleaned = name
        .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final short = switch (cleaned.length > _nameLength) {
      true => cleaned.substring(0, _nameLength).trim(),
      false => cleaned,
    };

    return switch (short) {
      '' || '.' || '..' => fallback,
      _ => short,
    };
  }

  /// The file name for kept text: its first words.
  static String textFile(String text) =>
      '${safe(text.trim().split('\n').first, fallback: 'Text')}.txt';

  /// The file name for a link: its site, as a shortcut this platform
  /// opens.
  static String linkFile(String address) {
    final host = Uri.tryParse(address.trim())?.host ?? '';
    final name = safe(
      host.replaceFirst(RegExp('^www\\.'), ''),
      fallback: 'Link',
    );
    if (Platform.isWindows) {
      return '$name.url';
    }

    if (Platform.isLinux) {
      return '$name.desktop';
    }

    return '$name.webloc';
  }

  /// What a link's shortcut file holds, for [linkFile].
  static String linkContents(String address) {
    final link = address.trim();
    if (Platform.isWindows) {
      return '[InternetShortcut]\r\nURL=$link\r\n';
    }

    if (Platform.isLinux) {
      return '[Desktop Entry]\nType=Link\nName=$link\nURL=$link\n';
    }

    final escaped = link
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
        '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
        '<plist version="1.0">\n<dict>\n'
        '\t<key>URL</key>\n\t<string>$escaped</string>\n'
        '</dict>\n</plist>\n';
  }

  /// The file name for a picture of type [mime].
  static String imageFile(String mime) => switch (mime.toLowerCase()) {
    'image/jpeg' || 'image/jpg' => 'Image.jpg',
    'image/gif' => 'Image.gif',
    'image/tiff' => 'Image.tiff',
    'image/heic' => 'Image.heic',
    'image/webp' => 'Image.webp',
    'image/bmp' => 'Image.bmp',
    _ => 'Image.png',
  };

  /// Whether [path] sits in a folder the system may empty at any time,
  /// such as where promised files land when dropped on Ferret.
  static bool isTemporary(String path) {
    final separator = p.separator;
    return path.contains('${separator}ferret-drops$separator');
  }
}
