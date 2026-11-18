import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The caller's contact photo in a circle; without one, the initials of
/// their [name], or a person icon for a number alone.
class CallerAvatar extends StatelessWidget {
  const CallerAvatar({
    super.key,
    required this.photoJpeg,
    this.name = '',
    this.size,
  });

  /// Empty when the contact has no photo.
  final List<int> photoJpeg;

  /// The contact's name, empty for a number that isn't a contact.
  final String name;

  /// The circle's width; [Spacing.d40] when null.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? Spacing.d40;
    final placeholder = _Placeholder(
      initials: initialsOf(name),
      dimension: dimension,
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: dimension,
        child: switch (photoJpeg.isEmpty) {
          true => placeholder,
          false => Image.memory(
            Uint8List.fromList(photoJpeg),
            fit: .cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => placeholder,
          ),
        },
      ),
    );
  }

  /// Up to two letters: the first of the first and of the last word, such
  /// as "AB" for "Ana Bell". Empty when [name] has no letters.
  static String initialsOf(String name) {
    final words = [
      for (final word in name.trim().split(RegExp(r'\s+')))
        if (word.isNotEmpty && RegExp(r'^\p{L}', unicode: true).hasMatch(word))
          word,
    ];
    if (words.isEmpty) {
      return '';
    }

    final first = String.fromCharCode(words.first.runes.first);
    if (words.length == 1) {
      return first.toUpperCase();
    }

    final last = String.fromCharCode(words.last.runes.first);
    return '$first$last'.toUpperCase();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.initials, required this.dimension});

  final String initials;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ColoredBox(
      color: palette.accent.withValues(alpha: 0.15),
      child: Center(
        child: switch (initials) {
          '' => Icon(
            LucideIcons.user,
            size: dimension / 2,
            color: palette.accent,
          ),
          final initials => Text(
            initials,
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: palette.link,
              fontSize: dimension * 0.4,
              fontWeight: .w600,
            ),
          ),
        },
      ),
    );
  }
}
