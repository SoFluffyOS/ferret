import 'dart:async';

import 'package:ferret/wiring/wiring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StreamController<bool> calls;
  late bool inCall;
  late bool enabled;
  late List<String> playing;
  late List<List<String>> resumed;
  late int pauses;
  late CallMediaPause wiring;

  CallMediaPause start() => CallMediaPause(
    inCallChanges: calls.stream,
    inCall: () => inCall,
    enabled: () => enabled,
    pause: () async {
      pauses++;
      final paused = [...playing];
      playing.clear();
      return paused;
    },
    resume: (playerIds) async => resumed.add(playerIds),
  )..start();

  Future<void> callChanges(bool value) async {
    inCall = value;
    calls.add(value);
    await pumpEventQueue();
    await wiring.settled;
  }

  setUp(() {
    calls = StreamController<bool>.broadcast();
    inCall = false;
    enabled = true;
    playing = ['spotify'];
    resumed = [];
    pauses = 0;
  });

  tearDown(() async {
    await wiring.dispose();
    await calls.close();
  });

  test('pauses when a call starts and resumes what it paused after', () async {
    wiring = start();

    await callChanges(true);
    expect(pauses, 1);
    expect(resumed, isEmpty);

    await callChanges(false);
    expect(resumed, [
      ['spotify'],
    ]);
  });

  test('resumes nothing when nothing was playing', () async {
    playing = [];
    wiring = start();

    await callChanges(true);
    await callChanges(false);

    expect(pauses, 1);
    expect(resumed, isEmpty);
  });

  test('does nothing when the setting is off', () async {
    enabled = false;
    wiring = start();

    await callChanges(true);
    await callChanges(false);

    expect(pauses, 0);
    expect(resumed, isEmpty);
  });

  test('pauses right away when started during a call', () async {
    inCall = true;
    wiring = start();
    await wiring.settled;

    expect(pauses, 1);
  });

  test('a second call signal does not pause twice', () async {
    wiring = start();

    await callChanges(true);
    await callChanges(true);
    await callChanges(false);

    expect(pauses, 1);
    expect(resumed, hasLength(1));
  });
}
