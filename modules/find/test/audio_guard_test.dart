import 'dart:async';

import 'package:core/core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/find.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  const before = AudioState(
    volume: 3,
    maxVolume: 7,
    interruptionFilter: 2,
    quiet: true,
  );

  test('raises to full, lifts Do Not Disturb and puts both back', () async {
    final platform = FakeFindPlatform(audio: before);
    final settings = FindSettings(MemorySettingsStore());
    final guard = AudioGuard(platform, settings);

    await guard.raise(await guard.read(), liftDoNotDisturb: true);

    expect(platform.audio?.volume, 7);
    expect(platform.audio?.interruptionFilter, AudioState.filterAll);
    expect(settings.savedAudio?.volume, 3);

    await guard.restore();

    expect(platform.audio?.volume, 3);
    expect(platform.audio?.interruptionFilter, 2);
    expect(settings.savedAudio, isNull);
  });

  test('leaves Do Not Disturb alone without access', () async {
    final platform = FakeFindPlatform(audio: before);
    final guard = AudioGuard(platform, FindSettings(MemorySettingsStore()));

    await guard.raise(before, liftDoNotDisturb: false);

    expect(platform.audio?.volume, 7);
    expect(platform.audio?.interruptionFilter, 2);
  });

  test('keeps the older saved volume when a ring never restored', () async {
    final store = MemorySettingsStore({
      FindSettings.savedAudioKey: before.toJson(),
    });
    final platform = FakeFindPlatform(
      audio: const AudioState(volume: 7, maxVolume: 7, interruptionFilter: 1),
    );
    final guard = AudioGuard(platform, FindSettings(store));

    await guard.raise(await guard.read(), liftDoNotDisturb: true);
    await guard.restore();

    expect(platform.audio?.volume, 3);
    expect(platform.audio?.interruptionFilter, 2);
  });

  test('does nothing where the volume cannot be read', () async {
    final platform = FakeFindPlatform()..audio = null;
    final settings = FindSettings(MemorySettingsStore());
    final guard = AudioGuard(platform, settings);

    await guard.raise(await guard.read(), liftDoNotDisturb: true);
    await guard.restore();

    expect(platform.applied, isEmpty);
    expect(settings.savedAudio, isNull);
  });

  test('a volume left raised by a crash goes back at start', () async {
    final platform = FakeFindPlatform(
      audio: const AudioState(volume: 7, maxVolume: 7, interruptionFilter: 1),
    );
    final settings = FindSettings(
      MemorySettingsStore({FindSettings.savedAudioKey: before.toJson()}),
    );

    await RingController(platform: platform, settings: settings).start();

    expect(platform.audio?.volume, 3);
    expect(settings.savedAudio, isNull);
  });

  test('every way a ring ends restores the volume', () {
    for (final ending in ['timeout', 'found', 'device', 'remote']) {
      fakeAsync((async) {
        final platform = FakeFindPlatform(audio: before);
        final settings = FindSettings(MemorySettingsStore());
        final controller = RingController(
          platform: platform,
          settings: settings,
        );
        unawaited(controller.start());
        async.flushMicrotasks();
        unawaited(
          controller.ring(requesterId: 'laptop', requesterName: 'Laptop'),
        );
        async.flushMicrotasks();
        expect(platform.audio?.volume, 7, reason: ending);

        switch (ending) {
          case 'timeout':
            async.elapse(RingController.defaultDuration);
          case 'found':
            unawaited(controller.stop(.STOP_REASON_FOUND));
          case 'device':
            platform.stopOnDevice(.found);
          case 'remote':
            unawaited(controller.stop(.STOP_REASON_STOPPED_REMOTELY));
        }
        async.flushMicrotasks();

        expect(platform.audio?.volume, 3, reason: ending);
        expect(platform.audio?.interruptionFilter, 2, reason: ending);
        expect(settings.savedAudio, isNull, reason: ending);
      });
    }
  });
}
