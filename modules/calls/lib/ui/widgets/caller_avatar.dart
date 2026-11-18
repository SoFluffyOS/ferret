import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The caller's contact photo in a circle, or a person icon without one.
class CallerAvatar extends StatelessWidget {
  const CallerAvatar({super.key, required this.photoJpeg});

  /// Empty when the contact has no photo.
  final List<int> photoJpeg;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final placeholder = ColoredBox(
      color: palette.background,
      child: Icon(
        LucideIcons.user,
        size: Spacing.d20,
        color: palette.mutedText,
      ),
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: Spacing.d40,
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
}
