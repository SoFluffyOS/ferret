import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One tile in the shelf box: a square [thumb] with a name of up to two
/// lines under it. It lights up under the pointer and when [isSelected],
/// and shows a ⓧ in its corner under the pointer when [onRemove] is set.
/// Pressing and moving starts [onDragStart].
class ShelfTile extends StatefulWidget {
  const ShelfTile({
    super.key,
    required this.thumb,
    required this.label,
    required this.tooltip,
    this.labelStyle,
    this.isSelected = false,
    this.isFresh = false,
    this.onTap,
    this.onDragStart,
    this.onRemove,
    this.removeTooltip,
    this.removeLabel,
    this.middleEllipsis = true,
  });

  final Widget thumb;
  final String label;

  /// What the tile is, in full: its name, or why it can't go out.
  final String tooltip;
  final TextStyle? labelStyle;
  final bool isSelected;

  /// Just put on the shelf: it grows into place.
  final bool isFresh;
  final VoidCallback? onTap;
  final VoidCallback? onDragStart;
  final VoidCallback? onRemove;
  final String? removeTooltip;
  final String? removeLabel;

  /// A file name keeps its start and end; text is cut at its end.
  final bool middleEllipsis;

  /// The thumbnail's side, its corner, and how far it sits inside the
  /// tile. The tile's corner is concentric with the thumbnail's.
  static double get thumbSize => Spacing.d52;
  static double get thumbRadius => Spacing.d8;
  static double get inset => Spacing.d4;
  static double get radius => Corners.around(thumbRadius, inset);
  static double get width => thumbSize + inset * 2;

  @override
  State<ShelfTile> createState() => _ShelfTileState();
}

class _ShelfTileState extends State<ShelfTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final style = typography.caption2
        .copyWith(color: palette.text, height: 1.2)
        .merge(widget.labelStyle);
    final fill = switch ((widget.isSelected, _isHovered)) {
      (true, _) => palette.accent.withValues(
        alpha: switch (context.fluffyTheme.isDark) {
          true => 0.32,
          false => 0.18,
        },
      ),
      (false, true) => palette.text.withValues(alpha: 0.06),
      (false, false) => null,
    };
    final label = switch (widget.middleEllipsis) {
      true => MiddleEllipsisText(
        widget.label,
        style: style,
        maxLines: 2,
        textAlign: .center,
      ),
      false => Text(
        widget.label,
        style: style,
        maxLines: 2,
        overflow: .ellipsis,
        textAlign: .center,
      ),
    };
    final tile = Container(
      width: ShelfTile.width,
      padding: EdgeInsets.all(ShelfTile.inset),
      decoration: ShapeDecoration(
        color: fill,
        shape: Corners.shape(ShelfTile.radius),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          SizedBox.square(dimension: ShelfTile.thumbSize, child: widget.thumb),
          Spacing.v4,
          ExcludeSemantics(child: label),
        ],
      ),
    );
    final remove = widget.onRemove;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        label: widget.tooltip,
        customSemanticsActions: switch ((remove, widget.removeLabel)) {
          (final remove?, final label?) => {
            CustomSemanticsAction(label: label): remove,
          },
          _ => null,
        },
        child: Stack(
          clipBehavior: .none,
          children: [
            FluffyTooltip(
              message: widget.tooltip,
              child: GestureDetector(
                behavior: .opaque,
                onTap: widget.onTap,
                onPanStart: switch (widget.onDragStart) {
                  final onDragStart? => (_) => onDragStart(),
                  null => null,
                },
                child: _Arrive(isFresh: widget.isFresh, child: tile),
              ),
            ),
            if (remove != null && _isHovered)
              Positioned(
                top: -Spacing.d4,
                left: -Spacing.d4,
                child: _RemoveButton(
                  onTap: remove,
                  tooltip: widget.removeTooltip,
                  label: widget.removeLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The ⓧ on a tile under the pointer: small to look at, 24 to hit.
class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap, this.tooltip, this.label});

  final VoidCallback onTap;
  final String? tooltip;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Tappable(
      tooltip: tooltip,
      semanticLabel: label,
      semanticButton: true,
      enableAnimation: false,
      enableHoverOverlay: false,
      onTap: onTap,
      child: SizedBox.square(
        dimension: Spacing.d24,
        child: Center(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: palette.mutedText,
              shape: CircleBorder(
                side: BorderSide(
                  color: palette.background,
                  width: Spacing.d1 * 1.5,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
            ),
            child: SizedBox.square(
              dimension: Spacing.d18,
              child: Icon(
                LucideIcons.x,
                size: Spacing.d12,
                color: palette.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tile that was just put on the shelf grows and fades into place.
class _Arrive extends StatelessWidget {
  const _Arrive({required this.isFresh, required this.child});

  final bool isFresh;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(
      begin: switch (isFresh) {
        true => 0,
        false => 1,
      },
      end: 1,
    ),
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutBack,
    builder: (context, value, child) => Opacity(
      opacity: value.clamp(0, 1),
      child: Transform.scale(scale: 0.6 + 0.4 * value, child: child),
    ),
    child: child,
  );
}
