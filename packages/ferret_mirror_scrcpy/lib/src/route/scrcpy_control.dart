import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/src/protocol/protocol.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';

/// Mouse, keyboard and buttons on the device, written as scrcpy control
/// messages to [send].
class ScrcpyControl implements MirrorControl {
  ScrcpyControl(this._send);

  static const int _primaryButton = 1;

  final void Function(Uint8List message) _send;

  int _videoWidth = 0;
  int _videoHeight = 0;
  int _pressedButtons = 0;

  @override
  Set<ControlAbility> get abilities => const {
    .pointer,
    .keys,
    .text,
    .buttons,
    .clipboard,
  };

  /// The size of the video right now. The server maps positions from it,
  /// and drops events that name another size.
  void setVideoSize(int width, int height) {
    _videoWidth = width;
    _videoHeight = height;
  }

  @override
  void pointer(MirrorPointer event) {
    if (_videoWidth == 0 || _videoHeight == 0) {
      return;
    }

    final x = _pixel(event.x, _videoWidth);
    final y = _pixel(event.y, _videoHeight);
    switch (event.phase) {
      case .scroll:
        _scroll(event, x, y);
      case .hover:
        _touch(AndroidMotionAction.hoverMove, event, x, y, pressure: 0);
      case .down:
        final changed = event.buttons & ~_pressedButtons;
        _pressedButtons = event.buttons;
        _touch(
          AndroidMotionAction.down,
          event,
          x,
          y,
          pressure: 1,
          actionButton: _orPrimary(changed),
          buttons: _pressedButtons,
        );
      case .move:
        _touch(
          AndroidMotionAction.move,
          event,
          x,
          y,
          pressure: 1,
          buttons: _pressedButtons,
        );
      // A cancelled pointer is lifted too: the server only forgets a
      // pointer on "up".
      case .up || .cancel:
        final released = _orPrimary(_pressedButtons);
        _pressedButtons = 0;
        _touch(
          AndroidMotionAction.up,
          event,
          x,
          y,
          pressure: 0,
          actionButton: released,
        );
    }
  }

  @override
  void key(MirrorKey event) {
    final keycode = HidKeycodes.keycodeFor(event.usage);
    if (keycode == null) {
      return;
    }

    final action = switch (event.phase) {
      .down => AndroidKeyAction.down,
      .up => AndroidKeyAction.up,
    };
    _send(
      ControlMessage.injectKeycode(
        action: action,
        keycode: keycode,
        repeat: event.repeat,
        metaState: _metaState(event.modifiers),
      ),
    );
  }

  /// The server types only what the device's key map has, so mostly ASCII.
  /// Anything else is left out by Android; [setClipboard] with paste gets
  /// it through.
  @override
  void text(String text) {
    for (final chunk in _chunks(text)) {
      _send(ControlMessage.injectText(chunk));
    }
  }

  @override
  void press(DeviceButton button) {
    switch (button) {
      case .back:
        _send(ControlMessage.backOrScreenOn(action: AndroidKeyAction.down));
        _send(ControlMessage.backOrScreenOn(action: AndroidKeyAction.up));
      case .home:
        _tap(AndroidKeycode.home);
      case .recents:
        _tap(AndroidKeycode.appSwitch);
      case .power:
        _tap(AndroidKeycode.power);
      case .volumeUp:
        _tap(AndroidKeycode.volumeUp);
      case .volumeDown:
        _tap(AndroidKeycode.volumeDown);
      case .notifications:
        _send(ControlMessage.expandNotificationPanel());
      case .rotate:
        _send(ControlMessage.rotateDevice());
    }
  }

  @override
  void setClipboard(String text, {bool paste = false}) =>
      _send(ControlMessage.setClipboard(text, paste: paste));

  void _touch(
    int action,
    MirrorPointer event,
    int x,
    int y, {
    required double pressure,
    int actionButton = 0,
    int buttons = 0,
  }) {
    final pointerId = switch (event.pointerId) {
      0 => ControlMessage.pointerIdMouse,
      final finger => finger,
    };
    _send(
      ControlMessage.injectTouch(
        action: action,
        pointerId: pointerId,
        x: x,
        y: y,
        videoWidth: _videoWidth,
        videoHeight: _videoHeight,
        pressure: pressure,
        actionButton: actionButton,
        buttons: buttons,
      ),
    );
  }

  /// Android counts a wheel turned away from the user as positive, so
  /// "down" changes sign.
  void _scroll(MirrorPointer event, int x, int y) {
    _send(
      ControlMessage.injectScroll(
        x: x,
        y: y,
        videoWidth: _videoWidth,
        videoHeight: _videoHeight,
        horizontal: event.scrollX,
        vertical: -event.scrollY,
        buttons: _pressedButtons,
      ),
    );
  }

  void _tap(int keycode) {
    _send(
      ControlMessage.injectKeycode(
        action: AndroidKeyAction.down,
        keycode: keycode,
      ),
    );
    _send(
      ControlMessage.injectKeycode(
        action: AndroidKeyAction.up,
        keycode: keycode,
      ),
    );
  }

  static int _pixel(double fraction, int size) =>
      (fraction.clamp(0, 1) * size).floor().clamp(0, size - 1);

  static int _orPrimary(int buttons) {
    if (buttons == 0) {
      return _primaryButton;
    }

    return buttons;
  }

  static int _metaState(Set<KeyModifier> modifiers) {
    var state = 0;
    for (final modifier in modifiers) {
      state |= switch (modifier) {
        .shift => AndroidMetaState.shift,
        .control => AndroidMetaState.control,
        .alt => AndroidMetaState.alt,
        .meta => AndroidMetaState.meta,
      };
    }

    return state;
  }

  /// [text] in pieces the server takes, never cutting a character.
  static Iterable<String> _chunks(String text) sync* {
    final chunk = StringBuffer();
    var chunkLength = 0;
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      final length = utf8.encode(character).length;
      if (chunkLength + length > ControlMessage.maxTextLength) {
        yield chunk.toString();
        chunk.clear();
        chunkLength = 0;
      }

      chunk.write(character);
      chunkLength += length;
    }

    if (chunkLength > 0) {
      yield chunk.toString();
    }
  }
}
