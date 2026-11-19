import 'package:flutter/foundation.dart';

/// This computer as strings name it. Pass [here] as a string's `here` and
/// write it as `{here, select, macOS{this Mac} windows{this PC}
/// other{this computer}}`.
abstract final class ThisComputer {
  static String get here => defaultTargetPlatform.name;
}
