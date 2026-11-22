import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bytes.dart';

void main() {
  late List<Uint8List> sent;
  late ScrcpyControl control;

  setUp(() {
    sent = [];
    control = ScrcpyControl(sent.add)..setVideoSize(576, 1280);
  });

  ByteData fields(Uint8List message) => ByteData.sublistView(message);

  group('pointer', () {
    test('drops events before the video has a size', () {
      final early = ScrcpyControl(sent.add);

      early.pointer(const MirrorPointer(phase: .down, x: 0.5, y: 0.5));

      expect(sent, isEmpty);
    });

    test('turns fractions into pixels of the current video', () {
      control.pointer(const MirrorPointer(phase: .down, x: 0.5, y: 0.25));

      final message = fields(sent.single);
      expect(message.getUint8(0), ControlMessage.typeInjectTouch);
      expect(message.getUint8(1), AndroidMotionAction.down);
      expect(message.getInt64(2), ControlMessage.pointerIdMouse);
      expect((message.getInt32(10), message.getInt32(14)), (288, 320));
      expect((message.getUint16(18), message.getUint16(20)), (576, 1280));
      expect(message.getUint16(22), 0xFFFF);
      expect((message.getUint32(24), message.getUint32(28)), (1, 1));
    });

    test('follows the video when it rotates', () {
      control.setVideoSize(1280, 576);

      control.pointer(const MirrorPointer(phase: .move, x: 1, y: 1.5));

      final message = fields(sent.single);
      expect((message.getInt32(10), message.getInt32(14)), (1279, 575));
      expect((message.getUint16(18), message.getUint16(20)), (1280, 576));
    });

    test('lifts with no pressure and no button left', () {
      control.pointer(const MirrorPointer(phase: .down, x: 0, y: 0));
      control.pointer(const MirrorPointer(phase: .up, x: 0, y: 0));

      final up = fields(sent.last);
      expect(up.getUint8(1), AndroidMotionAction.up);
      expect(up.getUint16(22), 0);
      expect((up.getUint32(24), up.getUint32(28)), (1, 0));
    });

    test('says which button went down on a right click', () {
      control.pointer(
        const MirrorPointer(phase: .down, x: 0, y: 0, buttons: 2),
      );

      final down = fields(sent.single);
      expect((down.getUint32(24), down.getUint32(28)), (2, 2));
    });

    test('hovers as a mouse, cancels as a lift', () {
      control.pointer(const MirrorPointer(phase: .hover, x: 0, y: 0));
      control.pointer(const MirrorPointer(phase: .cancel, x: 0, y: 0));

      expect(sent[0][1], AndroidMotionAction.hoverMove);
      expect(fields(sent[0]).getUint32(28), 0);
      expect(sent[1][1], AndroidMotionAction.up);
    });

    test('keeps other fingers under their own ids', () {
      control.pointer(
        const MirrorPointer(phase: .down, x: 0, y: 0, pointerId: 3),
      );

      expect(fields(sent.single).getInt64(2), 3);
    });

    test('scrolls down as a negative Android scroll', () {
      control.pointer(
        const MirrorPointer(
          phase: .scroll,
          x: 0.5,
          y: 0.5,
          scrollX: 2,
          scrollY: 4,
        ),
      );

      final message = fields(sent.single);
      expect(message.getUint8(0), ControlMessage.typeInjectScroll);
      expect((message.getInt32(1), message.getInt32(5)), (288, 640));
      expect(message.getInt16(13), 0x1000);
      expect(message.getInt16(15), -0x2000);
      expect(message.getUint32(17), 0);
    });
  });

  group('keys', () {
    test('sends the Android keycode with its modifiers', () {
      control.key(
        const MirrorKey(
          phase: .down,
          usage: 0x04,
          modifiers: {.shift, .control},
          repeat: 2,
        ),
      );

      expect(sent.single, hex('00 00 0000001d 00000002 00001001'));
    });

    test('sends key up', () {
      control.key(const MirrorKey(phase: .up, usage: 0x28));

      expect(sent.single, hex('00 01 00000042 00000000 00000000'));
    });

    test('drops a key Android does not have', () {
      control.key(const MirrorKey(phase: .down, usage: 0x32));

      expect(sent, isEmpty);
    });
  });

  group('text and clipboard', () {
    test('types long text in pieces of at most 300 bytes', () {
      control.text('${'a' * 299}é${'b' * 10}');

      expect(sent, hasLength(2));
      expect(fields(sent[0]).getUint32(1), 299);
      expect(fields(sent[1]).getUint32(1), 12);
    });

    test('sends nothing for empty text', () {
      control.text('');

      expect(sent, isEmpty);
    });

    test('sets the clipboard, pasting when asked', () {
      control.setClipboard('hi', paste: true);

      expect(sent.single, hex('09 0000000000000000 01 00000002 6869'));
    });
  });

  group('buttons', () {
    test('back goes through "back or screen on", down then up', () {
      control.press(.back);

      expect(sent, [hex('04 00'), hex('04 01')]);
    });

    test('home, recents, power and volume are keycodes', () {
      const keycodes = {
        DeviceButton.home: 3,
        DeviceButton.recents: 187,
        DeviceButton.power: 26,
        DeviceButton.volumeUp: 24,
        DeviceButton.volumeDown: 25,
      };

      for (final MapEntry(key: button, value: keycode) in keycodes.entries) {
        sent.clear();
        control.press(button);

        expect(sent, hasLength(2));
        expect(fields(sent[0]).getUint32(2), keycode);
        expect((sent[0][1], sent[1][1]), (0, 1));
      }
    });

    test('notifications and rotate have their own messages', () {
      control.press(.notifications);
      control.press(.rotate);

      expect(sent, [
        [5],
        [11],
      ]);
    });
  });

  test('offers every ability a phone takes; a computer\'s own mouse is for '
      'a second display', () {
    expect(
      control.abilities,
      ControlAbility.values.toSet().difference({ControlAbility.mouse}),
    );
  });
}
