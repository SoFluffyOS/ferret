import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeClipboard clipboard;
  late FakeHost host;
  late FakeSession pixel;
  late ClipboardFeature feature;
  late DateTime now;

  Future<void> start({
    Map<String, Object?>? settings,
    ClipboardAccess access = .always,
    ClipboardContent? initial,
  }) async {
    clipboard = FakeClipboard(access: access, content: initial);
    host = await FakeHost.create(settings: settings);
    pixel = FakeSession('pixelpixelpixelp');
    host.sessions = [pixel];
    now = DateTime(2026, 11, 18, 9);
    feature = ClipboardFeature(clipboard: () => clipboard, clock: () => now);
    await feature.start(host);
  }

  tearDown(() => feature.stop());

  group('sending', () {
    test('a copy here goes to connected devices', () async {
      await start();

      clipboard.copy(const .text('hello'));
      await settle();

      expect(pixel.pushes.single.item.text, 'hello');
      expect(pixel.pushes.single.item.sourceDeviceId, host.identity.deviceId);
      expect(pixel.pushes.single.item.contentHash, hasLength(32));
      expect(feature.latest?.direction, ClipDirection.sent);
      expect(feature.latest?.deviceNames, ['Pixel']);
    });

    test('Activity names the device as this device calls it', () async {
      await start();
      await nameHere(host.trustStore, pixel.remoteDeviceId, 'Work phone');

      clipboard.copy(const .text('hello'));
      await settle();

      expect(feature.latest?.deviceNames, ['Work phone']);
    });

    test('links are sent as links', () async {
      await start();

      clipboard.copy(const .text('https://ferret.dev/docs'));
      await settle();

      expect(pixel.pushes.single.item.kind.name, 'CLIP_KIND_URL');
    });

    test('what was on the clipboard at start is not sent', () async {
      await start(initial: const .text('old'));

      clipboard.copy(const .text('old'));
      await settle();

      expect(pixel.pushes, isEmpty);
    });

    test('the same content copied twice is sent once', () async {
      await start();

      clipboard.copy(const .text('twice'));
      await settle();
      clipboard.copy(const .text('twice'));
      await settle();

      expect(pixel.pushes, hasLength(1));
    });

    test('nothing is sent when auto send is off', () async {
      await start(settings: {ClipboardSettings.autoSendKey: false});

      clipboard.copy(const .text('quiet'));
      await settle();

      expect(clipboard.watching, isFalse);
      expect(pixel.pushes, isEmpty);
    });

    test('turning auto send off stops watching', () async {
      await start();
      expect(clipboard.watching, isTrue);

      await feature.settings.setAutoSend(false);
      await settle();

      expect(clipboard.watching, isFalse);
    });

    test('iOS never reads on its own', () async {
      await start(access: .onRequest);

      clipboard.copy(const .text('hello'));
      await settle();

      expect(clipboard.watching, isFalse);
      expect(pixel.pushes, isEmpty);
    });

    test('Send clipboard sends even what was sent already', () async {
      await start();
      clipboard.copy(const .text('again'));
      await settle();

      final result = await feature.sendClipboard();

      expect(result, ClipSendResult.sent);
      expect(pixel.pushes, hasLength(2));
    });

    test('Send clipboard to one device reaches only that one', () async {
      await start();
      final laptop = FakeSession('laptoplaptoplapt', name: 'Laptop');
      host.sessions = [pixel, laptop];
      clipboard.content = const .text('just you');

      final result = await feature.sendClipboard(
        toDeviceId: laptop.remoteDeviceId,
      );

      expect(result, ClipSendResult.sent);
      expect(pixel.pushes, isEmpty);
      expect(laptop.pushes, hasLength(1));
    });

    test('the tile sends the text it read', () async {
      await start(access: .foreground);

      final result = await feature.sendText('from the tile');

      expect(result, ClipSendResult.sent);
      expect(pixel.pushes.single.item.text, 'from the tile');
    });

    test('an empty clipboard says so', () async {
      await start();

      expect(await feature.sendClipboard(), ClipSendResult.nothingToSend);
    });

    test(
      'with no devices, the copy is kept for one that connects soon',
      () async {
        await start();
        host.sessions = [];

        clipboard.copy(const .text('later'));
        await settle();
        final waiting = feature.latest;
        expect(waiting?.skip, ClipSkip.noDevices);
        expect(feature.isWaiting(feature.history.first), isTrue);

        now = now.add(const Duration(seconds: 30));
        host.sessions = [pixel];
        feature.onSessionOpened(pixel);
        await settle();

        expect(pixel.pushes.single.item.text, 'later');
        final delivered = feature.history.single;
        expect(delivered.skip, ClipSkip.none);
        expect(delivered.deliveredLater, isTrue);
        expect(delivered.deviceNames, ['Pixel']);
        expect(feature.isWaiting(delivered), isFalse);
      },
    );

    test('a device that connects after the expiry gets nothing old', () async {
      await start();
      host.sessions = [];
      clipboard.copy(const .text('stale'));
      await settle();

      now = now.add(const Duration(minutes: 3));
      expect(feature.isWaiting(feature.history.single), isFalse);
      feature.onSessionOpened(pixel);
      await settle();

      expect(pixel.pushes, isEmpty);
      expect(feature.history.single.skip, ClipSkip.noDevices);
    });

    test('a failed send is reported, not hidden', () async {
      await start();
      pixel.failSends = true;
      clipboard.content = const .text('lost');

      expect(await feature.sendClipboard(), ClipSendResult.failed);
    });
  });

  group('private items', () {
    test('are skipped by default and kept out of history', () async {
      await start();

      clipboard.copy(const .text('hunter2', sensitive: true));
      await settle();

      expect(pixel.pushes, isEmpty);
      expect(feature.latest?.skip, ClipSkip.sensitive);
      expect(feature.latest?.item.text, isEmpty);
      expect(feature.latest?.hasContent, isFalse);
    });

    test('are sent marked private when turned on', () async {
      await start(settings: {ClipboardSettings.syncSensitiveKey: true});

      clipboard.copy(const .text('hunter2', sensitive: true));
      await settle();

      expect(pixel.pushes.single.item.sensitive, isTrue);
    });

    test('received ones are skipped by default', () async {
      await start();

      await feature.onEnvelope(
        pixel,
        envelopeOf(pushOf('pin', sensitive: true)),
      );

      expect(clipboard.writes, isEmpty);
      expect(feature.latest?.skip, ClipSkip.sensitive);
    });

    test('leave memory after the expiry', () async {
      await start(
        settings: {
          ClipboardSettings.syncSensitiveKey: true,
          ClipboardSettings.expirySecondsKey: 1,
        },
      );

      await feature.onEnvelope(
        pixel,
        envelopeOf(pushOf('pin', sensitive: true)),
      );
      expect(feature.latest?.item.text, 'pin');
      expect(clipboard.writes.single.sensitive, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(feature.latest?.redacted, isTrue);
      expect(feature.latest?.item.text, isEmpty);
    });
  });

  group('images', () {
    final small = Uint8List.fromList(List.filled(64, 1));

    test('are sent to devices that take images', () async {
      await start();

      clipboard.copy(.image(small, imageMime: 'image/png'));
      await settle();

      expect(pixel.pushes.single.item.image, small);
      expect(pixel.pushes.single.item.imageMime, 'image/png');
    });

    test('over the size limit are not sent', () async {
      await start(settings: {ClipboardSettings.maxImageBytesKey: 32});

      clipboard.copy(.image(small, imageMime: 'image/png'));
      await settle();

      expect(pixel.pushes, isEmpty);
      expect(feature.latest?.skip, ClipSkip.tooLarge);
    });

    test('are not sent when images are off', () async {
      await start(settings: {ClipboardSettings.syncImagesKey: false});

      clipboard.content = .image(small, imageMime: 'image/png');
      final result = await feature.sendClipboard();

      expect(result, ClipSendResult.imagesOff);
      expect(pixel.pushes, isEmpty);
    });

    test('skip devices that turned images off', () async {
      await start();
      host.sessions = [
        FakeSession('nopicsnopicsnopi', flags: ['receive']),
      ];
      clipboard.content = .image(small, imageMime: 'image/png');

      expect(await feature.sendClipboard(), ClipSendResult.noDevices);
    });

    test('put here by another feature go on the clipboard and stay '
        'here', () async {
      await start();
      final photo = Uint8List.fromList(List.filled(64, 7));

      expect(
        await feature.putOnClipboard(.image(photo, imageMime: 'image/jpeg')),
        isTrue,
      );
      await settle();

      expect(clipboard.writes.single.image, photo);
      expect(clipboard.writes.single.imageMime, 'image/jpeg');
      expect(pixel.pushes, isEmpty);
    });

    test('a converted copy of a put image is not sent out either', () async {
      final converted = Uint8List.fromList(List.filled(64, 9));
      await start();
      clipboard.storeAs = .image(converted, imageMime: 'image/png');

      await feature.putOnClipboard(
        .image(Uint8List.fromList(List.filled(64, 7)), imageMime: 'image/jpeg'),
      );
      await settle();

      expect(clipboard.content?.image, converted);
      expect(pixel.pushes, isEmpty);
    });

    test('a failed put says so', () async {
      await start();
      clipboard.failWrites = true;

      expect(
        await feature.putOnClipboard(.image(small, imageMime: 'image/png')),
        isFalse,
      );
    });

    test('received over the limit are dropped', () async {
      await start(settings: {ClipboardSettings.maxImageBytesKey: 32});
      final push = pushOf('')
        ..item.kind = .CLIP_KIND_IMAGE
        ..item.image = small
        ..item.imageMime = 'image/png';

      await feature.onEnvelope(pixel, envelopeOf(push));

      expect(clipboard.writes, isEmpty);
      expect(feature.latest?.skip, ClipSkip.tooLarge);
    });
  });

  group('receiving', () {
    test(
      'puts the clip on the clipboard and says where it came from',
      () async {
        await start();

        await feature.onEnvelope(pixel, envelopeOf(pushOf('from the phone')));

        expect(clipboard.writes.single.text, 'from the phone');
        expect(feature.latest?.direction, ClipDirection.received);
        expect(feature.latest?.onClipboard, isTrue);
        expect(feature.latest?.deviceNames, ['Pixel']);
      },
    );

    test('never echoes what it just wrote back to the devices', () async {
      await start();

      await feature.onEnvelope(pixel, envelopeOf(pushOf('ping pong')));
      await settle();

      expect(clipboard.writes, hasLength(1));
      expect(pixel.pushes, isEmpty);
    });

    test('the same item arriving twice is applied once', () async {
      await start();

      await feature.onEnvelope(pixel, envelopeOf(pushOf('once')));
      clipboard.content = const .text('something else');
      await feature.onEnvelope(pixel, envelopeOf(pushOf('once')));

      expect(clipboard.writes, hasLength(1));
      expect(feature.history, hasLength(1));
    });

    test('content already on the clipboard is not written again', () async {
      await start();
      clipboard.copy(const .text('same'));
      await settle();

      await feature.onEnvelope(pixel, envelopeOf(pushOf('same', id: 'other')));

      expect(clipboard.writes, isEmpty);
    });

    test('its own items coming back are ignored', () async {
      await start();

      await feature.onEnvelope(
        pixel,
        envelopeOf(pushOf('mine', source: host.identity.deviceId)),
      );

      expect(clipboard.writes, isEmpty);
    });

    test('with auto receive off, waits for Copy', () async {
      await start(settings: {ClipboardSettings.autoReceiveKey: false});

      await feature.onEnvelope(pixel, envelopeOf(pushOf('on demand')));
      expect(clipboard.writes, isEmpty);
      expect(feature.latest?.onClipboard, isFalse);

      final latest = feature.latest;
      if (latest == null) {
        fail('The received clip should be in history');
      }

      expect(await feature.copyToClipboard(latest), isTrue);
      await settle();

      expect(clipboard.writes.single.text, 'on demand');
      expect(feature.latest?.onClipboard, isTrue);
      expect(pixel.pushes, isEmpty);
    });

    test('a failed write is shown in history', () async {
      await start();
      clipboard.failWrites = true;

      await feature.onEnvelope(pixel, envelopeOf(pushOf('nope')));

      expect(feature.latest?.skip, ClipSkip.writeFailed);
    });
  });

  test('history keeps the last 20 and clears', () async {
    await start();

    for (var index = 0; index < 25; index++) {
      await feature.onEnvelope(
        pixel,
        envelopeOf(pushOf('clip $index', id: 'id-$index')),
      );
    }

    expect(feature.history, hasLength(ClipboardFeature.historyLimit));
    expect(feature.latest?.item.text, 'clip 24');

    feature.clearHistory();
    expect(feature.history, isEmpty);
  });

  test('flags follow the settings', () async {
    await start(settings: {ClipboardSettings.syncImagesKey: false});

    expect(feature.flags, containsAll(['receive', 'send']));
    expect(feature.flags, isNot(contains('images')));
  });
}
