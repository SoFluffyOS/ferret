import 'dart:async';
import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/find.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/find.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the feature and its UI share one id', () {
    final ui = FindFeatureUi();

    expect(ui.featureId, FindFeature.featureId);
    expect(ui.feature.id, FindFeature.featureId);
    for (final category in ui.noticeCategories) {
      expect(category.id, startsWith('${FindFeature.featureId}.'));
    }
  });

  group('when another device asks this one to ring', () {
    test('rings and answers with the time left', () async {
      final host = await FakeHost.create();
      final platform = FakeFindPlatform();
      final laptop = FakeSession('laptop', name: 'Laptop');
      host.sessions = [laptop];
      final feature = await startFeature(host, platform);

      final reply = await feature.onEnvelope(
        laptop,
        envelopeOf(RingRequest(durationSeconds: 60, overrideSilent: true)),
      );

      expect(reply, isA<RingStatus>());
      final status = reply as RingStatus;
      expect(status.state, RingState.RING_STATE_RINGING);
      expect(status.remainingMs, inInclusiveRange(59000, 60000));
      expect(platform.playing?.body, contains('Laptop'));
      expect(feature.localRing.isRinging, isTrue);
      await feature.stop();
    });

    test('says who asked by the name this device gives it', () async {
      final host = await FakeHost.create();
      final platform = FakeFindPlatform();
      final laptop = FakeSession('laptop', name: 'Laptop');
      host.sessions = [laptop];
      await nameHere(host.trustStore, 'laptop', 'Work laptop');
      final feature = await startFeature(host, platform);

      await feature.onEnvelope(laptop, envelopeOf(RingRequest()));

      expect(platform.playing?.body, contains('Work laptop'));
      await feature.stop();
    });

    test(
      'tells each device that asked how it ended, except the stopper',
      () async {
        final host = await FakeHost.create();
        final platform = FakeFindPlatform();
        final laptop = FakeSession('laptop', name: 'Laptop');
        final tablet = FakeSession('tablet', name: 'Tablet');
        host.sessions = [laptop, tablet];
        final feature = await startFeature(host, platform);

        await feature.onEnvelope(laptop, envelopeOf(RingRequest()));
        await feature.onEnvelope(tablet, envelopeOf(RingRequest()));
        final reply = await feature.onEnvelope(
          tablet,
          envelopeOf(StopRingRequest()),
        );
        await settle();

        expect(
          (reply as RingStatus).reason,
          StopReason.STOP_REASON_STOPPED_REMOTELY,
        );
        expect(platform.playing, isNull);
        final toLaptop = laptop.sent.whereType<RingStatus>().single;
        expect(toLaptop.state, RingState.RING_STATE_STOPPED);
        expect(toLaptop.reason, StopReason.STOP_REASON_STOPPED_REMOTELY);
        expect(tablet.sent.whereType<RingStatus>(), isEmpty);
        await feature.stop();
      },
    );

    test('Found it here tells the device that asked', () async {
      final host = await FakeHost.create();
      final platform = FakeFindPlatform();
      final laptop = FakeSession('laptop');
      host.sessions = [laptop];
      final feature = await startFeature(host, platform);
      await feature.onEnvelope(laptop, envelopeOf(RingRequest()));

      platform.stopOnDevice(.found);
      await settle();

      expect(
        laptop.sent.whereType<RingStatus>().single.reason,
        StopReason.STOP_REASON_FOUND,
      );
      await feature.stop();
    });

    test('says what it can do, and tells others when that changes', () async {
      final host = await FakeHost.create();
      final platform = FakeFindPlatform(
        abilitiesNow: const RingAbilities(
          controlsVolume: true,
          needsDndAccess: true,
        ),
      );
      final laptop = FakeSession('laptop');
      final feature = await startFeature(host, platform);

      final before = await feature.onEnvelope(
        laptop,
        envelopeOf(GetRingInfo()),
      );
      platform.abilitiesNow = const RingAbilities(
        controlsVolume: true,
        needsDndAccess: true,
        dndAccessGranted: true,
      );
      await feature.refreshAbilities();

      expect((before as RingInfo).needsPermission, isTrue);
      expect(before.ringsWhenSilent, isFalse);
      final pushed = host.broadcasts.whereType<RingInfo>().single;
      expect(pushed.needsPermission, isFalse);
      expect(pushed.ringsWhenSilent, isTrue);
      await feature.stop();
    });
  });

  group('when this device rings another one', () {
    test('follows it from ringing to found', () async {
      final host = await FakeHost.create();
      final phone = FakeSession(
        'phone',
        answer: (_) =>
            RingStatus(state: .RING_STATE_RINGING, remainingMs: 120000),
      );
      host.sessions = [phone];
      final feature = await startFeature(host, FakeFindPlatform());

      final ring = await feature.ring('phone');
      expect(ring.phase, OutgoingPhase.ringing);
      expect(phone.requests.single, isA<RingRequest>());

      await feature.onEnvelope(
        phone,
        envelopeOf(
          RingStatus(state: .RING_STATE_STOPPED, reason: .STOP_REASON_FOUND),
          expectsReply: false,
        ),
      );

      expect(feature.outgoingFor('phone')?.phase, OutgoingPhase.found);
      await feature.stop();
    });

    test('stops it from here', () async {
      final host = await FakeHost.create();
      final phone = FakeSession(
        'phone',
        answer: (request) => switch (request) {
          RingRequest() => RingStatus(
            state: .RING_STATE_RINGING,
            remainingMs: 1000,
          ),
          _ => RingStatus(
            state: .RING_STATE_STOPPED,
            reason: .STOP_REASON_STOPPED_REMOTELY,
          ),
        },
      );
      host.sessions = [phone];
      final feature = await startFeature(host, FakeFindPlatform());

      await feature.ring('phone');
      await feature.stopRinging('phone');

      expect(phone.requests.last, isA<StopRingRequest>());
      expect(feature.outgoingFor('phone')?.phase, OutgoingPhase.stoppedHere);
      await feature.stop();
    });

    test('explains a device that did not answer or cannot ring', () async {
      final host = await FakeHost.create();
      final silent = FakeSession('silent');
      final old = FakeSession(
        'old',
        answer: (_) =>
            throw const RemoteErrorException(.ERROR_CODE_UNSUPPORTED, 'find'),
      );
      final none = FakeSession('none', supportsFind: false);
      host.sessions = [silent, old, none];
      final feature = await startFeature(host, FakeFindPlatform());

      expect((await feature.ring('silent')).phase, OutgoingPhase.unreachable);
      expect((await feature.ring('old')).phase, OutgoingPhase.notSupported);
      expect((await feature.ring('none')).phase, OutgoingPhase.notSupported);
      expect((await feature.ring('gone')).phase, OutgoingPhase.unreachable);
      await feature.stop();
    });

    test('a dropped connection while ringing is reported', () async {
      final host = await FakeHost.create();
      final phone = FakeSession(
        'phone',
        answer: (_) =>
            RingStatus(state: .RING_STATE_RINGING, remainingMs: 120000),
      );
      host.sessions = [phone];
      final feature = await startFeature(host, FakeFindPlatform());
      await feature.ring('phone');

      feature.onSessionClosed(phone);

      expect(feature.outgoingFor('phone')?.phase, OutgoingPhase.lostConnection);
      feature.dismiss('phone');
      expect(feature.outgoingFor('phone'), isNull);
      await feature.stop();
    });

    test('a ring that should be over is marked so if no word came', () async {
      final host = await FakeHost.create();

      fakeAsync((async) {
        final phone = FakeSession(
          'phone',
          answer: (_) =>
              RingStatus(state: .RING_STATE_RINGING, remainingMs: 10),
        );
        host.sessions = [phone];
        late final FindFeature feature;
        unawaited(
          startFeature(
            host,
            FakeFindPlatform(),
          ).then((started) => feature = started),
        );
        async.flushMicrotasks();
        unawaited(feature.ring('phone'));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 4));
        expect(feature.outgoingFor('phone')?.phase, OutgoingPhase.ringing);
        async.elapse(const Duration(seconds: 2));
        expect(feature.outgoingFor('phone')?.phase, OutgoingPhase.timedOut);
      });
    });
  });

  group('device health', () {
    RingInfo info({
      bool loud = false,
      bool permission = false,
      bool appOpen = false,
    }) => RingInfo(
      ringsWhenSilent: loud,
      needsPermission: permission,
      needsAppOpen: appOpen,
    );

    OutgoingRing ringIn(OutgoingPhase phase) => OutgoingRing(
      deviceId: 'phone',
      deviceName: 'Pixel',
      phase: phase,
      startedAt: DateTime(2026),
    );

    test('comes from the last answer', () {
      expect(ringHealthOf(supported: true), RingHealth.unknown);
      expect(
        ringHealthOf(
          supported: true,
          remote: RemoteRingInfo.answered(info(loud: true)),
        ),
        RingHealth.loud,
      );
      expect(
        ringHealthOf(supported: true, remote: RemoteRingInfo.answered(info())),
        RingHealth.followsSilent,
      );
      expect(
        ringHealthOf(
          supported: true,
          remote: RemoteRingInfo.answered(info(permission: true)),
        ),
        RingHealth.needsPermission,
      );
      expect(
        ringHealthOf(
          supported: true,
          remote: RemoteRingInfo.answered(info(appOpen: true)),
        ),
        RingHealth.needsAppOpen,
      );
      expect(
        ringHealthOf(supported: true, remote: const RemoteRingInfo.failed()),
        RingHealth.notAnswering,
      );
      expect(ringHealthOf(supported: false), RingHealth.unsupported);
    });

    test('a failed ring outranks an older good answer', () {
      final remote = RemoteRingInfo.answered(info(loud: true));

      expect(
        ringHealthOf(
          supported: true,
          remote: remote,
          lastRing: ringIn(.unreachable),
        ),
        RingHealth.notAnswering,
      );
      expect(
        ringHealthOf(
          supported: true,
          remote: remote,
          lastRing: ringIn(.noSound),
        ),
        RingHealth.noSound,
      );
      expect(
        ringHealthOf(supported: true, remote: remote, lastRing: ringIn(.found)),
        RingHealth.loud,
      );
    });

    test('the UI turns it into a chip with a reason', () async {
      final host = await FakeHost.create();
      final phone = FakeSession(
        'phone',
        answer: (_) => RingInfo(needsPermission: true),
      );
      host.sessions = [phone];
      final ui = FindFeatureUi(
        feature: FindFeature(platform: FakeFindPlatform.new),
      );
      await ui.feature.start(host);
      final device = DeviceStatus(
        TrustedDevice(
          id: 'phone',
          name: 'Pixel',
          platform: .PLATFORM_ANDROID,
          formFactor: .FORM_FACTOR_PHONE,
          publicKey: Uint8List(0),
          pairedAt: DateTime(2026),
        ),
        phone,
      );

      ui.feature.onSessionOpened(phone);
      await settle();
      final health = ui.healthFor(_context, device);

      expect(health?.state, FeatureHealthState.needsAttention);
      expect(health?.reason, contains('Do Not Disturb'));
      expect(ui.healthFor(_context, DeviceStatus(device.device, null)), isNull);
      await ui.feature.stop();
    });
  });
}

final _context = _NoContext();

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
