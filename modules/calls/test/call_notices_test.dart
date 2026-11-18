import 'package:calls/calls.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late FakeControl control;
  late FakeNotifier notifier;
  late CallNotices notices;

  final ringing = remoteCall();
  final ringId = CallNotices.ringingId(ringing);

  setUp(() {
    control = FakeControl();
    notifier = FakeNotifier();
    notices = CallNotices(
      control: control,
      notifier: notifier,
      strings: platformCallsL10n,
    );
  });

  tearDown(() => notices.dispose());

  test('declares Answer and Decline for incoming calls', () {
    final category = CallNotices.categories(platformCallsL10n()).single;

    expect(category.id, 'calls.incoming');
    expect(category.actions.map((action) => action.label), [
      'Answer',
      'Decline',
    ]);
  });

  test('shows a notice with the caller when a phone rings', () async {
    control.emit(ringing);
    await settle();

    final notice = notifier.shown[ringId];
    expect(notice?.title, 'Alex');
    expect(notice?.body, 'Incoming call · Pixel');
    expect(notice?.channel, NoticeChannel.incoming);
    expect(notice?.category, CallNotices.incomingCategory);
    expect(notice?.silent, isFalse);
  });

  test('updates the notice quietly when the name arrives', () async {
    control
      ..emit(remoteCall(name: ''))
      ..emit(ringing);
    await settle();

    expect(notifier.history.map((notice) => notice.title), [
      '+15550100',
      'Alex',
    ]);
    expect(notifier.history.map((notice) => notice.silent), [false, true]);
    expect(notifier.shown, hasLength(1));
  });

  test('takes the notice away when the call is answered', () async {
    control
      ..emit(ringing)
      ..emit(remoteCall(state: .CALL_STATE_ACTIVE));
    await settle();

    expect(notifier.cancelled, [ringId]);
    expect(notifier.shown, isEmpty);
  });

  test(
    'takes the notice away when the call ends, with no missed call',
    () async {
      control
        ..emit(ringing)
        ..emit(
          remoteCall(
            state: .CALL_STATE_ENDED,
            outcome: .CALL_OUTCOME_DECLINED,
          ),
        );
      await settle();

      expect(notifier.cancelled, [ringId]);
      expect(notifier.shown, isEmpty);
    },
  );

  test('leaves one quiet "Missed call" when nobody picked up', () async {
    control
      ..emit(ringing)
      ..emit(
        remoteCall(state: .CALL_STATE_ENDED, outcome: .CALL_OUTCOME_MISSED),
      );
    await settle();

    final missed = notifier.shown[CallNotices.missedId('phone')];
    expect(notifier.cancelled, [ringId]);
    expect(notifier.shown, hasLength(1));
    expect(missed?.title, 'Missed call');
    expect(missed?.body, 'Alex · Pixel');
    expect(missed?.silent, isTrue);
    expect(missed?.category, isNull);
  });

  test('shows nothing for outgoing calls or with notices off', () async {
    control.emit(
      remoteCall(
        id: 'out',
        state: .CALL_STATE_DIALING,
        direction: .CALL_DIRECTION_OUTGOING,
      ),
    );
    control
      ..showIncoming = false
      ..emit(ringing)
      ..emit(
        remoteCall(state: .CALL_STATE_ENDED, outcome: .CALL_OUTCOME_MISSED),
      );
    await settle();

    expect(notifier.history, isEmpty);
    expect(notifier.cancelled, isEmpty);
  });

  test('Answer and Decline on the notice go to the phone', () async {
    control.emit(ringing);

    notifier
      ..respond(ringId, CallNotices.answerAction)
      ..respond(ringId, CallNotices.declineAction)
      ..respond(ringId)
      ..respond('clipboard.result', CallNotices.answerAction);
    await settle();

    expect(control.answered, ['call-1']);
    expect(control.endedCalls, ['call-1']);
  });

  test('says why when answering did not work', () async {
    control
      ..outcome = .permissionMissing
      ..emit(ringing);

    notifier.respond(ringId, CallNotices.answerAction);
    await settle();

    final problem = notifier.shown[CallNotices.problemId('phone')];
    expect(problem?.channel, NoticeChannel.problems);
    expect(problem?.body, contains("Pixel hasn't allowed this yet"));
  });
}
