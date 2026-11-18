import 'package:calls/calls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/calls.dart';

void main() {
  late DateTime now;
  late CallTracker tracker;
  var nextId = 0;

  setUp(() {
    now = DateTime(2026, 11, 18, 9);
    nextId = 0;
    tracker = CallTracker(clock: () => now, newId: () => 'call-${++nextId}');
  });

  test('an answered call goes ringing, active, ended', () {
    final ringing = tracker.handle(.ringing, number: '+15550100').single;
    now = now.add(const Duration(seconds: 4));
    final active = tracker.handle(.offHook).single;
    now = now.add(const Duration(minutes: 2));
    final ended = tracker.handle(.idle).single;

    expect(ringing.id, 'call-1');
    expect(ringing.state, CallState.CALL_STATE_RINGING);
    expect(ringing.direction, CallDirection.CALL_DIRECTION_INCOMING);
    expect(ringing.number, '+15550100');
    expect(ringing.connectedAtMs.toInt(), 0);

    expect(active.id, 'call-1');
    expect(active.state, CallState.CALL_STATE_ACTIVE);
    expect(
      active.connectedAtMs.toInt() - active.startedAtMs.toInt(),
      const Duration(seconds: 4).inMilliseconds,
    );

    expect(ended.id, 'call-1');
    expect(ended.state, CallState.CALL_STATE_ENDED);
    expect(ended.outcome, CallOutcome.CALL_OUTCOME_ANSWERED);
    expect(tracker.hasCalls, isFalse);
  });

  test('a call that stops ringing unanswered is missed', () {
    tracker.handle(.ringing, number: '+15550100');

    final ended = tracker.handle(.idle).single;

    expect(ended.state, CallState.CALL_STATE_ENDED);
    expect(ended.outcome, CallOutcome.CALL_OUTCOME_MISSED);
  });

  test('a call declined through Ferret is not missed', () {
    final ringing = tracker.handle(.ringing).single;
    tracker.markDeclined(ringing.id);

    final ended = tracker.handle(.idle).single;

    expect(ended.outcome, CallOutcome.CALL_OUTCOME_DECLINED);
  });

  test('a decline that failed still counts as missed', () {
    final ringing = tracker.handle(.ringing).single;
    tracker
      ..markDeclined(ringing.id)
      ..markDeclined(ringing.id, declined: false);

    expect(
      tracker.handle(.idle).single.outcome,
      CallOutcome.CALL_OUTCOME_MISSED,
    );
  });

  test('the number can arrive after the ring, and repeats change nothing', () {
    final first = tracker.handle(.ringing).single;
    final learned = tracker.handle(.ringing, number: ' +15550100 ').single;
    final repeat = tracker.handle(.ringing, number: '+15550100');

    expect(first.number, isEmpty);
    expect(learned.id, first.id);
    expect(learned.number, '+15550100');
    expect(repeat, isEmpty);
  });

  test('off hook from idle is an outgoing call that stays dialing', () {
    tracker.expectOutgoing('+15550123');

    final dialing = tracker.handle(.offHook).single;
    final ended = tracker.handle(.idle).single;

    expect(dialing.direction, CallDirection.CALL_DIRECTION_OUTGOING);
    expect(dialing.state, CallState.CALL_STATE_DIALING);
    expect(dialing.number, '+15550123');
    expect(ended.outcome, CallOutcome.CALL_OUTCOME_UNSPECIFIED);
  });

  test('a number dialed long ago is not pinned on a later call', () {
    tracker.expectOutgoing('+15550123');
    now = now.add(CallTracker.dialWindow + const Duration(seconds: 1));

    expect(tracker.handle(.offHook).single.number, isEmpty);
  });

  test('a call waiting rings beside the ongoing call', () {
    tracker
      ..handle(.ringing, number: '+15550100')
      ..handle(.offHook);

    final waiting = tracker.handle(.ringing, number: '+15550199').single;
    final stopped = tracker.handle(.offHook).single;
    final ended = tracker.handle(.idle).single;

    expect(waiting.id, 'call-2');
    expect(waiting.state, CallState.CALL_STATE_RINGING);
    expect(tracker.ringing, isNull);
    expect(stopped.id, 'call-2');
    expect(stopped.state, CallState.CALL_STATE_ENDED);
    expect(stopped.outcome, CallOutcome.CALL_OUTCOME_UNSPECIFIED);
    expect(ended.id, 'call-1');
  });

  test('a contact is added once and only to a live call', () {
    final ringing = tracker.handle(.ringing, number: '+15550100').single;

    final named = tracker.setContact(ringing.id, name: 'Alex', photo: [1, 2]);
    final again = tracker.setContact(ringing.id, name: 'Alex');
    final gone = tracker.setContact('other', name: 'Alex');

    expect(named?.contactName, 'Alex');
    expect(named?.photoJpeg, [1, 2]);
    expect(again, isNull);
    expect(gone, isNull);
    expect(tracker.find(ringing.id)?.contactName, 'Alex');
  });

  test('reset ends every call without an outcome', () {
    tracker.handle(.ringing);

    final ended = tracker.reset().single;

    expect(ended.state, CallState.CALL_STATE_ENDED);
    expect(ended.outcome, CallOutcome.CALL_OUTCOME_UNSPECIFIED);
    expect(tracker.calls, isEmpty);
  });

  test('what the tracker hands out can not change its calls', () {
    final ringing = tracker.handle(.ringing, number: '+15550100').single;
    ringing.number = 'changed';

    expect(tracker.find(ringing.id)?.number, '+15550100');
  });
}
