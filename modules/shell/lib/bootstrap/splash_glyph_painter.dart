import 'package:flutter/widgets.dart';
import 'package:shell/bootstrap/splash_look.dart';

/// The ferret of `branding/ferret-glyph.svg`, drawn where [look] says the
/// launch screen drew it. Painted from shapes rather than loaded as a
/// picture, so it is there on the very first frame.
class SplashGlyphPainter extends CustomPainter {
  const SplashGlyphPainter(this.look);

  final SplashLook look;

  /// The ferret's cream fur, also the spinner's colour on the sable.
  static const fur = Color(0xFFF5EBDC);
  static const _ears = Color(0xFFE39A33);
  static const _ink = SplashLook.background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(look.scale)
      ..translate(-look.anchor.dx, -look.anchor.dy);
    if (look.clipRadius case final radius?) {
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: look.anchor, radius: radius)),
      );
    }

    _circle(canvas, 356.56, 287.52, 69.6, fur);
    _circle(canvas, 667.44, 287.52, 69.6, fur);
    _circle(canvas, 354.24, 285.2, 30.16, _ears);
    _circle(canvas, 669.76, 285.2, 30.16, _ears);
    if (look.bleed) {
      canvas.drawRect(
        const Rect.fromLTWH(316, 900, 392, 380),
        Paint()..color = fur,
      );
    }
    canvas
      ..drawPath(_body, Paint()..color = fur)
      ..drawPath(_leftPaw, Paint()..color = _ink)
      ..drawPath(_rightPaw, Paint()..color = _ink);
    _circle(canvas, 512, 436, 199.52, fur);
    canvas.drawPath(_mask, Paint()..color = _ink);
    _circle(canvas, 426.16, 415.12, 25.52, fur);
    _circle(canvas, 597.84, 415.12, 25.52, fur);
    _circle(canvas, 512, 542.72, 30.16, _ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SplashGlyphPainter oldDelegate) =>
      oldDelegate.look != look;

  static void _circle(Canvas canvas, double x, double y, double r, Color c) =>
      canvas.drawCircle(Offset(x, y), r, Paint()..color = c);

  static final Path _body = Path()
    ..moveTo(362, 436)
    ..lineTo(362, 640)
    ..cubicTo(362, 734.67, 316, 829.33, 316, 924)
    ..lineTo(708, 924)
    ..cubicTo(708, 829.33, 662, 734.67, 662, 640)
    ..lineTo(662, 436)
    ..close();

  static final Path _leftPaw = Path()
    ..moveTo(478.77, 742.24)
    ..lineTo(487.92, 785.28)
    ..arcToPoint(const Offset(429.23, 797.76), radius: _pawRadius)
    ..lineTo(420.08, 754.72)
    ..arcToPoint(const Offset(478.77, 742.24), radius: _pawRadius)
    ..close();

  static final Path _rightPaw = Path()
    ..moveTo(603.92, 754.72)
    ..lineTo(594.77, 797.76)
    ..arcToPoint(const Offset(536.08, 785.28), radius: _pawRadius)
    ..lineTo(545.23, 742.24)
    ..arcToPoint(const Offset(603.92, 754.72), radius: _pawRadius)
    ..close();

  static final Path _mask = Path()
    ..moveTo(478.04, 368.72)
    ..lineTo(545.96, 368.72)
    ..arcToPoint(
      const Offset(542.16, 456.88),
      radius: _maskRadius,
      largeArc: true,
    )
    ..lineTo(481.84, 456.88)
    ..arcToPoint(
      const Offset(478.04, 368.72),
      radius: _maskRadius,
      largeArc: true,
    )
    ..close();

  static const _pawRadius = Radius.circular(30);
  static const _maskRadius = Radius.circular(69.6);
}
