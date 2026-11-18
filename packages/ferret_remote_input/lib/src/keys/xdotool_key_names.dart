import 'package:ferret_remote_input/src/keys/input_key.dart';
import 'package:ferret_remote_input/src/keys/key_modifier.dart';

/// X keysym names, as xdotool takes them.
abstract final class XdotoolKeyNames {
  static final Map<InputKey, String> keys = {
    .enter: 'Return',
    .backspace: 'BackSpace',
    .delete: 'Delete',
    .tab: 'Tab',
    .escape: 'Escape',
    .space: 'space',
    .arrowLeft: 'Left',
    .arrowRight: 'Right',
    .arrowUp: 'Up',
    .arrowDown: 'Down',
    .home: 'Home',
    .end: 'End',
    .pageUp: 'Page_Up',
    .pageDown: 'Page_Down',
    .mediaPlayPause: 'XF86AudioPlay',
    .mediaNext: 'XF86AudioNext',
    .mediaPrevious: 'XF86AudioPrev',
    .volumeUp: 'XF86AudioRaiseVolume',
    .volumeDown: 'XF86AudioLowerVolume',
    .volumeMute: 'XF86AudioMute',
    for (var index = 1; index <= 12; index++)
      InputKey.values.byName('f$index'): 'F$index',
    for (var index = 0; index < 26; index++)
      InputKey.values.byName(String.fromCharCode(0x61 + index)):
          String.fromCharCode(0x61 + index),
    for (var index = 0; index < 10; index++)
      InputKey.values.byName('digit$index'): '$index',
  };

  static const Map<KeyModifier, String> modifiers = {
    .shift: 'shift',
    .control: 'ctrl',
    .alt: 'alt',
    .meta: 'super',
  };
}
