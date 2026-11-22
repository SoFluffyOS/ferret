import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/models/models.dart';
import 'package:protocol/messages.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A contact's photo, their initial, or a people icon for groups.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.participants, required this.size});

  final List<Participant> participants;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final photo = switch (participants) {
      [final Participant only] when only.avatarJpeg.isNotEmpty =>
        Uint8List.fromList(only.avatarJpeg),
      _ => null,
    };

    final Widget content = switch ((photo, participants.length)) {
      (final Uint8List bytes?, _) => Image.memory(
        bytes,
        width: size,
        height: size,
        fit: .cover,
        gaplessPlayback: true,
      ),
      (_, > 1) => Icon(LucideIcons.users, size: size / 2, color: palette.link),
      _ => Text(
        _initialOf(participants),
        style: typography.base1.copyWith(color: palette.link),
      ),
    };

    // The name is said next to it; initials alone read as a stray letter.
    return ExcludeSemantics(
      child: ClipOval(
        child: Container(
          width: size,
          height: size,
          // The same tinted circle as a caller in Calls.
          color: palette.accent.withValues(alpha: 0.15),
          alignment: .center,
          child: content,
        ),
      ),
    );
  }

  static String _initialOf(List<Participant> participants) {
    if (participants.isEmpty) {
      return '?';
    }

    final label = participants.first.label.trim();
    final first = label.characters.firstOrNull;
    if (first == null || !RegExp(r'\p{L}', unicode: true).hasMatch(first)) {
      return '#';
    }

    return first.toUpperCase();
  }
}
