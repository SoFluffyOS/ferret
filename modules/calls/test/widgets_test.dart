import 'package:calls/calls.dart';
import 'package:calls/ui/frames/frames.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/calls.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

void main() {
  group('call card', () {
    late FakeControl control;
    late ActiveCallsViewModel viewModel;

    Future<void> pumpCard(WidgetTester tester) async {
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: viewModel,
            child: const CallCardFrame(),
          ),
        ),
      );
      await tester.pump();
    }

    setUp(() {
      control = FakeControl();
      viewModel = ActiveCallsViewModel(control);
    });

    tearDown(() => viewModel.dispose());

    testWidgets('shows nothing while no phone is in a call', (tester) async {
      await pumpCard(tester);

      expect(find.text('Answer'), findsNothing);
      expect(find.text('Hang up'), findsNothing);
    });

    testWidgets('a ringing call shows who it is and what to do', (
      tester,
    ) async {
      await pumpCard(tester);

      control.emit(remoteCall());
      await tester.pump();

      expect(find.byType(FeatureCard), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('+15550100 · Incoming call on Pixel'), findsOneWidget);
      expect(find.text('Answer'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Silence'), findsOneWidget);
      expect(find.byType(CallTimer), findsNothing);
      expect(
        find.text(
          'Audio stays on Pixel for now. Talk on the phone or its headset.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an unknown caller is called that', (tester) async {
      control.emit(remoteCall(name: '', number: ''));
      await pumpCard(tester);

      expect(find.text('Unknown caller'), findsOneWidget);
      expect(find.text('Incoming call on Pixel'), findsOneWidget);
    });

    testWidgets('Answer, Decline and Silence go to the phone', (tester) async {
      control.emit(remoteCall());
      await pumpCard(tester);

      await tester.tap(find.text('Silence'));
      await tester.pump();
      await tester.tap(find.text('Answer'));
      await tester.pump();
      await tester.tap(find.text('Decline'));
      await tester.pump();

      expect(control.silencedCalls, ['call-1']);
      expect(control.answered, ['call-1']);
      expect(control.endedCalls, ['call-1']);
      expect(find.text('Ringer silenced'), findsOneWidget);
    });

    testWidgets('an answered call shows a timer and Hang up', (tester) async {
      control.emit(remoteCall());
      await pumpCard(tester);

      control.emit(
        remoteCall(
          state: .CALL_STATE_ACTIVE,
          connectedAt: DateTime.now().subtract(const Duration(seconds: 65)),
        ),
      );
      await tester.pump();

      expect(find.text('Answer'), findsNothing);
      expect(find.text('+15550100 · On a call on Pixel'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^1:0\d$')), findsOneWidget);

      await tester.tap(find.text('Hang up'));
      await tester.pump();
      expect(control.endedCalls, ['call-1']);
    });

    testWidgets('an outgoing call says it is calling', (tester) async {
      control.emit(
        remoteCall(
          state: .CALL_STATE_DIALING,
          direction: .CALL_DIRECTION_OUTGOING,
        ),
      );
      await pumpCard(tester);

      expect(find.text('+15550100 · Calling from Pixel'), findsOneWidget);
      expect(find.text('Hang up'), findsOneWidget);
      expect(find.byType(CallTimer), findsOneWidget);
    });

    testWidgets('says why a button did not work', (tester) async {
      control
        ..outcome = .unreachable
        ..emit(remoteCall());
      await pumpCard(tester);

      await tester.tap(find.text('Answer'));
      await tester.pump();

      expect(
        find.text("Pixel didn't answer. Check that it's connected."),
        findsOneWidget,
      );
    });

    testWidgets('goes away when the call ends', (tester) async {
      control.emit(remoteCall());
      await pumpCard(tester);

      control.emit(remoteCall(state: .CALL_STATE_ENDED));
      await tester.pump();

      expect(find.text('Alex'), findsNothing);
    });
  });

  group('dialer', () {
    late FakeControl control;

    Future<void> pumpDialer(WidgetTester tester) async {
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider(
            create: (_) => DialerViewModel(
              control: control,
              deviceId: 'phone',
              deviceName: 'Pixel',
            ),
            child: const DialerFrame(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      control = FakeControl()
        ..log = CallLogResult([
          CallLogEntry(
            id: '7',
            number: '+15550100',
            name: 'Alex',
            type: .CALL_LOG_TYPE_MISSED,
            dateMs: Int64(DateTime(2026, 11, 17, 18, 5).millisecondsSinceEpoch),
          ),
          CallLogEntry(
            id: '6',
            number: '+15550123',
            type: .CALL_LOG_TYPE_OUTGOING,
            dateMs: Int64(DateTime(2026, 11, 16, 9).millisecondsSinceEpoch),
            durationS: Int64(125),
          ),
          CallLogEntry(id: '5', type: .CALL_LOG_TYPE_INCOMING),
        ]);
    });

    testWidgets('lists recent calls with type, date and length', (
      tester,
    ) async {
      await pumpDialer(tester);

      expect(find.text('Recent calls'.toUpperCase()), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'^Missed · \+15550100 · Nov 17 6:05\sPM$')),
        findsOneWidget,
      );
      expect(find.text('+15550123'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'^Outgoing · Nov 16 9:00\sAM · 2:05$')),
        findsOneWidget,
      );
      expect(find.text('Private number'), findsOneWidget);
    });

    testWidgets('picking a recent call fills the number, Call dials it', (
      tester,
    ) async {
      await pumpDialer(tester);

      await tester.tap(find.text('Alex'));
      await tester.pump();
      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();

      expect(control.dialed, [('phone', '+15550100')]);
      expect(
        find.text('Pixel is calling. Audio stays on the phone for now.'),
        findsOneWidget,
      );
    });

    testWidgets('a typed number is checked before it is sent', (tester) async {
      await pumpDialer(tester);

      await tester.enterText(find.byType(EditableText), 'not a number');
      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();

      expect(control.dialed, isEmpty);
      expect(
        find.text("That doesn't look like a phone number."),
        findsOneWidget,
      );
    });

    testWidgets('says why the call did not start', (tester) async {
      control.outcome = .permissionMissing;
      await pumpDialer(tester);

      await tester.enterText(find.byType(EditableText), '5550100');
      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("Pixel hasn't allowed this yet."),
        findsOneWidget,
      );
    });

    testWidgets('explains missing recent calls and retries', (tester) async {
      final entries = control.log;
      control.log = const .failed(.permissionMissing);
      await pumpDialer(tester);

      expect(
        find.textContaining("Pixel doesn't let Ferret read its recent calls."),
        findsOneWidget,
      );

      control.log = entries;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Alex'), findsOneWidget);
      expect(control.logRequests, 2);
    });

    testWidgets('says when there are no recent calls', (tester) async {
      control.log = const CallLogResult([]);
      await pumpDialer(tester);

      expect(find.text('No recent calls.'), findsOneWidget);
    });
  });

  group('phone setup', () {
    late FakePhone phone;
    late FakeHost host;
    late CallsFeature feature;

    Future<void> pumpSetup(WidgetTester tester, Widget frame) async {
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider(
            create: (_) => PhoneSetupViewModel(feature),
            child: frame,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> start({bool enabled = false}) async {
      host = FakeHost(settings: {CallsSettings.enabledKey: enabled});
      feature = CallsFeature(phone: phone);
      await feature.start(host);
    }

    setUp(() => phone = FakePhone()..granted = noPermissions());

    testWidgets('starts with the explainer and asks for nothing', (
      tester,
    ) async {
      await start();
      await pumpSetup(tester, const PhoneSetupFrame());

      expect(
        find.text("See who's calling and answer from your computer."),
        findsOneWidget,
      );
      expect(find.textContaining('Audio stays on this phone'), findsOneWidget);
      expect(phone.requested, 0);
    });

    testWidgets('Turn on asks for the permissions and shows what works', (
      tester,
    ) async {
      phone.afterRequest = allPermissions()..placeCalls = false;
      await start();
      await pumpSetup(tester, const PhoneSetupFrame());

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(phone.requested, 1);
      expect(feature.settings.enabled, isTrue);
      expect(phone.monitoring, isTrue);
      expect(
        find.text("Your computers see this phone's calls"),
        findsOneWidget,
      );
      expect(find.text('Answer, decline and hang up'), findsOneWidget);
      expect(find.text('Allow the rest'), findsOneWidget);
      expect(
        find.text('Call audio stays on this phone for now.'),
        findsOneWidget,
      );
    });

    testWidgets('a denied permission is explained and can be asked again', (
      tester,
    ) async {
      await start();
      await pumpSetup(tester, const PhoneSetupFrame());

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();

      expect(find.text("Ferret can't see calls yet"), findsOneWidget);

      phone.afterRequest = allPermissions();
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(phone.requested, 2);
      expect(
        find.text("Your computers see this phone's calls"),
        findsOneWidget,
      );
      expect(find.text('Allow the rest'), findsNothing);
    });

    testWidgets(
      'when Android stops asking, the button opens the app settings and '
      'coming back re-checks',
      (tester) async {
        phone.afterRequest = noPermissions(canAskAgain: false);
        await start();
        await pumpSetup(tester, const PhoneSetupFrame());

        await tester.tap(find.text('Turn on'));
        await tester.pumpAndSettle();

        expect(find.textContaining("Android won't ask again"), findsOneWidget);

        await tester.tap(find.text('Open app settings'));
        await tester.pumpAndSettle();
        expect(phone.openedSettings, 1);
        expect(phone.requested, 1);

        phone.granted = allPermissions();
        tester.binding.handleAppLifecycleStateChanged(.inactive);
        tester.binding.handleAppLifecycleStateChanged(.resumed);
        await tester.pumpAndSettle();

        expect(
          find.text("Your computers see this phone's calls"),
          findsOneWidget,
        );
      },
    );

    testWidgets('says when the settings page can not be opened', (
      tester,
    ) async {
      phone
        ..granted = noPermissions(canAskAgain: false)
        ..settingsOpen = false;
      await start(enabled: true);
      await pumpSetup(tester, const PhoneSetupFrame());

      await tester.tap(find.text('Open app settings'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't open Settings."), findsOneWidget);
    });

    testWidgets('Turn off stops watching calls', (tester) async {
      phone.granted = allPermissions();
      await start(enabled: true);
      await pumpSetup(tester, const PhoneSetupFrame());

      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();

      expect(feature.settings.enabled, isFalse);
      expect(phone.monitoring, isFalse);
      expect(find.text('Turn on'), findsOneWidget);
    });

    testWidgets('the home card invites, warns, then gets out of the way', (
      tester,
    ) async {
      var opened = 0;
      await start();
      await pumpSetup(tester, PhoneHomeFrame(onSetUp: () => opened++));

      await tester.tap(find.text('Set up'));
      expect(opened, 1);

      await feature.settings.setEnabled(true);
      await tester.pumpAndSettle();
      expect(
        find.text("Calls are on, but Ferret can't see them yet."),
        findsOneWidget,
      );
      expect(find.text('Fix'), findsOneWidget);

      phone.granted = allPermissions();
      await feature.refreshPermissions();
      await tester.pumpAndSettle();
      expect(find.text('Calls'), findsNothing);
    });
  });

  group('computer settings', () {
    testWidgets('the notice can be turned off, and audio is explained', (
      tester,
    ) async {
      final feature = CallsFeature();
      await feature.start(FakeHost());
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider(
            create: (_) => CallsSettingsViewModel(feature),
            child: const CallsSettingsFrame(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Show incoming calls'), findsOneWidget);
      expect(
        find.textContaining('Call audio stays on the phone for now.'),
        findsOneWidget,
      );

      await tester.tap(find.byType(SwitchToggle));
      await tester.pumpAndSettle();

      expect(feature.showIncoming, isFalse);
    });
  });
}
