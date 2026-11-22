import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Text and the control that goes with it: side by side, the control at
/// the end and centred on the text, while the control takes at most
/// [maxShare] of the width. A wider control (a long button label on a
/// small phone, or large text) goes under the text, at its start, so the
/// words keep the whole width instead of breaking a letter per line.
class BesideOrBelow extends MultiChildRenderObjectWidget {
  const BesideOrBelow({
    super.key,
    required this.gap,
    this.maxShare = 0.45,
    required super.children,
  }) : assert(children.length == 2, 'Text first, then its control');

  final double gap;
  final double maxShare;

  @override
  RenderBesideOrBelow createRenderObject(BuildContext context) =>
      RenderBesideOrBelow(
        gap: gap,
        maxShare: maxShare,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBesideOrBelow renderObject,
  ) {
    renderObject
      ..gap = gap
      ..maxShare = maxShare
      ..textDirection = Directionality.of(context);
  }
}

class BesideOrBelowParentData extends ContainerBoxParentData<RenderBox> {}

class RenderBesideOrBelow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, BesideOrBelowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, BesideOrBelowParentData> {
  RenderBesideOrBelow({
    required double gap,
    required double maxShare,
    required TextDirection textDirection,
  }) : _gap = gap,
       _maxShare = maxShare,
       _textDirection = textDirection;

  double _gap;
  double get gap => _gap;
  set gap(double value) {
    if (value != _gap) {
      _gap = value;
      markNeedsLayout();
    }
  }

  double _maxShare;
  double get maxShare => _maxShare;
  set maxShare(double value) {
    if (value != _maxShare) {
      _maxShare = value;
      markNeedsLayout();
    }
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value != _textDirection) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  /// Whether the control went under the text at the last layout.
  bool get isBelow => _below;
  bool _below = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BesideOrBelowParentData) {
      child.parentData = BesideOrBelowParentData();
    }
  }

  RenderBox get _text => firstChild!;
  RenderBox get _control => lastChild!;

  bool _goesBelow(double width, double controlWidth) =>
      width.isFinite && controlWidth + gap > width * maxShare;

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _text.getMinIntrinsicWidth(height),
    _control.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _text.getMaxIntrinsicWidth(height) +
      gap +
      _control.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _heightFor(width, (box, w) => box.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _heightFor(width, (box, w) => box.getMaxIntrinsicHeight(w));

  double _heightFor(double width, double Function(RenderBox, double) height) {
    final controlWidth = _control.getMaxIntrinsicWidth(double.infinity);
    if (_goesBelow(width, controlWidth)) {
      return height(_text, width) + gap + height(_control, width);
    }

    return math.max(
      height(_text, math.max(0, width - controlWidth - gap)),
      height(_control, controlWidth),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final width = constraints.maxWidth;
    final loose = BoxConstraints(maxWidth: width);
    final controlSize = switch (dry) {
      true => _control.getDryLayout(loose),
      false => (_control..layout(loose, parentUsesSize: true)).size,
    };
    final below = _goesBelow(width, controlSize.width);
    final textWidth = switch (below) {
      true => width,
      false => math.max(0.0, width - controlSize.width - gap),
    };
    final textConstraints = BoxConstraints(maxWidth: textWidth);
    final textSize = switch (dry) {
      true => _text.getDryLayout(textConstraints),
      false => (_text..layout(textConstraints, parentUsesSize: true)).size,
    };
    final rtl = textDirection == TextDirection.rtl;
    final Size result;
    if (below) {
      result = constraints.constrain(
        Size(width, textSize.height + gap + controlSize.height),
      );
      if (!dry) {
        _place(_text, rtl ? width - textSize.width : 0, 0);
        _place(
          _control,
          rtl ? width - controlSize.width : 0,
          textSize.height + gap,
        );
      }
    } else {
      final height = math.max(textSize.height, controlSize.height);
      result = constraints.constrain(Size(width, height));
      if (!dry) {
        _place(
          _text,
          rtl ? width - textSize.width : 0,
          (height - textSize.height) / 2,
        );
        _place(
          _control,
          rtl ? 0 : width - controlSize.width,
          (height - controlSize.height) / 2,
        );
      }
    }

    if (!dry) {
      _below = below;
    }

    return result;
  }

  static void _place(RenderBox child, double x, double y) {
    (child.parentData! as BesideOrBelowParentData).offset = Offset(x, y);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
