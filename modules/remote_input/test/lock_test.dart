import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';

class _FakeLocker implements ScreenLocker {
  _FakeLocker({this.works = true});

  final bool works;
  int locks = 0;

  @override
  bool get isSupported => true;

  @override
  Future<bool> lock() async {
    locks++;
    return works;
  }
}

void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeSession tablet;
  late _FakeLocker locker;
  late ControlHost control;

  setUp(() async {
    host = await FakeHost.create();
    pixel = FakeSession('pixel', name: 'Pixel');
    tablet = FakeSession('tablet', name: 'Tablet');
    host.sessions = [pixel, tablet];
    locker = _FakeLocker();
    control = ControlHost(
      host: host,
      featureId: RemoteInputFeature.featureId,
      injector: FakeInjector(),
      locker: locker,
      settings: RemoteInputSettings(host.settings),
      consentTimeout: const Duration(milliseconds: 200),
    );
    await control.start();
  });

  Future<LockResult> lockFrom(FakeSession session) async =>
      (await control.onLockRequest(session)).result;

  test('the first lock asks the owner, as a lock', () async {
    final reply = lockFrom(pixel);
    await pumpEventQueue();

    expect(control.pending?.kind, ConsentKind.lock);
    expect(control.pending?.deviceName, 'Pixel');
    expect(locker.locks, 0);

    await control.answer(.allowOnce);

    expect(await reply, LockResult.LOCK_RESULT_LOCKED);
    expect(locker.locks, 1);
    expect(control.pending, isNull);
    expect(control.active, isNull);
  });

  test('always allow locks right away next time', () async {
    final first = lockFrom(pixel);
    await pumpEventQueue();
    await control.answer(.always);
    await first;

    expect(await lockFrom(pixel), LockResult.LOCK_RESULT_LOCKED);
    expect(locker.locks, 2);
    expect(RemoteInputSettings(host.settings).lockDevices, ['pixel']);
  });

  test('a device always allowed to control may lock without asking', () async {
    await RemoteInputSettings(host.settings).allow('pixel');

    expect(await lockFrom(pixel), LockResult.LOCK_RESULT_LOCKED);
  });

  test("don't allow says no, and the device can't ask again at once", () async {
    final reply = lockFrom(pixel);
    await pumpEventQueue();
    await control.answer(.deny);

    expect(await reply, LockResult.LOCK_RESULT_DENIED);
    expect(await lockFrom(pixel), LockResult.LOCK_RESULT_DENIED);
    expect(locker.locks, 0);
  });

  test('nobody answering times out', () async {
    expect(await lockFrom(pixel), LockResult.LOCK_RESULT_TIMEOUT);
    expect(control.pending, isNull);
  });

  test(
    'another device asking meanwhile is told the computer is busy',
    () async {
      final first = lockFrom(pixel);
      await pumpEventQueue();

      expect(await lockFrom(tablet), LockResult.LOCK_RESULT_BUSY);

      await control.answer(.deny);
      await first;
    },
  );

  test('turned off, nothing is asked or locked', () async {
    await control.setEnabled(false);

    expect(await lockFrom(pixel), LockResult.LOCK_RESULT_TURNED_OFF);
    expect(control.pending, isNull);
  });

  test('a lock that fails says so', () async {
    await RemoteInputSettings(host.settings).allowLock('pixel');
    control = ControlHost(
      host: host,
      featureId: RemoteInputFeature.featureId,
      injector: FakeInjector(),
      locker: _FakeLocker(works: false),
      settings: RemoteInputSettings(host.settings),
    );

    expect(await lockFrom(pixel), LockResult.LOCK_RESULT_FAILED);
  });

  group('feature', () {
    test('a computer that can lock says so in its flags', () {
      final computer = RemoteInputFeature(
        injector: FakeInjector.new,
        locker: _FakeLocker(),
        canBeControlled: true,
        canControl: false,
      );
      final phone = RemoteInputFeature(
        injector: FakeInjector.new,
        locker: const UnsupportedScreenLocker(),
        canBeControlled: false,
        canControl: true,
      );

      expect(computer.flags, contains(RemoteInputFeature.lockFlag));
      expect(phone.flags, isNot(contains(RemoteInputFeature.lockFlag)));
    });

    test('the phone keeps what came of its lock for Activity', () async {
      final phoneHost = await FakeHost.create();
      final mac = FakeSession('mac', name: 'MacBook Air')
        ..answer = (_) => LockReply(result: .LOCK_RESULT_LOCKED);
      phoneHost.sessions = [mac];
      final phone = RemoteInputFeature(
        injector: FakeInjector.new,
        locker: const UnsupportedScreenLocker(),
        canBeControlled: false,
        canControl: true,
      );
      await phone.start(phoneHost);
      addTearDown(phone.stop);

      final result = await phone.lockDevice('mac');

      expect(result, LockResult.LOCK_RESULT_LOCKED);
      expect(phone.locks.single.deviceName, 'MacBook Air');
      expect(phone.locks.single.result, LockResult.LOCK_RESULT_LOCKED);

      phone.dismissLock('mac');
      expect(phone.locks, isEmpty);
    });
  });
}
