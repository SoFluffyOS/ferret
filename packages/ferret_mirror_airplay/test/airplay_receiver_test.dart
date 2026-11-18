import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_phone.dart';
import 'support/hex.dart';
import 'support/mirror_packets.dart';

const _idr = [0x65, 0x88, 0x84, 0x00, 0x33, 0xff, 0xfe];
const _slice = [0x41, 0x9a, 0x24, 0x6c, 0x41];

final _identity = AirPlayIdentity.derive(const [1, 2, 3, 4]);

/// Waits for [reached], which bytes still on their way will make true.
Future<void> _until(bool Function() reached) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!reached() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late AirPlayReceiver receiver;
  late List<String> asked;
  late bool answer;
  late List<MirrorFeed> feeds;
  late StreamSubscription<MirrorFeed> subscription;
  final phones = <FakePhone>[];

  Future<FakePhone> phone() async {
    final connected = await FakePhone.connect(receiver.boundPort ?? 0);
    phones.add(connected);
    return connected;
  }

  /// A phone that paired, was let in and opened its video stream.
  Future<FakePhone> mirroringPhone() async {
    final connected = await phone();
    await connected.pair();
    await connected.setupSession();
    await connected.setupVideo();
    return connected;
  }

  setUp(() async {
    asked = [];
    answer = true;
    feeds = [];
    receiver = AirPlayReceiver(
      identity: () async => _identity,
      advertise: false,
      allow: (deviceName) async {
        asked.add(deviceName);
        return answer;
      },
    );
    subscription = receiver.incoming.listen(feeds.add);
    await receiver.start('Ferret Test');
  });

  tearDown(() async {
    for (final connected in phones) {
      await connected.close();
    }

    phones.clear();
    await subscription.cancel();
    await receiver.dispose();
  });

  test('listens only between start and stop', () async {
    expect(receiver.isListening, isTrue);
    expect(receiver.id, 'airplay');
    final port = receiver.boundPort ?? 0;

    await receiver.stop();

    expect(receiver.isListening, isFalse);
    await expectLater(
      Socket.connect(InternetAddress.loopbackIPv4, port),
      throwsA(isA<SocketException>()),
    );
  });

  test('is ready on this computer, with the FairPlay library loaded', () async {
    expect(await receiver.status(), isA<RouteReady>());
  });

  test('says who it is on /info, over plain HTTP too', () async {
    final connected = await phone();

    final response = await connected.send(
      'GET',
      '/info',
      protocol: 'HTTP/1.1',
    );

    final info = response.plist;
    expect(response.status, 200);
    expect(
      response.headers['content-type'],
      'application/x-apple-binary-plist',
    );
    expect(info['name'], 'Ferret Test');
    expect(info['deviceID'], _identity.deviceIdColons);
    expect(info['features'], 0x5A7FFEE6);
    expect(info['model'], 'AppleTV3,2');
    expect(info['pk'], await PairVerify.publicKeyOf(_identity.signingSeed));
    expect(info['displays'], hasLength(1));
  });

  test('adds the TXT records to /info when the phone asks for them', () async {
    final connected = await phone();

    final response = await connected.sendPlist('GET', '/info', {
      'qualifier': ['txtAirPlay'],
    });

    final txt = response.plist['txtAirPlay'];
    expect(String.fromCharCodes(txt as Uint8List), contains('deviceid='));
  });

  test(
    'pairs: the phone can check our signature and we accept its own',
    () async {
      final connected = await phone();

      expect(await connected.pair(), 200);
      expect(
        connected.receiverSigningKey,
        await PairVerify.publicKeyOf(_identity.signingSeed),
      );
    },
  );

  test('turns away a phone whose pair-verify signature is wrong', () async {
    final connected = await phone();

    expect(await connected.pair(breakSignature: true), 470);
    await connected.waitClosed();
  });

  test('asks about the phone by name before the session is set up', () async {
    final connected = await phone();
    await connected.pair();

    final response = await connected.setupSession(name: 'Mai\u0000\'s iPad\n');

    expect(response.status, 200);
    expect(asked, ['Mai\'s iPad']);
    expect(response.plist['timingPort'], isA<int>());
    expect(response.plist['eventPort'], 0);
    expect(feeds, isEmpty);
  });

  test('a phone the owner refuses gets 401 and never a feed', () async {
    answer = false;
    final connected = await phone();
    await connected.pair();

    final response = await connected.setupSession();

    expect(response.status, 401);
    await connected.waitClosed();
    expect(feeds, isEmpty);
  });

  test('a phone that takes too long to be answered is refused', () async {
    await receiver.stop();
    receiver = AirPlayReceiver(
      identity: () async => _identity,
      advertise: false,
      askTimeout: const Duration(milliseconds: 50),
      allow: (_) => Completer<bool>().future,
    );
    await receiver.start('Ferret Test');
    final connected = await phone();
    await connected.pair();

    expect((await connected.setupSession()).status, 401);
  });

  test('a phone that leaves while the owner is asked gets nothing', () async {
    await receiver.stop();
    final question = Completer<bool>();
    final wasAsked = Completer<void>();
    receiver = AirPlayReceiver(
      identity: () async => _identity,
      advertise: false,
      allow: (_) {
        wasAsked.complete();
        return question.future;
      },
    );
    subscription = receiver.incoming.listen(feeds.add);
    await receiver.start('Ferret Test');
    final connected = await phone();
    await connected.pair();
    unawaited(connected.setupSession().then((_) {}, onError: (Object _) {}));
    await wasAsked.future.timeout(const Duration(seconds: 5));

    await connected.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    question.complete(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(feeds, isEmpty);
  });

  test('a stream asked for without a session is refused', () async {
    final connected = await phone();
    await connected.pair();

    final response = await connected.setupVideo();

    expect(response.status, 401);
    expect(asked, isEmpty);
    expect(feeds, isEmpty);
  });

  test('a session without FairPlay first is refused', () async {
    final connected = await phone();

    final response = await connected.sendPlist('SETUP', 'rtsp://x/1', {
      'name': 'Phone',
      'ekey': Uint8List(72),
      'eiv': Uint8List(16),
    });

    expect(response.status, 400);
    expect(asked, isEmpty);
  });

  test(
    'shows the phone\'s screen: configured, frames, then stopped there',
    () async {
      final connected = await mirroringPhone();
      final feed = feeds.single;
      final events = <FeedEvent>[];
      final done = Completer<void>();
      feed.events.listen(events.add, onDone: done.complete);

      connected
        ..sendVideo(
          mirrorPacket(
            type: 1,
            payload: avccRecord(),
            option: 0x0116,
            width: 886,
            height: 1920,
            sourceWidth: 1170,
            sourceHeight: 2532,
          ),
        )
        ..sendVideo(
          mirrorPacket(
            type: 0,
            payload: connected.encrypt(lengthPrefixed(const [_idr])),
            timestamp: 5 << 32,
          ),
        )
        ..sendVideo(mirrorPacket(type: 2, payload: const []))
        ..sendVideo(
          mirrorPacket(
            type: 0,
            payload: connected.encrypt(lengthPrefixed(const [_slice])),
            timestamp: 6 << 32,
          ),
        );
      await connected.video?.flush();
      await _until(() => events.length == 3);
      final teardown = await connected.send(
        'TEARDOWN',
        'rtsp://127.0.0.1/1234',
      );
      await done.future.timeout(const Duration(seconds: 5));

      expect(teardown.status, 200);
      expect(feed.target.name, 'Test iPhone');
      expect(feed.target.routeId, 'airplay');
      expect(feed.target.id, 'AA:BB:CC:DD:EE:FF');
      expect(feed.control, isNull);
      expect(events, hasLength(4));
      final config = (events[0] as FeedConfigured).config;
      expect(config.codec, MirrorCodec.h264);
      expect((config.width, config.height), (886, 1920));
      expect(config.sps, sampleSps);
      expect(config.pps, samplePps);
      final first = (events[1] as FeedFrame).frame;
      expect(hex(first.data), hex(annexB(const [_idr])));
      expect(first.keyframe, isTrue);
      expect(first.ptsUs, 5000000);
      final second = (events[2] as FeedFrame).frame;
      expect(hex(second.data), hex(annexB(const [_slice])));
      expect(second.keyframe, isFalse);
      expect((events[3] as FeedEnded).reason, FeedEnd.stoppedThere);
    },
  );

  test('gives the phone ports for the sound it sends along', () async {
    final connected = await phone();
    await connected.pair();
    await connected.setupSession();

    final response = await connected.setupVideo(withAudio: true);

    expect(response.plist['streams'], [
      {'type': 110, 'dataPort': isA<int>()},
      {'type': 96, 'dataPort': isA<int>(), 'controlPort': isA<int>()},
    ]);
  });

  test(
    'stopping only the video stream ends the feed, not the session',
    () async {
      final connected = await mirroringPhone();
      final ended = feeds.single.events.last;

      final teardown = await connected.sendPlist('TEARDOWN', 'rtsp://x/1', {
        'streams': [
          {'type': 110},
        ],
      });

      expect(teardown.status, 200);
      expect(((await ended) as FeedEnded).reason, FeedEnd.stoppedThere);
      expect((await connected.send('POST', '/feedback')).status, 200);
    },
  );

  test('a phone that vanishes ends the feed as a lost connection', () async {
    final connected = await mirroringPhone();
    final ended = feeds.single.events.last;

    await connected.close();

    expect(((await ended) as FeedEnded).reason, FeedEnd.lostConnection);
  });

  test('stopping the feed here ends it and hangs up on the phone', () async {
    final connected = await mirroringPhone();
    final feed = feeds.single;
    final ended = feed.events.last;

    await feed.stop();

    expect(((await ended) as FeedEnded).reason, FeedEnd.stoppedHere);
    await connected.waitClosed();
  });

  test('turning the receiver off ends running feeds', () async {
    await mirroringPhone();
    final ended = feeds.single.events.last;

    await receiver.stop();

    expect(((await ended) as FeedEnded).reason, FeedEnd.stoppedHere);
  });

  test('a stream that makes no sense ends the feed as failed', () async {
    final connected = await mirroringPhone();
    final ended = feeds.single.events.last;

    connected.sendVideo(mirrorPacket(type: 1, payload: const [9, 9, 9]));

    expect(((await ended) as FeedEnded).reason, FeedEnd.failed);
    await connected.waitClosed();
  });

  test('answers the small requests a phone sends along the way', () async {
    final connected = await phone();

    final options = await connected.send('OPTIONS', '*');
    final record = await connected.send('RECORD', 'rtsp://x/1');
    final volume = await connected.send(
      'GET_PARAMETER',
      'rtsp://x/1',
      body: 'volume\r\n'.codeUnits,
      contentType: 'text/parameters',
    );
    final feedback = await connected.send('POST', '/feedback');
    final unknown = await connected.send('SETPEERS', 'rtsp://x/1');

    expect(options.headers['public'], contains('SETUP'));
    expect(record.headers['audio-jack-status'], 'connected; type=analog');
    expect(String.fromCharCodes(volume.body), startsWith('volume: '));
    expect(feedback.status, 200);
    expect(unknown.status, 200);
  });

  test('hangs up on bytes that are not RTSP', () async {
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      receiver.boundPort ?? 0,
    );

    socket.add('hello there\r\n\r\n'.codeUnits);

    await socket.drain<void>().timeout(const Duration(seconds: 5));
    socket.destroy();
  });
}
