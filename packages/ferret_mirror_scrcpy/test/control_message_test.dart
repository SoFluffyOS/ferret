import 'dart:convert';

import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bytes.dart';

/// The expected bytes are the ones in scrcpy 5.0.1's own
/// `app/tests/test_control_msg_serialize.c`.
void main() {
  group('ControlMessage', () {
    test('inject keycode', () {
      final message = ControlMessage.injectKeycode(
        action: AndroidKeyAction.up,
        keycode: 66,
        repeat: 5,
        metaState: 0x41,
      );

      expect(message, hex('00 01 00000042 00000005 00000041'));
    });

    test('inject text', () {
      final message = ControlMessage.injectText('hello, world!');

      expect(
        message,
        joined([hex('01 0000000d'), utf8.encode('hello, world!')]),
      );
    });

    test('inject text stops at 300 bytes, on a whole character', () {
      final exact = ControlMessage.injectText('a' * 400);
      final accented = ControlMessage.injectText('${'a' * 299}é');

      expect(exact, joined([hex('01 0000012c'), utf8.encode('a' * 300)]));
      expect(accented, joined([hex('01 0000012b'), utf8.encode('a' * 299)]));
    });

    test('inject touch', () {
      final message = ControlMessage.injectTouch(
        action: AndroidMotionAction.down,
        pointerId: 0x1234567887654321,
        x: 100,
        y: 200,
        videoWidth: 1080,
        videoHeight: 1920,
        pressure: 1,
        actionButton: 1,
        buttons: 1,
      );

      expect(
        message,
        hex(
          '02 00 1234567887654321 00000064 000000c8 0438 0780 ffff '
          '00000001 00000001',
        ),
      );
    });

    test('inject touch writes the mouse pointer id as -1', () {
      final message = ControlMessage.injectTouch(
        action: AndroidMotionAction.hoverMove,
        pointerId: ControlMessage.pointerIdMouse,
        x: 1,
        y: 2,
        videoWidth: 576,
        videoHeight: 1280,
        pressure: 0,
      );

      expect(message.sublist(0, 10), hex('02 07 ffffffffffffffff'));
      expect(message.sublist(22, 24), hex('0000'));
    });

    test('inject scroll', () {
      final message = ControlMessage.injectScroll(
        x: 260,
        y: 1026,
        videoWidth: 1080,
        videoHeight: 1920,
        horizontal: 16,
        vertical: -16,
        buttons: 1,
      );

      expect(
        message,
        hex('03 00000104 00000402 0438 0780 7fff 8000 00000001'),
      );
    });

    test('inject scroll keeps within 16 notches', () {
      final message = ControlMessage.injectScroll(
        x: 0,
        y: 0,
        videoWidth: 10,
        videoHeight: 10,
        horizontal: 40,
        vertical: 1,
      );

      expect(message.sublist(13, 17), hex('7fff 0800'));
    });

    test('back or screen on', () {
      expect(
        ControlMessage.backOrScreenOn(action: AndroidKeyAction.up),
        hex('04 01'),
      );
    });

    test('set clipboard', () {
      final message = ControlMessage.setClipboard(
        'hello, world!',
        paste: true,
        sequence: 0x0102030405060708,
      );

      expect(
        message,
        joined([
          hex('09 0102030405060708 01 0000000d'),
          utf8.encode('hello, world!'),
        ]),
      );
    });

    test('messages without a body are one byte', () {
      expect(ControlMessage.expandNotificationPanel(), [5]);
      expect(ControlMessage.rotateDevice(), [11]);
      expect(ControlMessage.resetVideo(), [17]);
    });
  });

  group('HidKeycodes', () {
    test('maps letters, digits and function keys by range', () {
      expect(HidKeycodes.keycodeFor(0x04), 29);
      expect(HidKeycodes.keycodeFor(0x1D), 54);
      expect(HidKeycodes.keycodeFor(0x1E), 8);
      expect(HidKeycodes.keycodeFor(0x26), 16);
      expect(HidKeycodes.keycodeFor(0x27), 7);
      expect(HidKeycodes.keycodeFor(0x3A), 131);
      expect(HidKeycodes.keycodeFor(0x45), 142);
      expect(HidKeycodes.keycodeFor(0x59), 145);
    });

    test('maps the keys people use most', () {
      expect(HidKeycodes.keycodeFor(0x28), 66);
      expect(HidKeycodes.keycodeFor(0x2A), 67);
      expect(HidKeycodes.keycodeFor(0x29), 111);
      expect(HidKeycodes.keycodeFor(0x2C), 62);
      expect(HidKeycodes.keycodeFor(0x52), 19);
      expect(HidKeycodes.keycodeFor(0xE1), 59);
    });

    test('has nothing for a usage Android lacks', () {
      expect(HidKeycodes.keycodeFor(0x00), isNull);
      expect(HidKeycodes.keycodeFor(0x32), isNull);
      expect(HidKeycodes.keycodeFor(0x1234), isNull);
    });
  });
}
