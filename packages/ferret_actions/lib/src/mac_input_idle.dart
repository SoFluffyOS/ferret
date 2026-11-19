import 'dart:ffi';

import 'package:ferret_actions/src/input_idle.dart';

typedef _SecondsSinceNative = Double Function(Int32 state, Uint32 eventType);
typedef _SecondsSince = double Function(int state, int eventType);

/// `CGEventSourceSecondsSinceLastEventType` for any input, as the system
/// itself counts it for the screen saver. No permission needed.
class MacInputIdle implements InputIdle {
  const MacInputIdle();

  static const _coreGraphics =
      '/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics';

  static const _hidSystemState = 1;
  static const _anyInputEvent = 0xFFFFFFFF;

  @override
  Future<Duration?> idleTime() async {
    try {
      final library = DynamicLibrary.open(_coreGraphics);
      final secondsSince = library
          .lookupFunction<_SecondsSinceNative, _SecondsSince>(
            'CGEventSourceSecondsSinceLastEventType',
          );
      final seconds = secondsSince(_hidSystemState, _anyInputEvent);

      return Duration(
        microseconds: (seconds * Duration.microsecondsPerSecond).round(),
      );
    } on Object {
      return null;
    }
  }
}
