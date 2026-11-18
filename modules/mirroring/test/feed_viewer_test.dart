import 'package:fake_async/fake_async.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';

import 'helpers/fakes.dart';

/// The viewer with a route that isn't Ferret's own: no prompt, no session,
/// only feed events.
void main() {
  late FakeHost host;
  late FakeRoute cable;
  late FakeReceiver receiver;
  late FakeControl control;
  late FakeDecoder decoder;
  late MirrorRoutes routes;
  late MirrorViewer viewer;
  late MirrorTarget galaxy;
  var disposedInTest = false;

  Future<void> create() async {
    host = await FakeHost.create(
      settings: {MirroringSettings.moreWaysKey: true},
    );
    control = FakeControl();
    cable = FakeRoute('cable', control: control);
    receiver = FakeReceiver('cast');
    decoder = FakeDecoder();
    galaxy = cable.target('a1', 'Galaxy');
    final settings = MirroringSettings(host.settings);
    routes = MirrorRoutes(
      ferret: FerretRoute(host: host, featureId: MirroringFeature.featureId),
      settings: settings,
      receiverName: () => 'MacBook',
      routes: [cable],
      receivers: [receiver],
    )..start();
    viewer = MirrorViewer(
      routes: routes,
      createDecoder: () => decoder,
      codecs: const [.h264],
      settings: settings,
      clock: () => DateTime(2026, 11, 18, 21, 10),
    );
    await settle();
  }

  setUp(create);

  tearDown(() async {
    if (!disposedInTest) {
      await viewer.dispose();
      await routes.dispose();
    }

    disposedInTest = false;
  });

  test('a route that never asks goes from its first config straight to '
      'pictures, and may be controlled', () async {
    await viewer.startTarget(galaxy);
    expect(viewer.current?.phase, ViewPhase.requesting);
    expect(viewer.current?.deviceId, 'cable:a1');
    expect(cable.options.single.control, isTrue);
    expect(cable.options.single.codecs, [MirrorCodec.h264]);
    expect(viewer.control, isNull, reason: 'nothing to control yet');

    cable.feeds.single.play();
    await settle();

    expect(viewer.current?.phase, ViewPhase.streaming);
    expect(viewer.current?.config?.width, 1080);
    expect(viewer.picture.value?.width, 1080);
    expect(viewer.control, control);
  });

  test('a lost frame is skipped to the next keyframe, which the route is '
      'asked for', () async {
    await viewer.startTarget(galaxy);
    final feed = cable.feeds.single..play();
    await settle();

    decoder.fail();
    feed.emit(
      FeedFrame(MirrorFrame(data: Uint8List(1), ptsUs: 1000, keyframe: false)),
    );
    await settle();

    expect(feed.keyframeRequests, 1);
    expect(decoder.frames, hasLength(1));
  });

  test('the route ending the feed is said in the viewer\'s words, and '
      'recorded', () async {
    await viewer.startTarget(galaxy);
    final feed = cable.feeds.single..play();
    await settle();

    feed.emit(const FeedEnded(.stoppedThere));
    await settle();

    expect(viewer.current?.end, ViewEnd.stoppedOnPhone);
    expect(viewer.control, isNull);
    expect(viewer.lastRecord?.deviceName, 'Galaxy');
    expect(decoder.disposed, isTrue);
  });

  test('Stop here stops the feed', () async {
    await viewer.startTarget(galaxy);
    final feed = cable.feeds.single..play();
    await settle();

    await viewer.stop();

    expect(feed.stops, 1);
    expect(viewer.current?.end, ViewEnd.stoppedHere);
  });

  test(
    'a route that needs a step first says which, and opens nothing',
    () async {
      cable.statusNow = const RouteNeedsSetup(.authorizeComputer, detail: 'a1');

      await viewer.startTarget(galaxy);

      expect(viewer.current?.end, ViewEnd.needsSetup);
      expect(viewer.current?.setup, RouteSetup.authorizeComputer);
      expect(viewer.current?.setupDetail, 'a1');
      expect(cable.feeds, isEmpty);
    },
  );

  test('a route that can\'t open, or isn\'t there, ends the attempt', () async {
    cable.failOpen = true;
    await viewer.startTarget(galaxy);
    expect(viewer.current?.end, ViewEnd.failed);

    await viewer.startTarget(
      const MirrorTarget(routeId: 'gone', id: 'x', name: 'Ghost'),
    );
    expect(viewer.current?.end, ViewEnd.notConnected);
  });

  test('a route that opens and then stays silent gives up', () {
    fakeAsync((async) {
      create();
      async.flushMicrotasks();
      viewer.startTarget(galaxy);
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 11));

      expect(viewer.current?.end, ViewEnd.noAnswer);
      expect(cable.feeds.single.stops, 1);
      viewer.dispose();
      routes.dispose();
      async.flushMicrotasks();
      disposedInTest = true;
    });
  });

  test('a screen a device sends here itself replaces the one shown', () async {
    await viewer.startTarget(galaxy);
    final first = cable.feeds.single..play();
    await settle();
    routes.incoming.listen(viewer.show);
    final iphone = FakeFeed(
      const MirrorTarget(routeId: 'cast', id: 'i1', name: 'iPhone'),
    );

    receiver.receive(iphone);
    await settle();
    iphone.play(width: 1170, height: 2532);
    await settle();

    expect(first.stops, 1);
    expect(viewer.current?.deviceName, 'iPhone');
    expect(viewer.current?.phase, ViewPhase.streaming);
    expect(viewer.control, isNull, reason: 'this one is view only');
  });

  test('every way a feed ends has its words here, and back', () {
    for (final end in FeedEnd.values) {
      expect(ViewEnd.ofFeed(end).feedEnd, end);
    }

    expect(ViewEnd.decoderFailed.feedEnd, FeedEnd.failed);
  });

  test('keys travel as keyboard usages; keys off the keyboard don\'t', () {
    expect(MirrorKeys.usageOf(PhysicalKeyboardKey.keyA), 0x04);
    expect(MirrorKeys.usageOf(PhysicalKeyboardKey.enter), 0x28);
    expect(MirrorKeys.usageOf(PhysicalKeyboardKey.shiftLeft), 0xE1);
    expect(MirrorKeys.usageOf(PhysicalKeyboardKey.mediaPlayPause), isNull);

    final down = MirrorKeys.keyOf(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
      ),
      modifiers: const {KeyModifier.shift},
    );
    final up = MirrorKeys.keyOf(
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
      ),
    );

    expect(down?.phase, KeyPhase.down);
    expect(down?.usage, 0x04);
    expect(down?.modifiers, {KeyModifier.shift});
    expect(up?.phase, KeyPhase.up);
  });
}
