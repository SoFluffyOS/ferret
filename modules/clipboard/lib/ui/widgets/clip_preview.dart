import 'dart:typed_data';
import 'dart:ui';

import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/models/models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A short look at a clip: a few lines of text or a thumbnail, blurred when
/// the source app marked it as private.
class ClipPreview extends StatelessWidget {
  const ClipPreview({super.key, required this.entry});

  final ClipEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.clipboardL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    if (!entry.hasContent) {
      return Text(
        switch (entry.redacted) {
          true => l10n.privateCleared,
          false => l10n.privateHidden,
        },
        style: typography.body2.copyWith(color: palette.mutedText),
      );
    }

    final preview = switch (entry.isImage) {
      true => _image(context),
      false => Text(
        entry.item.text,
        style: typography.body2.copyWith(color: palette.text),
        maxLines: 3,
        overflow: .ellipsis,
      ),
    };

    if (!entry.isSensitive) {
      return preview;
    }

    return Semantics(
      label: l10n.privateHidden,
      excludeSemantics: true,
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: Spacing.d6, sigmaY: Spacing.d6),
          child: preview,
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    final bytes = switch (entry.item.image) {
      final Uint8List image => image,
      final image => Uint8List.fromList(image),
    };
    final height = Spacing.d96;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Semantics(
      label: context.clipboardL10n.imageLabel,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Spacing.d8),
        child: Image.memory(
          bytes,
          height: height,
          fit: .cover,
          cacheHeight: (height * pixelRatio).round(),
          gaplessPlayback: true,
          errorBuilder: (context, _, _) => SizedBox(height: height),
        ),
      ),
    );
  }
}
