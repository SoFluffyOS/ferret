import 'dart:convert';
import 'dart:typed_data';

/// The messages scrcpy's server reads on its control socket, as scrcpy
/// 5.0.1 serializes them (`app/src/control_msg.c`). All numbers are
/// big-endian.
abstract final class ControlMessage {
  static const int typeInjectKeycode = 0;
  static const int typeInjectText = 1;
  static const int typeInjectTouch = 2;
  static const int typeInjectScroll = 3;
  static const int typeBackOrScreenOn = 4;
  static const int typeExpandNotificationPanel = 5;
  static const int typeSetClipboard = 9;
  static const int typeRotateDevice = 11;
  static const int typeResetVideo = 17;

  /// The server's own limits, in UTF-8 bytes.
  static const int maxTextLength = 300;
  static const int maxClipboardLength = (1 << 18) - 14;

  /// What scrcpy uses for the mouse: the server treats it as a real mouse
  /// when hovering or with a secondary button, as a finger otherwise.
  static const int pointerIdMouse = -1;

  /// The most a scroll message can carry on each axis, in notches.
  static const double maxScroll = 16;

  static Uint8List injectKeycode({
    required int action,
    required int keycode,
    int repeat = 0,
    int metaState = 0,
  }) {
    final message = ByteData(14)
      ..setUint8(0, typeInjectKeycode)
      ..setUint8(1, action)
      ..setUint32(2, keycode)
      ..setUint32(6, repeat)
      ..setUint32(10, metaState);

    return message.buffer.asUint8List();
  }

  /// Types [text], cut to [maxTextLength] bytes without splitting a
  /// character.
  static Uint8List injectText(String text) {
    final bytes = _utf8Truncated(text, maxTextLength);
    final message = ByteData(5 + bytes.length)
      ..setUint8(0, typeInjectText)
      ..setUint32(1, bytes.length);

    return message.buffer.asUint8List()..setRange(5, 5 + bytes.length, bytes);
  }

  /// [x] and [y] are pixels of the video, [videoWidth] by [videoHeight]:
  /// the server drops the event when that size isn't the current one.
  static Uint8List injectTouch({
    required int action,
    required int pointerId,
    required int x,
    required int y,
    required int videoWidth,
    required int videoHeight,
    required double pressure,
    int actionButton = 0,
    int buttons = 0,
  }) {
    final message = ByteData(32)
      ..setUint8(0, typeInjectTouch)
      ..setUint8(1, action)
      ..setInt64(2, pointerId);
    _setPosition(message, 10, x, y, videoWidth, videoHeight);
    message
      ..setUint16(22, _unsignedFixedPoint(pressure))
      ..setUint32(24, actionButton)
      ..setUint32(28, buttons);

    return message.buffer.asUint8List();
  }

  /// Scrolls by notches, each axis within [maxScroll]: positive
  /// [horizontal] is right, positive [vertical] is up, as on Android.
  static Uint8List injectScroll({
    required int x,
    required int y,
    required int videoWidth,
    required int videoHeight,
    required double horizontal,
    required double vertical,
    int buttons = 0,
  }) {
    final message = ByteData(21)..setUint8(0, typeInjectScroll);
    _setPosition(message, 1, x, y, videoWidth, videoHeight);
    message
      ..setInt16(13, _signedFixedPoint(horizontal / maxScroll))
      ..setInt16(15, _signedFixedPoint(vertical / maxScroll))
      ..setUint32(17, buttons);

    return message.buffer.asUint8List();
  }

  /// Back, or the power key when the screen is off.
  static Uint8List backOrScreenOn({required int action}) =>
      Uint8List.fromList([typeBackOrScreenOn, action]);

  static Uint8List expandNotificationPanel() =>
      Uint8List.fromList([typeExpandNotificationPanel]);

  static Uint8List rotateDevice() => Uint8List.fromList([typeRotateDevice]);

  /// Restarts the encoder, so the next picture is a keyframe.
  static Uint8List resetVideo() => Uint8List.fromList([typeResetVideo]);

  /// Sets the device's clipboard. With a [sequence] other than 0 the
  /// server acknowledges it.
  static Uint8List setClipboard(
    String text, {
    bool paste = false,
    int sequence = 0,
  }) {
    final bytes = _utf8Truncated(text, maxClipboardLength);
    final pasteFlag = switch (paste) {
      true => 1,
      false => 0,
    };
    final message = ByteData(14 + bytes.length)
      ..setUint8(0, typeSetClipboard)
      ..setInt64(1, sequence)
      ..setUint8(9, pasteFlag)
      ..setUint32(10, bytes.length);

    return message.buffer.asUint8List()..setRange(14, 14 + bytes.length, bytes);
  }

  static void _setPosition(
    ByteData message,
    int offset,
    int x,
    int y,
    int videoWidth,
    int videoHeight,
  ) {
    message
      ..setInt32(offset, x)
      ..setInt32(offset + 4, y)
      ..setUint16(offset + 8, videoWidth)
      ..setUint16(offset + 10, videoHeight);
  }

  /// 0 to 1 as scrcpy's unsigned 16-bit fixed point.
  static int _unsignedFixedPoint(double value) {
    final scaled = (value.clamp(0, 1) * 0x10000).toInt();
    if (scaled >= 0xFFFF) {
      return 0xFFFF;
    }

    return scaled;
  }

  /// -1 to 1 as scrcpy's signed 16-bit fixed point.
  static int _signedFixedPoint(double value) {
    final scaled = (value.clamp(-1, 1) * 0x8000).toInt();
    if (scaled >= 0x7FFF) {
      return 0x7FFF;
    }

    return scaled;
  }

  static Uint8List _utf8Truncated(String text, int maxLength) {
    final bytes = utf8.encode(text);
    if (bytes.length <= maxLength) {
      return bytes;
    }

    var end = maxLength;
    while (end > 0 && bytes[end] & 0xC0 == 0x80) {
      end--;
    }

    return Uint8List.sublistView(bytes, 0, end);
  }
}
