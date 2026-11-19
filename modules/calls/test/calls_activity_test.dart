import 'package:calls/calls.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late FakeControl control;
  late ActiveCallsViewModel viewModel;

  final l10n = lookupCallsLocalizations(const Locale('en'));

  List<ActivityItem> activity() => callsActivity(l10n, viewModel);

  setUp(() {
    control = FakeControl();
    viewModel = ActiveCallsViewModel(control);
  });

  tearDown(() => viewModel.dispose());

  test('no line while no phone is in a call', () {
    expect(activity(), isEmpty);
  });

  test('a ringing call needs you, names the phone and offers Answer and '
      'Silence', () {
    final startedAt = DateTime(2026, 11, 18, 21, 10);
    control.emit(remoteCall(startedAt: startedAt));

    final line = activity().single;

    expect(line.id, 'calls.phone/call-1');
    expect(line.title, 'Alex is calling Pixel');
    expect(line.detail, '+15550100');
    expect(line.pinned, isTrue);
    expect(line.needsYou, isTrue);
    expect(line.at, startedAt);
    expect(line.tone, FeatureTone.normal);
    expect(line.actions.map((action) => action.label), [
      'Answer',
      'Decline',
      'Silence',
    ]);
    expect(line.actions.map((action) => action.primary), [true, false, false]);
    expect(line.trailing, isNull);
    expect(line.leading, isA<CallerAvatar>());
  });

  test('Silence quiets the phone and then says so', () async {
    control.emit(remoteCall());

    activity().single.actions.last.onPressed();
    await settle();
    final line = activity().single;

    expect(control.silencedCalls, ['call-1']);
    expect(line.detail, '+15550100 · Ringer silenced');
    expect(line.actions.map((action) => action.label), ['Answer', 'Decline']);
  });

  test('a caller without a name shows the number once', () {
    control.emit(remoteCall(name: ''));

    final line = activity().single;

    expect(line.title, '+15550100 is calling Pixel');
    expect(line.detail, isNull);
  });

  test('a hidden number is an unknown caller', () {
    control.emit(remoteCall(name: '', number: ''));

    expect(activity().single.title, 'Unknown caller is calling Pixel');
  });

  test('Answer and Decline go to the phone', () async {
    control.emit(remoteCall());

    activity().single.actions.first.onPressed();
    await settle();
    activity().single.actions[1].onPressed();
    await settle();

    expect(control.answered, ['call-1']);
    expect(control.endedCalls, ['call-1']);
  });

  test('an answered call says who and where, with Hang up', () async {
    control.emit(remoteCall(state: .CALL_STATE_ACTIVE));

    final line = activity().single;
    line.actions.single.onPressed();
    await settle();

    expect(line.title, 'On a call with Alex');
    expect(line.detail, 'Pixel');
    expect(line.pinned, isTrue);
    expect(line.needsYou, isFalse);
    expect(line.actions.single.label, 'Hang up');
    expect(line.actions.single.primary, isFalse);
    expect(line.trailing, isNotNull);
    expect(control.endedCalls, ['call-1']);
  });

  test('initials stand in for a missing photo', () {
    expect(CallerAvatar.initialsOf('Ana Bell'), 'AB');
    expect(CallerAvatar.initialsOf('alex'), 'A');
    expect(CallerAvatar.initialsOf('Ana Maria de la Cruz'), 'AC');
    expect(CallerAvatar.initialsOf('+1 555 0100'), '');
    expect(CallerAvatar.initialsOf(''), '');
  });

  test('an outgoing call and a held one say so', () {
    control
      ..emit(
        remoteCall(
          id: 'out',
          state: .CALL_STATE_DIALING,
          direction: .CALL_DIRECTION_OUTGOING,
          startedAt: DateTime(2026, 11, 18, 21),
        ),
      )
      ..emit(
        remoteCall(
          id: 'held',
          state: .CALL_STATE_HELD,
          startedAt: DateTime(2026, 11, 18, 22),
        ),
      );

    expect(activity().map((line) => line.title), [
      'Calling Alex',
      'On hold with Alex',
    ]);
  });

  test('says why a button did not work, in red', () async {
    control
      ..outcome = .permissionMissing
      ..emit(remoteCall());

    activity().single.actions.first.onPressed();
    await settle();
    final line = activity().single;

    expect(line.detail, l10n.outcomePermission('Pixel'));
    expect(line.tone, FeatureTone.danger);
  });

  test('the line goes away when the call ends', () {
    control
      ..emit(remoteCall())
      ..emit(remoteCall(state: .CALL_STATE_ENDED));

    expect(activity(), isEmpty);
  });
}
