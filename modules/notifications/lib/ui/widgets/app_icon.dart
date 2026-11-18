import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// An app's icon from its PNG bytes, or a bell when there is none.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, required this.png, required this.size});

  final Uint8List? png;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = png;
    if (bytes == null || bytes.isEmpty) {
      return SizedBox.square(
        dimension: size,
        child: Icon(
          LucideIcons.bell,
          size: size * 0.75,
          color: context.palette.mutedText,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Spacing.d6),
      child: Image.memory(
        bytes,
        width: size,
        height: size,
        fit: .cover,
        gaplessPlayback: true,
      ),
    );
  }
}
