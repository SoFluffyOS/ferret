import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/directional_icon.dart';
import 'package:feature_kit/widgets/outset_touch_target.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/base_components/menu_overlay.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// An icon at either end of a page's header, such as Back, + or •••, whose
/// drawn glyph lines up with the page's content, as the title's first
/// letter does.
///
/// It lays out as wide as its icon. The fill on hover and press reaches
/// past that into the page's margin, and so does what takes a tap: the
/// density's 48 dp for a finger, the fill for a pointer. With [entries]
/// it opens a menu whose edge meets the glyph's.
class HeaderIconButton extends StatefulWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.entries,
    this.nudge = 0,
    this.padding = 6,
    this.mirrors = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  /// A menu to open instead of [onTap].
  final List<MenuEntry>? entries;

  /// How far the icon moves toward the end (negative: toward the start)
  /// from its place in the row, so its glyph rather than the empty room
  /// in the icon lines up with the content. See [backNudge] and
  /// [endNudge].
  final double nudge;

  /// The fill's room around the icon.
  final double padding;

  /// Turned around for a right-to-left language, as Back is.
  final bool mirrors;

  /// The room between a 20-point chevron-left's box and its stroke.
  static const double backNudge = -20 * 8 / 24;

  /// The room between a 20-point ••• or +'s box and its stroke, at the end.
  static const double endNudge = 20 * 3 / 24;

  static const double _iconSize = 20;

  @override
  State<HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<HeaderIconButton> {
  final OverlayPortalController _menu = OverlayPortalController();
  final LayerLink _anchor = LayerLink();

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final dx = switch (isRtl) {
      true => -widget.nudge,
      false => widget.nudge,
    };
    final fill = HeaderIconButton._iconSize + widget.padding * 2;
    final color = context.palette.text;
    final icon = switch (widget.mirrors) {
      true => DirectionalIcon(
        widget.icon,
        size: HeaderIconButton._iconSize,
        color: color,
      ),
      false => Icon(
        widget.icon,
        size: HeaderIconButton._iconSize,
        color: color,
      ),
    };
    final entries = widget.entries;

    Widget button = OutsetTouchTarget(
      minSize: switch (context.fluffyDensity.minTarget > fill) {
        true => context.fluffyDensity.minTarget,
        false => fill,
      },
      child: SizedBox(
        width: HeaderIconButton._iconSize,
        height: fill,
        child: OverflowBox(
          minWidth: fill,
          maxWidth: fill,
          minHeight: fill,
          maxHeight: fill,
          child: Tappable(
            tooltip: widget.tooltip,
            onTap: switch (entries) {
              null => widget.onTap,
              _ => _menu.toggle,
            },
            child: Padding(
              padding: EdgeInsets.all(widget.padding),
              child: icon,
            ),
          ),
        ),
      ),
    );

    if (entries != null) {
      // The menu hangs from the glyph's end, not from the target's.
      final (target, follower) = switch (isRtl) {
        true => (Alignment.bottomLeft, Alignment.topLeft),
        false => (Alignment.bottomRight, Alignment.topRight),
      };
      button = CompositedTransformTarget(
        link: _anchor,
        child: OverlayPortal(
          controller: _menu,
          overlayChildBuilder: (_) => MenuOverlay(
            entries: entries,
            onClose: _menu.hide,
            placement: (menu) => Positioned(
              left: 0,
              top: 0,
              child: CompositedTransformFollower(
                link: _anchor,
                showWhenUnlinked: false,
                targetAnchor: target,
                followerAnchor: follower,
                offset: Offset(-dx, Spacing.d4),
                child: menu,
              ),
            ),
          ),
          child: button,
        ),
      );
    }

    return Transform.translate(offset: Offset(dx, 0), child: button);
  }
}
