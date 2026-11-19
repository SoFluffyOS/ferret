import 'dart:async';

import 'package:actions/actions.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeLocker locker;
  late FakeIdle idle;
  late ActionsSettings settings;

  setUp(() async {
    host = await FakeHost.create();
    await pairPhone(host, 'pixel');
    pixel = FakeSession('pixel');
    host.sessions = [pixel];
    locker = FakeLocker();
    idle = FakeIdle();
    settings = ActionsSettings(host.settings);
    await settings.setLocksWhenGone('pixel', locks: true);
  });

  /// Runs [body] with a lock that waits the default two minutes, then
  /// counts down ten seconds.
  void withLeaveLock(void Function(FakeAsync async, LeaveLock lock) body) {
    fakeAsync((async) {
      final lock = LeaveLock(
        host: host,
        settings: settings,
        locker: locker,
        idle: idle,
        clock: () => DateTime(2026, 11, 19).add(async.elapsed),
      )..start();
      body(async, lock);
      unawaited(lock.dispose());
      async.flushMicrotasks();
    });
  }

  void drop(LeaveLock lock, {GoodbyeReason? goodbye}) {
    host.sessions = [];
    pixel.remoteGoodbye = goodbye;
    lock.onSessionClosed(pixel);
  }

  void comeBack(LeaveLock lock) {
    pixel = FakeSession('pixel');
    host.sessions = [pixel];
    lock.onSessionOpened(pixel);
  }

  test('a phone gone for two minutes locks after the countdown', () {
    withLeaveLock((async, lock) {
      drop(lock);
      async.elapse(const Duration(minutes: 1, seconds: 59));
      expect(lock.countdown, isNull);

      async.elapse(const Duration(seconds: 1));
      expect(lock.countdown?.deviceName, 'Pixel 7');
      expect(locker.locks, 0);

      async.elapse(const Duration(seconds: 10));
      expect(locker.locks, 1);
      expect(lock.countdown, isNull);
      expect(lock.recent.single.outcome, LeaveLockOutcome.locked);
      expect(lock.recent.single.deviceId, 'pixel');
    });
  });

  test('the wait follows the minutes in Settings', () {
    withLeaveLock((async, lock) {
      unawaited(settings.setLockAfterMinutes(5));
      async.flushMicrotasks();
      drop(lock);

      async.elapse(const Duration(minutes: 4));
      expect(lock.countdown, isNull);

      async.elapse(const Duration(minutes: 1));
      expect(lock.countdown, isNotNull);
    });
  });

  test('a phone that reconnects in time never locks', () {
    withLeaveLock((async, lock) {
      drop(lock);
      async.elapse(const Duration(seconds: 40));
      comeBack(lock);

      async.elapse(const Duration(minutes: 10));
      expect(lock.countdown, isNull);
      expect(locker.locks, 0);
      expect(lock.recent, isEmpty);
    });
  });

  test('while the engine still reconnects, it waits', () {
    withLeaveLock((async, lock) {
      var reconnecting = true;
      lock.watchReconnecting((_) => reconnecting);
      drop(lock);

      async.elapse(const Duration(minutes: 3));
      expect(lock.countdown, isNull);

      reconnecting = false;
      async.elapse(const Duration(seconds: 30));
      expect(lock.countdown, isNotNull);
    });
  });

  test('a phone that came back during the countdown stops it', () {
    withLeaveLock((async, lock) {
      drop(lock);
      async.elapse(const Duration(minutes: 2, seconds: 5));
      expect(lock.countdown, isNotNull);

      comeBack(lock);
      async.elapse(const Duration(seconds: 10));
      expect(lock.countdown, isNull);
      expect(locker.locks, 0);
    });
  });

  test('a goodbye (Ferret paused or quit there) is not leaving', () {
    withLeaveLock((async, lock) {
      drop(lock, goodbye: .GOODBYE_REASON_SHUTDOWN);

      async.elapse(const Duration(minutes: 10));
      expect(lock.countdown, isNull);
      expect(locker.locks, 0);
    });
  });

  test('someone at the keyboard keeps it unlocked', () {
    withLeaveLock((async, lock) {
      idle.idle = const Duration(seconds: 20);
      drop(lock);

      async.elapse(const Duration(minutes: 10));
      expect(lock.countdown, isNull);
      expect(locker.locks, 0);
    });
  });

  test('once the keyboard sits untouched for a minute, it counts down', () {
    withLeaveLock((async, lock) {
      idle.idle = const Duration(seconds: 20);
      drop(lock);
      async.elapse(const Duration(minutes: 3));
      expect(lock.countdown, isNull);

      idle.idle = const Duration(minutes: 1);
      async.elapse(const Duration(seconds: 30));
      expect(lock.countdown, isNotNull);
    });
  });

  test('an idle time the system will not give still counts down', () {
    withLeaveLock((async, lock) {
      idle.idle = null;
      drop(lock);

      async.elapse(const Duration(minutes: 2));
      expect(lock.countdown, isNotNull);
    });
  });

  test('cancel keeps it unlocked until the phone leaves again', () {
    withLeaveLock((async, lock) {
      drop(lock);
      async.elapse(const Duration(minutes: 2));
      lock.cancel();

      async.elapse(const Duration(minutes: 10));
      expect(locker.locks, 0);
      expect(lock.recent.single.outcome, LeaveLockOutcome.cancelled);

      comeBack(lock);
      drop(lock);
      async.elapse(const Duration(minutes: 2, seconds: 10));
      expect(locker.locks, 1);
    });
  });

  test('a phone not chosen never locks', () {
    withLeaveLock((async, lock) {
      unawaited(settings.setLocksWhenGone('pixel', locks: false));
      async.flushMicrotasks();
      drop(lock);

      async.elapse(const Duration(minutes: 10));
      expect(lock.countdown, isNull);
    });
  });

  test('turning the switch off mid-countdown stops it', () {
    withLeaveLock((async, lock) {
      drop(lock);
      async.elapse(const Duration(minutes: 2));
      expect(lock.countdown, isNotNull);

      unawaited(settings.setLocksWhenGone('pixel', locks: false));
      async.elapse(const Duration(seconds: 10));
      expect(lock.countdown, isNull);
      expect(locker.locks, 0);
    });
  });

  test('an already locked screen is left alone', () {
    withLeaveLock((async, lock) {
      host.localPresence = Presence(batteryPercent: -1, away: true);
      drop(lock);

      async.elapse(const Duration(minutes: 10));
      expect(lock.countdown, isNull);
    });
  });

  test('a lock the system refused shows as failed', () {
    withLeaveLock((async, lock) {
      locker.works = false;
      drop(lock);

      async.elapse(const Duration(minutes: 2, seconds: 10));
      expect(lock.recent.single.outcome, LeaveLockOutcome.failed);
    });
  });

  test('only Android phones can be watched', () {
    expect(LeaveLock.canWatch(.PLATFORM_ANDROID), isTrue);
    expect(LeaveLock.canWatch(.PLATFORM_IOS), isFalse);
    expect(LeaveLock.canWatch(.PLATFORM_MACOS), isFalse);
  });

  test('minutes stay between one and ten', () async {
    expect(settings.lockAfterMinutes, 2);

    await settings.setLockAfterMinutes(30);
    expect(settings.lockAfterMinutes, 10);

    await settings.setLockAfterMinutes(0);
    expect(settings.lockAfterMinutes, 1);
  });
}
