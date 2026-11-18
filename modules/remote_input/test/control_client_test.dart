import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHost host;
  late FakeSession mac;
  late ControlClient client;

  setUp(() async {
    host = await FakeHost.create();
    mac = FakeSession('mac', name: 'Mac');
    host.sessions = [mac];
    client = ControlClient(
      host: host,
      featureId: RemoteInputFeature.featureId,
    );
  });

  tearDown(() => client.dispose());

  List<InputEvent> sentEvents() => [
    for (final batch in mac.sentOf<InputBatch>()) ...batch.events,
  ];

  test('a device that allows it for good grants at once', () async {
    mac.answer = (_) => ControlGrant(version: 1, always: true);

    final control = await client.start('mac');

    expect(control.phase, OutgoingPhase.active);
    expect(control.always, isTrue);
    expect((mac.requests.single as ControlRequest).version, 1);
  });

  test('waits for the owner, then the grant arrives', () async {
    mac.answer = (_) => ControlPending(timeoutSeconds: 60);

    final waiting = await client.start('mac');
    expect(waiting.phase, OutgoingPhase.waitingForConsent);

    client.onGrant(mac, ControlGrant(version: 1));
    expect(client.current?.phase, OutgoingPhase.active);
  });

  test('a no after waiting says why', () async {
    mac.answer = (_) => ControlPending(timeoutSeconds: 60);
    await client.start('mac');

    client.onDeny(mac, ControlDeny(reason: .DENY_REASON_DENIED));

    expect(client.current?.phase, OutgoingPhase.denied);
    expect(client.current?.denial, OutgoingDenial.denied);
    expect(client.lastFor('mac')?.denial, OutgoingDenial.denied);
  });

  test('a missing permission on the computer reads as such', () async {
    mac.answer = (_) => ControlDeny(reason: .DENY_REASON_NEEDS_PERMISSION);

    final control = await client.start('mac');

    expect(control.denial, OutgoingDenial.needsPermission);
  });

  test('no answer at all is unreachable', () async {
    final control = await client.start('mac');

    expect(control.phase, OutgoingPhase.unreachable);
  });

  test('a device that is not connected is unreachable', () async {
    expect(
      (await client.start('elsewhere')).phase,
      OutgoingPhase.unreachable,
    );
  });

  test('input goes out in batches while active, never before', () async {
    client.move(5, 5);
    mac.answer = (_) => ControlGrant(version: 1);
    await client.start('mac');

    client
      ..move(3, 1)
      ..click(.left)
      ..tapKey(.c, modifiers: {.control})
      ..type('hey');
    await settle();

    final kinds = [for (final event in sentEvents()) event.whichKind().name];
    expect(kinds, [
      'move',
      'button',
      'button',
      'key',
      'key',
      'text',
    ]);
    expect(sentEvents().first.move.dx, 3);
  });

  test('stop tells the computer and forgets the control', () async {
    mac.answer = (_) => ControlGrant(version: 1);
    await client.start('mac');

    await client.stop();

    expect(client.current, isNull);
    expect(
      mac.sentOf<ControlStop>().single.reason,
      StopReason.STOP_REASON_CONTROLLER_DONE,
    );
  });

  test('the computer stopping it says who stopped it', () async {
    mac.answer = (_) => ControlGrant(version: 1);
    await client.start('mac');

    client.onStop(mac, ControlStop(reason: .STOP_REASON_STOPPED_ON_HOST));
    client.move(1, 1);
    await settle();

    expect(client.current?.phase, OutgoingPhase.stopped);
    expect(client.current?.stop, OutgoingStop.stoppedOnHost);
    expect(mac.sentOf<InputBatch>(), isEmpty);
  });

  test('a dropped connection is said plainly', () async {
    mac.answer = (_) => ControlGrant(version: 1);
    await client.start('mac');

    client.onSessionClosed('mac');

    expect(client.current?.phase, OutgoingPhase.lostConnection);
  });

  test('a grant that arrives after giving up is let go', () async {
    late void Function() release;
    mac.answer = (_) async {
      await Future<void>(() => release());
      return ControlGrant(version: 1);
    };
    release = () {};
    final starting = client.start('mac');
    await client.stop();
    await starting;
    await settle();

    expect(mac.sentOf<ControlStop>(), hasLength(2));
    expect(client.current, isNull);
  });

  test('waiting too long gives up and tells the computer', () {
    fakeAsync((async) {
      final waitingClient = ControlClient(
        host: host,
        featureId: RemoteInputFeature.featureId,
      );
      mac.answer = (_) => ControlPending(timeoutSeconds: 60);
      waitingClient.start('mac');
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 76));

      expect(waitingClient.current?.denial, OutgoingDenial.timeout);
      expect(mac.sentOf<ControlStop>(), hasLength(1));
    });
  });
}
