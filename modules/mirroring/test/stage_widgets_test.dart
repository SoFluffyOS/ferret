import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

class _FakeEngine implements FerretEngine {
  @override
  List<DeviceStatus> get devices => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifier implements LocalNotifier {
  final List<LocalNotice> shown = [];
  final List<String> cancelled = [];
  final StreamController<NoticeResponse> answers = .broadcast(sync: true);

  @override
  Future<void> show(LocalNotice notice) async => shown.add(notice);

  @override
  Future<void> cancel(String id) async => cancelled.add(id);

  @override
  Stream<NoticeResponse> get responses => answers.stream;
}

/// The mirror stage from the first question to the ending, on a computer
/// with a phone over Ferret, a cable and a receiver.
void main() {
  const phoneWindow = Size(400, 800);
  const wideWindow = Size(1000, 640);

  late FakeHost host;
  late FakeSession pixel;
  late FakeDecoder decoder;
  late FakeWindow window;
  late FakeToolRoute cable;
  late FakeControl control;
  late FakeReceiver receiver;
  late MirroringFeature feature;
  late ViewerViewModel viewModel;
  late DateTime now;
  late String clipboard;
  late int closed;

  FerretRoute ferret() {
    final route = feature.routes?.ferret;
    if (route == null) {
      fail('The computer should be able to view');
    }

    return route;
  }

  Future<void> start(
    WidgetTester tester, {
    FutureOr<GeneratedMessage> Function(GeneratedMessage)? answer,
    bool connected = true,
    bool lookForCable = false,
    bool systemMirrors = false,
    bool canFullScreen = false,
    Size size = phoneWindow,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final created = await tester.runAsync(
      () => FakeHost.create(
        settings: {MirroringSettings.lookForCableKey: lookForCable},
      ),
    );
    if (created == null) {
      fail('The host should start');
    }

    host = created;
    await tester.runAsync(
      () => host.trustStore.save(
        TrustedDevice(
          id: 'pixel',
          name: 'Pixel',
          platform: .PLATFORM_ANDROID,
          formFactor: .FORM_FACTOR_PHONE,
          publicKey: Uint8List(32),
          pairedAt: DateTime(2026),
        ),
      ),
    );
    pixel = FakeSession(
      'pixel',
      answer: answer ?? (_) => StartPending(timeoutSeconds: 60),
    );
    host.sessions = [if (connected) pixel];
    decoder = FakeDecoder();
    window = FakeWindow(can: canFullScreen);
    control = FakeControl(
      abilities: const {.pointer, .keys, .text, .buttons, .clipboard},
    );
    cable = FakeToolRoute('adb', control: control);
    receiver = FakeReceiver('airplay', listensByDefault: false);
    now = DateTime(2026, 11, 18, 21, 10);
    clipboard = '';
    closed = 0;
    feature = MirroringFeature(
      decoder: () => decoder,
      codecs: const [.h264, .jpeg],
      routes: [cable],
      receivers: [receiver],
      canShare: false,
      canView: true,
      clock: () => now,
    );
    await feature.start(host);
    viewModel = ViewerViewModel(
      feature,
      window: window,
      readClipboard: () async => clipboard,
      systemMirrors: systemMirrors,
      clock: () => now,
    );
    addTearDown(() async {
      viewModel.dispose();
      await feature.viewer?.stop();
    });
    await tester.pump();
  }

  Future<void> pumpStage(
    WidgetTester tester, {
    String deviceId = 'pixel',
    String deviceName = 'Pixel',
  }) async {
    viewModel.openStage(deviceId);
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: MirrorStageFrame(
            deviceId: deviceId,
            deviceName: deviceName,
            onClose: () => closed++,
            clock: () => now,
          ),
        ),
        scroll: false,
      ),
    );
    await tester.pump();
  }

  /// Lets [time] pass on the stage's own clock and on the test's.
  Future<void> wait(WidgetTester tester, Duration time) async {
    now = now.add(time);
    await tester.pump(time);
    await tester.pump();
  }

  Future<void> streamOverFerret(WidgetTester tester) async {
    await viewModel.show('pixel', 'Pixel');
    ferret()
      ..onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264))
      ..onConfig(
        pixel,
        StreamConfig(
          configId: 1,
          codec: .CODEC_H264,
          width: 1080,
          height: 2400,
          sps: [0x67],
          pps: [0x68],
        ),
      )
      ..onFrame(
        pixel,
        Frame(configId: 1, sequence: Int64(0), keyframe: true, data: [1]),
      );
    await tester.pump();
  }

  /// A phone on a cable with debugging on, shown.
  Future<MirrorTarget> streamOverCable(
    WidgetTester tester, {
    String name = 'Old tablet',
  }) async {
    final target = cable.target('R58', name);
    cable.find([target]);
    await tester.pump();
    await viewModel.showTarget(target);
    cable.feeds.last.play();
    await tester.pump();
    return target;
  }

  Finder tool(IconData icon) => find.widgetWithIcon(ToolbarButton, icon);

  group('asking the phone', () {
    testWidgets('says so with nothing else, and Cancel takes it back', (
      tester,
    ) async {
      final reply = Completer<GeneratedMessage>();
      await start(tester, answer: (_) => reply.future);
      unawaited(viewModel.show('pixel', 'Pixel'));
      await pumpStage(tester);

      expect(find.text('Asking Pixel…'), findsOneWidget);
      expect(find.text('This takes a moment.'), findsNothing);

      reply.complete(StartDeny(reason: .DENY_REASON_BUSY));
      await tester.pump();
      await tester.pump();
      expect(find.text('Pixel is already sharing its screen'), findsOneWidget);
    });

    testWidgets('while the phone asks: what to choose there in words that '
        'hold on any Android, and how long is left', (tester) async {
      await start(tester);
      await viewModel.show('pixel', 'Pixel');
      await pumpStage(tester);

      expect(find.text('Answer on Pixel'), findsOneWidget);
      expect(
        find.text('On Pixel, choose to share the entire screen, then Start.'),
        findsOneWidget,
      );
      expect(find.text('1:00 left'), findsOneWidget);
      expect(find.textContaining('Nothing on Pixel?'), findsNothing);
      expect(find.textContaining('Android asks every time'), findsOneWidget);

      await wait(tester, const Duration(seconds: 8));

      expect(find.text('0:52 left'), findsOneWidget);
      expect(
        find.text('Nothing on Pixel? Open the notice from Ferret.'),
        findsOneWidget,
      );
    });

    testWidgets('Cancel takes the question back and closes the stage', (
      tester,
    ) async {
      await start(tester);
      await viewModel.show('pixel', 'Pixel');
      await pumpStage(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(pixel.sentOf<Stop>(), hasLength(1));
      expect(closed, 1);
    });

    testWidgets('after the yes: waits for the first picture in words', (
      tester,
    ) async {
      await start(tester);
      await viewModel.show('pixel', 'Pixel');
      ferret().onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
      await pumpStage(tester);

      expect(find.text('Pixel said yes'), findsOneWidget);
      expect(find.text('Waiting for the first picture…'), findsOneWidget);
    });
  });

  group('a picture over Ferret', () {
    testWidgets('is view only and says so: one chip instead of the '
        'phone\'s keys', (tester) async {
      await start(tester);
      await streamOverFerret(tester);
      await pumpStage(tester);

      expect(tester.widget<Texture>(find.byType(Texture)).textureId, 7);
      expect(find.text('View only'), findsOneWidget);
      expect(tool(LucideIcons.chevronLeft), findsNothing);
      expect(tool(LucideIcons.keyboard), findsNothing);
      expect(find.byType(QualityMark), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.textContaining('fps'), findsNothing, reason: 'no stats line');
    });

    testWidgets('the chip explains, and a click on the picture says it '
        'once', (tester) async {
      await start(tester);
      await streamOverFerret(tester);
      await pumpStage(tester);

      await tester.tap(find.text('View only'));
      await tester.pump();
      expect(
        find.text(
          'Pixel shares its picture, not its controls. To click and type, '
          'plug it in.',
        ),
        findsOneWidget,
      );
      expect(find.text('How'), findsOneWidget);

      await tester.tapAt(const Offset(4, 4));
      await tester.pump();
      await tester.tap(find.byType(Texture));
      await tester.pump();
      expect(find.byType(StageNoticeBar), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();
      await tester.tap(find.byType(Texture));
      await tester.pump();
      expect(find.byType(StageNoticeBar), findsNothing, reason: 'said once');
    });

    testWidgets('Stop ends it on both devices and closes the stage', (
      tester,
    ) async {
      await start(tester);
      await streamOverFerret(tester);
      await pumpStage(tester);

      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();

      expect(
        pixel.sentOf<Stop>().single.reason,
        StopReason.STOP_REASON_VIEWER_DONE,
      );
      expect(closed, 1);
    });

    testWidgets('the numbers sit behind the quality mark, with three '
        'presets', (tester) async {
      await start(tester);
      await streamOverFerret(tester);
      await pumpStage(tester);

      await tester.tap(find.byType(QualityMark));
      await tester.pump();

      expect(find.text('Picture'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Sharp'), findsOneWidget);
      expect(find.text('Fast'), findsOneWidget);
      expect(find.textContaining('H.264 · 1080×2400'), findsOneWidget);
      expect(
        find.text(
          'Pixel has to say yes again for a change, so it applies next time.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Fast'));
      await tester.pump();
      expect(MirroringSettings(host.settings).quality, QualityPreset.fast);
      expect(pixel.requests, hasLength(1), reason: 'the phone is not re-asked');
    });

    testWidgets('the screen going off dims the picture and says so', (
      tester,
    ) async {
      await start(tester);
      await streamOverFerret(tester);
      await pumpStage(tester);

      ferret().onSourceState(pixel, SourceState(screenOff: true));
      await tester.pump();
      await tester.pump();

      expect(find.text("Pixel's screen is off"), findsOneWidget);
      expect(find.byType(Texture), findsOneWidget);
      expect(find.text('Wake'), findsNothing, reason: 'view only');
    });

    testWidgets('a dropped connection keeps the picture and says it is '
        'reconnecting; after 20 seconds the phone is lost, and Stop still '
        'works', (tester) async {
      await start(tester);
      await streamOverFerret(tester);
      await pumpStage(tester);

      host.setSessions([]);
      ferret().onSessionClosed('pixel');
      await tester.pump();
      await tester.pump();

      expect(find.text('Reconnecting to Pixel…'), findsOneWidget);
      expect(find.byType(Texture), findsOneWidget);
      expect(find.text('Try again'), findsNothing);

      await wait(tester, const Duration(seconds: 21));

      expect(find.text('Lost Pixel'), findsOneWidget);
      expect(
        find.text('This picks up again when Pixel is back.'),
        findsOneWidget,
      );
      expect(find.byType(Texture), findsNothing);

      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();
      expect(feature.viewer?.current?.end, ViewEnd.stoppedHere);
      expect(closed, 1);
    });
  });

  group('how it ended', () {
    testWidgets('a no: Ask again waits out the half minute the phone turns '
        'this computer away', (tester) async {
      await start(tester);
      await viewModel.show('pixel', 'Pixel');
      ferret().onDeny(pixel, StartDeny(reason: .DENY_REASON_DENIED));
      await pumpStage(tester);

      expect(find.text('Pixel said no'), findsOneWidget);
      expect(find.text('You can ask again in 0:30.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);

      await tester.tap(find.text('Ask again'));
      await tester.pump();
      expect(pixel.requests, hasLength(1), reason: 'not yet');

      await wait(tester, const Duration(seconds: 31));
      expect(find.textContaining('You can ask again in'), findsNothing);

      await tester.tap(find.text('Ask again'));
      await tester.pump();
      await tester.pump();
      expect(pixel.requests, hasLength(2));
      expect(find.text('Answer on Pixel'), findsOneWidget);
    });

    for (final (reason, title, button) in [
      (
        StopReason.STOP_REASON_STOPPED_ON_SOURCE,
        'Stopped on Pixel',
        'Show again',
      ),
      (
        StopReason.STOP_REASON_SYSTEM_ENDED,
        'Pixel stopped sharing',
        'Show again',
      ),
      (StopReason.STOP_REASON_FAILED, 'The picture stopped', 'Try again'),
    ]) {
      testWidgets('the phone ending with ${reason.name} says "$title" with '
          '$button', (tester) async {
        await start(tester);
        await streamOverFerret(tester);
        await pumpStage(tester);

        ferret().onStop(pixel, Stop(reason: reason));
        await tester.pump();
        await tester.pump();

        expect(find.text(title), findsOneWidget);
        expect(find.text(button), findsOneWidget);
        expect(find.byType(Texture), findsNothing);

        await tester.tap(find.text('Close'));
        expect(closed, 1);
      });
    }

    testWidgets('nobody answered: Ask again, not Try again', (tester) async {
      await start(tester);
      await viewModel.show('pixel', 'Pixel');
      ferret().onDeny(pixel, StartDeny(reason: .DENY_REASON_TIMEOUT));
      await pumpStage(tester);

      expect(find.text('Nobody answered on Pixel'), findsOneWidget);
      expect(find.text('Ask again'), findsOneWidget);
    });

    testWidgets('leaving the stage forgets an attempt that is over', (
      tester,
    ) async {
      await start(tester);
      await viewModel.show('pixel', 'Pixel');
      ferret().onDeny(pixel, StartDeny(reason: .DENY_REASON_TIMEOUT));
      await pumpStage(tester);

      await viewModel.leaveStage('pixel');

      expect(feature.viewer?.current, isNull);
    });

    testWidgets('leaving the stage stops a screen that is shown: nothing '
        'shares from a closed page', (tester) async {
      await start(tester);
      await streamOverFerret(tester);
      await pumpStage(tester);

      await viewModel.leaveStage('pixel');

      expect(pixel.sentOf<Stop>(), hasLength(1));
      expect(feature.viewer?.current, isNull);
    });
  });

  group('a paired phone that is not connected', () {
    testWidgets('gets its two ways in, and starts by itself when it '
        'connects', (tester) async {
      await start(tester, connected: false);
      await viewModel.show('pixel', 'Pixel');
      await pumpStage(tester);

      expect(find.text("Pixel isn't connected"), findsOneWidget);
      expect(
        find.text('This starts by itself when Pixel connects.'),
        findsOneWidget,
      );
      expect(find.text('Plug Pixel into this computer'), findsOneWidget);
      expect(find.text('How'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);

      host.setSessions([pixel]);
      await tester.pump();
      await tester.pump();

      expect(pixel.requests, hasLength(1));
      expect(find.text('Answer on Pixel'), findsOneWidget);
    });

    testWidgets('How opens the cable steps, which tick themselves and start '
        'the picture when the phone answers', (tester) async {
      await start(tester, connected: false);
      cable.statusNow = const RouteNeedsSetup(.enableDebugging);
      await viewModel.show('pixel', 'Pixel');
      await pumpStage(tester);

      await tester.tap(find.text('How'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Show Pixel with a cable'), findsOneWidget);
      expect(find.text('Turn on USB debugging'), findsOneWidget);
      expect(find.text('2. Tap Build number 7 times'), findsOneWidget);
      expect(find.text('Waiting for the phone…'), findsOneWidget);
      expect(find.textContaining('without asking'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Check again'), findsNothing);
      expect(
        MirroringSettings(host.settings).lookForCable,
        isTrue,
        reason: 'opening the steps turns the looking on',
      );
      expect(find.byIcon(LucideIcons.circleCheck), findsNothing);

      await tester.tap(find.text('Samsung, Xiaomi, others'));
      await tester.pump();
      expect(find.textContaining('Security settings'), findsOneWidget);

      cable.statusNow = const RouteNeedsSetup(
        .authorizeComputer,
        detail: 'Pixel 7',
      );
      await wait(tester, const Duration(seconds: 2));
      expect(
        find.text(
          'On Pixel 7: tap Allow. Tick Always allow from this computer.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.circleCheck), findsNWidgets(2));
      expect(find.text('2. Tap Build number 7 times'), findsNothing);

      cable
        ..statusNow = const RouteReady()
        ..find([cable.target('2A13', 'Pixel 7')]);
      await wait(tester, const Duration(seconds: 2));
      await tester.pump();

      expect(cable.feeds, hasLength(1), reason: 'no button to press');
      cable.feeds.single.play();
      await tester.pump();
      await tester.pump();
      expect(find.byType(Texture), findsOneWidget);
      expect(viewModel.sessionFor('pixel')?.way, MirrorWay.cable);
    });

    testWidgets('a cable that only charges is doubted after 20 seconds', (
      tester,
    ) async {
      await start(tester, connected: false);
      cable.statusNow = const RouteNeedsSetup(.enableDebugging);
      viewModel.openCableGuide('pixel');
      await pumpStage(tester);
      expect(find.textContaining('Many cables only charge'), findsNothing);

      await wait(tester, const Duration(seconds: 22));

      expect(
        find.text('Many cables only charge. Try another one.'),
        findsOneWidget,
      );
    });

    testWidgets('the helper tool is its own first step: fetched only on a '
        'click, with words that say from where', (tester) async {
      await start(tester, connected: false);
      cable.statusNow = const RouteNeedsSetup(.installTool, detail: 'adb');
      viewModel.openCableGuide('pixel');
      await pumpStage(tester);
      await tester.pump();

      expect(find.text("Get Android's helper tool"), findsOneWidget);
      expect(find.textContaining('from Google, about 16 MB'), findsOneWidget);
      expect(cable.installs, 0);

      cable.failDownload = true;
      await tester.tap(find.text('Download'));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining("The download didn't finish"), findsOneWidget);

      cable
        ..failDownload = false
        ..statusNow = const RouteNeedsSetup(.installTool, detail: 'adb');
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(cable.installs, 2);
      expect(find.text("Get Android's helper tool"), findsNothing);
    });

    testWidgets('a tool only the owner can start gets start words and no '
        'download', (tester) async {
      await start(tester, connected: false);
      cable.statusNow = const RouteNeedsSetup(
        .installTool,
        detail: FakeToolRoute.notStarted,
      );
      viewModel.openCableGuide('pixel');
      await pumpStage(tester);
      await tester.pump();

      expect(find.text("Start Android's helper tool"), findsOneWidget);
      expect(find.text('Download'), findsNothing);
    });
  });

  group('a phone on a cable', () {
    testWidgets('has the phone\'s keys on the toolbar, and each presses its '
        'button', (tester) async {
      await start(tester, lookForCable: true);
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );

      expect(find.text('View only'), findsNothing);
      await tester.tap(tool(LucideIcons.chevronLeft));
      await tester.tap(tool(LucideIcons.circle));
      await tester.tap(tool(LucideIcons.square));
      await tester.tap(tool(LucideIcons.rotateCw));

      expect(control.pressed, const <DeviceButton>[
        .back,
        .home,
        .recents,
        .rotate,
      ]);
    });

    testWidgets('volume, power and the notifications panel wait behind '
        'More', (tester) async {
      await start(tester, lookForCable: true);
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );

      await tester.tap(tool(LucideIcons.ellipsis));
      await tester.pump();
      expect(find.text('Notifications panel'), findsOneWidget);
      expect(find.text('Power'), findsOneWidget);

      await tester.tap(find.text('Volume up'));
      await tester.pump();

      expect(control.pressed, const <DeviceButton>[.volumeUp]);
      expect(find.text('Volume up'), findsNothing, reason: 'the menu closed');
    });

    testWidgets('says once that a cable doesn\'t ask each time', (
      tester,
    ) async {
      await start(tester, lookForCable: true);
      final target = await streamOverCable(tester);
      final deviceId = ViewSession.deviceIdOf(target);
      await pumpStage(tester, deviceId: deviceId, deviceName: 'Old tablet');

      expect(
        find.text(
          "Over a cable, Old tablet doesn't ask each time. Only do this "
          'with your own phone.',
        ),
        findsOneWidget,
      );

      await wait(tester, const Duration(seconds: 11));
      expect(find.byType(StageNoticeBar), findsNothing);

      await viewModel.stop();
      await viewModel.showTarget(target);
      cable.feeds.last.play();
      await tester.pump();
      await tester.pump();
      expect(find.byType(StageNoticeBar), findsNothing, reason: 'said once');
    });

    testWidgets('a click is a touch at the same spot of the picture, a '
        'right-click is Back, a middle-click is Home', (tester) async {
      await start(tester, lookForCable: true);
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );
      final picture = tester.getRect(find.byType(Texture));
      final spot = picture.topLeft + picture.size.centerRight(Offset.zero) / 2;

      final click = await tester.startGesture(
        picture.topLeft + Offset(picture.width / 4, picture.height / 2),
        kind: .mouse,
      );
      await click.up();
      expect(
        [for (final event in control.pointers) event.phase],
        const [
          PointerPhase.down,
          PointerPhase.up,
        ],
      );
      expect(control.pointers.first.x, closeTo(0.25, 0.01));
      expect(control.pointers.first.y, closeTo(0.5, 0.01));
      control.pointers.clear();

      final right = await tester.startGesture(
        spot,
        kind: .mouse,
        buttons: kSecondaryMouseButton,
      );
      await right.up();
      final middle = await tester.startGesture(
        spot,
        kind: .mouse,
        buttons: kMiddleMouseButton,
      );
      await middle.up();

      expect(control.pressed, const <DeviceButton>[.back, .home]);
      expect(control.pointers, isEmpty, reason: 'not a touch');
    });

    testWidgets('the wheel scrolls, and so do two fingers on a trackpad', (
      tester,
    ) async {
      await start(tester, lookForCable: true);
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );
      final center = tester.getCenter(find.byType(Texture));

      final mouse = TestPointer(1, .mouse);
      await tester.sendEventToBinding(mouse.hover(center));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 100)));
      expect(control.pointers.single.phase, PointerPhase.scroll);
      expect(control.pointers.single.scrollY, 2);
      control.pointers.clear();

      final trackpad = TestPointer(2, .trackpad);
      await tester.sendEventToBinding(trackpad.panZoomStart(center));
      await tester.sendEventToBinding(
        trackpad.panZoomUpdate(center, pan: const Offset(0, -50)),
      );
      await tester.sendEventToBinding(trackpad.panZoomEnd());

      final scroll = control.pointers.single;
      expect(scroll.phase, PointerPhase.scroll);
      expect(scroll.scrollY, 1, reason: 'fingers up scrolls down');
      expect(scroll.x, closeTo(0.5, 0.01));
    });

    testWidgets('typing types text, the shortcut key pastes this '
        'computer\'s clipboard, Escape is Back', (tester) async {
      await start(tester, lookForCable: true);
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );
      await tester.pump();

      await tester.sendKeyEvent(.keyA, character: 'a');
      expect(control.typed, ['a']);
      expect(
        control.keys,
        isEmpty,
        reason: 'neither the press nor the release',
      );

      await tester.sendKeyEvent(.enter);
      expect(
        [for (final key in control.keys) key.phase],
        const [
          KeyPhase.down,
          KeyPhase.up,
        ],
      );

      clipboard = 'from the Mac 🦊';
      await tester.sendKeyDownEvent(.control);
      await tester.sendKeyEvent(.keyV);
      await tester.sendKeyUpEvent(.control);
      await tester.pump();
      expect(control.pasted, ['from the Mac 🦊']);

      await tester.sendKeyEvent(.escape);
      expect(control.pressed, const <DeviceButton>[.back]);
    });

    testWidgets('the keyboard field sends composed text, accents and emoji '
        'through the clipboard', (tester) async {
      await start(tester, lookForCable: true);
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );

      await tester.tap(tool(LucideIcons.keyboard));
      await tester.pump();
      expect(find.text('Type or paste, then press Enter'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'héllo');
      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'plain');
      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(control.pasted, ['héllo']);
      expect(control.typed, ['plain']);
    });

    testWidgets('a screen that is off can be woken', (tester) async {
      await start(tester, lookForCable: true);
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );

      cable.feeds.single.emit(const FeedSourceState(screenOff: true));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Wake'));

      expect(control.pressed, const <DeviceButton>[.power]);
    });

    testWidgets('a new preset restarts the picture at once', (tester) async {
      await start(tester, lookForCable: true);
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );

      await tester.tap(find.byType(QualityMark));
      await tester.pump();
      expect(find.text('Changing it restarts the picture.'), findsOneWidget);
      await tester.tap(find.text('Fast'));
      await tester.pump();
      await tester.pump();

      expect(cable.feeds, hasLength(2));
      expect(cable.options.last.maxSize, 1600);
      expect(find.byType(Texture), findsOneWidget, reason: 'the frame holds');
    });
  });

  group('a paired phone that is also plugged in', () {
    testWidgets('goes over Ferret, and the chip offers the cable to click '
        'and type', (tester) async {
      await start(tester, lookForCable: true);
      cable.find([cable.target('2A13', 'Pixel')]);
      await tester.pump();
      await streamOverFerret(tester);
      await pumpStage(tester);
      expect(viewModel.sessionFor('pixel')?.way, MirrorWay.wifi);

      await tester.tap(find.text('View only'));
      await tester.pump();
      await tester.tap(find.text('Control with the cable'));
      await tester.pump();
      cable.feeds.single.play();
      await tester.pump();
      await tester.pump();

      expect(pixel.sentOf<Stop>(), hasLength(1));
      expect(viewModel.sessionFor('pixel')?.way, MirrorWay.cable);
      expect(find.text('View only'), findsNothing);
      expect(tool(LucideIcons.chevronLeft), findsOneWidget);
    });

    testWidgets('says "over the cable instead" when Ferret could not ask', (
      tester,
    ) async {
      await start(
        tester,
        lookForCable: true,
        answer: (_) => StartDeny(reason: .DENY_REASON_CANNOT_ASK),
      );
      await tester.runAsync(
        () => MirroringSettings(host.settings).addCableTold('2A13'),
      );
      cable.find([cable.target('2A13', 'Pixel')]);
      await tester.pump();
      await viewModel.show('pixel', 'Pixel');
      await tester.pump();
      cable.feeds.single.play();
      await pumpStage(tester);
      await tester.pump();

      expect(find.text('Showing over the cable instead.'), findsOneWidget);
    });
  });

  group('the toolbar', () {
    testWidgets('floats over the picture and hides when the pointer rests, '
        'but never while the pointer is on it', (tester) async {
      await start(tester);
      await streamOverFerret(tester);
      await pumpStage(tester);
      double opacity() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
      expect(opacity(), 1, reason: 'seen once when the picture appears');

      await tester.pump(const Duration(seconds: 4));
      expect(opacity(), 0);

      final mouse = await tester.createGesture(kind: .mouse);
      await mouse.addPointer(location: const Offset(200, 300));
      await mouse.moveTo(const Offset(210, 310));
      await tester.pump();
      expect(opacity(), 1);

      await mouse.moveTo(tester.getCenter(find.byType(MirrorToolbar)));
      await tester.pump(const Duration(seconds: 5));
      expect(opacity(), 1, reason: 'the pointer is on it');

      await mouse.moveTo(const Offset(200, 300));
      await tester.pump(const Duration(seconds: 3));
      expect(opacity(), 0);
    });

    testWidgets('"Keep toolbar visible" docks it under the picture for '
        'good', (tester) async {
      await start(tester);
      await streamOverFerret(tester);
      await pumpStage(tester);
      final floating = tester.getRect(find.byType(Texture));

      await tester.tap(tool(LucideIcons.ellipsis));
      await tester.pump();
      await tester.tap(find.text('Keep toolbar visible'));
      await tester.pump();
      await tester.pump();

      expect(MirroringSettings(host.settings).toolbarPinned, isTrue);
      expect(find.byType(IdleFade), findsNothing);
      final docked = tester.getRect(find.byType(Texture));
      final toolbar = tester.getRect(find.byType(MirrorToolbar));
      expect(docked.height, lessThan(floating.height));
      expect(toolbar.top, greaterThanOrEqualTo(docked.bottom));
    });

    testWidgets('stands beside the picture with words where the stage is '
        'wider than tall', (tester) async {
      await start(tester, lookForCable: true, size: wideWindow);
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recents'), findsOneWidget);
      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.byType(IdleFade), findsNothing);
      expect(
        tester.getRect(find.byType(MirrorToolbar)).left,
        greaterThanOrEqualTo(tester.getRect(find.byType(Texture)).right),
      );
    });

    testWidgets('full screen only where the window can', (tester) async {
      await start(tester, canFullScreen: true);
      await streamOverFerret(tester);
      await viewModel.refreshWindow();
      await pumpStage(tester);

      await tester.tap(tool(LucideIcons.maximize));
      await tester.pump();

      expect(window.fullScreen, isTrue);
      expect(tool(LucideIcons.minimize), findsOneWidget);
    });

    testWidgets('folds what is used least behind More when it gets '
        'narrow', (tester) async {
      await start(tester, lookForCable: true, size: const Size(320, 700));
      final target = await streamOverCable(tester);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(target),
        deviceName: 'Old tablet',
      );

      expect(tool(LucideIcons.chevronLeft), findsOneWidget);
      expect(tool(LucideIcons.rotateCw), findsNothing);
      expect(tool(LucideIcons.keyboard), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(tool(LucideIcons.ellipsis));
      await tester.pump();
      await tester.tap(find.text('Rotate'));

      expect(control.pressed, const <DeviceButton>[.rotate]);
    });
  });

  group('a second phone', () {
    testWidgets('asks before it takes the place of the one on screen', (
      tester,
    ) async {
      await start(tester, lookForCable: true);
      await streamOverFerret(tester);
      final tablet = cable.target('R58', 'Old tablet');
      cable.find([tablet]);
      await tester.pump();

      await viewModel.showTarget(tablet);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(tablet),
        deviceName: 'Old tablet',
      );

      expect(
        find.text('Stop showing Pixel and show Old tablet?'),
        findsOneWidget,
      );
      expect(feature.viewer?.current?.deviceId, 'pixel');
      expect(cable.feeds, isEmpty);

      await tester.tap(find.text('Show Old tablet'));
      await tester.pump();
      await tester.pump();

      expect(pixel.sentOf<Stop>(), hasLength(1));
      expect(cable.feeds, hasLength(1));
    });

    testWidgets('Cancel leaves the first one showing', (tester) async {
      await start(tester, lookForCable: true);
      await streamOverFerret(tester);
      final tablet = cable.target('R58', 'Old tablet');
      cable.find([tablet]);
      await tester.pump();
      await viewModel.showTarget(tablet);
      await pumpStage(
        tester,
        deviceId: ViewSession.deviceIdOf(tablet),
        deviceName: 'Old tablet',
      );

      await tester.tap(find.text('Cancel'));
      await viewModel.leaveStage(ViewSession.deviceIdOf(tablet));

      expect(closed, 1);
      expect(feature.viewer?.current?.isMirroring, isTrue);
      expect(pixel.sentOf<Stop>(), isEmpty);
    });
  });

  group('an iPhone or iPad', () {
    Future<void> pumpGuide(WidgetTester tester) =>
        pumpStage(tester, deviceId: 'iphone', deviceName: "Simon's iPhone");

    testWidgets('gets the three steps with this computer\'s name, while it '
        'listens for two minutes', (tester) async {
      await start(tester);
      await viewModel.openAirplayGuide('iphone');
      await pumpGuide(tester);

      expect(find.text("On Simon's iPhone:"), findsOneWidget);
      expect(
        find.text('1. Open Control Center (swipe down from the top right)'),
        findsOneWidget,
      );
      expect(find.text('2. Tap Screen Mirroring'), findsOneWidget);
      expect(find.text('3. Pick “This device”'), findsOneWidget);
      expect(find.text('Listening… 2:00'), findsOneWidget);
      expect(find.textContaining('View only. No sound.'), findsOneWidget);
      expect(receiver.listeningAs, 'This device');

      await wait(tester, const Duration(minutes: 2, seconds: 1));

      expect(find.text('Nobody picked this computer'), findsOneWidget);
      expect(receiver.isListening, isFalse);

      await tester.tap(find.text('Listen again'));
      await tester.pump();
      await tester.pump();
      expect(receiver.isListening, isTrue);
      await viewModel.leaveStage('iphone');
    });

    testWidgets('the device that connects is confirmed right there, and '
        'its picture shows on the same stage', (tester) async {
      await start(tester);
      await viewModel.openAirplayGuide('iphone');
      await pumpGuide(tester);

      final answer = receiver.ask("Simon's iPhone");
      await tester.pump();
      await tester.pump();
      expect(find.text("Simon's iPhone is connecting"), findsOneWidget);
      expect(find.text('Not mine'), findsOneWidget);

      await tester.tap(find.text('Show'));
      expect(await answer, isTrue);
      final feed = FakeFeed(
        const MirrorTarget(
          routeId: 'airplay',
          id: 'aa:bb',
          name: "Simon's iPhone",
        ),
      );
      receiver.receive(feed);
      await tester.pump();
      feed.play();
      await tester.pump();
      await tester.pump();

      expect(find.byType(Texture), findsOneWidget);
      expect(find.text('View only'), findsOneWidget);
      expect(viewModel.sessionFor('iphone')?.way, MirrorWay.airplay);
      expect(viewModel.airplayGuideFor, isNull);
      await viewModel.leaveStage('iphone');
      await feature.routes?.disarmReceivers();
    });

    testWidgets('Not mine turns it away', (tester) async {
      await start(tester);
      await viewModel.openAirplayGuide('iphone');
      await pumpGuide(tester);
      final answer = receiver.ask('Stranger');
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Not mine'));

      expect(await answer, isFalse);
      await viewModel.leaveStage('iphone');
    });

    testWidgets('on a Mac the system does this already, and Ferret only '
        'listens when told to', (tester) async {
      await start(tester, systemMirrors: true);
      await viewModel.openAirplayGuide('iphone');
      await pumpGuide(tester);

      expect(find.text('Macs already do this'), findsOneWidget);
      expect(receiver.isListening, isFalse);

      await tester.tap(find.text('Use Ferret anyway'));
      await tester.pump();
      await tester.pump();

      expect(find.text('2. Tap Screen Mirroring'), findsOneWidget);
      expect(receiver.isListening, isTrue);
      await viewModel.leaveStage('iphone');
    });

    testWidgets('leaving the stage stops the listening', (tester) async {
      await start(tester);
      await viewModel.openAirplayGuide('iphone');
      await pumpGuide(tester);

      await viewModel.leaveStage('iphone');

      expect(receiver.isListening, isFalse);
      expect(viewModel.airplayGuideFor, isNull);
    });
  });

  group('what the app shows around the stage', () {
    late MirroringFeatureUi ui;
    late _Notifier notifier;
    late FeatureContext context;
    late int reveals;

    Future<void> startUi(WidgetTester tester, {bool on = true}) async {
      await start(tester, lookForCable: true);
      await tester.runAsync(
        () => MirroringSettings(host.settings).setReceiverOn('airplay', on),
      );
      await tester.pump();
      notifier = _Notifier();
      reveals = 0;
      ui = MirroringFeatureUi(feature: feature, window: window);
      context = FeatureContext(
        engine: _FakeEngine(),
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: notifier,
        onReveal: () async => reveals++,
      );
      await ui.onAppStarted(context);
      addTearDown(ui.dispose);
    }

    Future<List<ActivityItem>> activity(WidgetTester tester) async {
      late List<ActivityItem> items;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (buildContext) {
              items = ui.activity(buildContext, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return items;
    }

    testWidgets('no offer to "turn on" anything, and no card for a screen '
        'that is shown', (tester) async {
      await startUi(tester);
      late FeatureOffer? offer;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (buildContext) {
              offer = ui.offerFor(buildContext, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await ui.viewerViewModel.show('pixel', 'Pixel');

      expect(offer, isNull);
      expect(ui.hasHomeCard(context), isFalse);
    });

    testWidgets('a screen that is shown is a pinned Activity line with '
        'Stop, then a line that says how long it was', (tester) async {
      await startUi(tester);
      await ui.viewerViewModel.show('pixel', 'Pixel');
      ferret().onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
      await tester.pump();

      final live = (await activity(tester)).single;
      expect(live.title, "Showing Pixel's screen");
      expect(live.detail, 'Since 21:10 · Wi-Fi');
      expect(live.pinned, isTrue);
      expect(live.actions.single.label, 'Stop');

      now = now.add(const Duration(minutes: 12));
      live.actions.single.onPressed();
      await tester.pump();
      await tester.pump();

      final record = (await activity(tester)).single;
      expect(record.title, "You viewed Pixel's screen for 12 min at 21:10");
      expect(record.pinned, isFalse);

      record.onDismiss?.call();
      await tester.pump();
      expect(await activity(tester), isEmpty);
    });

    testWidgets('a device that asks by itself needs the person: a line '
        'with Show and Don\'t allow, a notice, and no page in the way', (
      tester,
    ) async {
      await startUi(tester);

      final answer = receiver.ask("Simon's iPhone");
      await tester.pump();

      final request = (await activity(tester)).single;
      expect(request.title, "Simon's iPhone wants to show its screen here");
      expect(request.needsYou, isTrue);
      expect(
        [for (final action in request.actions) action.label],
        [
          'Show',
          "Don't allow",
        ],
      );
      expect(reveals, 1);
      expect(
        notifier.shown.single.title,
        "Simon's iPhone wants to show its screen here",
      );

      request.actions.last.onPressed();
      await tester.pump();

      expect(await answer, isFalse);
      expect(await activity(tester), isEmpty);
      expect(notifier.cancelled, ['mirroring.request']);
    });

    testWidgets('the notice\'s own Show lets it in', (tester) async {
      await startUi(tester);
      final answer = receiver.ask("Simon's iPhone");
      await tester.pump();

      notifier.answers.add(
        const NoticeResponse(
          noticeId: 'mirroring.request',
          actionId: 'mirroring.show',
        ),
      );

      expect(await answer, isTrue);
    });

    testWidgets('phones on a cable that aren\'t paired get a card with '
        'Show screen; a paired one doesn\'t show there', (tester) async {
      await startUi(tester);
      cable.find([
        cable.target('R58', 'Old tablet'),
        cable.target('2A13', 'Pixel'),
      ]);
      await tester.pump();
      final shown = <MirrorTarget>[];
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: ui.viewerViewModel,
            child: ViewerCardFrame(onShow: shown.add),
          ),
        ),
      );

      expect(ui.hasHomeCard(context), isTrue);
      expect(find.text('Phones on a cable'), findsOneWidget);
      expect(find.text('Old tablet'), findsOneWidget);
      expect(find.text('Cable'), findsOneWidget);
      expect(find.text('Pixel'), findsNothing);
      expect(find.textContaining('experimental'), findsNothing);

      await tester.tap(find.text('Show screen'));
      expect(shown.single.id, 'R58');
    });

    testWidgets('settings are two switches, each marked Experimental, and '
        'no setup rows', (tester) async {
      await startUi(tester, on: false);
      cable.statusNow = const RouteNeedsSetup(.enableDebugging);
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (buildContext) =>
                ui.buildSettings(buildContext, context) ??
                const Text('no section'),
          ),
        ),
      );

      expect(find.text('Look for phones on a cable'), findsOneWidget);
      expect(
        find.text('Show iPhone and iPad screens here'),
        findsOneWidget,
      );
      expect(find.text('Experimental'), findsNWidgets(2));
      expect(find.textContaining('More ways'), findsNothing);
      expect(find.textContaining('needs one setting'), findsNothing);
      expect(find.text('Check again'), findsNothing);

      await tester.tap(find.byType(SwitchToggle).first);
      await tester.pumpAndSettle();
      expect(MirroringSettings(host.settings).lookForCable, isFalse);

      await tester.tap(find.byType(SwitchToggle).last);
      await tester.pumpAndSettle();
      expect(receiver.isListening, isTrue);
    });
  });
}
