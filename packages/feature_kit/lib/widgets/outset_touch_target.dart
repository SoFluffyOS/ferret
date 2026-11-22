import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Lays out a target the size it draws, for small words or an icon in a
/// line of text, while a finger keeps the density's 48 dp to tap.
///
/// With touch density the kit grows a `Tappable` to
/// [FluffyDensity.minTarget] through `TouchTarget`, and that square takes
/// room in the layout, so a line with a link in it grows. This takes the
/// growth back out of the layout: [child] still gets the whole square for
/// taps (and a screen reader's focus), drawn over the space around it.
/// That reaches only as far as the parents take taps: a target at the edge
/// of a card stops at the card. With a pointer, nothing changes.
class OutsetTouchTarget extends SingleChildRenderObjectWidget {
  const OutsetTouchTarget({
    super.key,
    required Widget super.child,
    this.alignment = Alignment.center,
    this.keepsWidth = false,
  });

  /// Where the drawn target sits in the square a finger can tap. At the
  /// top, the square reaches down below it, none of it above.
  final AlignmentGeometry alignment;

  /// Leaves the target's width in the layout and takes out only its
  /// height, for a button whose menu lines up with the target's edge, such
  /// as an icon at the end of a title bar.
  final bool keepsWidth;

  @override
  RenderOutsetTouchTarget createRenderObject(BuildContext context) =>
      RenderOutsetTouchTarget(
        alignment: alignment.resolve(Directionality.maybeOf(context)),
        keepsWidth: keepsWidth,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOutsetTouchTarget renderObject,
  ) {
    renderObject
      ..alignment = alignment.resolve(Directionality.maybeOf(context))
      ..keepsWidth = keepsWidth;
  }
}

/// Sized as what the kit's touch target inside it draws; takes taps on the
/// whole target.
class RenderOutsetTouchTarget extends RenderShiftedBox {
  RenderOutsetTouchTarget({
    required Alignment alignment,
    bool keepsWidth = false,
    RenderBox? child,
  }) : _alignment = alignment,
       _keepsWidth = keepsWidth,
       super(child);

  bool _keepsWidth;
  bool get keepsWidth => _keepsWidth;
  set keepsWidth(bool value) {
    if (_keepsWidth == value) {
      return;
    }
    _keepsWidth = value;
    markNeedsLayout();
  }

  Alignment _alignment;
  Alignment get alignment => _alignment;
  set alignment(Alignment value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    markNeedsPaint();
  }

  /// How much the touch target grew [child] on each axis.
  Size _growth = Size.zero;

  /// The kit's grown target under [child], through boxes that only pass
  /// their size on, or null when there is none (a pointer, or nothing to
  /// press).
  RenderMinTouchSize? get _target {
    RenderObject? node = child;
    while (node != null) {
      if (node is RenderMinTouchSize) {
        return node;
      }
      if (node is! RenderProxyBoxMixin) {
        return null;
      }
      node = node.child;
    }
    return null;
  }

  /// What the target draws, which [child] lays out around.
  RenderBox? get _drawn => _target?.child;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _widthBox?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _widthBox?.getMaxIntrinsicWidth(height) ?? 0;

  /// What the layout takes its width from.
  RenderBox? get _widthBox => switch (_keepsWidth) {
    true => child,
    false => _drawn ?? child,
  };

  @override
  double computeMinIntrinsicHeight(double width) =>
      (_drawn ?? child)?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      (_drawn ?? child)?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final box = _drawn ?? child;
    if (box == null) {
      return constraints.smallest;
    }

    final drawn = box.getDryLayout(constraints);
    return constraints.constrain(
      Size(
        switch (_keepsWidth) {
          true => child!.getDryLayout(constraints).width,
          false => drawn.width,
        },
        drawn.height,
      ),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      _growth = Size.zero;
      size = constraints.smallest;
      return;
    }

    child.layout(constraints, parentUsesSize: true);
    // The kit's target centres what it draws, so its offset in there is
    // half of what it grew. A box only reads its own child's size.
    _growth = switch (_drawn?.parentData) {
      final BoxParentData drawn => Size(
        switch (_keepsWidth) {
          true => 0,
          false => math.max(0, drawn.offset.dx * 2),
        },
        math.max(0, drawn.offset.dy * 2),
      ),
      _ => Size.zero,
    };
    size = constraints.constrain(
      Size(
        child.size.width - _growth.width,
        child.size.height - _growth.height,
      ),
    );
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final child = this.child;
    if (child == null) {
      return null;
    }

    final childBaseline = child.getDistanceToActualBaseline(baseline);
    if (childBaseline == null) {
      return null;
    }

    final parentData = child.parentData! as BoxParentData;
    return childBaseline + parentData.offset.dy;
  }

  /// The square a finger can tap, in this box's coordinates.
  Rect get targetRect {
    final left = _growth.width * (1 + _alignment.x) / 2;
    final top = _growth.height * (1 + _alignment.y) / 2;

    return Rect.fromLTWH(
      -left,
      -top,
      size.width + _growth.width,
      size.height + _growth.height,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || !targetRect.contains(position)) {
      return false;
    }

    final parentData = child.parentData! as BoxParentData;
    final isHit = result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (result, inChild) => child.hitTest(
        result,
        position: Offset(
          inChild.dx.clamp(0, math.max(0, child.size.width - 0.01)),
          inChild.dy.clamp(0, math.max(0, child.size.height - 0.01)),
        ),
      ),
    );
    if (isHit) {
      result.add(BoxHitTestEntry(this, position));
    }
    return isHit;
  }
}
