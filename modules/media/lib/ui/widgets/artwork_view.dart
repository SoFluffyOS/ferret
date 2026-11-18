import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Album art, or a music note when the player sent none.
class ArtworkView extends StatelessWidget {
  const ArtworkView({super.key, required this.artwork, required this.size});

  final Uint8List? artwork;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final placeholder = ColoredBox(
      color: palette.background,
      child: Center(
        child: Icon(
          LucideIcons.music,
          size: Spacing.d20,
          color: palette.mutedText,
        ),
      ),
    );
    final image = switch (artwork) {
      final bytes? when bytes.isNotEmpty => Image.memory(
        bytes,
        fit: .cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => placeholder,
      ),
      _ => placeholder,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(Spacing.d8),
      child: SizedBox.square(dimension: size, child: image),
    );
  }
}
