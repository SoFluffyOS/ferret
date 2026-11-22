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
    this.minSize = 0,
  });

  /// Where the drawn target sits in the square a finger can tap. At the
  /// top, the square reaches down below it, none of it above.
  final AlignmentGeometry alignment;

  /// The least side of what takes taps, for a child that draws past its
  /// own layout, such as a header icon whose hover fill reaches into the
  /// page's margin. The kit's grown target counts too.
  final double minSize;

  @override
  RenderOutsetTouchTarget createRenderObject(BuildContext context) =>
      RenderOutsetTouchTarget(
        alignment: alignment.resolve(Directionality.maybeOf(context)),
        minSize: minSize,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOutsetTouchTarget renderObject,
  ) {
    renderObject
      ..alignment = alignment.resolve(Directionality.maybeOf(context))
      ..minSize = minSize;
  }
}

/// Sized as what the kit's touch target inside it draws; takes taps on the
/// whole target.
class RenderOutsetTouchTarget extends RenderShiftedBox {
  RenderOutsetTouchTarget({
    required Alignment alignment,
    double minSize = 0,
    RenderBox? child,
  }) : _alignment = alignment,
       _minSize = minSize,
       super(child);

  double _minSize;
  double get minSize => _minSize;
  set minSize(double value) {
    if (_minSize == value) {
      return;
    }
    _minSize = value;
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
      (_drawn ?? child)?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (_drawn ?? child)?.getMaxIntrinsicWidth(height) ?? 0;

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

    return constraints.constrain(box.getDryLayout(constraints));
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
        math.max(0, drawn.offset.dx * 2),
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
    final extraWidth = math.max(_growth.width, _minSize - size.width);
    final extraHeight = math.max(_growth.height, _minSize - size.height);
    final left = math.max(0.0, extraWidth) * (1 + _alignment.x) / 2;
    final top = math.max(0.0, extraHeight) * (1 + _alignment.y) / 2;

    return Rect.fromLTWH(
      -left,
      -top,
      size.width + math.max(0.0, extraWidth),
      size.height + math.max(0.0, extraHeight),
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

/// Lets a finger's taps in [margin] around [child] reach it, slid onto its
/// nearest edge, so an [OutsetTouchTarget] at the end of a header row keeps
/// its whole target in the page's margin. Put it where the margin is still
/// inside the parent, such as just inside the padding that makes it. A
/// pointer gets only [child].
class OverhangHits extends SingleChildRenderObjectWidget {
  const OverhangHits({
    super.key,
    required this.margin,
    required Widget super.child,
  });

  final EdgeInsetsGeometry margin;

  @override
  RenderOverhangHits createRenderObject(BuildContext context) =>
      RenderOverhangHits(margin: _resolve(context));

  EdgeInsets _resolve(BuildContext context) =>
      switch (context.fluffyDensity.isTouch) {
        true => margin.resolve(Directionality.maybeOf(context)),
        false => EdgeInsets.zero,
      };

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOverhangHits renderObject,
  ) {
    renderObject.margin = _resolve(context);
  }
}

class RenderOverhangHits extends RenderProxyBox {
  RenderOverhangHits({required this.margin, RenderBox? child}) : super(child);

  EdgeInsets margin;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null ||
        size.isEmpty ||
        !margin.inflateRect(Offset.zero & size).contains(position)) {
      return false;
    }

    final inside = Offset(
      position.dx.clamp(0, size.width - 0.01),
      position.dy.clamp(0, size.height - 0.01),
    );
    final isHit = child.hitTest(result, position: inside);
    if (isHit) {
      result.add(BoxHitTestEntry(this, position));
    }
    return isHit;
  }
}
