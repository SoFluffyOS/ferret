import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification Source', () {
    test('reads event, flags, category, count and the little-endian uid', () {
      final event = AncsEvent.parse(
        Uint8List.fromList([0, 0x1A, 1, 3, 0x78, 0x56, 0x34, 0x12]),
      );

      expect(event?.kind, AncsEventKind.added);
      expect(event?.category, AncsCategory.incomingCall);
      expect(event?.categoryCount, 3);
      expect(event?.uid, 0x12345678);
      expect(event?.isSilent, isFalse);
      expect(event?.isImportant, isTrue);
      expect(event?.isPreExisting, isFalse);
      expect(event?.hasPositiveAction, isTrue);
      expect(event?.hasNegativeAction, isTrue);
    });

    test('reads every flag bit on its own', () {
      AncsEvent? withFlags(int flags) =>
          AncsEvent.parse(Uint8List.fromList([1, flags, 4, 1, 1, 0, 0, 0]));

      expect(withFlags(1 << 0)?.isSilent, isTrue);
      expect(withFlags(1 << 1)?.isImportant, isTrue);
      expect(withFlags(1 << 2)?.isPreExisting, isTrue);
      expect(withFlags(1 << 3)?.hasPositiveAction, isTrue);
      expect(withFlags(1 << 4)?.hasNegativeAction, isTrue);
      expect(withFlags(0)?.isPreExisting, isFalse);
      expect(withFlags(0)?.kind, AncsEventKind.modified);
      expect(withFlags(0)?.category, AncsCategory.social);
    });

    test('keeps a uid above the signed 32-bit range', () {
      final event = AncsEvent.parse(
        Uint8List.fromList([2, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF]),
      );

      expect(event?.kind, AncsEventKind.removed);
      expect(event?.uid, 0xFFFFFFFF);
    });

    test('maps the category ids of the specification in order', () {
      expect(AncsCategory.fromId(0), AncsCategory.other);
      expect(AncsCategory.fromId(2), AncsCategory.missedCall);
      expect(AncsCategory.fromId(3), AncsCategory.voicemail);
      expect(AncsCategory.fromId(5), AncsCategory.schedule);
      expect(AncsCategory.fromId(6), AncsCategory.email);
      expect(AncsCategory.fromId(7), AncsCategory.news);
      expect(AncsCategory.fromId(8), AncsCategory.healthAndFitness);
      expect(AncsCategory.fromId(9), AncsCategory.businessAndFinance);
      expect(AncsCategory.fromId(10), AncsCategory.location);
      expect(AncsCategory.fromId(11), AncsCategory.entertainment);
      expect(AncsCategory.fromId(200), AncsCategory.other);
    });

    test('rejects short packets and unknown events', () {
      expect(
        AncsEvent.parse(Uint8List.fromList([0, 0, 0, 0, 1, 0, 0])),
        isNull,
      );
      expect(
        AncsEvent.parse(Uint8List.fromList([3, 0, 0, 0, 1, 0, 0, 0])),
        isNull,
      );
    });
  });

  group('Control Point commands', () {
    test('Get Notification Attributes adds a max length to text only', () {
      final command = AncsCommands.notificationAttributes(0x01020304, const [
        .appIdentifier,
        .title,
        .subtitle,
        .message,
        .date,
        .positiveActionLabel,
        .negativeActionLabel,
      ], maxLength: 0x0120);

      expect(command, [
        0, 0x04, 0x03, 0x02, 0x01, //
        0,
        1, 0x20, 0x01,
        2, 0x20, 0x01,
        3, 0x20, 0x01,
        5,
        6,
        7,
      ]);
    });

    test('Get App Attributes ends the bundle id with NUL', () {
      expect(AncsCommands.appAttributes('ab.c'), [
        1,
        ...utf8.encode('ab.c'),
        0,
        0,
      ]);
    });

    test('Perform Notification Action carries the uid and the action', () {
      expect(AncsCommands.performAction(7, .positive), [2, 7, 0, 0, 0, 0]);
      expect(AncsCommands.performAction(0x100, .negative), [2, 0, 1, 0, 0, 1]);
    });
  });

  group('Data Source answers', () {
    Uint8List answer(int uid, Map<int, String> attributes) {
      final builder = BytesBuilder()
        ..addByte(0)
        ..add(
          (ByteData(4)..setUint32(0, uid, Endian.little)).buffer.asUint8List(),
        );
      for (final MapEntry(key: id, value: text) in attributes.entries) {
        final encoded = utf8.encode(text);
        builder
          ..addByte(id)
          ..addByte(encoded.length & 0xFF)
          ..addByte(encoded.length >> 8)
          ..add(encoded);
      }

      return builder.toBytes();
    }

    test('reads a whole answer from one packet', () {
      final assembler = AncsResponseAssembler.notification(
        9,
        attributeCount: 3,
      );

      final attributes = assembler.add(
        answer(9, {0: 'com.apple.MobileSMS', 1: 'Zoé', 3: 'On my way 🚗'}),
      );

      expect(attributes, {
        0: 'com.apple.MobileSMS',
        1: 'Zoé',
        3: 'On my way 🚗',
      });
    });

    test('waits for every packet of a split answer, wherever it is cut', () {
      final whole = answer(9, {0: 'com.example.app', 1: 'Title', 3: 'x' * 300});

      for (final cut in [1, 5, 6, 7, 8, 20, 30, whole.length - 1]) {
        final assembler = AncsResponseAssembler.notification(
          9,
          attributeCount: 3,
        );

        expect(assembler.add(whole.sublist(0, cut)), isNull, reason: '$cut');
        expect(assembler.add(whole.sublist(cut))?[3], 'x' * 300);
      }
    });

    test('puts three packets back together', () {
      final whole = answer(1, {1: 'a' * 40, 3: 'b' * 40});
      final assembler = AncsResponseAssembler.notification(
        1,
        attributeCount: 2,
      );

      expect(assembler.add(whole.sublist(0, 20)), isNull);
      expect(assembler.add(whole.sublist(20, 60)), isNull);
      expect(assembler.add(whole.sublist(60)), {1: 'a' * 40, 3: 'b' * 40});
    });

    test('keeps empty attributes', () {
      final assembler = AncsResponseAssembler.notification(
        2,
        attributeCount: 2,
      );

      expect(assembler.add(answer(2, {1: '', 2: ''})), {1: '', 2: ''});
    });

    test('drops a packet for another notification or command', () {
      final assembler = AncsResponseAssembler.notification(
        2,
        attributeCount: 1,
      );

      expect(assembler.add(answer(3, {1: 'other'})), isNull);
      expect(assembler.add(Uint8List.fromList([1, 2, 0, 0, 0])), isNull);
      expect(assembler.add(answer(2, {1: 'mine'})), {1: 'mine'});
    });

    test('reads an app answer keyed by the NUL-terminated bundle id', () {
      final assembler = AncsResponseAssembler.app(
        'com.apple.Music',
        attributeCount: 1,
      );
      final packet = Uint8List.fromList([
        1,
        ...utf8.encode('com.apple.Music'),
        0,
        0, 5, 0, ...utf8.encode('Music'), //
      ]);

      expect(assembler.add(packet.sublist(0, 10)), isNull);
      expect(assembler.add(packet.sublist(10)), {0: 'Music'});
    });

    test('drops an app answer for another app', () {
      final assembler = AncsResponseAssembler.app(
        'com.apple.Music',
        attributeCount: 1,
      );

      expect(
        assembler.add(
          Uint8List.fromList([1, ...utf8.encode('com.apple.Maps'), 0, 0, 0, 0]),
        ),
        isNull,
      );
    });

    test('survives text cut in the middle of a character', () {
      final cut = utf8.encode('é').sublist(0, 1);
      final packet = Uint8List.fromList([0, 4, 0, 0, 0, 1, 1, 0, ...cut]);
      final assembler = AncsResponseAssembler.notification(
        4,
        attributeCount: 1,
      );

      expect(assembler.add(packet), isNotNull);
    });
  });

  group('dates', () {
    test('reads the ANCS format as local time', () {
      expect(
        parseAncsDate('20261118T093005'),
        DateTime(2026, 11, 18, 9, 30, 5),
      );
    });

    test('rejects anything else', () {
      expect(parseAncsDate(''), isNull);
      expect(parseAncsDate('2026-11-18T09:30:05'), isNull);
      expect(parseAncsDate('20261318T093005'), isNull);
      expect(parseAncsDate('20261118T253005'), isNull);
    });
  });

  test('a notification is built from attributes by id', () {
    final event = AncsEvent.parse(
      Uint8List.fromList([0, 0x18, 1, 1, 5, 0, 0, 0]),
    );
    if (event == null) {
      fail('The event should parse');
    }

    final notification = AncsNotification.fromAttributes(event, {
      0: 'com.apple.mobilephone',
      1: 'Mum',
      3: 'Incoming call',
      5: '20261118T093005',
      6: 'Answer',
      7: 'Decline',
    });

    expect(notification.uid, 5);
    expect(notification.appId, 'com.apple.mobilephone');
    expect(notification.title, 'Mum');
    expect(notification.subtitle, '');
    expect(notification.message, 'Incoming call');
    expect(notification.date, DateTime(2026, 11, 18, 9, 30, 5));
    expect(notification.positiveActionLabel, 'Answer');
    expect(notification.negativeActionLabel, 'Decline');
  });
}
