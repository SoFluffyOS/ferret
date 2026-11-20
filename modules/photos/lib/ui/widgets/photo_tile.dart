import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One square in a phone's photo grid. Its thumbnail is asked for when the
/// tile is first built, so only tiles that come into view cost anything.
class PhotoTile extends StatefulWidget {
  const PhotoTile({
    super.key,
    required this.loadThumbnail,
    required this.semanticLabel,
    required this.onTap,
    this.isVideo = false,
    this.isSelecting = false,
    this.isSelected = false,
    this.onLongPress,
    this.onDragStart,
  });

  final Future<Uint8List?> Function() loadThumbnail;
  final String semanticLabel;
  final bool isVideo;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// A drag began on the tile: it goes out to another app. Null where
  /// nothing can be dragged out.
  final VoidCallback? onDragStart;

  @override
  State<PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<PhotoTile> {
  late final Future<Uint8List?> _thumbnail = widget.loadThumbnail();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = Corners.radius(Corners.row);

    return Semantics(
      label: widget.semanticLabel,
      selected: widget.isSelected,
      button: true,
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        onPanStart: switch (widget.onDragStart) {
          final onDragStart? => (_) => onDragStart(),
          null => null,
        },
        child: Tappable(
          onTap: widget.onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRSuperellipse(
              borderRadius: radius,
              child: Stack(
                fit: .expand,
                children: [
                  ColoredBox(color: palette.surface),
                  FutureBuilder<Uint8List?>(
                    future: _thumbnail,
                    builder: (context, snapshot) {
                      if (snapshot.data case final bytes?) {
                        return Image.memory(
                          bytes,
                          fit: .cover,
                          gaplessPlayback: true,
                          excludeFromSemantics: true,
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  if (widget.isVideo)
                    PositionedDirectional(
                      start: Spacing.d6,
                      bottom: Spacing.d6,
                      child: const _Badge(icon: LucideIcons.play),
                    ),
                  if (widget.isSelected)
                    ColoredBox(color: palette.accent.withValues(alpha: 0.25)),
                  if (widget.isSelecting)
                    PositionedDirectional(
                      top: Spacing.d6,
                      end: Spacing.d6,
                      child: _Badge(
                        icon: switch (widget.isSelected) {
                          true => LucideIcons.circleCheck,
                          false => LucideIcons.circle,
                        },
                        filled: widget.isSelected,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, this.filled = false});

  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background = switch (filled) {
      true => palette.accent,
      false => palette.background.withValues(alpha: 0.7),
    };
    final foreground = switch (filled) {
      true => palette.background,
      false => palette.text,
    };

    return DecoratedBox(
      decoration: BoxDecoration(color: background, shape: .circle),
      child: Padding(
        padding: EdgeInsets.all(Spacing.d2),
        child: Icon(icon, size: Spacing.d16, color: foreground),
      ),
    );
  }
}
