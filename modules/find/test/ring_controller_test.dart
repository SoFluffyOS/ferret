import 'dart:async';

import 'package:core/core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/find.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/find.dart';

import 'helpers/fakes.dart';

void main() {
  final start = DateTime(2026, 11, 18, 9);

  ({
    RingController controller,
    FakeFindPlatform platform,
    FindSettings settings,
  })
  setUpController(
    FakeAsync async, {
    FakeFindPlatform? platform,
    Map<String, Object?>? settings,
  }) {
    final fake = platform ?? FakeFindPlatform();
    final store = FindSettings(MemorySettingsStore(settings));
    final controller = RingController(
      platform: fake,
      settings: store,
      clock: () => start.add(async.elapsed),
    );
    unawaited(controller.start());
    async.flushMicrotasks();
    return (controller: controller, platform: fake, settings: store);
  }

  LocalRing ringNow(
    FakeAsync async,
    RingController controller, {
    String requesterId = 'laptop',
    Duration? duration,
    bool overrideSilent = true,
  }) {
    LocalRing? result;
    unawaited(
      controller
          .ring(
            requesterId: requesterId,
            requesterName: 'Laptop',
            duration: duration,
            overrideSilent: overrideSilent,
          )
          .then((ring) => result = ring),
    );
    async.flushMicrotasks();
    if (result case final ring?) {
      return ring;
    }

    fail('The ring did not finish');
  }

  test('rings, then stops on its own after the duration', () {
    fakeAsync((async) {
      final (:controller, :platform, settings: _) = setUpController(async);

      final ring = ringNow(async, controller);

      expect(ring.isRinging, isTrue);
      expect(ring.endsAt, start.add(RingController.defaultDuration));
      expect(platform.playing?.body, contains('Laptop'));
      expect(platform.playing?.flashTorch, isTrue);

      async.elapse(const Duration(minutes: 1, seconds: 59));
      expect(controller.current.isRinging, isTrue);

      async.elapse(const Duration(seconds: 1));
      expect(controller.current.phase, LocalRingPhase.stopped);
      expect(controller.current.reason, StopReason.STOP_REASON_TIMEOUT);
      expect(platform.playing, isNull);
    });
  });

  test('Found it on the device stops the ring', () {
    fakeAsync((async) {
      final (:controller, :platform, settings: _) = setUpController(async);
      ringNow(async, controller);

      platform.stopOnDevice(.volumeKey);
      async.flushMicrotasks();

      expect(controller.current.reason, StopReason.STOP_REASON_FOUND);
      async.elapse(const Duration(minutes: 3));
      expect(controller.current.reason, StopReason.STOP_REASON_FOUND);
    });
  });

  test('a second request extends the ring, never past the longest', () {
    fakeAsync((async) {
      final (:controller, :platform, settings: _) = setUpController(async);
      ringNow(async, controller, duration: const Duration(minutes: 2));

      async.elapse(const Duration(minutes: 2) - const Duration(seconds: 10));
      final extended = ringNow(
        async,
        controller,
        requesterId: 'tablet',
        duration: const Duration(minutes: 4),
      );

      expect(platform.alerts, hasLength(1));
      expect(extended.requesterIds, ['laptop', 'tablet']);
      expect(extended.endsAt, start.add(RingController.maxDuration));

      async.elapse(const Duration(minutes: 3, seconds: 9));
      expect(controller.current.isRinging, isTrue);
      async.elapse(const Duration(seconds: 1));
      expect(controller.current.reason, StopReason.STOP_REASON_TIMEOUT);
    });
  });

  test('durations are kept between the shortest and the longest', () {
    fakeAsync((async) {
      final (:controller, platform: _, settings: _) = setUpController(async);

      final ring = ringNow(async, controller, duration: Duration.zero);

      expect(ring.endsAt, start.add(RingController.minDuration));
    });
  });

  test('stopping when idle does nothing', () {
    fakeAsync((async) {
      final (:controller, :platform, settings: _) = setUpController(async);

      unawaited(controller.stop(.STOP_REASON_FOUND));
      async.flushMicrotasks();

      expect(controller.current.phase, LocalRingPhase.idle);
      expect(platform.stopCount, 0);
    });
  });

  test('with ringing on silent off, a silent device only vibrates', () {
    fakeAsync((async) {
      final (:controller, :platform, settings: _) = setUpController(
        async,
        settings: {FindSettings.ringOnSilentKey: false},
      );

      final ring = ringNow(async, controller);

      expect(ring.muted, isTrue);
      expect(platform.playing?.silent, isTrue);
      expect(platform.applied, isEmpty);
    });
  });

  test('a device that is not on silent rings out loud anyway', () {
    fakeAsync((async) {
      final platform = FakeFindPlatform(
        audio: const AudioState(volume: 5, maxVolume: 7),
      );
      final (:controller, platform: _, settings: _) = setUpController(
        async,
        platform: platform,
        settings: {FindSettings.ringOnSilentKey: false},
      );

      final ring = ringNow(async, controller);

      expect(ring.muted, isFalse);
      expect(platform.playing?.silent, isFalse);
    });
  });

  test('a ring that cannot sound fails and leaves the volume as it was', () {
    fakeAsync((async) {
      final platform = FakeFindPlatform()..failStart = true;
      final (:controller, platform: _, :settings) = setUpController(
        async,
        platform: platform,
      );

      final ring = ringNow(async, controller);

      expect(ring.phase, LocalRingPhase.stopped);
      expect(ring.reason, StopReason.STOP_REASON_FAILED);
      expect(platform.audio?.volume, 3);
      expect(platform.audio?.interruptionFilter, 2);
      expect(settings.savedAudio, isNull);
    });
  });
}
