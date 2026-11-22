import 'dart:async';

import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  late MulticastNeed need;
  late List<bool> changes;
  late StreamSubscription<bool> subscription;

  setUp(() {
    need = MulticastNeed();
    changes = [];
    subscription = need.changes.listen(changes.add);
  });

  tearDown(() => subscription.cancel());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a missing paired device needs it while running', () async {
    need
      ..setRunning(true)
      ..setMissing(true);
    await settle();

    expect(need.isNeeded, isTrue);
    expect(need.reasons, ['missing']);
    expect(changes, [true]);
  });

  test('every paired device connected and nobody looking: released', () {
    need
      ..setRunning(true)
      ..setMissing(true)
      ..setMissing(false);

    expect(need.isNeeded, isFalse);
    expect(need.reasons, isEmpty);
  });

  test('a drop brings it back', () async {
    need
      ..setRunning(true)
      ..setMissing(false);
    expect(need.isNeeded, isFalse);

    need.setMissing(true);
    await settle();
    expect(need.isNeeded, isTrue);
    expect(changes, [true]);
  });

  test('a scan screen open while every device is connected needs it', () {
    need
      ..setRunning(true)
      ..setMissing(false);

    final nearby = need.hold('nearby');
    expect(need.isNeeded, isTrue);
    expect(need.reasons, ['nearby']);

    nearby.release();
    expect(need.isNeeded, isFalse);
  });

  test('a pause releases it, whatever is held or missing', () async {
    need
      ..setRunning(true)
      ..setMissing(true);
    final nearby = need.hold('nearby');
    expect(need.isNeeded, isTrue);

    need.setRunning(false);
    expect(need.isNeeded, isFalse);
    expect(need.reasons, isEmpty);

    need.setRunning(true);
    expect(need.isNeeded, isTrue);
    nearby.release();
    await settle();
    expect(changes, [true, false, true]);
  });

  test('holds count, and releasing one twice counts once', () {
    need.setRunning(true);
    final first = need.hold('nearby');
    final second = need.hold('nearby');
    final localSend = need.hold('localsend');

    first
      ..release()
      ..release();
    localSend.release();
    expect(need.isNeeded, isTrue, reason: 'the second nearby hold is left');
    expect(need.reasons, ['nearby']);

    second.release();
    expect(need.isNeeded, isFalse);
  });

  test('changes fire only when the answer changes', () async {
    need.setRunning(true);
    final nearby = need.hold('nearby');
    need.setMissing(true);
    final localSend = need.hold('localsend');
    nearby.release();
    localSend.release();
    need.setMissing(false);
    await settle();

    expect(changes, [true, false]);
  });
}
