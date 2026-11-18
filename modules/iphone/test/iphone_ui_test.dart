import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:ferret_iphone/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iphone/iphone.dart';
import 'package:iphone/ui/frames/frames.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

class _FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Rig rig;
  var now = DateTime(2026, 11, 18, 12);

  Future<void> start(
    WidgetTester tester, {
    Map<String, Object?>? settings,
    FakeAppleTransport? transport,
  }) async {
    now = DateTime(2026, 11, 18, 12);
    rig = await Rig.start(
      settings: settings,
      transport: transport,
      clock: () => now,
      retryDelays: const [],
    );
    await tester.pump();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await rig.feature.stop();
    await tester.pump();
  }

  group('home card', () {
    late IphoneViewModel viewModel;
    var setUpOpened = 0;

    Future<void> show(WidgetTester tester) async {
      viewModel = IphoneViewModel(rig.feature);
      setUpOpened = 0;
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: viewModel,
            child: IphoneCardFrame(
              onSetUp: () => setUpOpened++,
              now: () => now,
            ),
          ),
        ),
      );
    }

    testWidgets('stays away while the feature is off', (tester) async {
      await start(tester);
      await show(tester);

      expect(find.byType(FeatureCard), findsNothing);
      expect(viewModel.hasCard, isFalse);

      await finish(tester);
    });

    testWidgets('stays away while connected and nothing plays', (tester) async {
      await start(tester, settings: pairedSettings());
      await show(tester);

      expect(rig.feature.link.isConnected, isTrue);
      expect(find.byType(FeatureCard), findsNothing);

      await finish(tester);
    });

    testWidgets('shows what the iPhone plays, and where it is', (tester) async {
      await start(tester, settings: pairedSettings());
      await show(tester);

      rig.iphone.play(
        player: 'Music',
        title: 'Song',
        artist: 'Artist',
        duration: 200,
        elapsed: 65,
      );
      await tester.pump();

      expect(find.byType(FeatureCard), findsOneWidget);
      expect(find.text('Song'), findsOneWidget);
      expect(
        find.text('Now playing on Zoé’s iPhone\nArtist · Music'),
        findsOneWidget,
      );
      expect(find.text('1:05'), findsOneWidget);
      expect(find.text('3:20'), findsOneWidget);

      now = now.add(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('1:15'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('the controls reach the iPhone', (tester) async {
      await start(tester, settings: pairedSettings());
      await show(tester);
      rig.iphone.play();
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.pause));
      await tester.tap(find.byIcon(LucideIcons.skipForward));
      await tester.tap(find.byIcon(LucideIcons.skipBack));
      await tester.tap(find.byIcon(LucideIcons.volume2));
      await tester.tap(find.byIcon(LucideIcons.volume1));
      await tester.pump();

      expect(rig.iphone.commands, [
        AmsCommand.togglePlayPause,
        AmsCommand.nextTrack,
        AmsCommand.previousTrack,
        AmsCommand.volumeUp,
        AmsCommand.volumeDown,
      ]);

      await finish(tester);
    });

    testWidgets('says paused, and offers Play', (tester) async {
      await start(tester, settings: pairedSettings());
      await show(tester);
      rig.iphone
        ..play(title: 'Song', artist: '')
        ..update(.player, AmsPlayerAttribute.playbackInfo, '0,0.0,30');
      await tester.pump();

      expect(find.text('Paused on Zoé’s iPhone\nMusic'), findsOneWidget);
      expect(find.byIcon(LucideIcons.play), findsOneWidget);
      expect(find.text('0:30'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('greys out what the iPhone will not do now', (tester) async {
      await start(tester, settings: pairedSettings());
      await show(tester);
      rig.iphone.play();
      rig.transport.emit(.remoteCommand, [0, 1, 2, 5, 6]);
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.skipForward));
      await tester.pump();

      expect(rig.iphone.commands, isEmpty);

      await finish(tester);
    });

    testWidgets('says so when a control does not get there', (tester) async {
      await start(tester, settings: pairedSettings());
      await show(tester);
      rig.iphone.play();
      await tester.pump();
      rig.transport.writeError = const GattException(.notConnected);

      await tester.tap(find.byIcon(LucideIcons.pause));
      await tester.pump();

      expect(
        find.text("The iPhone didn't answer. Is it still nearby?"),
        findsOneWidget,
      );

      await finish(tester);
    });

    testWidgets('goes away when the iPhone goes out of reach', (tester) async {
      await start(tester, settings: pairedSettings());
      await show(tester);
      rig.iphone.play();
      await tester.pump();

      rig.transport.drop();
      await tester.pump();

      expect(find.byType(FeatureCard), findsNothing);
      expect(viewModel.hasCard, isFalse);

      await finish(tester);
    });

    testWidgets('Bluetooth off: says so, with the way to fix it', (
      tester,
    ) async {
      await start(
        tester,
        settings: pairedSettings(),
        transport: FakeAppleTransport(statusNow: .off),
      );
      await show(tester);

      expect(find.text('Bluetooth is off'), findsOneWidget);

      await tester.tap(find.text('Open Bluetooth settings'));
      await tester.pump();
      expect(rig.transport.settingsOpened, 1);

      rig.transport.statusNow = .ready;
      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(rig.feature.link.isConnected, isTrue);
      expect(find.text('Bluetooth is off'), findsNothing);

      await finish(tester);
    });

    testWidgets('no iPhone picked: offers to set one up', (tester) async {
      await start(tester, settings: {IphoneSettings.enabledKey: true});
      await show(tester);

      expect(find.text('Pick your iPhone'), findsOneWidget);

      await tester.tap(find.text('Set up'));

      expect(setUpOpened, 1);

      await finish(tester);
    });

    testWidgets('an iPhone that holds back explains the iPhone setting', (
      tester,
    ) async {
      await start(
        tester,
        settings: pairedSettings(),
        transport: FakeAppleTransport(services: const AppleServices()),
      );
      await show(tester);

      expect(
        find.text('Zoé’s iPhone isn\'t sharing with this computer'),
        findsOneWidget,
      );
      expect(find.textContaining('Share System Notifications'), findsOneWidget);

      await finish(tester);
    });
  });

  group('settings', () {
    Future<IphoneSettingsViewModel> show(
      WidgetTester tester, {
      IphoneHostKind host = .windows,
    }) async {
      final viewModel = IphoneSettingsViewModel(rig.feature, host: host);
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider(
            create: (_) => viewModel,
            child: const IphoneSettingsFrame(),
          ),
        ),
      );
      await tester.pump();
      return viewModel;
    }

    testWidgets('says what works and what does not before turning it on', (
      tester,
    ) async {
      await start(tester);
      await show(tester);

      expect(find.text('Connect an iPhone'), findsOneWidget);
      expect(find.text('What works with an iPhone'), findsOneWidget);
      expect(find.text('Not yet'), findsOneWidget);
      expect(find.textContaining('SMS and iMessage'), findsOneWidget);
      expect(find.text('Pair your iPhone'), findsNothing);
      expect(rig.transport.connects, isEmpty);

      await finish(tester);
    });

    testWidgets('turning it on walks through pairing, then connects', (
      tester,
    ) async {
      await start(tester);
      await show(tester);

      await tester.tap(find.byType(SwitchToggle).first);
      await tester.pumpAndSettle();

      expect(find.text('Pair your iPhone'), findsOneWidget);
      expect(find.textContaining('Add device'), findsOneWidget);
      expect(find.text('Zoé’s iPhone'), findsOneWidget);
      expect(find.text('Connected now'), findsOneWidget);

      await tester.tap(find.text('Use'));
      await tester.pumpAndSettle();

      expect(find.text('Connected to Zoé’s iPhone'), findsOneWidget);
      expect(find.text('Pair your iPhone'), findsNothing);
      expect(rig.feature.settings.deviceId, iphoneDevice.id);

      await finish(tester);
    });

    testWidgets('on Linux the pairing starts from the iPhone', (tester) async {
      await start(tester, settings: {IphoneSettings.enabledKey: true});
      await show(tester, host: .linux);

      expect(find.textContaining('Other Devices'), findsOneWidget);
      expect(find.textContaining('Add device'), findsNothing);

      await finish(tester);
    });

    testWidgets('on a Mac it is marked experimental', (tester) async {
      await start(tester, settings: {IphoneSettings.enabledKey: true});
      await show(tester, host: .macos);

      expect(find.textContaining('Experimental'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('finds an iPhone paired while the list was open', (
      tester,
    ) async {
      await start(
        tester,
        settings: {IphoneSettings.enabledKey: true},
        transport: FakeAppleTransport(),
      );
      await show(tester);

      expect(find.text('No paired iPhone found yet.'), findsOneWidget);

      rig.transport.bonded = [iphoneDevice];
      await tester.tap(find.text('Look again'));
      await tester.pump();

      expect(find.text('Zoé’s iPhone'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('an iPhone out of reach says so, with Try again', (
      tester,
    ) async {
      await start(
        tester,
        settings: pairedSettings(),
        transport: FakeAppleTransport()
          ..connectError = const GattException(.notConnected),
      );
      await show(tester);

      expect(find.textContaining('is out of reach'), findsOneWidget);

      rig.transport.connectError = null;
      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(find.text('Connected to Zoé’s iPhone'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('says when the iPhone holds its notifications back', (
      tester,
    ) async {
      await start(
        tester,
        settings: pairedSettings(),
        transport: FakeAppleTransport(
          services: const AppleServices(hasAms: true),
        ),
      );
      await show(tester);

      expect(find.text('Connected to Zoé’s iPhone'), findsOneWidget);
      expect(
        find.textContaining("isn't sharing its notifications"),
        findsOneWidget,
      );

      await finish(tester);
    });

    testWidgets('a computer without Bluetooth says so', (tester) async {
      await start(
        tester,
        settings: pairedSettings(),
        transport: FakeAppleTransport(statusNow: .unsupported),
      );
      await show(tester);

      expect(find.textContaining('no Bluetooth LE'), findsOneWidget);
      expect(find.text('Show notifications'), findsNothing);

      await finish(tester);
    });

    testWidgets('the options are saved, and another iPhone can be picked', (
      tester,
    ) async {
      await start(tester, settings: pairedSettings());
      await show(tester);

      await tester.tap(find.byType(SwitchToggle).at(2));
      await tester.pumpAndSettle();
      expect(rig.feature.settings.hidePreviews, isTrue);

      await tester.tap(find.byType(SwitchToggle).at(1));
      await tester.pumpAndSettle();
      expect(rig.feature.settings.showNotifications, isFalse);
      expect(find.text('Hide what notifications say'), findsNothing);

      await tester.tap(find.text('Use another iPhone'));
      await tester.pumpAndSettle();

      expect(rig.feature.settings.deviceId, isNull);
      expect(find.text('Pair your iPhone'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('says so when the Bluetooth settings will not open', (
      tester,
    ) async {
      await start(tester, settings: {IphoneSettings.enabledKey: true});
      await show(tester);
      await rig.feature.stop();

      await tester.tap(find.text('Open Bluetooth settings'));
      await tester.pump();

      expect(find.textContaining("Couldn't open"), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('feature UI', () {
    testWidgets('tells the shell when its card comes and goes', (tester) async {
      await start(tester, settings: pairedSettings());
      final ui = IphoneFeatureUi(feature: rig.feature);
      final notifier = RecordingNotifier();
      final context = FeatureContext(
        engine: _FakeEngine(),
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: notifier,
      );
      await ui.onAppStarted(context);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);
      final quiet = ui.hasHomeCard(context);

      rig.iphone.play();
      await tester.pump();
      final playing = ui.hasHomeCard(context);
      rig.iphone.notify(1, title: 'Hello');
      await tester.pump();

      expect(quiet, isFalse);
      expect(playing, isTrue);
      expect(changes, greaterThan(0));
      expect(notifier.shown.keys, ['iphone.n.1']);
      expect(ui.noticeCategories, isNotEmpty);

      ui.dispose();
      await rig.feature.stop();
      await tester.pump();
    });

    testWidgets('shows nothing at all on a phone', (tester) async {
      final feature = IphoneFeature(
        transport: FakeAppleTransport.new,
        isSupported: false,
      );
      await feature.start(FakeHost(pairedSettings()));
      final ui = IphoneFeatureUi(feature: feature);
      final context = FeatureContext(
        engine: _FakeEngine(),
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: RecordingNotifier(),
      );
      await ui.onAppStarted(context);
      late BuildContext buildContext;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              buildContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ui.hasHomeCard(context), isFalse);
      expect(ui.buildSettings(buildContext, context), isNull);
      expect(ui.noticeCategories, isEmpty);

      ui.dispose();
      await feature.stop();
    });
  });
}
