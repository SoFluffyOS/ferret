import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

class _FakeEngine implements FerretEngine {
  _FakeEngine([this.devices = const []]);

  @override
  final List<DeviceStatus> devices;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QuietNotifier implements LocalNotifier {
  @override
  Future<void> show(LocalNotice notice) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const .empty();
}

/// The computer with more ways to show a screen plugged in: a cable route
/// that can be controlled, and a receiver other devices send to.
void main() {
  late FakeHost host;
  late FakeRoute cable;
  late FakeReceiver receiver;
  late FakeControl control;
  late MirroringFeature feature;
  late MirroringFeatureUi ui;
  late MirrorTarget galaxy;

  Future<void> startComputer(
    WidgetTester tester, {
    bool moreWays = true,
    bool plugged = true,
    bool fetchesTool = false,
    Set<ControlAbility>? abilities,
  }) async {
    final created = await tester.runAsync(
      () => FakeHost.create(
        settings: {MirroringSettings.moreWaysKey: moreWays},
      ),
    );
    if (created == null) {
      fail('The host should start');
    }

    host = created;
    control = switch (abilities) {
      final abilities? => FakeControl(abilities: abilities),
      null => FakeControl(),
    };
    cable = switch (fetchesTool) {
      true => FakeToolRoute('cable', control: control),
      false => FakeRoute('cable', control: control),
    };
    receiver = FakeReceiver('cast');
    galaxy = cable.target('a1', 'Galaxy');
    cable.found = [galaxy];
    feature = MirroringFeature(
      decoder: FakeDecoder.new,
      codecs: const [.h264],
      routes: [if (plugged) cable],
      receivers: [if (plugged) receiver],
      canShare: false,
      canView: true,
      clock: () => DateTime(2026, 11, 18, 21, 10),
    );
    ui = MirroringFeatureUi(feature: feature, window: FakeWindow());
    await feature.start(host);
    await tester.pump();
    addTearDown(() async {
      await feature.viewer?.stop();
    });
  }

  FeatureContext featureContext({
    GlobalKey<NavigatorState>? navigatorKey,
    List<DeviceStatus> devices = const [],
  }) => FeatureContext(
    engine: _FakeEngine(devices),
    navigatorKey: navigatorKey ?? GlobalKey<NavigatorState>(),
    notifier: _QuietNotifier(),
  );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: ui.viewerViewModel,
          child: const MirrorPage(deviceId: 'cable:a1', deviceName: 'Galaxy'),
        ),
        scroll: false,
      ),
    );
    await tester.pump();
  }

  Future<void> showGalaxy(WidgetTester tester) async {
    await ui.viewerViewModel.startTarget(galaxy);
    cable.feeds.single.play(width: 1000, height: 2000);
    await tester.pump();
    await pumpPage(tester);
  }

  Future<void> pumpSettings(
    WidgetTester tester, {
    List<DeviceStatus> devices = const [],
  }) => tester.pumpWidget(
    testApp(
      Builder(
        builder: (context) =>
            ui.buildSettings(context, featureContext(devices: devices)) ??
            const Text('no section'),
      ),
    ),
  );

  final androidPhone = DeviceStatus(
    TrustedDevice(
      id: 'pixel',
      name: 'Pixel',
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: Uint8List(32),
      pairedAt: DateTime(2026),
    ),
    null,
  );

  group('opt-in', () {
    testWidgets('nothing plugged in: no offer and no switch', (tester) async {
      await startComputer(tester, moreWays: false, plugged: false);
      await pumpSettings(tester);

      final context = tester.element(find.text('no section'));
      expect(ui.offerFor(context, featureContext()), isNull);
    });

    testWidgets('the other ways are offered as experimental, and turning '
        'them on is one tap', (tester) async {
      await startComputer(tester, moreWays: false);
      await pumpSettings(tester);
      final context = tester.element(find.text('no section'));

      final offer = ui.offerFor(context, featureContext());
      expect(offer?.title, 'Screen');
      expect(offer?.description, startsWith('Experimental'));
      expect(ui.hasHomeCard(featureContext()), isFalse);

      offer?.onAction();
      await tester.pump();
      await tester.pump();

      expect(MirroringSettings(host.settings).moreWays, isTrue);
      expect(ui.offerFor(context, featureContext()), isNull);
      expect(receiver.listeningAs, 'This device');
      expect(ui.hasHomeCard(featureContext()), isTrue);
    });

    testWidgets('settings stay away until an Android phone is paired or the '
        'other ways are on', (tester) async {
      await startComputer(tester, moreWays: false);
      await pumpSettings(tester);
      expect(find.text('no section'), findsOneWidget);

      await MirroringSettings(host.settings).setMoreWays(true);
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpSettings(tester);

      expect(find.text('no section'), findsNothing);
      expect(find.text('Experimental'), findsOneWidget);
      expect(
        tester.widgetList<SwitchToggle>(find.byType(SwitchToggle)).first.value,
        isTrue,
      );
    });

    testWidgets('settings are marked Experimental, with the other ways off '
        'until asked for', (tester) async {
      await startComputer(tester, moreWays: false);
      await pumpSettings(tester, devices: [androidPhone]);

      expect(find.text('More ways to show a screen'), findsOneWidget);
      expect(find.text('Experimental'), findsOneWidget);
      expect(
        tester.widget<SwitchToggle>(find.byType(SwitchToggle)).value,
        isFalse,
      );

      await tester.tap(find.byType(SwitchToggle));
      await tester.pumpAndSettle();

      expect(MirroringSettings(host.settings).moreWays, isTrue);
    });

    testWidgets('settings say what a way still needs in plain words, with '
        'how to and Check again', (tester) async {
      await startComputer(tester, moreWays: false);
      cable.statusNow = const RouteNeedsSetup(.installTool, detail: '/opt/adb');
      await MirroringSettings(host.settings).setMoreWays(true);
      await tester.pump();
      await pumpSettings(tester);
      await tester.pump();

      expect(
        find.text('This computer needs a small helper first'),
        findsOneWidget,
      );
      expect(find.textContaining('How to: install'), findsOneWidget);
      expect(find.textContaining('/opt/adb'), findsOneWidget);

      cable.statusNow = const RouteReady();
      await tester.tap(find.text('Check again'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('This computer needs a small helper first'),
        findsNothing,
      );
      expect(find.text('Check again'), findsNothing);
    });
  });

  group('a way that can fetch its tool', () {
    Future<FakeToolRoute> settingsMissing(
      WidgetTester tester,
      String detail,
    ) async {
      await startComputer(tester, moreWays: false, fetchesTool: true);
      final adb = cable as FakeToolRoute;
      adb.statusNow = RouteNeedsSetup(.installTool, detail: detail);
      await MirroringSettings(host.settings).setMoreWays(true);
      await tester.pump();
      await pumpSettings(tester);
      await tester.pump();
      return adb;
    }

    testWidgets('says it downloads from Google, and fetches only on the '
        'owner\'s click', (tester) async {
      final adb = await settingsMissing(tester, 'adb');
      adb.download = Completer<void>();

      expect(find.text("Get Android's helper tool"), findsOneWidget);
      expect(find.textContaining('from Google'), findsOneWidget);
      expect(adb.installs, 0);

      await tester.tap(find.text('Download'));
      await tester.pump();

      expect(adb.installs, 1);
      expect(find.text('Downloading…'), findsOneWidget);

      adb.download?.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text("Get Android's helper tool"), findsNothing);
    });

    testWidgets('a failed download says so, with Try again', (tester) async {
      final adb = await settingsMissing(tester, 'adb');
      adb.failDownload = true;

      await tester.tap(find.text('Download'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining("didn't finish"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a tool only the owner can start gets start words, no '
        'download', (tester) async {
      await settingsMissing(tester, FakeToolRoute.notStarted);

      expect(find.text("Start Android's helper tool"), findsOneWidget);
      expect(find.textContaining('adb start-server'), findsOneWidget);
      expect(find.text('Download'), findsNothing);
    });
  });

  group('screens the other ways find', () {
    testWidgets('are listed on the home card with Show', (tester) async {
      await startComputer(tester);
      final shown = <MirrorTarget>[];
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: ui.viewerViewModel,
            child: ViewerCardFrame(onOpen: (_) {}, onShow: shown.add),
          ),
        ),
      );

      expect(find.text('Screens you can show'), findsOneWidget);
      expect(find.text('Galaxy'), findsOneWidget);
      expect(find.text('Plugged in with a cable'), findsOneWidget);

      await tester.tap(find.text('Show screen'));
      expect(shown.single, galaxy);
    });

    testWidgets('a paired phone only they reach gets Show screen on its own '
        'page, not a second line on the card', (tester) async {
      await startComputer(tester);
      await tester.runAsync(
        () => host.trustStore.save(
          TrustedDevice(
            id: 'tab',
            name: 'Tablet',
            platform: .PLATFORM_ANDROID,
            formFactor: .FORM_FACTOR_TABLET,
            publicKey: Uint8List(32),
            pairedAt: DateTime(2026),
          ),
        ),
      );
      cable.find([galaxy, cable.target('a2', 'Tablet', ferretDeviceId: 'tab')]);
      await tester.pump();
      await pumpSettings(tester);
      final context = tester.element(find.byType(SwitchToggle).first);
      final tablet = host.trustStore['tab'];
      if (tablet == null) {
        fail('The tablet should be paired');
      }

      final actions = ui.deviceActions(
        context,
        featureContext(),
        DeviceStatus(tablet, null),
      );

      expect(actions.single.label, 'Show screen');
      expect(ui.viewerViewModel.targets, [galaxy]);
    });
  });

  group('mirror page', () {
    testWidgets('a step the way still needs is said in plain words, with '
        'Try again', (tester) async {
      await startComputer(tester);
      cable.statusNow = const RouteNeedsSetup(.authorizeComputer);
      await ui.viewerViewModel.startTarget(galaxy);
      await pumpPage(tester);

      expect(find.text('Allow this computer on the phone'), findsOneWidget);
      expect(find.textContaining('tap Allow'), findsOneWidget);

      cable.statusNow = const RouteReady();
      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(cable.feeds, hasLength(1));
    });

    testWidgets('Back, Home and Recent apps press the device\'s own '
        'buttons', (tester) async {
      await startComputer(tester);
      await showGalaxy(tester);

      await tester.tap(find.text('Home'));
      await tester.tap(find.text('Recent apps'));
      await tester.tap(find.text('Back'));

      expect(control.pressed, [
        DeviceButton.home,
        DeviceButton.recents,
        DeviceButton.back,
      ]);
    });

    testWidgets('clicks and scrolling travel as fractions of the picture', (
      tester,
    ) async {
      await startComputer(tester);
      await showGalaxy(tester);
      final picture = tester.getRect(find.byType(Texture));

      final gesture = await tester.startGesture(
        picture.topLeft + Offset(picture.width / 4, picture.height / 2),
        kind: .mouse,
      );
      await gesture.moveBy(Offset(picture.width / 4, 0));
      await gesture.up();
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: picture.center,
          scrollDelta: const Offset(0, 100),
        ),
      );

      final phases = [for (final event in control.pointers) event.phase];
      expect(phases.first, PointerPhase.down);
      expect(phases, contains(PointerPhase.move));
      expect(phases[phases.length - 2], PointerPhase.up);
      expect(phases.last, PointerPhase.scroll);
      expect(control.pointers.first.x, closeTo(0.25, 0.01));
      expect(control.pointers.first.y, closeTo(0.5, 0.01));
      expect(control.pointers.first.buttons, 1);
      expect(control.pointers[phases.length - 2].x, closeTo(0.5, 0.01));
      expect(control.pointers.last.scrollY, 2);
    });

    testWidgets('typing travels as keyboard usages', (tester) async {
      await startComputer(tester);
      await showGalaxy(tester);

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyA,
        physicalKey: PhysicalKeyboardKey.keyA,
      );
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.keyA,
        physicalKey: PhysicalKeyboardKey.keyA,
      );

      expect(
        [for (final key in control.keys) (key.phase, key.usage)],
        [(KeyPhase.down, 0x04), (KeyPhase.up, 0x04)],
      );
    });

    testWidgets('a device that is view only gets no buttons and no input', (
      tester,
    ) async {
      await startComputer(tester, abilities: const {});
      await showGalaxy(tester);

      expect(find.text('Home'), findsNothing);
      await tester.tap(find.byType(Texture));
      expect(control.pointers, isEmpty);
    });
  });

  testWidgets('a receiver has its own switch once the other ways are on', (
    tester,
  ) async {
    await startComputer(tester);
    await pumpSettings(tester);

    expect(
      find.text('Let other devices send their screen here'),
      findsOneWidget,
    );
    expect(receiver.isListening, isTrue);

    await tester.tap(find.byType(SwitchToggle).last);
    await tester.pumpAndSettle();

    expect(receiver.isListening, isFalse);
    expect(
      MirroringSettings(host.settings).receiverOn('cast', byDefault: true),
      isFalse,
    );
  });

  testWidgets('a device that asks gets a prompt: Allow lets it in, Don\'t '
      'allow turns it away', (tester) async {
    await startComputer(tester);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      testApp(const SizedBox.shrink(), navigatorKey: navigatorKey),
    );
    var revealed = 0;
    await ui.onAppStarted(
      FeatureContext(
        engine: _FakeEngine(),
        navigatorKey: navigatorKey,
        notifier: _QuietNotifier(),
        onReveal: () async => revealed++,
      ),
    );
    final answers = <bool>[];

    unawaited(receiver.ask("Simon's iPhone").then(answers.add));
    await tester.pump();
    await tester.pump();
    expect(
      find.text("Simon's iPhone wants to show its screen here"),
      findsOneWidget,
    );
    expect(revealed, 1);

    await tester.tap(find.text('Allow'));
    await tester.pump();
    await tester.pump();
    expect(answers, [true]);
    expect(find.text('Allow'), findsNothing);

    unawaited(receiver.ask('Stranger').then(answers.add));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text("Don't allow"));
    await tester.pump();
    await tester.pump();
    expect(answers, [true, false]);
    expect(find.text("Don't allow"), findsNothing);
  });

  testWidgets('a screen a device sends here itself opens the mirror page', (
    tester,
  ) async {
    await startComputer(tester);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      testApp(const SizedBox.shrink(), navigatorKey: navigatorKey),
    );
    await ui.onAppStarted(featureContext(navigatorKey: navigatorKey));
    final iphone = FakeFeed(
      const MirrorTarget(routeId: 'cast', id: 'i1', name: 'iPhone'),
    );

    receiver.receive(iphone);
    await tester.pump();
    iphone.play();
    await tester.pump();
    await tester.pump();

    expect(find.text('iPhone'), findsOneWidget);
    expect(find.byType(Texture), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
