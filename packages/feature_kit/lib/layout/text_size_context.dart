import 'package:flutter/widgets.dart';

extension TextSizeContext on BuildContext {
  /// Whether the system's text size is set large (130 % and up). From
  /// there, a title next to its value or two buttons side by side start to
  /// be cut, so rows stack them and let lines wrap.
  bool get hasLargeText =>
      MediaQuery.textScalerOf(this).scale(_bodySize) / _bodySize >= 1.3;
}

/// The size the scale is measured at: body text, where non-linear scaling
/// still follows the setting.
const _bodySize = 16.0;
