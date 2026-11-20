import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/models/models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A small square for one shelf item: the picture itself, or the icon of
/// what it is. A hidden item shows a lock, a missing one a crossed file.
class ShelfThumb extends StatelessWidget {
  const ShelfThumb({
    super.key,
    required this.item,
    required this.size,
    required this.radius,
    this.isHidden = false,
  });

  final ShelfItem item;
  final double size;
  final double radius;
  final bool isHidden;

  static IconData iconOf(ShelfItem item) => switch (item.kind) {
    _ when item.isMissing => LucideIcons.fileX,
    .folder => LucideIcons.folder,
    .image => LucideIcons.image,
    .text => LucideIcons.type,
    .link => LucideIcons.link,
    .file => LucideIcons.file,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = Corners.shape(radius);
    final icon = Center(
      child: Icon(
        switch (isHidden) {
          true => LucideIcons.lock,
          false => iconOf(item),
        },
        size: size / 2,
        color: palette.mutedText,
      ),
    );
    final showsPicture = item.kind == .image && !isHidden && !item.isMissing;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: palette.background, shape: shape),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: switch (showsPicture) {
            true => Image.file(
              File(item.path),
              fit: .cover,
              cacheWidth: pixels,
              errorBuilder: (_, _, _) => icon,
            ),
            false => icon,
          },
        ),
      ),
    );
  }
}
