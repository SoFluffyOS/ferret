import 'dart:typed_data';

import 'package:ferret_remote_input/src/input_action.dart';
import 'package:ferret_remote_input/src/key_chords.dart';
import 'package:ferret_remote_input/src/keys/keys.dart';
import 'package:ferret_remote_input/src/linux/uinput_codec.dart';
import 'package:ferret_remote_input/src/linux/uinput_syscalls.dart';
import 'package:ferret_remote_input/src/linux/us_layout.dart';

/// A virtual mouse and keyboard made with `/dev/uinput`. The desktop sees it
/// like a plugged-in device, so it works on X11 and Wayland alike.
class UinputDevice {
  UinputDevice._(this._syscalls, this._fd);

  static const deviceName = 'Ferret remote input';

  /// Pixels of scrolling per wheel notch.
  static const pixelsPerNotch = 40;

  /// Creates the device, or returns null when uinput can't be used.
  static UinputDevice? create(UinputSyscalls syscalls) {
    if (!syscalls.canWrite(UinputCodec.path)) {
      return null;
    }

    final fd = syscalls.openWrite(UinputCodec.path);
    if (fd < 0) {
      return null;
    }

    final ok = _setUp(syscalls, fd);
    if (!ok) {
      syscalls.close(fd);
      return null;
    }

    return UinputDevice._(syscalls, fd);
  }

  /// Every key and button the device may press.
  static Set<int> get keyCodes => {
    ...LinuxKeyCodes.keys.values,
    ...LinuxKeyCodes.modifiers.values,
    for (final rune in _typeable.runes)
      ?UsLayout.keyOf(String.fromCharCode(rune))?.code,
    LinuxKeyCodes.buttonLeft,
    LinuxKeyCodes.buttonRight,
    LinuxKeyCodes.buttonMiddle,
  };

  static const _typeable = '-=[];\'`\\,./';

  static const relativeAxes = [
    UinputCodec.relX,
    UinputCodec.relY,
    UinputCodec.relWheel,
    UinputCodec.relHWheel,
    UinputCodec.relWheelHiRes,
    UinputCodec.relHWheelHiRes,
  ];

  final UinputSyscalls _syscalls;
  final int _fd;
  final KeyChords _chords = KeyChords(LinuxKeyCodes.modifiers);
  int _wheelRemainder = 0;
  int _hWheelRemainder = 0;
  bool _closed = false;

  static bool _setUp(UinputSyscalls syscalls, int fd) {
    final requests = <(int, int)>[
      (UinputCodec.uiSetEvBit, UinputCodec.evKey),
      (UinputCodec.uiSetEvBit, UinputCodec.evRel),
      for (final code in keyCodes) (UinputCodec.uiSetKeyBit, code),
      for (final axis in relativeAxes) (UinputCodec.uiSetRelBit, axis),
    ];
    for (final (request, value) in requests) {
      if (syscalls.ioctlValue(fd, request, value) < 0) {
        return false;
      }
    }

    final setup = UinputCodec.setup(deviceName);
    if (syscalls.ioctlBytes(fd, UinputCodec.uiDevSetup, setup) < 0) {
      return false;
    }

    return syscalls.ioctlValue(fd, UinputCodec.uiDevCreate, 0) >= 0;
  }

  /// Performs [actions]. Returns the text it could not type with a US
  /// layout, for another backend to type, or empty.
  String send(List<InputAction> actions) {
    if (_closed) {
      return '';
    }

    final events = <(int, int, int)>[];
    final untyped = StringBuffer();
    for (final action in actions) {
      untyped.write(_append(events, action));
    }

    _write(events);
    return untyped.toString();
  }

  void close() {
    if (_closed) {
      return;
    }

    _closed = true;
    _syscalls.ioctlValue(_fd, UinputCodec.uiDevDestroy, 0);
    _syscalls.close(_fd);
  }

