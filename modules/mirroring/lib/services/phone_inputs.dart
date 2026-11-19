import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:protocol/mirroring.dart';
import 'package:protocol/remote_input.dart';

/// What a computer sends to control this phone, in Android's terms.
abstract final class PhoneInputs {
  /// Android's key code for [key], or null for a key Android has none for.
  static int? keyCodeOf(Key key) {
    final value = key.value;
    if (value >= Key.KEY_A.value && value <= Key.KEY_Z.value) {
      return AndroidKeys.a + value - Key.KEY_A.value;
    }

    if (value >= Key.KEY_DIGIT_0.value && value <= Key.KEY_DIGIT_9.value) {
      return AndroidKeys.digit0 + value - Key.KEY_DIGIT_0.value;
    }

    if (value >= Key.KEY_F1.value && value <= Key.KEY_F12.value) {
      return AndroidKeys.f1 + value - Key.KEY_F1.value;
    }

    return switch (key) {
      .KEY_ENTER => AndroidKeys.enter,
      .KEY_BACKSPACE => AndroidKeys.backspace,
      .KEY_DELETE => AndroidKeys.forwardDelete,
      .KEY_TAB => AndroidKeys.tab,
      .KEY_ESCAPE => AndroidKeys.escape,
      .KEY_SPACE => AndroidKeys.space,
      .KEY_ARROW_LEFT => AndroidKeys.arrowLeft,
      .KEY_ARROW_RIGHT => AndroidKeys.arrowRight,
      .KEY_ARROW_UP => AndroidKeys.arrowUp,
      .KEY_ARROW_DOWN => AndroidKeys.arrowDown,
      .KEY_HOME => AndroidKeys.moveHome,
      .KEY_END => AndroidKeys.moveEnd,
      .KEY_PAGE_UP => AndroidKeys.pageUp,
      .KEY_PAGE_DOWN => AndroidKeys.pageDown,
      .KEY_MEDIA_PLAY_PAUSE => AndroidKeys.mediaPlayPause,
      .KEY_MEDIA_NEXT => AndroidKeys.mediaNext,
      .KEY_MEDIA_PREVIOUS => AndroidKeys.mediaPrevious,
      .KEY_VOLUME_UP => AndroidKeys.volumeUp,
      .KEY_VOLUME_DOWN => AndroidKeys.volumeDown,
      .KEY_VOLUME_MUTE => AndroidKeys.volumeMute,
      _ => null,
    };
  }

  /// Android's meta state for the [modifiers] held.
  static int metaStateOf(Iterable<Modifier> modifiers) {
    var state = 0;
    for (final modifier in modifiers) {
      state |= switch (modifier) {
        .MODIFIER_SHIFT => AndroidKeys.metaShift,
        .MODIFIER_CONTROL => AndroidKeys.metaCtrl,
        .MODIFIER_ALT => AndroidKeys.metaAlt,
        .MODIFIER_META => AndroidKeys.metaMeta,
        _ => 0,
      };
    }

    return state;
  }

  static PhoneButton? buttonOf(ControlButton button) => switch (button) {
    .CONTROL_BUTTON_BACK => .back,
    .CONTROL_BUTTON_HOME => .home,
    .CONTROL_BUTTON_RECENTS => .recents,
    .CONTROL_BUTTON_NOTIFICATIONS => .notifications,
    .CONTROL_BUTTON_POWER => .power,
    .CONTROL_BUTTON_VOLUME_UP => .volumeUp,
    .CONTROL_BUTTON_VOLUME_DOWN => .volumeDown,
    _ => null,
  };

  static ControlButton buttonToProto(PhoneButton button) => switch (button) {
    .back => .CONTROL_BUTTON_BACK,
    .home => .CONTROL_BUTTON_HOME,
    .recents => .CONTROL_BUTTON_RECENTS,
    .notifications => .CONTROL_BUTTON_NOTIFICATIONS,
    .power => .CONTROL_BUTTON_POWER,
    .volumeUp => .CONTROL_BUTTON_VOLUME_UP,
    .volumeDown => .CONTROL_BUTTON_VOLUME_DOWN,
  };

  static ControlKind kindOf(PhoneAbility ability) => switch (ability) {
    .pointer => .CONTROL_KIND_POINTER,
    .keys => .CONTROL_KIND_KEYS,
    .text => .CONTROL_KIND_TEXT,
    .buttons => .CONTROL_KIND_BUTTONS,
  };
}
