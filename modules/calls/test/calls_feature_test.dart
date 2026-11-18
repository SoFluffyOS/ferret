import 'package:calls/calls.dart';
import 'package:ferret_calls/ferret_calls.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/calls.dart';

import 'support/fakes.dart';

void main() {
  group('on the phone', () {
    late FakePhone phone;
    late FakeHost host;
    late FakeSession laptop;
    late CallsFeature feature;

    Future<void> start({bool enabled = true}) async {
      host = FakeHost(settings: {CallsSettings.enabledKey: enabled})
        ..sessions = [laptop];
      feature = CallsFeature(phone: phone);
      await feature.start(host);
      await settle();
    }

    Future<CallCommandStatus> command(CallCommand command) async {
      final reply = await feature.onEnvelope(
        laptop,
        envelopeOf(command, expectsReply: true),
      );
      return (reply as CallCommandResult).status;
    }

    setUp(() {
      phone = FakePhone();
      laptop = FakeSession('laptop');
    });

    tearDown(() => feature.stop());

    test('offers the phone flag, and computers the view flag', () async {
      await start();

      expect(feature.flags, [CallsFeature.phoneFlag]);
      expect(CallsFeature().flags, [CallsFeature.viewFlag]);
    });

    test('pushes a call from ringing to active to ended', () async {
      await start();

      phone.ring('+15550100');
      await settle();
      phone.offHook();
      await settle();
      phone.idle();
      await settle();

      final states = [for (final call in laptop.calls) call.state];
      expect(states.first, CallState.CALL_STATE_RINGING);
      expect(states, contains(CallState.CALL_STATE_ACTIVE));
      expect(states.last, CallState.CALL_STATE_ENDED);
      expect(laptop.calls.map((call) => call.id).toSet(), hasLength(1));
      expect(laptop.calls.last.outcome, CallOutcome.CALL_OUTCOME_ANSWERED);
      expect(feature.inCall, isFalse);
    });

    test('adds the contact name and photo once it is found', () async {
      phone.contact = alex();
      await start();

      phone.ring('+15550100');
      await settle();

      expect(phone.lookedUp, ['+15550100']);
      expect(laptop.calls.first.contactName, isEmpty);
      expect(laptop.calls.last.contactName, 'Alex');
      expect(laptop.calls.last.photoJpeg, [1, 2, 3]);
    });

    test('does not look contacts up without the permission', () async {
      phone
        ..contact = alex()
        ..granted = (allPermissions()..contacts = false);
      await start();

      phone.ring('+15550100');
      await settle();

      expect(phone.lookedUp, isEmpty);
      expect(laptop.calls.single.contactName, isEmpty);
    });

    test('sends calls only to devices that show them', () async {
      final otherPhone = FakeSession('tablet', flags: [CallsFeature.phoneFlag]);
      await start();
      host.sessions = [laptop, otherPhone];

      phone.ring();
      await settle();

      expect(laptop.calls, hasLength(1));
      expect(otherPhone.sent, isEmpty);
    });

    test('watches nothing while calls are off', () async {
      await start(enabled: false);

      phone.ring('+15550100');
      await settle();

      expect(phone.monitoring, isFalse);
      expect(laptop.calls, isEmpty);
      expect(feature.localStatus.enabled, isFalse);
    });

    test('watches nothing without the phone permission', () async {
      phone.granted = noPermissions();
      await start();

      expect(phone.monitoring, isFalse);
      expect(feature.isMonitoring, isFalse);
      expect(feature.localStatus.canSeeCalls, isFalse);
    });

    test('turning calls on starts watching and tells computers', () async {
      await start(enabled: false);
      laptop.sent.clear();

      await feature.settings.setEnabled(true);
      await settle();

      expect(phone.monitoring, isTrue);
      expect(laptop.statuses.single.enabled, isTrue);
      expect(laptop.statuses.single.canAnswer, isTrue);
    });

    test('turning calls off ends the call computers were shown', () async {
      await start();
      phone.ring();
      await settle();

      await feature.settings.setEnabled(false);
      await settle();

      expect(phone.monitoring, isFalse);
      expect(laptop.calls.last.state, CallState.CALL_STATE_ENDED);
      expect(laptop.statuses.last.enabled, isFalse);
    });

    test('a newly granted permission is picked up on refresh', () async {
      phone.granted = noPermissions();
      await start();

      phone.granted = allPermissions();
      await feature.refreshPermissions();
      await settle();

      expect(feature.isMonitoring, isTrue);
      expect(laptop.statuses.last.canSeeCalls, isTrue);
    });

    test(
      'a device that connects mid-call gets the call, not old ones',
      () async {
        await start();
        phone
          ..ring('+15550111')
          ..idle()
          ..ring('+15550100');
        await settle();
        final desktop = FakeSession('desktop');

        feature.onSessionOpened(desktop);
        await settle();

        expect(desktop.statuses.single.enabled, isTrue);
        expect(desktop.calls.single.number, '+15550100');
        expect(desktop.calls.single.state, CallState.CALL_STATE_RINGING);
      },
    );

    test('answer goes to the ringing call only', () async {
      await start();
      phone.ring();
      await settle();
      final callId = laptop.calls.single.id;

      final wrong = await command(
        CallCommand(action: .CALL_ACTION_ANSWER, callId: 'other'),
      );
      final right = await command(
        CallCommand(action: .CALL_ACTION_ANSWER, callId: callId),
      );

      expect(wrong, CallCommandStatus.CALL_COMMAND_STATUS_NO_CALL);
      expect(right, CallCommandStatus.CALL_COMMAND_STATUS_OK);
      expect(phone.answered, 1);
    });

    test('declining through Ferret ends the call as declined', () async {
      await start();
      phone.ring();
      await settle();

      final status = await command(
        CallCommand(action: .CALL_ACTION_END, callId: laptop.calls.single.id),
      );
      phone.idle();
      await settle();

      expect(status, CallCommandStatus.CALL_COMMAND_STATUS_OK);
      expect(phone.ended, 1);
      expect(laptop.calls.last.outcome, CallOutcome.CALL_OUTCOME_DECLINED);
    });

    test('hanging up needs a call, and silence a ringing one', () async {
      await start();

      final nothing = await command(
        CallCommand(action: .CALL_ACTION_END, callId: 'gone'),
      );
      phone
        ..ring()
        ..offHook();
      await settle();
      final callId = laptop.calls.last.id;
      final silence = await command(
        CallCommand(action: .CALL_ACTION_SILENCE, callId: callId),
      );
      final hangUp = await command(
        CallCommand(action: .CALL_ACTION_END, callId: callId),
      );

      expect(nothing, CallCommandStatus.CALL_COMMAND_STATUS_NO_CALL);
      expect(silence, CallCommandStatus.CALL_COMMAND_STATUS_NO_CALL);
      expect(hangUp, CallCommandStatus.CALL_COMMAND_STATUS_OK);
      expect(phone.silenced, 0);
      expect(phone.ended, 1);
    });

    test('silence stops the ringer of the ringing call', () async {
      await start();
      phone.ring();
      await settle();

      final status = await command(
        CallCommand(
          action: .CALL_ACTION_SILENCE,
          callId: laptop.calls.single.id,
        ),
      );

      expect(status, CallCommandStatus.CALL_COMMAND_STATUS_OK);
      expect(phone.silenced, 1);
    });

    test('dial cleans the number and names the outgoing call', () async {
      await start();

      final status = await command(
        CallCommand(action: .CALL_ACTION_DIAL, number: '+1 (555) 0100'),
      );
      phone.offHook();
      await settle();

      expect(status, CallCommandStatus.CALL_COMMAND_STATUS_OK);
      expect(phone.dialed, ['+15550100']);
      expect(laptop.calls.single.number, '+15550100');
      expect(laptop.calls.single.state, CallState.CALL_STATE_DIALING);
      expect(
        laptop.calls.single.direction,
        CallDirection.CALL_DIRECTION_OUTGOING,
      );
    });

    test('dial refuses what is not a number', () async {
      await start();

      final status = await command(
        CallCommand(action: .CALL_ACTION_DIAL, number: 'mom'),
      );

      expect(status, CallCommandStatus.CALL_COMMAND_STATUS_INVALID_NUMBER);
      expect(phone.dialed, isEmpty);
    });

    test('commands say why the phone could not do it', () async {
      await start();
      phone
        ..result = .permissionMissing
        ..ring();
      await settle();

      final status = await command(
        CallCommand(
          action: .CALL_ACTION_ANSWER,
          callId: laptop.calls.single.id,
        ),
      );

      expect(status, CallCommandStatus.CALL_COMMAND_STATUS_PERMISSION_MISSING);
    });

    test('commands are refused while calls are off', () async {
      await start(enabled: false);

      final status = await command(
        CallCommand(action: .CALL_ACTION_DIAL, number: '5550100'),
      );

      expect(status, CallCommandStatus.CALL_COMMAND_STATUS_DISABLED);
      expect(phone.dialed, isEmpty);
    });

    test('maps the call log, newest first and capped', () async {
      phone.log = [
        platformLogEntry(id: '9', durationSeconds: 0),
        platformLogEntry(
          id: '8',
          name: '',
          type: .outgoing,
          dateMs: 1794999000000,
          durationSeconds: 61,
        ),
        platformLogEntry(id: '7', type: .rejected),
        platformLogEntry(id: '6', type: .incoming),
      ];
      await start();

      final reply = await feature.onEnvelope(
        laptop,
        envelopeOf(GetCallLog(limit: 3), expectsReply: true),
      );
      final log = reply as CallLog;

      expect(phone.askedLogLimit, 3);
      expect(log.entries.map((entry) => entry.id), ['9', '8', '7']);
      expect(log.entries[0].type, CallLogType.CALL_LOG_TYPE_MISSED);
      expect(log.entries[0].name, 'Alex');
      expect(log.entries[1].type, CallLogType.CALL_LOG_TYPE_OUTGOING);
      expect(log.entries[1].name, isEmpty);
      expect(log.entries[1].dateMs, Int64(1794999000000));
      expect(log.entries[1].durationS, Int64(61));
      expect(log.entries[2].type, CallLogType.CALL_LOG_TYPE_REJECTED);
    });

    test('the call log asks for 50 by default and never over 200', () async {
      await start();

      await feature.onEnvelope(laptop, envelopeOf(GetCallLog()));
      final byDefault = phone.askedLogLimit;
      await feature.onEnvelope(laptop, envelopeOf(GetCallLog(limit: 5000)));

      expect(byDefault, 50);
      expect(phone.askedLogLimit, 200);
    });

    test('the call log says when it may not be read', () async {
      phone.granted = (allPermissions()..callLog = false);
      await start();

      final missing = await feature.onEnvelope(
        laptop,
        envelopeOf(GetCallLog()),
      );
      await feature.settings.setEnabled(false);
      final disabled = await feature.onEnvelope(
        laptop,
        envelopeOf(GetCallLog()),
      );

      expect((missing as CallLog).permissionMissing, isTrue);
      expect((disabled as CallLog).disabled, isTrue);
      expect(phone.askedLogLimit, isNull);
    });

    test('reports what it can do when asked', () async {
      phone.granted = (allPermissions()
        ..answerCalls = false
        ..callLog = false);
      await start();

      final reply = await feature.onEnvelope(
        laptop,
        envelopeOf(GetCallsStatus(), expectsReply: true),
      );
      final status = reply as CallsStatus;

      expect(status.enabled, isTrue);
      expect(status.canSeeCalls, isTrue);
      expect(status.canSeeNumbers, isFalse);
      expect(status.canAnswer, isFalse);
      expect(status.canDial, isTrue);
      expect(status.canReadLog, isFalse);
    });

    test('remembers when an update did not reach a device', () async {
      await start();
      laptop.failSends = true;

      phone.ring();
      await settle();
      final failed = feature.pushFailedTo('laptop');
      laptop.failSends = false;
      phone.idle();
      await settle();

      expect(failed, isTrue);
      expect(feature.pushFailedTo('laptop'), isFalse);
    });

    test('says when a call starts and stops, for pausing media', () async {
      await start();
      final activity = <bool>[];
      final subscription = feature.inCallChanges.listen(activity.add);

      phone.ring();
      await settle();
      phone.offHook();
      await settle();
      phone.idle();
      await settle();

      expect(activity, [true, false]);
      await subscription.cancel();
    });
  });

  group('on a computer', () {
    late FakeHost host;
    late FakeSession pixel;
    late CallsFeature feature;
    late List<RemoteCall> events;
    late DateTime now;

    CallUpdate update(
      CallState state, {
      String id = 'call-1',
      CallOutcome outcome = .CALL_OUTCOME_UNSPECIFIED,
      int startedAtMs = 0,
      int connectedAtMs = 0,
      int sentAtMs = 0,
    }) => CallUpdate(
      call: Call(
        id: id,
        number: '+15550100',
        direction: .CALL_DIRECTION_INCOMING,
        state: state,
        outcome: outcome,
        startedAtMs: Int64(startedAtMs),
        connectedAtMs: Int64(connectedAtMs),
      ),
      sentAtMs: Int64(sentAtMs),
    );

    setUp(() async {
      now = DateTime(2026, 11, 18, 9);
      pixel = FakeSession(
        'phone',
        name: 'Pixel',
        flags: [CallsFeature.phoneFlag],
      );
      host = FakeHost()..sessions = [pixel];
      feature = CallsFeature(clock: () => now);
      await feature.start(host);
      events = [];
      feature.callEvents.listen(events.add);
    });

    tearDown(() => feature.stop());

    test('shows a call while it lasts', () async {
      await feature.onEnvelope(
        pixel,
        envelopeOf(update(.CALL_STATE_RINGING)),
      );
      final whileRinging = feature.remoteCalls;
      await feature.onEnvelope(pixel, envelopeOf(update(.CALL_STATE_ACTIVE)));
      await feature.onEnvelope(
        pixel,
        envelopeOf(
          update(.CALL_STATE_ENDED, outcome: .CALL_OUTCOME_ANSWERED),
        ),
      );

      expect(whileRinging.single.deviceName, 'Pixel');
      expect(whileRinging.single.isRinging, isTrue);
      expect(feature.remoteCalls, isEmpty);
      expect(events.map((call) => call.call.state), [
        CallState.CALL_STATE_RINGING,
        CallState.CALL_STATE_ACTIVE,
        CallState.CALL_STATE_ENDED,
      ]);
      expect(feature.inCall, isFalse);
    });

    test('never shows a call it only hears the end of', () async {
      await feature.onEnvelope(pixel, envelopeOf(update(.CALL_STATE_ENDED)));

      expect(events, isEmpty);
      expect(feature.remoteCalls, isEmpty);
    });

    test('times the call in its own clock', () async {
      final phoneClock = now.subtract(const Duration(hours: 3));
      final connected = phoneClock.subtract(const Duration(seconds: 42));

      await feature.onEnvelope(
        pixel,
        envelopeOf(
          update(
            .CALL_STATE_ACTIVE,
            startedAtMs: connected.millisecondsSinceEpoch - 5000,
            connectedAtMs: connected.millisecondsSinceEpoch,
            sentAtMs: phoneClock.millisecondsSinceEpoch,
          ),
        ),
      );

      final call = feature.remoteCalls.single;
      expect(now.difference(call.timerStart), const Duration(seconds: 42));
      expect(now.difference(call.startedAt), const Duration(seconds: 47));
    });

    test('a phone that disconnects takes its calls with it', () async {
      await feature.onEnvelope(
        pixel,
        envelopeOf(update(.CALL_STATE_RINGING)),
      );

      feature.onSessionClosed(pixel);

      expect(feature.remoteCalls, isEmpty);
      expect(events.last.isEnded, isTrue);
      expect(events.last.wasMissed, isFalse);
    });

    test('keeps what the phone says it can do', () async {
      await feature.onEnvelope(
        pixel,
        envelopeOf(CallsStatus(enabled: true, canSeeCalls: true)),
      );

      final link = feature.linkOf('phone');
      expect(link?.status?.canSeeCalls, isTrue);
      expect(link?.failed, isFalse);
      expect(link?.lastRoundTrip, now);
    });

    test(
      'refuses to dial what is not a number, or a phone that left',
      () async {
        final invalid = await feature.dial('phone', 'not a number');
        final gone = await feature.dial('other', '5550100');
        final log = await feature.fetchCallLog('other');

        expect(invalid, CommandOutcome.invalidNumber);
        expect(gone, CommandOutcome.unreachable);
        expect(log.problem, CallLogProblem.unreachable);
      },
    );

    test('ignores commands meant for a phone', () async {
      final reply = await feature.onEnvelope(
        pixel,
        envelopeOf(CallCommand(action: .CALL_ACTION_DIAL, number: '5550100')),
      );

      expect(
        (reply as CallCommandResult).status,
        CallCommandStatus.CALL_COMMAND_STATUS_UNSUPPORTED,
      );
    });
  });

  test('maps what the platform says about a command', () {
    expect(
      CallCodec.commandStatus(PlatformCallResult.unsupported),
      CallCommandStatus.CALL_COMMAND_STATUS_UNSUPPORTED,
    );
    expect(
      CommandOutcome.fromStatus(.CALL_COMMAND_STATUS_PERMISSION_MISSING),
      CommandOutcome.permissionMissing,
    );
    expect(
      CommandOutcome.fromStatus(.CALL_COMMAND_STATUS_UNSPECIFIED),
      CommandOutcome.failed,
    );
  });
}
