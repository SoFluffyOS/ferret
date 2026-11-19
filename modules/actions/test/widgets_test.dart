import 'dart:async';

import 'package:actions/actions.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/actions.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

void main() {
  final askedAt = DateTime(2026, 11, 19, 9);

  group('ActionConsentDialog', () {
    testWidgets('asks by name, for what it does', (tester) async {
      ActionChoice? answered;
      await tester.pumpWidget(
        testApp(
          ActionConsentDialog(
            ask: ActionAsk(
              deviceId: 'pixel',
              deviceName: 'Pixel 7',
              action: const OfferedAction(
                id: ActionIds.restart,
                kind: .ACTION_KIND_RESTART,
              ),
              askedAt: askedAt,
            ),
            computer: .mac,
            onAnswer: (choice) => answered = choice,
          ),
          scroll: false,
        ),
      );

      expect(find.text('Let Pixel 7 restart this Mac?'), findsOneWidget);
      expect(
        find.text('You get 10 seconds to cancel before it happens.'),
        findsOneWidget,
      );
      expect(find.byType(CommandBlock), findsNothing);

      await tester.tap(find.text('Always allow'));
      expect(answered, ActionChoice.always);
    });

    testWidgets('shows a custom action\'s command word for word', (
      tester,
    ) async {
      ActionChoice? answered;
      await tester.pumpWidget(
        testApp(
          ActionConsentDialog(
            ask: ActionAsk(
              deviceId: 'pixel',
              deviceName: 'Pixel 7',
              action: const OfferedAction(
                id: 'custom.1',
                kind: .ACTION_KIND_CUSTOM,
                title: 'Backup',
                commandLine: '~/bin/backup.sh --quick "My Disk"',
              ),
              askedAt: askedAt,
            ),
            computer: .windows,
            onAnswer: (choice) => answered = choice,
          ),
          scroll: false,
        ),
      );

      expect(
        find.text('Let Pixel 7 run “Backup” on this PC?'),
        findsOneWidget,
      );
      expect(find.text('It runs exactly this:'), findsOneWidget);
      expect(find.text('~/bin/backup.sh --quick "My Disk"'), findsOneWidget);

      await tester.tap(find.text("Don't allow"));
      expect(answered, ActionChoice.deny);
    });
  });

  group('CountdownDialog', () {
    testWidgets('counts the seconds down and cancels', (tester) async {
      var now = askedAt;
      var cancelled = 0;
      await tester.pumpWidget(
        testApp(
          CountdownDialog(
            countdown: ActionCountdown(
              deviceId: 'pixel',
              deviceName: 'Pixel 7',
              action: const OfferedAction(
                id: ActionIds.shutDown,
                kind: .ACTION_KIND_SHUT_DOWN,
              ),
              startedAt: askedAt,
              endsAt: askedAt.add(const Duration(seconds: 10)),
            ),
            computer: .mac,
            clock: () => now,
            onCancel: () => cancelled++,
          ),
          scroll: false,
        ),
      );

      expect(find.text('Shutting down this Mac in 10 seconds'), findsOneWidget);
      expect(
        find.text('Pixel 7 asked for it. Save your work, or cancel.'),
        findsOneWidget,
      );

      now = askedAt.add(const Duration(seconds: 9));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Shutting down this Mac in 1 second'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      expect(cancelled, 1);
    });
  });

  group('DeviceActionsFrame', () {
    late FakeHost host;
    late FakeSession mac;
    late ActionsFeature feature;
    late ActionsViewModel viewModel;

    final everyAction = [
      Action(id: ActionIds.sleep, kind: .ACTION_KIND_SLEEP),
      Action(
        id: ActionIds.restart,
        kind: .ACTION_KIND_RESTART,
        confirm: true,
      ),
      Action(
        id: ActionIds.shutDown,
        kind: .ACTION_KIND_SHUT_DOWN,
        confirm: true,
      ),
      Action(id: ActionIds.mute, kind: .ACTION_KIND_MUTE),
      Action(id: ActionIds.volumeUp, kind: .ACTION_KIND_VOLUME_UP),
      Action(id: ActionIds.volumeDown, kind: .ACTION_KIND_VOLUME_DOWN),
      Action(id: 'custom.1', kind: .ACTION_KIND_CUSTOM, title: 'Good night'),
    ];

    Future<void> setUpPhone(
      WidgetTester tester, {
      List<Action>? actions,
    }) async {
      await tester.runAsync(() async {
        host = await FakeHost.create();
        mac = FakeSession(
          'mac',
          name: 'MacBook Air',
          flags: const [ActionsFeature.runFlag],
          platform: .PLATFORM_MACOS,
          answer: (_) => RunActionReply(result: .RUN_RESULT_DONE),
        );
        host.sessions = [mac];
        feature = ActionsFeature(offersActions: false);
        await feature.start(host);
        await feature.onEnvelope(
          mac,
          envelopeOf(
            ActionList(actions: actions ?? everyAction),
          ),
        );
      });
      viewModel = ActionsViewModel(feature);
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: viewModel,
            child: const DeviceActionsFrame(
              deviceId: 'mac',
              deviceName: 'MacBook Air',
              computer: .mac,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists the computer\'s actions under Power and sound', (
      tester,
    ) async {
      await setUpPhone(tester);

      expect(find.text('Power and sound'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('Restart…'), findsOneWidget);
      expect(find.text('Shut down…'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Your actions'), findsOneWidget);
      expect(find.text('Good night'), findsOneWidget);
      expect(
        find.text('The first time, MacBook Air asks on its own screen.'),
        findsOneWidget,
      );
    });

    testWidgets('Sleep goes out right away', (tester) async {
      await setUpPhone(tester);

      await tester.tap(find.text('Sleep'));
      await tester.runAsync(settle);

      expect((mac.requests.single as RunAction).id, ActionIds.sleep);
    });

    testWidgets('Restart asks "are you sure" first', (tester) async {
      await setUpPhone(tester);

      await tester.tap(find.text('Restart…'));
      await tester.pumpAndSettle();

      expect(find.text('Restart MacBook Air?'), findsOneWidget);
      expect(mac.requests, isEmpty);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.runAsync(settle);
      expect(mac.requests, isEmpty);

      await tester.tap(find.text('Restart…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restart'));
      await tester.pumpAndSettle();
      await tester.runAsync(settle);

      expect((mac.requests.single as RunAction).id, ActionIds.restart);
    });

    testWidgets('Shut down says it can not be reached afterwards', (
      tester,
    ) async {
      await setUpPhone(tester);

      await tester.tap(find.text('Shut down…'));
      await tester.pumpAndSettle();

      expect(find.text('Shut down MacBook Air?'), findsOneWidget);
      expect(
        find.textContaining("Ferret can't reach it until someone turns it on"),
        findsOneWidget,
      );
    });

    testWidgets('volume buttons send their own ids and leave no line', (
      tester,
    ) async {
      await setUpPhone(tester);

      await tester.tap(find.byKey(const ValueKey(ActionIds.volumeUp)));
      await tester.runAsync(settle);
      await tester.tap(find.byKey(const ValueKey(ActionIds.mute)));
      await tester.runAsync(settle);

      expect(
        [for (final request in mac.requests) (request as RunAction).id],
        [
          ActionIds.volumeUp,
          ActionIds.mute,
        ],
      );
      expect(viewModel.outgoing, isEmpty);
    });

    testWidgets('own actions alone come without the Power and sound title', (
      tester,
    ) async {
      await setUpPhone(
        tester,
        actions: [
          Action(id: 'custom.1', kind: .ACTION_KIND_CUSTOM, title: 'Say hi'),
        ],
      );

      expect(find.text('Power and sound'), findsNothing);
      expect(find.text('Volume'), findsNothing);
      expect(find.text('Your actions'), findsOneWidget);
      expect(find.text('Say hi'), findsOneWidget);
    });

    testWidgets('a device without actions shows nothing', (tester) async {
      await setUpPhone(tester);
      feature.onSessionClosed(mac);
      await tester.runAsync(settle);
      await tester.pumpAndSettle();

      expect(find.text('Power and sound'), findsNothing);
    });
  });

  group('ActionsSettingsFrame', () {
    late FakeHost host;
    late ActionsFeature feature;
    late ActionsViewModel viewModel;

    Future<void> setUpComputer(WidgetTester tester) async {
      await tester.runAsync(() async {
        host = await FakeHost.create();
        feature = ActionsFeature(
          computer: FakeComputer(),
          runner: FakeRunner(),
          offersActions: true,
        );
        await feature.start(host);
      });
      viewModel = ActionsViewModel(feature);
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: viewModel,
            child: const ActionsSettingsFrame(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('adds an action with a name and a command', (tester) async {
      await setUpComputer(tester);
      expect(find.textContaining('only ever see the name'), findsOneWidget);

      await tester.tap(find.text('Add action'));
      await tester.pumpAndSettle();
      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), 'Good night');
      await tester.enterText(fields.at(1), 'shortcuts run "Good night"');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.runAsync(settle);
      await tester.pumpAndSettle();

      final saved = feature.settings.custom.single;
      expect(saved.name, 'Good night');
      expect(saved.commandLine, 'shortcuts run "Good night"');
      expect(find.text('Good night'), findsOneWidget);
      expect(find.text('shortcuts run "Good night"'), findsOneWidget);
    });

    testWidgets('Save waits for both fields', (tester) async {
      await setUpComputer(tester);

      await tester.tap(find.text('Add action'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(0), 'Only a name');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.runAsync(settle);

      expect(feature.settings.custom, isEmpty);
    });

    testWidgets('edits and removes an action', (tester) async {
      await setUpComputer(tester);
      await tester.runAsync(
        () async => feature.actionsHost?.addCustom(
          name: 'Backup',
          commandLine: '~/bin/backup.sh',
        ),
      );
      await tester.runAsync(settle);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(1), '~/bin/other.sh');
      await tester.pumpAndSettle();
      expect(
        find.text('A new command asks every device again.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Remove'));
      await tester.runAsync(settle);
      await tester.pumpAndSettle();

      expect(feature.settings.custom, isEmpty);
    });

    testWidgets('the switch turns actions off', (tester) async {
      await setUpComputer(tester);

      await tester.tap(find.byType(SwitchToggle));
      await tester.pumpAndSettle();
      await tester.runAsync(settle);

      expect(feature.settings.enabled, isFalse);
    });
  });

  group('activity', () {
    final l10n = lookupActionsLocalizations(const Locale('en'));

    test('a run on this computer names the action, the device and the '
        'last line it printed', () {
      final lines = recordActivity(
        l10n,
        [
          ActionRecord(
            deviceId: 'pixel',
            deviceName: 'Pixel 7',
            actionId: 'custom.1',
            kind: .ACTION_KIND_CUSTOM,
            title: 'Backup',
            at: askedAt,
            result: .RUN_RESULT_DONE,
            exitCode: 0,
            output: '3 files copied',
          ),
          ActionRecord(
            deviceId: 'pixel',
            deviceName: 'Pixel 7',
            actionId: 'custom.1',
            kind: .ACTION_KIND_CUSTOM,
            title: 'Backup',
            at: askedAt,
            result: .RUN_RESULT_TIMED_OUT,
          ),
          ActionRecord(
            deviceId: 'pixel',
            deviceName: 'Pixel 7',
            actionId: ActionIds.restart,
            kind: .ACTION_KIND_RESTART,
            at: askedAt,
            result: .RUN_RESULT_CANCELLED,
          ),
        ],
        commandSeconds: 30,
        onDismiss: (_) {},
      );

      expect(lines[0].title, 'Backup, asked by Pixel 7');
      expect(lines[0].detail, '3 files copied');
      expect(lines[0].tone, FeatureTone.success);
      expect(lines[1].detail, 'Stopped: it ran longer than 30 seconds.');
      expect(lines[2].title, 'Restart, asked by Pixel 7');
      expect(lines[2].detail, 'Cancelled here.');
    });

    test('a request is pinned while the computer answers, then says how '
        'it went', () {
      final restart = Action(
        id: ActionIds.restart,
        kind: .ACTION_KIND_RESTART,
        confirm: true,
      );
      final lines = outgoingActivity(
        l10n,
        [
          OutgoingAction(
            deviceId: 'mac',
            deviceName: 'MacBook Air',
            action: restart,
            at: askedAt,
          ),
          OutgoingAction(
            deviceId: 'mac',
            deviceName: 'MacBook Air',
            action: restart,
            at: askedAt,
            result: .RUN_RESULT_DONE,
          ),
          OutgoingAction(
            deviceId: 'mac',
            deviceName: 'MacBook Air',
            action: restart,
            at: askedAt,
            result: .RUN_RESULT_TURNED_OFF,
          ),
        ],
        onDismiss: (_) {},
      );

      expect(lines[0].pinned, isTrue);
      expect(lines[0].title, 'Asking MacBook Air: Restart…');
      expect(lines[1].title, 'MacBook Air is restarting');
      expect(lines[2].title, 'Actions are off on MacBook Air');
      expect(lines[2].detail, 'Turn them on there: Settings → Control.');
    });
  });

  group('ActionPrompter', () {
    testWidgets('shows the question, then the countdown, then nothing', (
      tester,
    ) async {
      late ActionsFeature feature;
      late FakeSession pixel;
      await tester.runAsync(() async {
        final host = await FakeHost.create();
        pixel = FakeSession('pixel');
        host.sessions = [pixel];
        feature = ActionsFeature(
          computer: FakeComputer(),
          runner: FakeRunner(),
          offersActions: true,
          countdownLength: const Duration(seconds: 10),
        );
        await feature.start(host);
      });
      final viewModel = ActionsViewModel(feature);
      addTearDown(viewModel.dispose);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        testApp(const SizedBox.shrink(), navigatorKey: navigatorKey),
      );
      final prompter = ActionPrompter(
        viewModel: viewModel,
        navigatorKey: navigatorKey,
      )..start();
      addTearDown(prompter.dispose);

      RunActionReply? reply;
      await tester.runAsync(() async {
        unawaited(
          feature.actionsHost
              ?.onRun(pixel, RunAction(id: ActionIds.restart))
              .then((answered) => reply = answered),
        );
        await settle();
      });
      await tester.pumpAndSettle();
      expect(find.byType(ActionConsentDialog), findsOneWidget);

      await tester.tap(find.text('Allow once'));
      await tester.runAsync(settle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ActionConsentDialog), findsNothing);
      expect(find.byType(CountdownDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.runAsync(settle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CountdownDialog), findsNothing);
      expect(reply?.result, RunResult.RUN_RESULT_CANCELLED);
    });
  });

  group('lock when a phone leaves', () {
    testWidgets('the countdown names the phone and cancels', (tester) async {
      var cancelled = false;
      final startedAt = DateTime(2026, 11, 19, 9);
      await tester.pumpWidget(
        testApp(
          LeaveCountdownDialog(
            countdown: LeaveCountdown(
              deviceId: 'pixel',
              deviceName: 'Pixel 7',
              startedAt: startedAt,
              endsAt: startedAt.add(const Duration(seconds: 10)),
            ),
            computer: .mac,
            clock: () => startedAt,
            onCancel: () => cancelled = true,
          ),
          scroll: false,
        ),
      );

      expect(find.text('Locking this Mac in 10 seconds'), findsOneWidget);
      expect(
        find.text("Pixel 7 left. Cancel if you're still here."),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      expect(cancelled, isTrue);
    });

    testWidgets('Settings has a switch per Android phone and the minutes', (
      tester,
    ) async {
      late FakeHost host;
      late ActionsFeature feature;
      await tester.runAsync(() async {
        host = await FakeHost.create();
        await pairPhone(host, 'pixel');
        feature = ActionsFeature(
          computer: FakeComputer(),
          runner: FakeRunner(),
          locker: FakeLocker(),
          idle: FakeIdle(),
          offersActions: true,
        );
        await feature.start(host);
      });
      final viewModel = ActionsViewModel(feature);
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: viewModel,
            child: const LeaveLockSettingsFrame(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lock when your phone leaves'), findsOneWidget);
      expect(find.textContaining('when Pixel 7 leaves'), findsOneWidget);
      expect(find.text('2 minutes'), findsOneWidget);
      expect(find.byType(SwitchToggle), findsOneWidget);

      await tester.tap(find.byType(SwitchToggle));
      await tester.runAsync(settle);
      await tester.pumpAndSettle();
      expect(feature.settings.locksWhenGone('pixel'), isTrue);

      await tester.tap(find.text('2 minutes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 minutes'));
      await tester.runAsync(settle);
      await tester.pumpAndSettle();
      expect(feature.settings.lockAfterMinutes, 5);
      await tester.runAsync(feature.stop);
    });

    testWidgets('Activity says when it locked and why', (tester) async {
      late List<ActivityItem> items;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              items = leaveActivity(
                context.actionsL10n,
                [
                  LeaveLockRecord(
                    deviceId: 'pixel',
                    deviceName: 'Pixel 7',
                    at: DateTime(2026, 11, 19, 9),
                    outcome: .locked,
                  ),
                  LeaveLockRecord(
                    deviceId: 'pixel',
                    deviceName: 'Pixel 7',
                    at: DateTime(2026, 11, 19, 8),
                    outcome: .cancelled,
                  ),
                ],
                lockAfterMinutes: 2,
                onDismiss: (_) {},
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(items.first.title, contains('Pixel 7 left'));
      expect(
        items.first.detail,
        'Gone for 2 minutes, with nobody at the keyboard',
      );
      expect(items.last.title, 'Stayed unlocked after Pixel 7 left');
    });
  });
}
