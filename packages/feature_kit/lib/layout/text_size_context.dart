import 'package:flutter/widgets.dart';

extension TextSizeContext on BuildContext {
  /// How many times its usual size body text is drawn: 1 at the default
  /// size, 2 at 200 %. Widths that hold text, such as the widest a page
  /// gets or where two columns fit, grow by it, the way em breakpoints do
  /// on the web.
  double get textScale =>
      MediaQuery.textScalerOf(this).scale(_bodySize) / _bodySize;

  /// Whether the system's text size is set large (130 % and up). From
  /// there, a title next to its value or two buttons side by side start to
  /// be cut, so rows stack them and let lines wrap.
  bool get hasLargeText => textScale >= 1.3;
}

/// The size the scale is measured at: body text, where non-linear scaling
/// still follows the setting.
const _bodySize = 16.0;
