import 'package:ferret_phone_control/src/control_service.dart';

/// Android's `KeyEvent.KEYCODE_*` and `KeyEvent.META_*` values this
/// package works with, and what the accessibility service makes of them.
abstract final class AndroidKeys {
  static const home = 3;
  static const back = 4;
  static const digit0 = 7;
  static const arrowUp = 19;
  static const arrowDown = 20;
  static const arrowLeft = 21;
  static const arrowRight = 22;
  static const volumeUp = 24;
  static const volumeDown = 25;
  static const power = 26;
  static const a = 29;
  static const c = 31;
  static const v = 50;
  static const x = 52;
  static const tab = 61;
  static const space = 62;
  static const enter = 66;
  static const backspace = 67;
  static const notification = 83;
  static const mediaPlayPause = 85;
  static const mediaNext = 87;
  static const mediaPrevious = 88;
  static const pageUp = 92;
  static const pageDown = 93;
  static const escape = 111;
  static const forwardDelete = 112;
  static const moveHome = 122;
  static const moveEnd = 123;
  static const f1 = 131;
  static const volumeMute = 164;
  static const appSwitch = 187;

  static const metaShift = 0x1;
  static const metaAlt = 0x2;
  static const metaCtrl = 0x1000;
  static const metaMeta = 0x10000;

  /// What the service does for [keyCode] pressed with [metaState], or null
  /// for a key it has no way to stand in for, such as an arrow up.
  static ServiceKey? serviceKeyOf(int keyCode, int metaState) {
    if (metaState & metaCtrl != 0) {
      return switch (keyCode) {
        a => .selectAll,
        c => .copy,
        x => .cut,
        v => .paste,
        _ => null,
      };
    }

    return switch (keyCode) {
      enter => .enter,
      backspace => .backspace,
      forwardDelete => .delete,
      tab => .tab,
      escape => .escape,
      arrowLeft => .arrowLeft,
      arrowRight => .arrowRight,
      moveHome => .home,
      moveEnd => .end,
      mediaPlayPause => .playPause,
      mediaNext => .next,
      mediaPrevious => .previous,
      volumeUp => .volumeUp,
      volumeDown => .volumeDown,
      volumeMute => .volumeMute,
      _ => null,
    };
  }
}
