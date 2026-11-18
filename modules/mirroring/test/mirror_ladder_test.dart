import 'dart:async';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';

import 'helpers/fakes.dart';

/// Which way the viewer takes to a paired phone that Ferret and a cable
/// both reach, and when it changes its mind.
void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeRoute cable;
  late FakeControl control;
  late FerretRoute ferret;
  late MirrorRoutes routes;
  late MirrorViewer viewer;
  late MirroringSettings settings;

  Future<void> create({
    FutureOr<GeneratedMessage> Function(GeneratedMessage)? answer,
    bool connected = true,
    bool pluggedIn = true,
  }) async {
    host = await FakeHost.create(
      settings: {MirroringSettings.lookForCableKey: true},
    );
    pixel = FakeSession(
      'pixel',
      answer: answer ?? (_) => StartPending(timeoutSeconds: 60),
    );
    host.sessions = [if (connected) pixel];
    control = FakeControl();
    cable = FakeRoute('adb', control: control);
    settings = MirroringSettings(host.settings);
    ferret = FerretRoute(host: host, featureId: MirroringFeature.featureId);
    routes = MirrorRoutes(
      ferret: ferret,
      settings: settings,
      receiverName: () => 'MacBook',
      pairedPhones: () => {'pixel': 'Pixel'},
      routes: [cable],
    )..start();
    viewer = MirrorViewer(
      routes: routes,
      createDecoder: FakeDecoder.new,
      codecs: const [.h264, .jpeg],
      settings: settings,
    );
    await settle();
    if (pluggedIn) {
      cable.find([cable.target('2A13', 'Pixel')]);
      await settle();
    }
  }

  tearDown(() async {
    await viewer.dispose();
    await routes.dispose();
  });

  test(
    'connected and plugged in: Ferret asks the phone, the cable waits',
    () async {
      await create();

      await viewer.show('pixel');

      expect(viewer.current?.way, MirrorWay.wifi);
      expect(viewer.current?.phase, ViewPhase.waitingForPhone);
      expect(cable.feeds, isEmpty);
    },
  );

  test('asked for control: the cable, with no question on the phone', () async {
    await create();

    await viewer.show('pixel', preferControl: true);
    cable.feeds.single.play();
    await settle();

    expect(pixel.requests, isEmpty);
    expect(viewer.current?.way, MirrorWay.cable);
    expect(viewer.current?.deviceId, 'pixel');
    expect(viewer.current?.viaFallback, isFalse);
    expect(viewer.control, control);
  });

  test(
    'taking control while Ferret shows the phone stops that first',
    () async {
      await create();
      await viewer.show('pixel');
      ferret.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
      await settle();

      await viewer.show('pixel', preferControl: true);

      expect(pixel.sentOf<Stop>(), hasLength(1));
      expect(viewer.current?.way, MirrorWay.cable);
    },
  );

  test('not connected over Ferret: the cable right away', () async {
    await create(connected: false);

    await viewer.show('pixel');

    expect(viewer.current?.way, MirrorWay.cable);
    expect(cable.feeds, hasLength(1));
  });

  test(
    'not connected and not plugged in: says so, with nothing tried',
    () async {
      await create(connected: false, pluggedIn: false);

      await viewer.show('pixel');
      await settle();

      expect(viewer.current?.end, ViewEnd.notConnected);
      expect(viewer.current?.endedAt, isNotNull);
      expect(cable.feeds, isEmpty);
    },
  );

  for (final (reason, end) in [
    (DenyReason.DENY_REASON_CANNOT_ASK, ViewEnd.cannotAsk),
    (DenyReason.DENY_REASON_VERSION, ViewEnd.version),
    (DenyReason.DENY_REASON_UNSUPPORTED, ViewEnd.unsupported),
    (DenyReason.DENY_REASON_NO_CODEC, ViewEnd.noCodec),
  ]) {
    test('Ferret ending with ${end.name} goes on over the cable', () async {
      await create(answer: (_) => StartDeny(reason: reason));

      await viewer.show('pixel');
      await settle();

      expect(end.mayFallBack, isTrue);
      expect(viewer.current?.way, MirrorWay.cable);
      expect(viewer.current?.viaFallback, isTrue);
      expect(viewer.current?.isLive, isTrue);
      expect(cable.feeds, hasLength(1));
    });
  }

  test(
    'a phone that never answers the request goes on over the cable',
    () async {
      await create();
      pixel.answer = null;

      await viewer.show('pixel');
      await settle();

      expect(viewer.current?.way, MirrorWay.cable);
      expect(viewer.current?.viaFallback, isTrue);
    },
  );

  for (final (reason, end) in [
    (DenyReason.DENY_REASON_DENIED, ViewEnd.denied),
    (DenyReason.DENY_REASON_TURNED_OFF, ViewEnd.turnedOff),
    (DenyReason.DENY_REASON_TIMEOUT, ViewEnd.timedOut),
    (DenyReason.DENY_REASON_BUSY, ViewEnd.busy),
  ]) {
    test('${end.name} is the owner\'s answer: never worked around with the '
        'cable', () async {
      await create(answer: (_) => StartDeny(reason: reason));

      await viewer.show('pixel');
      await settle();

      expect(end.mayFallBack, isFalse);
      expect(viewer.current?.end, end);
      expect(cable.feeds, isEmpty);
    });
  }

  test('a no on the prompt, after the phone asked, stays a no', () async {
    await create();
    await viewer.show('pixel');

    ferret.onDeny(pixel, StartDeny(reason: .DENY_REASON_DENIED));
    await settle();

    expect(viewer.current?.end, ViewEnd.denied);
    expect(cable.feeds, isEmpty);
  });

  test('once pictures showed over Ferret, a failure ends it: no silent '
      'switch to the cable', () async {
    await create();
    await viewer.show('pixel');
    ferret.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
    await settle();

    ferret.onStop(pixel, Stop(reason: .STOP_REASON_FAILED));
    await settle();

    expect(viewer.current?.end, ViewEnd.failed);
    expect(cable.feeds, isEmpty);
  });

  test('the cable failing after a fall-through ends it there', () async {
    await create(answer: (_) => StartDeny(reason: .DENY_REASON_CANNOT_ASK));
    await viewer.show('pixel');
    await settle();

    cable.feeds.single.emit(const FeedEnded(.failed));
    await settle();

    expect(viewer.current?.end, ViewEnd.failed);
    expect(pixel.requests, hasLength(1), reason: 'Ferret is not asked again');
  });

  group('quality presets', () {
    test('the preset in settings is what the route is asked for', () async {
      await create(connected: false);
      await settings.setQuality(.fast);

      await viewer.show('pixel');

      expect(cable.options.single.maxSize, 1600);
      expect(cable.options.single.bitrate, 3000000);
    });

    test('over the cable a change restarts the picture and keeps the '
        'session', () async {
      await create(connected: false);
      await viewer.show('pixel');
      cable.feeds.single.play();
      await settle();
      final startedAt = viewer.current?.startedAt;

      await settings.setQuality(.sharp);
      await viewer.restart();
      await settle();

      expect(cable.feeds, hasLength(2));
      expect(cable.feeds.first.stops, 1);
      expect(cable.options.last.bitrate, 8000000);
      expect(viewer.current?.isMirroring, isTrue);
      expect(viewer.current?.startedAt, startedAt);
      expect(viewer.picture.value, isNotNull, reason: 'the last frame holds');
      expect(viewer.lastRecord, isNull);

      cable.feeds.last.play();
      await settle();
      expect(viewer.current?.phase, ViewPhase.streaming);
    });

    test('over Ferret nothing restarts: the phone would have to ask '
        'again', () async {
      await create(pluggedIn: false);
      await viewer.show('pixel');
      ferret.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
      await settle();

      await viewer.restart();

      expect(pixel.requests, hasLength(1));
      expect(pixel.sentOf<Stop>(), isEmpty);
    });
  });

  group('a cable pulled out', () {
    test('holds the picture, and picks up when the phone is plugged back '
        'in', () async {
      await create(connected: false);
      await viewer.show('pixel');
      cable.feeds.single.play();
      await settle();

      cable.find(const []);
      cable.feeds.single.emit(const FeedEnded(.lostConnection));
      await settle();
      expect(viewer.current?.phase, ViewPhase.reconnecting);
      expect(cable.feeds, hasLength(1));

      cable.find([cable.target('2A13', 'Pixel')]);
      await settle();
      expect(cable.feeds, hasLength(2));
      cable.feeds.last.play();
      await settle();

      expect(viewer.current?.phase, ViewPhase.streaming);
    });
  });

  group('a device that starts by itself', () {
    test('ends for good when it drops: only it can start again', () async {
      await create();
      final feed = FakeFeed(
        const MirrorTarget(routeId: 'airplay', id: 'i1', name: 'iPhone'),
      );

      await viewer.showIncoming(feed);
      feed.play();
      await settle();
      expect(viewer.isShowingIncoming, isTrue);
      expect(viewer.current?.way, MirrorWay.airplay);

      feed.emit(const FeedEnded(.lostConnection));
      await settle();

      expect(viewer.current?.end, ViewEnd.lostConnection);
      expect(viewer.isShowingIncoming, isFalse);
    });
  });
}
