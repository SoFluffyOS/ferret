import 'package:calls/calls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/calls.dart';

import 'support/fakes.dart';

void main() {
  group('active calls', () {
    late FakeControl control;
    late ActiveCallsViewModel viewModel;

    setUp(() {
      control = FakeControl();
      viewModel = ActiveCallsViewModel(control);
    });

    tearDown(() => viewModel.dispose());

    test('lists ringing calls first', () {
      control
        ..emit(
          remoteCall(
            id: 'active',
            state: .CALL_STATE_ACTIVE,
            startedAt: DateTime(2026, 11, 18, 9),
          ),
        )
        ..emit(
          remoteCall(id: 'waiting', startedAt: DateTime(2026, 11, 18, 10)),
        );

      expect(viewModel.calls.map((call) => call.id), ['waiting', 'active']);
    });

    test('keeps the reason a command failed until the call is gone', () async {
      final call = remoteCall();
      control
        ..emit(call)
        ..outcome = .permissionMissing;

      await viewModel.answer(call);
      final whileRinging = viewModel.problemOf(call);
      control.emit(remoteCall(state: .CALL_STATE_ENDED));

      expect(whileRinging, CommandOutcome.permissionMissing);
      expect(viewModel.isBusy(call), isFalse);
      expect(viewModel.problemOf(call), isNull);
    });

    test('remembers that the ringer was silenced', () async {
      final call = remoteCall();
      control.emit(call);

      await viewModel.silence(call);

      expect(control.silencedCalls, ['call-1']);
      expect(viewModel.isSilenced(call), isTrue);
    });
  });

  group('dialer', () {
    late FakeControl control;

    DialerViewModel dialer() => DialerViewModel(
      control: control,
      deviceId: 'phone',
      deviceName: 'Pixel',
    );

    setUp(() => control = FakeControl());

    test('loads the recent calls when it opens', () async {
      control.log = CallLogResult([CallLogEntry(id: '7', name: 'Alex')]);
      final viewModel = dialer();
      await settle();

      expect(viewModel.entries.single.name, 'Alex');
      expect(viewModel.loading, isFalse);
      expect(viewModel.logProblem, isNull);
    });

    test('says why the recent calls are missing, and can retry', () async {
      control.log = const .failed(.permissionMissing);
      final viewModel = dialer();
      await settle();
      final problem = viewModel.logProblem;

      control.log = CallLogResult([CallLogEntry(id: '7')]);
      await viewModel.loadRecent();

      expect(problem, CallLogProblem.permissionMissing);
      expect(viewModel.logProblem, isNull);
      expect(viewModel.entries, hasLength(1));
    });

    test('the recent calls stay readable while the phone is offline', () async {
      final lastLoaded = <String, List<CallLogEntry>>{};
      DialerViewModel open() => DialerViewModel(
        control: control,
        deviceId: 'phone',
        deviceName: 'Pixel',
        lastLoaded: lastLoaded,
      );
      control.log = CallLogResult([CallLogEntry(id: '7', name: 'Alex')]);
      final viewModel = open();
      await settle();

      control.log = const .failed(.unreachable);
      await viewModel.loadRecent();
      final reopened = open();
      await settle();

      expect(viewModel.entries.single.name, 'Alex');
      expect(viewModel.logProblem, isNull);
      expect(reopened.entries.single.name, 'Alex');
      expect(reopened.logProblem, isNull);
    });

    test(
      'a phone that never answered still says it can\'t be reached',
      () async {
        control.log = const .failed(.unreachable);
        final viewModel = dialer();
        await settle();

        expect(viewModel.entries, isEmpty);
        expect(viewModel.logProblem, CallLogProblem.unreachable);
      },
    );

    test('never sends what is not a number', () async {
      final viewModel = dialer();

      await viewModel.call('hello');

      expect(viewModel.outcome, CommandOutcome.invalidNumber);
      expect(control.dialed, isEmpty);
    });

    test('calls and keeps the outcome', () async {
      final viewModel = dialer();

      await viewModel.call('555 0100');

      expect(control.dialed, [('phone', '555 0100')]);
      expect(viewModel.outcome, CommandOutcome.ok);
      expect(viewModel.calling, isFalse);
    });
  });
}
