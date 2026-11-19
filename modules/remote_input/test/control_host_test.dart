import 'package:fake_async/fake_async.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHost host;
  late FakeInjector injector;
  late FakeSession pixel;
  late FakeSession tablet;
  late DateTime now;
  late ControlHost control;

  setUp(() async {
    host = await FakeHost.create();
    injector = FakeInjector();
    pixel = FakeSession('pixel', name: 'Pixel');
    tablet = FakeSession('tablet', name: 'Tablet');
    host.sessions = [pixel, tablet];
    now = DateTime(2026, 11, 18, 21, 10);
    control = ControlHost(
      host: host,
      featureId: RemoteInputFeature.featureId,
      injector: injector,
      settings: RemoteInputSettings(host.settings),
      clock: () => now,
    );
    await control.start();
  });

  Future<Object> request(FakeSession session, {int version = 1}) =>
      control.onRequest(session, ControlRequest(version: version));

  InputBatch batchOf(List<InputEvent> events) => InputBatch(events: events);

  group('consent', () {
    test('the first request asks the owner', () async {
      final reply = await request(pixel);

      expect(reply, isA<ControlPending>());
      expect((reply as ControlPending).timeoutSeconds, 60);
      expect(control.pending?.deviceName, 'Pixel');
      expect(control.active, isNull);
    });

    test('the request names the device as this one calls it', () async {
      await nameHere(host.trustStore, 'pixel', 'Work phone');

      await request(pixel);

      expect(control.pending?.deviceName, 'Work phone');
    });

    test('allow once grants this time, and asks again next time', () async {
      await request(pixel);
      await control.answer(.allowOnce);

      expect(control.active?.deviceId, 'pixel');
      expect(control.active?.always, isFalse);
      expect(pixel.sentOf<ControlGrant>().single.always, isFalse);

      await control.onStop(pixel);
      expect(await request(pixel), isA<ControlPending>());
    });

    test('always grants now and every time after', () async {
      await request(pixel);
      await control.answer(.always);
      await control.onStop(pixel);

      final reply = await request(pixel);

      expect(reply, isA<ControlGrant>());
      expect((reply as ControlGrant).always, isTrue);
      expect(RemoteInputSettings(host.settings).allowedDevices, ['pixel']);
    });

    test("don't allow denies, and turns the device away for a while", () async {
      await request(pixel);
      await control.answer(.deny);

      expect(control.pending, isNull);
      expect(
        pixel.sentOf<ControlDeny>().single.reason,
        DenyReason.DENY_REASON_DENIED,
      );
      expect(await request(pixel), isA<ControlDeny>());

      now = now.add(const Duration(seconds: 31));
      expect(await request(pixel), isA<ControlPending>());
    });

    test('revoke forgets always and ends control at once', () async {
      await request(pixel);
      await control.answer(.always);

      await control.revoke('pixel');

      expect(control.active, isNull);
      expect(injector.releases, 1);
      expect(
        pixel.sentOf<ControlStop>().single.reason,
        StopReason.STOP_REASON_REVOKED,
      );
      expect(RemoteInputSettings(host.settings).allowedDevices, isEmpty);
      expect(await request(pixel), isA<ControlPending>());
    });

    test('nobody answering denies with a timeout', () {
      fakeAsync((async) {
        control.onRequest(pixel, ControlRequest(version: 1));
        async.flushMicrotasks();
        expect(control.pending, isNotNull);

        async.elapse(const Duration(seconds: 61));

        expect(control.pending, isNull);
        expect(
          pixel.sentOf<ControlDeny>().single.reason,
          DenyReason.DENY_REASON_TIMEOUT,
        );
      });
    });

    test(
      'a repeated request while asking waits on the same question',
      () async {
        await request(pixel);
        now = now.add(const Duration(seconds: 20));

        final reply = await request(pixel);

        expect((reply as ControlPending).timeoutSeconds, 40);
      },
    );

    test('the controller giving up clears the question', () async {
      await request(pixel);

      await control.onStop(pixel);

      expect(control.pending, isNull);
    });
  });

  group('one at a time', () {
    test('another device is busy while one asks or controls', () async {
      await request(pixel);
      expect(
        (await request(tablet) as ControlDeny).reason,
        DenyReason.DENY_REASON_BUSY,
      );

      await control.answer(.allowOnce);
      expect(
        (await request(tablet) as ControlDeny).reason,
        DenyReason.DENY_REASON_BUSY,
      );
      expect(await request(pixel), isA<ControlGrant>());
    });
  });

  group('refusals', () {
    test('turned off', () async {
      await RemoteInputSettings(host.settings).setEnabled(false);

      expect(
        (await request(pixel) as ControlDeny).reason,
        DenyReason.DENY_REASON_TURNED_OFF,
      );
    });

    test('a newer major version', () async {
      expect(
        (await request(pixel, version: 2) as ControlDeny).reason,
        DenyReason.DENY_REASON_VERSION,
      );
    });

    test('no way to inject on this computer', () async {
      injector.statusNow = const .unavailable(.noLinuxBackend);

      expect(
        (await request(pixel) as ControlDeny).reason,
        DenyReason.DENY_REASON_UNSUPPORTED,
      );
    });

    test('a missing permission tells the owner who asked', () async {
      injector.statusNow = const .needsPermission(.quartz);

      final reply = await request(pixel);

      expect(
        (reply as ControlDeny).reason,
        DenyReason.DENY_REASON_NEEDS_PERMISSION,
      );
      expect(control.permissionAsk?.deviceName, 'Pixel');

      injector.statusNow = const .ready(.quartz);
      await control.refreshStatus();
      expect(control.permissionAsk, isNull);
    });

    test(
      'asking for access opens settings when the prompt is used up',
      () async {
        injector.statusNow = const .needsPermission(.quartz);

        await control.requestAccess();

        expect(injector.requests, 1);
        expect(injector.settingsOpened, 1);
      },
    );
  });

  group('while controlled', () {
    Future<void> grant() async {
      await request(pixel);
      await control.answer(.allowOnce);
    }

    test('input from the controller is injected in order', () async {
      await grant();

      await control.onBatch(
        pixel,
        batchOf([
          InputCodec.move(4, 2),
          InputCodec.button(.left, pressed: true),
          InputCodec.button(.left, pressed: false),
          InputCodec.text('hi'),
        ]),
      );

      expect(injector.injected, const [
        MoveAction(4, 2),
        ButtonAction(.left, pressed: true),
        ButtonAction(.left, pressed: false),
        TextAction('hi'),
      ]);
    });

    test('input from any other device is dropped and answered once', () async {
      await grant();

      await control.onBatch(tablet, batchOf([InputCodec.move(1, 1)]));
      await control.onBatch(tablet, batchOf([InputCodec.move(1, 1)]));

      expect(injector.injected, isEmpty);
      expect(
        tablet.sentOf<ControlStop>().single.reason,
        StopReason.STOP_REASON_NOT_CONTROLLING,
      );
    });

    test(
      'Stop here cuts it off, lets go of keys and tells the phone',
      () async {
        await grant();
        now = now.add(const Duration(minutes: 4));

        await control.stop();
        await control.onBatch(pixel, batchOf([InputCodec.move(1, 1)]));

        expect(control.active, isNull);
        expect(injector.releases, 1);
        expect(injector.injected, isEmpty);
        expect(
          pixel.sentOf<ControlStop>().first.reason,
          StopReason.STOP_REASON_STOPPED_ON_HOST,
        );
        expect(control.lastRecord?.duration, const Duration(minutes: 4));
        expect(control.lastRecord?.end, ControlEnd.stoppedHere);
      },
    );

    test('the controller finishing writes an audit line', () async {
      await grant();
      now = now.add(const Duration(minutes: 4));

      await control.onStop(pixel);

      final history = RemoteInputSettings(host.settings).history;
      expect(history.single.deviceName, 'Pixel');
      expect(history.single.startedAt, DateTime(2026, 11, 18, 21, 10));
      expect(history.single.duration, const Duration(minutes: 4));
      expect(history.single.end, ControlEnd.controllerDone);
    });

    test('a dropped connection ends it and lets go of keys', () async {
      await grant();

      await control.onSessionClosed('pixel');

      expect(control.active, isNull);
      expect(injector.releases, 1);
      expect(control.lastRecord?.end, ControlEnd.lostConnection);
    });

    test('a failing injector that lost its permission ends it', () async {
      await grant();
      injector
        ..failInject = true
        ..statusNow = const .needsPermission(.quartz);

      await control.onBatch(pixel, batchOf([InputCodec.move(1, 1)]));

      expect(control.active, isNull);
      expect(
        pixel.sentOf<ControlStop>().single.reason,
        StopReason.STOP_REASON_FAILED,
      );
    });

    test('turning remote input off ends control', () async {
      await grant();

      await control.setEnabled(false);

      expect(control.active, isNull);
      expect(control.lastRecord?.end, ControlEnd.revoked);
    });
  });

  test('a long time without input ends control', () {
    fakeAsync((async) {
      var fakeNow = DateTime(2026, 11, 18);
      final idle = ControlHost(
        host: host,
        featureId: RemoteInputFeature.featureId,
        injector: injector,
        settings: RemoteInputSettings(host.settings),
        clock: () => fakeNow,
        idleTimeout: const Duration(minutes: 10),
      );
      idle.onRequest(pixel, ControlRequest(version: 1));
      async.flushMicrotasks();
      idle.answer(.allowOnce);
      async.flushMicrotasks();

      fakeNow = fakeNow.add(const Duration(minutes: 6));
      async.elapse(const Duration(minutes: 6));
      idle.onBatch(pixel, batchOf([InputCodec.move(1, 0)]));
      fakeNow = fakeNow.add(const Duration(minutes: 6));
      async.elapse(const Duration(minutes: 6));
      expect(idle.active, isNotNull);

      fakeNow = fakeNow.add(const Duration(minutes: 5));
      async.elapse(const Duration(minutes: 5));
      expect(idle.active, isNull);
      expect(idle.lastRecord?.end, ControlEnd.idle);
      expect(
        pixel.sentOf<ControlStop>().last.reason,
        StopReason.STOP_REASON_IDLE,
      );
    });
  });

  test('the history keeps the newest twenty', () async {
    final settings = RemoteInputSettings(host.settings);
    for (var index = 0; index < 25; index++) {
      await settings.addRecord(
        ControlRecord(
          deviceId: 'pixel',
          deviceName: 'Pixel $index',
          startedAt: now,
          endedAt: now,
          end: .controllerDone,
        ),
      );
    }

    expect(settings.history, hasLength(RemoteInputSettings.historyLength));
    expect(settings.history.first.deviceName, 'Pixel 24');

    await control.clearHistory();
    expect(settings.history, isEmpty);
  });
}
