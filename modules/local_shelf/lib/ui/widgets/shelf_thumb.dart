import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/models/models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A small square for one shelf item: the picture itself, or the icon of
/// what it is. A hidden item shows a lock, a missing one a crossed file.
/// With [showsContent], text shows its first lines and a link its site,
/// so a row of clips tells them apart.
class ShelfThumb extends StatelessWidget {
  const ShelfThumb({
    super.key,
    required this.item,
    required this.size,
    required this.radius,
    this.isHidden = false,
    this.showsContent = false,
  });

  final ShelfItem item;
  final double size;
  final double radius;
  final bool isHidden;
  final bool showsContent;

  /// Between the square's edge and the words in it.
  static double get textInset => Spacing.d4;

  /// The site of a link, without "www.", or null when it has none.
  static String? hostOf(String address) {
    final host = Uri.tryParse(address.trim())?.host ?? '';
    if (host.isEmpty) {
      return null;
    }

    return host.replaceFirst(RegExp('^www\\.'), '');
  }

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
    final isShown = !isHidden && !item.isMissing;
    final showsPicture = item.kind == .image && isShown;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final words = switch ((showsContent && isShown, item.kind)) {
      (true, .text) when item.text.trim().isNotEmpty => _Snippet(
        text: item.text,
      ),
      (true, .link) => switch (hostOf(item.text)) {
        final host? => _Site(host: host),
        null => null,
      },
      _ => null,
    };

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: palette.background, shape: shape),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: switch ((showsPicture, words)) {
            (true, _) => Image.file(
              File(item.path),
              fit: .cover,
              cacheWidth: pixels,
              errorBuilder: (_, _, _) => icon,
            ),
            (false, final words?) => ExcludeSemantics(child: words),
            (false, null) => icon,
          },
        ),
      ),
    );
  }
}

/// The first lines of a text, small, like a page seen from afar.
class _Snippet extends StatelessWidget {
  const _Snippet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(ShelfThumb.textInset),
    child: Text(
      text.trim().replaceAll(RegExp(r'\s+'), ' '),
      maxLines: 3,
      overflow: .ellipsis,
      style: context.fluffyTheme.typography.caption2.copyWith(
        fontSize: 9,
        height: 1.2,
        color: context.palette.text,
      ),
    ),
  );
}

/// A link's site under a small link mark.
class _Site extends StatelessWidget {
  const _Site({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.all(ShelfThumb.textInset),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Icon(LucideIcons.link, size: Spacing.d12, color: palette.link),
          Spacing.v4,
          Flexible(
            child: Text(
              // A long site breaks after a dot, not inside a word.
              host.replaceAll('.', '.\u200B'),
              maxLines: 2,
              overflow: .ellipsis,
              style: context.fluffyTheme.typography.caption2.copyWith(
                fontSize: 9,
                height: 1.2,
                fontWeight: .w600,
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
