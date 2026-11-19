import 'package:flutter/foundation.dart';

/// Menus on a Mac are in title case ("Fix Connection…"); Windows and GNOME
/// write them as sentences ("Fix connection…"). English strings are kept in
/// the Mac's case and lowered here, word by word, only for the words menus
/// use, so a device name such as "Pixel Tablet" is never touched.
abstract final class MenuCase {
  static const _words = {
    'a',
    'activity',
    'check',
    'clipboard',
    'connection',
    'device',
    'files',
    'keyboard',
    'my',
    'network',
    'pane',
    'photo',
    'shortcuts',
    'sidebar',
    'this',
    'to',
    'top',
    'window',
    'with',
  };

  /// [label] as menus on [platform] write it. Languages other than English
  /// are left alone: their strings are already sentences.
  static String of(
    String label, {
    required String languageCode,
    TargetPlatform? platform,
  }) {
    final target = platform ?? defaultTargetPlatform;
    if (target == .macOS || target == .iOS || languageCode != 'en') {
      return label;
    }

    final words = label.split(' ');
    return [
      words.first,
      for (final word in words.skip(1)) _lower(word),
    ].join(' ');
  }

  static String _lower(String word) {
    final bare = word.replaceAll('…', '');
    if (!_words.contains(bare.toLowerCase()) || bare.isEmpty) {
      return word;
    }

    return word.toLowerCase();
  }
}
