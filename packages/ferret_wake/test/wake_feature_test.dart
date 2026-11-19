import 'package:fake_async/fake_async.dart';
import 'package:ferret_wake/ferret_wake.dart';
import 'package:protocol/protocol.dart';
import 'package:protocol/wake.dart';
import 'package:test/test.dart';

import 'helpers/fakes.dart';

final _cards = [
  NetworkCard(
    name: 'en7',
    mac: MacAddress.parse('a0:ce:c8:00:11:22') ?? .new(6),
    address: '192.168.1.24',
    broadcast: '192.168.1.255',
    link: .WAKE_LINK_WIRED,
    setting: .WAKE_SETTING_ON,
  ),
];

Future<(FakeHost, WakeFeature, FakeSender)> _start({
  bool isComputer = true,
  FakeSender? sender,
  Map<String, Object?>? settings,
  List<NetworkCard>? cards,
}) async {
  final host = await FakeHost.create(settings: settings);
  final usedSender = sender ?? FakeSender();
  final feature = WakeFeature(
    isComputer: isComputer,
    sender: usedSender,
    readCards: () async => cards ?? _cards,
  );
  await feature.start(host);
  await settle();
  return (host, feature, usedSender);
}

void main() {
  group('sharing how to wake this computer', () {
    test(
      'tells a device that connects, and remembers what it is told',
      () async {
        final (host, feature, _) = await _start();
        final phone = FakeSession('phone');
        host.connect(phone);

        feature.onSessionOpened(phone);
        await settle();

        final told = phone.sent.whereType<WakeInfo>().single;
        expect(told.interfaces.single.broadcast, '192.168.1.255');
        expect(told.interfaces.single.link, WakeLink.WAKE_LINK_WIRED);
      },
    );

    test('a phone shares nothing', () async {
      final (host, feature, _) = await _start(isComputer: false);
      final laptop = FakeSession('laptop');
      host.connect(laptop);

      feature.onSessionOpened(laptop);
      await settle();

      expect(laptop.sent, isEmpty);
      expect(feature.localWake.interfaces, isEmpty);
    });

    test('turning sharing off tells devices to forget it', () async {
      final (host, feature, _) = await _start();
      final phone = FakeSession('phone');
      host.connect(phone);

      await feature.setShares(false);

      expect(phone.sent.whereType<WakeInfo>().last.interfaces, isEmpty);
    });

    test('changed cards go out to every connected device', () async {
      var cards = _cards;
      final host = await FakeHost.create();
      final feature = WakeFeature(
        isComputer: true,
        sender: FakeSender(),
        readCards: () async => cards,
      );
      await feature.start(host);
      await settle();
      final phone = FakeSession('phone');
      host.connect(phone);
      cards = const [];

      final changed = await feature.refreshCards();

      expect(changed, isTrue);
      expect(phone.sent.whereType<WakeInfo>().single.interfaces, isEmpty);
    });

    test('what a computer says is saved in the trust store', () async {
      final (host, feature, _) = await _start(isComputer: false);
      await pairComputer(host.trustStore, 'pc');

      await feature.onEnvelope(FakeSession('pc'), envelopeOf(wiredWake()));

      expect(host.trustStore['pc']?.wake, wiredWake());
      expect(
        feature.canWake(host.trustStore['pc'] ?? (throw StateError(''))),
        isTrue,
      );
    });
  });

  group('waking for another device', () {
    test(
      'wakes a device paired here, with this computer\'s own copy',
      () async {
        final (host, feature, sender) = await _start();
        final ownCopy = wiredWake(mac: const [1, 1, 1, 1, 1, 1]);
        await pairComputer(host.trustStore, 'pc', wake: ownCopy);

        final reply = await feature.onEnvelope(
          FakeSession('phone'),
          envelopeOf(
            WakeRequest(
              deviceId: 'pc',
              info: wiredWake(mac: const [2, 2, 2, 2, 2, 2]),
            ),
          ),
        );

        expect((reply as WakeReply?)?.result, WakeResult.WAKE_RESULT_SENT);
        expect(
          sender.sends.single.first.bytes,
          MagicPacket.of(const [1, 1, 1, 1, 1, 1]),
        );
      },
    );

    test(
      'uses what the asking device knows when it has nothing itself',
      () async {
        final (host, feature, sender) = await _start();
        await pairComputer(host.trustStore, 'pc');

        final reply = await feature.onEnvelope(
          FakeSession('phone'),
          envelopeOf(WakeRequest(deviceId: 'pc', info: wiredWake())),
        );

        expect((reply as WakeReply?)?.result, WakeResult.WAKE_RESULT_SENT);
        expect(sender.sends, hasLength(1));
      },
    );

    test('refuses a device that isn\'t paired here', () async {
      final (_, feature, sender) = await _start();

      final reply = await feature.onEnvelope(
        FakeSession('phone'),
        envelopeOf(WakeRequest(deviceId: 'stranger', info: wiredWake())),
      );

      expect((reply as WakeReply?)?.result, WakeResult.WAKE_RESULT_NOT_PAIRED);
      expect(sender.sends, isEmpty);
    });

    test('refuses when its owner turned it off, and on a phone', () async {
      final (offHost, off, offSender) = await _start(
        settings: {WakeSettings.relayKey: false},
      );
      await pairComputer(offHost.trustStore, 'pc', wake: wiredWake());
      final (phoneHost, phone, phoneSender) = await _start(isComputer: false);
      await pairComputer(phoneHost.trustStore, 'pc', wake: wiredWake());
      final request = envelopeOf(WakeRequest(deviceId: 'pc'));

      final offReply = await off.onEnvelope(FakeSession('a'), request);
      final phoneReply = await phone.onEnvelope(FakeSession('a'), request);

      expect(
        (offReply as WakeReply?)?.result,
        WakeResult.WAKE_RESULT_RELAY_OFF,
      );
      expect(
        (phoneReply as WakeReply?)?.result,
        WakeResult.WAKE_RESULT_RELAY_OFF,
      );
      expect(off.flags, isNot(contains(WakeFeature.relayFlag)));
      expect([...offSender.sends, ...phoneSender.sends], isEmpty);
    });

    test('says when nobody knows the card', () async {
      final (host, feature, _) = await _start();
      await pairComputer(host.trustStore, 'pc');

      final reply = await feature.onEnvelope(
        FakeSession('phone'),
        envelopeOf(WakeRequest(deviceId: 'pc')),
      );

      expect((reply as WakeReply?)?.result, WakeResult.WAKE_RESULT_NO_INFO);
    });

    test('a burst of requests sends one burst of packets', () async {
      final (host, feature, sender) = await _start();
      await pairComputer(host.trustStore, 'pc', wake: wiredWake());
      final request = envelopeOf(WakeRequest(deviceId: 'pc'));

      await feature.onEnvelope(FakeSession('phone'), request);
      final second = await feature.onEnvelope(FakeSession('tablet'), request);

      expect((second as WakeReply?)?.result, WakeResult.WAKE_RESULT_SENT);
      expect(sender.sends, hasLength(1));
    });
  });

  group('waking a computer from here', () {
    test('sends from here and through connected computers', () async {
      final (host, feature, sender) = await _start(isComputer: false);
      await pairComputer(
        host.trustStore,
        'pc',
        wake: wiredWake(),
        lastHost: '192.168.1.20',
      );
      final mac = FakeSession(
        'mac',
        flags: const [WakeFeature.relayFlag],
        answer: (_) => WakeReply(result: .WAKE_RESULT_SENT),
      );
      final tablet = FakeSession('tablet');
      host.connect(mac);
      host.connect(tablet);

      final attempt = await feature.wake('pc');

      expect(attempt.phase, WakePhase.waking);
      expect(attempt.broadcastHere, isTrue);
      expect(attempt.relayedBy, ['mac']);
      expect(sender.sends.single, hasLength(6));
      expect((mac.requests.single as WakeRequest).lastAddress, '192.168.1.20');
      expect(tablet.requests, isEmpty);
    });

    test('an iPhone that may not broadcast leans on a computer', () async {
      final (host, feature, _) = await _start(
        isComputer: false,
        sender: FakeSender(refusesBroadcast: true),
      );
      await pairComputer(
        host.trustStore,
        'pc',
        wake: wiredWake(),
        lastHost: '192.168.1.20',
      );
      host.connect(
        FakeSession(
          'mac',
          flags: const [WakeFeature.relayFlag],
          answer: (_) => WakeReply(result: .WAKE_RESULT_SENT),
        ),
      );

      final attempt = await feature.wake('pc');

      expect(attempt.broadcastHere, isFalse);
      expect(attempt.relayedBy, ['mac']);
      expect(attempt.hadNoWayOut, isFalse);
    });

    test('says it couldn\'t send when nothing went out', () async {
      final (host, feature, _) = await _start(
        isComputer: false,
        sender: FakeSender(refusesAll: true),
      );
      await pairComputer(host.trustStore, 'pc', wake: wiredWake());

      final attempt = await feature.wake('pc');

      expect(attempt.phase, WakePhase.couldntSend);
      expect(attempt.hadNoWayOut, isTrue);
    });

    test('turns into nothing once the computer connects', () async {
      final (host, feature, _) = await _start(isComputer: false);
      await pairComputer(host.trustStore, 'pc', wake: wiredWake());
      await feature.wake('pc');

      host.connect(FakeSession('pc'));
      await settle();

      expect(feature.attemptFor('pc'), isNull);
    });

    test("says it didn't wake after the wait", () {
      fakeAsync((async) {
        late WakeFeature feature;
        late FakeHost host;
        FakeHost.create().then((created) async {
          host = created;
          feature = WakeFeature(
            isComputer: false,
            sender: FakeSender(),
            readCards: () async => const [],
          );
          await feature.start(host);
          await pairComputer(host.trustStore, 'pc', wake: wiredWake());
          await feature.wake('pc');
        });
        async.flushMicrotasks();
        expect(feature.attemptFor('pc')?.phase, WakePhase.waking);

        async.elapse(const Duration(seconds: 89));
        expect(feature.attemptFor('pc')?.phase, WakePhase.waking);

        async.elapse(const Duration(seconds: 2));
        expect(feature.attemptFor('pc')?.phase, WakePhase.didntWake);

        feature.dismiss('pc');
        expect(feature.attemptFor('pc'), isNull);
      });
    });
  });
}
