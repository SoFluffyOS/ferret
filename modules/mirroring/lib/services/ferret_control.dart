import 'dart:async';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';
import 'package:protocol/remote_input.dart' as input;

/// Clicks, keys and the phone's own buttons, sent over Ferret to a phone
/// whose owner let this computer control it. What happens in one go
/// leaves as one batch.
class FerretControl implements MirrorControl {
  FerretControl({
    required Future<void> Function(GeneratedMessage message) send,
    required this.abilities,
    required this.buttons,
  }) : _send = send;

  /// Taken from what the phone says it takes.
  factory FerretControl.of(
    ControlState state, {
    required Future<void> Function(GeneratedMessage message) send,
  }) => FerretControl(
    send: send,
    abilities: {
      for (final kind in state.kinds)
        ?switch (kind) {
          .CONTROL_KIND_POINTER => ControlAbility.pointer,
          .CONTROL_KIND_KEYS => ControlAbility.keys,
          .CONTROL_KIND_TEXT => ControlAbility.text,
          .CONTROL_KIND_BUTTONS => ControlAbility.buttons,
          _ => null,
        },
    },
    buttons: {
      for (final button in state.buttons) ?_buttonFrom(button),
    },
  );

  @override
  final Set<ControlAbility> abilities;

  /// The phone's own buttons it can press.
  final Set<DeviceButton> buttons;

  final Future<void> Function(GeneratedMessage message) _send;
  final List<ControlEvent> _waiting = [];

  @override
  void pointer(MirrorPointer event) {
    if (!abilities.contains(ControlAbility.pointer)) {
      return;
    }

    final phase = switch (event.phase) {
      .down => TouchPhase.TOUCH_PHASE_DOWN,
      .move => TouchPhase.TOUCH_PHASE_MOVE,
      .up => TouchPhase.TOUCH_PHASE_UP,
      .cancel => TouchPhase.TOUCH_PHASE_CANCEL,
      .scroll => TouchPhase.TOUCH_PHASE_SCROLL,
      .hover => null,
    };
    if (phase == null) {
      return;
    }

    _queue(
      ControlEvent(
        pointer: PointerInput(
          phase: phase,
          x: event.x,
          y: event.y,
          scrollX: event.scrollX,
          scrollY: event.scrollY,
        ),
      ),
    );
  }

  @override
  void key(MirrorKey event) {
    final key = keyOf(event.usage);
    if (!abilities.contains(ControlAbility.keys) || key == null) {
      return;
    }

    _queue(
      ControlEvent(
        key: input.KeyEvent(
          key: key,
          pressed: event.phase == .down,
          modifiers: event.modifiers.map(
            (modifier) => switch (modifier) {
              .shift => input.Modifier.MODIFIER_SHIFT,
              .control => input.Modifier.MODIFIER_CONTROL,
              .alt => input.Modifier.MODIFIER_ALT,
              .meta => input.Modifier.MODIFIER_META,
            },
          ),
        ),
      ),
    );
  }

  @override
  void text(String text) {
    if (!abilities.contains(ControlAbility.text) || text.isEmpty) {
      return;
    }

    _queue(ControlEvent(text: input.TextInput(text: text)));
  }

  @override
  void press(DeviceButton button) {
    final proto = _buttonTo(button);
    if (!buttons.contains(button) || proto == null) {
      return;
    }

    _queue(ControlEvent(button: ButtonPress(button: proto)));
  }

  /// The phone's own clipboard is Clipboard's job over Ferret.
  @override
  void setClipboard(String text, {bool paste = false}) {}

  /// The key with USB HID [usage] on the keyboard page, or null for one
  /// the phone has no use for.
  static input.Key? keyOf(int usage) {
    if (usage >= _letterA && usage <= _letterZ) {
      return input.Key.valueOf(input.Key.KEY_A.value + usage - _letterA);
    }

    if (usage >= _digit1 && usage <= _digit9) {
      return input.Key.valueOf(input.Key.KEY_DIGIT_1.value + usage - _digit1);
    }

    if (usage >= _f1 && usage <= _f12) {
      return input.Key.valueOf(input.Key.KEY_F1.value + usage - _f1);
    }

    return switch (usage) {
      0x27 => .KEY_DIGIT_0,
      0x28 => .KEY_ENTER,
      0x29 => .KEY_ESCAPE,
      0x2A => .KEY_BACKSPACE,
      0x2B => .KEY_TAB,
      0x2C => .KEY_SPACE,
      0x4A => .KEY_HOME,
      0x4B => .KEY_PAGE_UP,
      0x4C => .KEY_DELETE,
      0x4D => .KEY_END,
      0x4E => .KEY_PAGE_DOWN,
      0x4F => .KEY_ARROW_RIGHT,
      0x50 => .KEY_ARROW_LEFT,
      0x51 => .KEY_ARROW_DOWN,
      0x52 => .KEY_ARROW_UP,
      0x7F => .KEY_VOLUME_MUTE,
      0x80 => .KEY_VOLUME_UP,
      0x81 => .KEY_VOLUME_DOWN,
      _ => null,
    };
  }

  static const _letterA = 0x04;
  static const _letterZ = 0x1D;
  static const _digit1 = 0x1E;
  static const _digit9 = 0x26;
  static const _f1 = 0x3A;
  static const _f12 = 0x45;

  static DeviceButton? _buttonFrom(ControlButton button) => switch (button) {
    .CONTROL_BUTTON_BACK => .back,
    .CONTROL_BUTTON_HOME => .home,
    .CONTROL_BUTTON_RECENTS => .recents,
    .CONTROL_BUTTON_NOTIFICATIONS => .notifications,
    .CONTROL_BUTTON_POWER => .power,
    .CONTROL_BUTTON_VOLUME_UP => .volumeUp,
    .CONTROL_BUTTON_VOLUME_DOWN => .volumeDown,
    _ => null,
  };

  static ControlButton? _buttonTo(DeviceButton button) => switch (button) {
    .back => .CONTROL_BUTTON_BACK,
    .home => .CONTROL_BUTTON_HOME,
    .recents => .CONTROL_BUTTON_RECENTS,
    .notifications => .CONTROL_BUTTON_NOTIFICATIONS,
    .power => .CONTROL_BUTTON_POWER,
    .volumeUp => .CONTROL_BUTTON_VOLUME_UP,
    .volumeDown => .CONTROL_BUTTON_VOLUME_DOWN,
    .rotate => null,
  };

  void _queue(ControlEvent event) {
    _waiting.add(event);
    if (_waiting.length == 1) {
      scheduleMicrotask(_flush);
    }
  }

  void _flush() {
    if (_waiting.isEmpty) {
      return;
    }

    final batch = ControlInput(events: List.of(_waiting));
    _waiting.clear();
    unawaited(_send(batch));
  }
}
