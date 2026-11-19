import 'dart:math' as math;

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A small card that opens from a toolbar button: upward from a toolbar
/// that lies along the bottom, sideways from one that stands beside the
/// picture, and always inside the window. A click anywhere else, or
/// Escape, closes it.
class ToolbarPopup extends StatefulWidget {
  const ToolbarPopup({
    super.key,
    required this.controller,
    required this.axis,
    required this.builder,
    required this.child,
    this.onClosed,
  });

  final OverlayPortalController controller;

  /// The way the toolbar runs.
  final Axis axis;
  final WidgetBuilder builder;
  final Widget child;
  final VoidCallback? onClosed;

  @override
  State<ToolbarPopup> createState() => _ToolbarPopupState();
}

class _ToolbarPopupState extends State<ToolbarPopup> {
  void _close() {
    widget.controller.hide();
    widget.onClosed?.call();
  }

  /// Where the button is, in the overlay the popup opens in.
  Rect _buttonIn(BuildContext overlayContext) {
    final button = context.findRenderObject();
    final overlay = Overlay.of(overlayContext).context.findRenderObject();
    if (button is! RenderBox || !button.hasSize) {
      return Rect.zero;
    }

    return button.localToGlobal(Offset.zero, ancestor: overlay) & button.size;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return OverlayPortal(
      controller: widget.controller,
      overlayChildBuilder: (overlayContext) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(behavior: .opaque, onTap: _close),
              ),
              Positioned.fill(
                child: CustomSingleChildLayout(
                  delegate: _PopupLayout(
                    button: _buttonIn(overlayContext),
                    axis: widget.axis,
                    gap: Spacing.d8,
                  ),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: palette.surface,
                      shape: Corners.shape(Corners.card),
                      shadows: [
                        BoxShadow(
                          color: palette.text.withValues(alpha: 0.2),
                          blurRadius: Spacing.d24,
                          offset: Offset(0, Spacing.d8),
                        ),
                      ],
                    ),
                    child: widget.builder(overlayContext),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: widget.child,
    );
  }
}

/// Puts the popup next to its button and keeps all of it in the window.
class _PopupLayout extends SingleChildLayoutDelegate {
  const _PopupLayout({
    required this.button,
    required this.axis,
    required this.gap,
  });

  final Rect button;
  final Axis axis;
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          math.max(0, constraints.maxWidth - gap * 2),
          math.max(0, constraints.maxHeight - gap * 2),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final mostLeft = math.max(gap, size.width - gap - childSize.width);
    final mostTop = math.max(gap, size.height - gap - childSize.height);
    final wanted = switch (axis) {
      .horizontal => Offset(
        button.right - childSize.width,
        button.top - gap - childSize.height,
      ),
      .vertical => Offset(
        button.left - gap - childSize.width,
        button.bottom - childSize.height,
      ),
    };

    return Offset(
      wanted.dx.clamp(gap, mostLeft),
      wanted.dy.clamp(gap, mostTop),
    );
  }

  @override
  bool shouldRelayout(_PopupLayout oldDelegate) =>
      oldDelegate.button != button ||
      oldDelegate.axis != axis ||
      oldDelegate.gap != gap;
}