  /// Adds the events for [action] and returns what it couldn't type.
  String _append(List<(int, int, int)> events, InputAction action) {
    switch (action) {
      case MoveAction(:final dx, :final dy):
        events.addAll([
          if (dx != 0) (UinputCodec.evRel, UinputCodec.relX, dx),
          if (dy != 0) (UinputCodec.evRel, UinputCodec.relY, dy),
          _sync,
        ]);
        return '';
      case ScrollAction(:final dx, :final dy):
        events.addAll(_scroll(dx, dy));
        return '';
      case ButtonAction(:final button, :final pressed):
        events.addAll([
          (UinputCodec.evKey, _buttonCode(button), _valueOf(pressed)),
          _sync,
        ]);
        return '';
      case KeyAction(:final key, :final pressed, :final modifiers):
        final code = LinuxKeyCodes.keys[key];
        if (code == null) {
          return '';
        }

        final raw = switch (pressed) {
          true => _chords.press(code, modifiers),
          false => _chords.release(code),
        };
        events.addAll(_rawKeys(raw));
        return '';
      case TextAction(:final text):
        return _type(events, text);
    }
  }

  String _type(List<(int, int, int)> events, String text) {
    final untyped = StringBuffer();
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      final usKey = UsLayout.keyOf(character);
      if (usKey == null) {
        untyped.write(character);
        continue;
      }

      final modifiers = switch (usKey.shift) {
        true => {KeyModifier.shift},
        false => <KeyModifier>{},
      };
      events.addAll(_rawKeys(_chords.tap(usKey.code, modifiers)));
    }

    return untyped.toString();
  }

  List<(int, int, int)> _rawKeys(List<RawKey> raw) => [
    for (final rawKey in raw) ...[
      (UinputCodec.evKey, rawKey.code, _valueOf(rawKey.pressed)),
      _sync,
    ],
  ];

  /// High-resolution wheel events, plus a classic notch event each time a
  /// whole notch adds up, as the kernel asks of devices that offer both.
  List<(int, int, int)> _scroll(int dx, int dy) {
    final vertical = -dy * UinputCodec.hiResPerNotch ~/ pixelsPerNotch;
    final horizontal = dx * UinputCodec.hiResPerNotch ~/ pixelsPerNotch;
    _wheelRemainder += vertical;
    _hWheelRemainder += horizontal;
    final notches = _wheelRemainder ~/ UinputCodec.hiResPerNotch;
    final hNotches = _hWheelRemainder ~/ UinputCodec.hiResPerNotch;
    _wheelRemainder -= notches * UinputCodec.hiResPerNotch;
    _hWheelRemainder -= hNotches * UinputCodec.hiResPerNotch;

    return [
      if (vertical != 0)
        (UinputCodec.evRel, UinputCodec.relWheelHiRes, vertical),
      if (notches != 0) (UinputCodec.evRel, UinputCodec.relWheel, notches),
      if (horizontal != 0)
        (UinputCodec.evRel, UinputCodec.relHWheelHiRes, horizontal),
      if (hNotches != 0) (UinputCodec.evRel, UinputCodec.relHWheel, hNotches),
      _sync,
    ];
  }

  void _write(List<(int, int, int)> events) {
    if (events.isEmpty) {
      return;
    }

    final longSize = _syscalls.longSize;
    final size = UinputCodec.eventSize(longSize);
    final bytes = Uint8List(size * events.length);
    for (final (index, (type, code, value)) in events.indexed) {
      bytes.setAll(
        index * size,
        UinputCodec.event(type, code, value, longSize: longSize),
      );
    }

    _syscalls.write(_fd, bytes);
  }

  static const _sync = (UinputCodec.evSyn, UinputCodec.synReport, 0);

  int _valueOf(bool pressed) => switch (pressed) {
    true => 1,
    false => 0,
  };

  int _buttonCode(PointerButton button) => switch (button) {
    .left => LinuxKeyCodes.buttonLeft,
    .right => LinuxKeyCodes.buttonRight,
    .middle => LinuxKeyCodes.buttonMiddle,
  };
}
