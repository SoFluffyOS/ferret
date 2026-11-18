import 'dart:async';
import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';
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

void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeSession mac;
  late FakeDecoder decoder;
  late FakeCapture capture;
  late FakeWindow window;
  late MirroringFeature feature;
  late MirroringFeatureUi ui;
  late DateTime now;

  Future<void> startComputer(
    WidgetTester tester, {
    FutureOr<GeneratedMessage> Function(GeneratedMessage)? answer,
    bool canFullScreen = true,
  }) async {
    final created = await tester.runAsync(FakeHost.create);
    if (created == null) {
      fail('The host should start');
    }

    host = created;
    pixel = FakeSession(
      'pixel',
      answer: answer ?? (_) => StartPending(timeoutSeconds: 60),
    );
    host.sessions = [pixel];
    decoder = FakeDecoder();
    window = FakeWindow(can: canFullScreen);
    now = DateTime(2026, 11, 18, 21, 10);
    feature = MirroringFeature(
      decoder: () => decoder,
      codecs: const [.h264, .jpeg],
      canShare: false,
      canView: true,
      clock: () => now,
    );
    ui = MirroringFeatureUi(feature: feature, window: window);
    await feature.start(host);
    addTearDown(() async {
      await feature.viewer?.stop();
    });
  }

  Future<void> startPhone(
    WidgetTester tester, {
    CaptureSupport support = const CaptureSupport(h264: true, jpeg: true),
  }) async {
    final created = await tester.runAsync(FakeHost.create);
    if (created == null) {
      fail('The host should start');
    }

    host = created;
    mac = FakeSession('mac', name: 'MacBook', flags: const ['view']);
    host.sessions = [mac];
    capture = FakeCapture(supportNow: support);
    now = DateTime(2026, 11, 18, 21, 10);
    feature = MirroringFeature(
      capture: () => capture,
      canShare: true,
      canView: false,
      clock: () => now,
    );
    ui = MirroringFeatureUi(feature: feature);
    await feature.start(host);
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: ui.viewerViewModel,
          child: const MirrorPage(deviceId: 'pixel', deviceName: 'Pixel'),
        ),
        scroll: false,
      ),
    );
    await tester.pump();
  }

  Future<void> stream(WidgetTester tester, {Codec codec = .CODEC_H264}) async {
    final route = feature.routes?.ferret;
    if (route == null) {
      fail('The computer should be able to view');
    }

    await ui.viewerViewModel.start('pixel');
    route.onAccept(pixel, StartAccept(version: 1, codec: codec));
    route.onConfig(
      pixel,
      StreamConfig(
        configId: 1,
        codec: codec,
        width: 1080,
        height: 2400,
        sps: [0x67],
        pps: [0x68],
      ),
    );
    route.onFrame(
      pixel,
      Frame(configId: 1, sequence: Int64(0), keyframe: true, data: [1]),
    );
    await tester.pump();
  }

  FeatureContext featureContext({
    Future<void> Function()? onReveal,
    List<DeviceStatus> devices = const [],
  }) => FeatureContext(
    engine: _FakeEngine(devices),
    navigatorKey: GlobalKey<NavigatorState>(),
    notifier: _QuietNotifier(),
    onReveal: onReveal,
  );

  group('mirror page', () {
    testWidgets('asking: says so while the request is on its way', (
      tester,
    ) async {
      final reply = Completer<GeneratedMessage>();
      await startComputer(tester, answer: (_) => reply.future);
      unawaited(ui.viewerViewModel.start('pixel'));
      await pumpPage(tester);

      expect(find.text('Asking Pixel…'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('1:1'), findsNothing);

      reply.complete(StartDeny(reason: .DENY_REASON_BUSY));
      await tester.pump();
      await tester.pump();
      expect(find.text('Pixel is already sharing its screen'), findsOneWidget);
    });

    testWidgets('waiting: points at the phone, and Cancel takes the question '
        'back', (tester) async {
      await startComputer(tester);
      await ui.viewerViewModel.start('pixel');
      await pumpPage(tester);

      expect(find.text('Answer on Pixel'), findsOneWidget);
      expect(find.textContaining('On Pixel: Android asks'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump();

      expect(pixel.sentOf<Stop>(), hasLength(1));
      expect(find.text('Stopped on this computer'), findsOneWidget);
    });

    testWidgets('after the yes: waits for the first picture in words', (
      tester,
    ) async {
      await startComputer(tester);
      await ui.viewerViewModel.start('pixel');
      feature.routes?.ferret.onAccept(
        pixel,
        StartAccept(version: 1, codec: .CODEC_H264),
      );
      await pumpPage(tester);

      expect(find.text('Pixel said yes'), findsOneWidget);
      expect(find.text('Waiting for the first picture…'), findsOneWidget);
    });

    testWidgets('streaming: the texture, a status line with fps, latency and '
        'bitrate, and Stop', (tester) async {
      await startComputer(tester);
      await stream(tester);
      await pumpPage(tester);

      final texture = tester.widget<Texture>(find.byType(Texture));
      expect(texture.textureId, 7);
      expect(find.text('H.264 · 1080×2400 · 0 fps'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      final sent = pixel.sentOf<Stats>().single;
      now = now.add(const Duration(milliseconds: 30));
      feature.routes?.ferret.onStats(
        pixel,
        Stats(echoSentAtMs: sent.sentAtMs, bitrateKbps: 5200),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.text('H.264 · 1080×2400 · 1 fps · 15 ms · 5.2 Mbps'),
        findsOneWidget,
      );

      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(Texture), findsNothing);
      expect(find.text('Stopped on this computer'), findsOneWidget);
      expect(
        pixel.sentOf<Stop>().single.reason,
        StopReason.STOP_REASON_VIEWER_DONE,
      );
    });

    testWidgets('Fit and 1:1 switch the picture between the window and its '
        'real size', (tester) async {
      await startComputer(tester);
      await stream(tester);
      await pumpPage(tester);

      expect(find.byType(AspectRatio), findsOneWidget);

      await tester.tap(find.text('1:1'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Fit'), findsOneWidget);
      expect(find.byType(AspectRatio), findsNothing);
      final pixelRatio = tester.view.devicePixelRatio;
      expect(
        tester.getSize(find.byType(Texture)),
        Size(1080 / pixelRatio, 2400 / pixelRatio),
      );
      expect(MirroringSettings(host.settings).actualSize, isTrue);
    });

    testWidgets('full screen shows only where the window can, and leaving '
        'the page exits it', (tester) async {
      await startComputer(tester);
      await stream(tester);
      await pumpPage(tester);

      await tester.tap(find.text('Full screen'));
      await tester.pump();
      expect(window.fullScreen, isTrue);
      expect(find.text('Exit full screen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(window.fullScreen, isFalse);
      expect(
        feature.viewer?.current?.isMirroring,
        isTrue,
        reason: 'Back keeps mirroring',
      );
    });

    testWidgets('no full screen button in a window that can\'t', (
      tester,
    ) async {
      await startComputer(tester, canFullScreen: false);
      await stream(tester);
      await pumpPage(tester);

      expect(find.text('1:1'), findsOneWidget);
      expect(find.text('Full screen'), findsNothing);
    });

    testWidgets('the screen going off is said over the picture', (
      tester,
    ) async {
      await startComputer(tester);
      await stream(tester);
      await pumpPage(tester);

      feature.routes?.ferret.onSourceState(pixel, SourceState(screenOff: true));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining("Pixel's screen is off"), findsOneWidget);
      expect(find.byType(Texture), findsOneWidget);
    });

    testWidgets('a no explains itself, and Try again asks again', (
      tester,
    ) async {
      await startComputer(tester);
      await ui.viewerViewModel.start('pixel');
      feature.routes?.ferret.onDeny(
        pixel,
        StartDeny(reason: .DENY_REASON_DENIED),
      );
      await pumpPage(tester);

      expect(find.text('Pixel said no'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();

      expect(pixel.requests, hasLength(2));
      expect(find.text('Answer on Pixel'), findsOneWidget);
    });

    for (final (reason, title) in [
      (StopReason.STOP_REASON_STOPPED_ON_SOURCE, 'Stopped on Pixel'),
      (StopReason.STOP_REASON_SYSTEM_ENDED, 'Pixel stopped sharing'),
      (StopReason.STOP_REASON_FAILED, 'The picture stopped'),
    ]) {
      testWidgets('the phone ending with ${reason.name} says "$title"', (
        tester,
      ) async {
        await startComputer(tester);
        await stream(tester);
        await pumpPage(tester);

        feature.routes?.ferret.onStop(pixel, Stop(reason: reason));
        await tester.pump();
        await tester.pump();

        expect(find.text(title), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.byType(Texture), findsNothing);
      });
    }

    testWidgets('a lost connection says so', (tester) async {
      await startComputer(tester);
      await stream(tester);
      await pumpPage(tester);

      host.sessions = [];
      feature.routes?.ferret.onSessionClosed('pixel');
      await tester.pump();
      await tester.pump();

      expect(find.text('Lost the connection to Pixel'), findsOneWidget);
    });

    testWidgets('closing the page forgets an attempt that is over', (
      tester,
    ) async {
      await startComputer(tester);
      await ui.viewerViewModel.start('pixel');
      feature.routes?.ferret.onDeny(
        pixel,
        StartDeny(reason: .DENY_REASON_TIMEOUT),
      );
      await pumpPage(tester);
      expect(find.text('Nobody answered on Pixel'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(feature.viewer?.current, isNull);
    });
  });

  group('JPEG fallback picture', () {
    testWidgets('an image picture is drawn with RawImage', (tester) async {
      final image = await tester.runAsync(
        () => createTestImage(width: 4, height: 2),
      );
      if (image == null) {
        fail('The test image should be made');
      }

      await tester.pumpWidget(
        testApp(
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: MirrorSurface(
                picture: ImagePicture(image),
                actualSize: false,
              ),
            ),
          ),
        ),
      );

      expect(tester.widget<RawImage>(find.byType(RawImage)).image, image);
      expect(tester.getSize(find.byType(RawImage)), const Size(200, 100));
      await tester.pumpWidget(const SizedBox.shrink());
      image.dispose();
    });
  });

  group('computer card', () {
    Future<void> pumpCard(WidgetTester tester, List<ViewSession> opened) =>
        tester.pumpWidget(
          testApp(
            ChangeNotifierProvider.value(
              value: ui.viewerViewModel,
              child: ViewerCardFrame(onOpen: opened.add),
            ),
          ),
        );

    testWidgets('while a phone is shown: who, since when, Open and Stop; '
        'then the audit line', (tester) async {
      await startComputer(tester);
      final context = featureContext();
      expect(ui.hasHomeCard(context), isFalse);

      await stream(tester);
      final opened = <ViewSession>[];
      await pumpCard(tester, opened);

      expect(ui.hasHomeCard(context), isTrue);
      expect(find.text("Showing Pixel's screen"), findsOneWidget);
      expect(find.text('Since 21:10'), findsOneWidget);

      await tester.tap(find.text('Open'));
      expect(opened.single.deviceId, 'pixel');

      now = now.add(const Duration(minutes: 12));
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text("You viewed Pixel's screen for 12 min at 21:10"),
        findsOneWidget,
      );
      expect(ui.hasHomeCard(context), isTrue);

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();
      await tester.pump();
      expect(ui.hasHomeCard(context), isFalse);
    });

    testWidgets('while the phone asks: waiting, with Stop to give up', (
      tester,
    ) async {
      await startComputer(tester);
      await ui.viewerViewModel.start('pixel');
      await pumpCard(tester, []);

      expect(find.text('Waiting for Pixel'), findsOneWidget);
      expect(find.text("On Pixel: answer Android's prompt."), findsOneWidget);
    });
  });

  group('phone card', () {
    Future<void> pumpCard(WidgetTester tester) => tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: ui.shareViewModel,
          child: const ShareCardFrame(),
        ),
      ),
    );

    Future<void> ask() async {
      await feature.onEnvelope(
        mac,
        envelopeOf(
          StartRequest(version: 1, codecs: const [.CODEC_H264]),
          expectsReply: true,
        ),
      );
    }

    testWidgets('asking, then "Sharing screen with MacBook" with Stop, then '
        'the audit line', (tester) async {
      await startPhone(tester);
      var reveals = 0;
      final context = featureContext(onReveal: () async => reveals++);
      await ui.onAppStarted(context);
      expect(ui.hasHomeCard(context), isFalse);

      await ask();
      await pumpCard(tester);
      await tester.pump();
      expect(find.text('MacBook wants to see this screen'), findsOneWidget);
      expect(ui.hasHomeCard(context), isTrue);
      expect(reveals, 1);
      expect(
        capture.asked.single.sharingTitle,
        'Sharing screen with MacBook',
        reason: 'the system notice uses the app\'s words',
      );

      capture.answer(.granted);
      await tester.pump();
      await tester.pump();
      expect(find.text('Sharing screen with MacBook'), findsOneWidget);
      expect(find.textContaining('Since 21:10'), findsOneWidget);

      now = now.add(const Duration(minutes: 12));
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();

      expect(capture.stops, 1);
      expect(
        mac.sentOf<Stop>().single.reason,
        StopReason.STOP_REASON_STOPPED_ON_SOURCE,
      );
      expect(
        find.text("MacBook saw this phone's screen for 12 min at 21:10"),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();
      await tester.pump();
      expect(ui.hasHomeCard(context), isFalse);
      await tester.runAsync(ui.dispose);
    });

    testWidgets('a short look is told in seconds, a long one in hours', (
      tester,
    ) async {
      await startPhone(tester);
      final l10n = lookupMirroringLocalizations(const Locale('en'));
      MirrorRecord record(Duration length) => MirrorRecord(
        deviceId: 'mac',
        deviceName: 'MacBook',
        role: .shared,
        startedAt: now,
        endedAt: now.add(length),
        end: .viewerDone,
      );

      expect(
        l10n.audit(record(const Duration(seconds: 40))),
        "MacBook saw this phone's screen for 40 s at 21:10",
      );
      expect(
        l10n.audit(record(const Duration(minutes: 1))),
        "MacBook saw this phone's screen for 1 min at 21:10",
      );
      expect(
        l10n.audit(record(const Duration(minutes: 75))),
        "MacBook saw this phone's screen for 1 h 15 min at 21:10",
      );
    });
  });

  group('settings', () {
    testWidgets('the phone can turn mirroring off, sees the root note and '
        'its history', (tester) async {
      await startPhone(tester);
      await MirroringSettings(host.settings).addRecord(
        MirrorRecord(
          deviceId: 'mac',
          deviceName: 'MacBook',
          role: .shared,
          startedAt: now,
          endedAt: now.add(const Duration(minutes: 3)),
          end: .viewerDone,
        ),
      );
      late BuildContext buildContext;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              buildContext = context;
              return ui.buildSettings(context, featureContext()) ??
                  const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ui.title(buildContext), 'Screen');
      expect(
        find.text('Let my computers ask to see this screen'),
        findsOneWidget,
      );
      expect(find.textContaining('needs root'), findsOneWidget);
      expect(
        find.text("MacBook saw this phone's screen for 3 min at 21:10"),
        findsOneWidget,
      );

      await tester.tap(find.byType(SwitchToggle));
      await tester.pumpAndSettle();
      expect(MirroringSettings(host.settings).enabled, isFalse);

      await tester.tap(find.text('Clear history'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Nobody has seen this screen yet.'), findsOneWidget);
    });

    Future<void> pumpComputerSettings(
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

    testWidgets('a computer with no Android phone has no section', (
      tester,
    ) async {
      await startComputer(tester);
      await pumpComputerSettings(tester);

      expect(find.text('no section'), findsOneWidget);
    });

    testWidgets('a computer with a phone sees how to start', (tester) async {
      await startComputer(tester);
      await pumpComputerSettings(
        tester,
        devices: [
          DeviceStatus(
            TrustedDevice(
              id: 'pixel',
              name: 'Pixel',
              platform: .PLATFORM_ANDROID,
              formFactor: .FORM_FACTOR_PHONE,
              publicKey: Uint8List(32),
              pairedAt: now,
            ),
            null,
          ),
        ],
      );

      expect(find.textContaining('choose Show screen'), findsOneWidget);
      expect(find.text("You haven't mirrored a phone yet."), findsNothing);
    });

    testWidgets('a computer keeps showing what it mirrored', (tester) async {
      await startComputer(tester);
      await MirroringSettings(host.settings).addRecord(
        MirrorRecord(
          deviceId: 'pixel',
          deviceName: 'Pixel',
          role: .viewed,
          startedAt: now,
          endedAt: now.add(const Duration(minutes: 3)),
          end: .viewerDone,
        ),
      );
      await pumpComputerSettings(tester);

      expect(find.text('no section'), findsNothing);
      expect(find.text('Clear history'), findsOneWidget);
    });
  });

  group('device card', () {
    DeviceStatus status(FakeSession session) => DeviceStatus(
      TrustedDevice(
        id: session.remoteDeviceId,
        name: session.name,
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
        publicKey: Uint8List(32),
        pairedAt: now,
      ),
      session,
    );

    testWidgets('"Show screen" only on phones that can share, and health '
        'follows the last try', (tester) async {
      await startComputer(tester);
      final iphone = FakeSession('iphone', name: 'iPhone', flags: const []);
      final context = featureContext();
      late List<FeatureAction> pixelActions;
      late List<FeatureAction> iphoneActions;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (buildContext) {
              pixelActions = ui.deviceActions(
                buildContext,
                context,
                status(pixel),
              );
              iphoneActions = ui.deviceActions(
                buildContext,
                context,
                status(iphone),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(pixelActions.single.label, 'Show screen');
      expect(iphoneActions, isEmpty);
      final untried = ui.healthFor(context, status(pixel));
      expect(untried?.state, FeatureHealthState.ok);
      expect(untried?.reason, 'Asks on Pixel every time');
      expect(ui.healthFor(context, status(iphone)), isNull);

      var changes = 0;
      ui.uiChanges.addListener(() => changes++);
      await stream(tester);
      expect(
        ui.healthFor(context, status(pixel))?.state,
        FeatureHealthState.ok,
      );
      expect(changes, greaterThan(0));

      feature.routes?.ferret.onStop(pixel, Stop(reason: .STOP_REASON_FAILED));
      expect(
        ui.healthFor(context, status(pixel))?.state,
        FeatureHealthState.failing,
      );

      await ui.viewerViewModel.start('pixel');
      feature.routes?.ferret.onDeny(
        pixel,
        StartDeny(reason: .DENY_REASON_TURNED_OFF),
      );
      final health = ui.healthFor(context, status(pixel));
      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Off on Pixel');
      expect(
        health?.help,
        startsWith('On Pixel: open Ferret → Settings → To your computer'),
      );
    });

    testWidgets('a phone offers no "Show screen"', (tester) async {
      await startPhone(tester);
      late List<FeatureAction> actions;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (buildContext) {
              actions = ui.deviceActions(
                buildContext,
                featureContext(),
                status(mac),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(actions, isEmpty);
    });
  });

  group('settings parts', () {
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

    Future<List<FeatureSettings>> partsOf(
      WidgetTester tester, {
      List<DeviceStatus> devices = const [],
    }) async {
      late List<FeatureSettings> parts;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              parts = ui.settingsSections(
                context,
                featureContext(devices: devices),
              );
              return Column(children: [for (final part in parts) part.child]);
            },
          ),
        ),
      );

      return parts;
    }

    testWidgets('a phone has Screen under what it shares with a computer, '
        'on and marked Experimental', (tester) async {
      await startPhone(tester);

      final part = (await partsOf(tester)).single;

      expect(part.group, SettingsGroup.phone);
      expect(part.title, 'Screen');
      expect(part.summary, 'Asks every time');
      expect(part.isOn, isTrue);
      expect(part.needsAttention, isFalse);
      expect(find.text('Experimental'), findsOneWidget);
    });

    testWidgets('turned off on the phone reads Off, and the row hears about '
        'it', (tester) async {
      await startPhone(tester);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      await ui.shareViewModel.setEnabled(false);
      await tester.pump();
      final part = (await partsOf(tester)).single;

      expect(changes, greaterThan(0));
      expect(part.summary, 'Off');
      expect(part.isOn, isFalse);
      expect(part.needsAttention, isFalse);
    });

    testWidgets('a phone that cannot capture says so quietly', (tester) async {
      await startPhone(tester, support: const .none());

      final part = (await partsOf(tester)).single;
      final note = tester.widget<Text>(
        find.text("This phone can't capture its screen"),
      );

      expect(part.summary, "Can't capture");
      expect(part.isOn, isFalse);
      expect(part.needsAttention, isFalse);
      expect(note.style?.color, isNot(const Color(0xFFFF453A)));
    });

    testWidgets('a computer has no part until an Android phone is paired', (
      tester,
    ) async {
      await startComputer(tester);

      expect(await partsOf(tester), isEmpty);

      final part = (await partsOf(tester, devices: [androidPhone])).single;

      expect(part.group, SettingsGroup.phone);
      expect(part.title, 'Screen');
      expect(part.isOn, isNull);
      expect(part.needsAttention, isFalse);
      expect(find.text('Experimental'), findsOneWidget);
    });
  });

  group('what a computer may do on this phone', () {
    DeviceStatus status(FakeSession session) => DeviceStatus(
      TrustedDevice(
        id: session.remoteDeviceId,
        name: session.name,
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
        publicKey: Uint8List(32),
        pairedAt: now,
      ),
      session,
    );

    Future<List<DevicePermission>> permissionsFor(
      WidgetTester tester,
      FakeSession session,
    ) async {
      late List<DevicePermission> permissions;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              permissions = ui.devicePermissions(
                context,
                featureContext(),
                status(session),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      return permissions;
    }

    Future<GeneratedMessage?> ask() => feature.onEnvelope(
      mac,
      envelopeOf(
        StartRequest(version: 1, codecs: const [.CODEC_H264]),
        expectsReply: true,
      ),
    );

    testWidgets('a computer may ask until its switch is turned off, which '
        'also stops it at once', (tester) async {
      await startPhone(tester);
      final permission = (await permissionsFor(tester, mac)).single;
      expect(permission.label, "Ask to see this phone's screen");
      expect(permission.value, isTrue);
      expect(
        ui.healthFor(featureContext(), status(mac))?.reason,
        'Asks you every time',
      );

      await ask();
      capture.answer(.granted);
      await tester.pump();
      await tester.pump();
      expect(feature.source?.active?.deviceId, 'mac');
      expect(
        ui.healthFor(featureContext(), status(mac))?.reason,
        "Sees this phone's screen now",
      );

      permission.onChanged(false);
      await tester.pump();
      await tester.pump();

      expect(feature.source?.active, isNull);
      expect((await permissionsFor(tester, mac)).single.value, isFalse);
      expect(await ask(), isA<StartDeny>());
      final health = ui.healthFor(featureContext(), status(mac));
      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Off for MacBook');
      expect(health?.help, contains("Ask to see this phone's screen"));
    });

    testWidgets('with Screen off for everyone, the switch says where to turn '
        'it on', (tester) async {
      await startPhone(tester);
      await ui.shareViewModel.setEnabled(false);

      final permission = (await permissionsFor(tester, mac)).single;
      final health = ui.healthFor(featureContext(), status(mac));

      expect(permission.detail, contains('Settings → To your computer'));
      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Off on this phone');
      expect(health?.help, startsWith('Open Settings → To your computer'));
    });

    testWidgets('a device that cannot show a screen gets no switch, and a '
        'computer gives none', (tester) async {
      await startPhone(tester);
      final tablet = FakeSession('tablet', name: 'Tablet', flags: const []);

      expect(await permissionsFor(tester, tablet), isEmpty);
      expect(ui.healthFor(featureContext(), status(tablet)), isNull);

      await startComputer(tester);
      expect(await permissionsFor(tester, pixel), isEmpty);
    });
  });
}
