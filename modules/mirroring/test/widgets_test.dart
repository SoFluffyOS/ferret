import 'dart:async';
import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:ferret_phone_control/testing.dart';
import 'package:ferret_power/testing.dart';
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
    AudioCaptureSupport sound = .unsupported,
    FakeControlService? controlService,
    FakeCamera? camera,
  }) async {
    final created = await tester.runAsync(FakeHost.create);
    if (created == null) {
      fail('The host should start');
    }

    host = created;
    mac = FakeSession('mac', name: 'MacBook', flags: const ['view']);
    host.sessions = [mac];
    capture = FakeCapture(supportNow: support)..soundNow = sound;
    now = DateTime(2026, 11, 18, 21, 10);
    final service = controlService;
    feature = MirroringFeature(
      capture: () => capture,
      phoneControl: switch (service) {
        null => null,
        final fake => () => PhoneControl(
          power: PowerCapabilities.withPlatform(FakePowerPlatform()),
          service: fake,
          supported: true,
        ),
      },
      camera: switch (camera) {
        null => null,
        final fake => () => fake,
      },
      canShare: true,
      canShareCamera: camera != null,
      canView: false,
      clock: () => now,
    );
    ui = MirroringFeatureUi(feature: feature);
    await feature.start(host);
  }

  Future<void> stream(WidgetTester tester, {Codec codec = .CODEC_H264}) async {
    final route = feature.routes?.ferret;
    if (route == null) {
      fail('The computer should be able to view');
    }

    await ui.viewerViewModel.show('pixel', 'Pixel');
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
    testWidgets('the phone can turn mirroring off and sees its history', (
      tester,
    ) async {
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
      expect(find.textContaining('needs root'), findsNothing);
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

    Future<void> pumpPhoneSettings(WidgetTester tester) => tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) =>
              ui.buildSettings(context, featureContext()) ??
              const SizedBox.shrink(),
        ),
      ),
    );

    testWidgets('"Send sound too" is off, says what it sends, and asks '
        'Android when it is turned on', (tester) async {
      await startPhone(tester, sound: .needsPermission);
      await pumpPhoneSettings(tester);

      expect(find.text('Send sound too'), findsOneWidget);
      expect(find.textContaining('never the microphone'), findsOneWidget);
      expect(find.textContaining('files it under Microphone'), findsOneWidget);
      expect(
        tester.widget<SwitchToggle>(find.byType(SwitchToggle).last).value,
        isFalse,
      );
      expect(capture.soundAsks, 0, reason: 'nothing is asked up front');

      await tester.tap(find.byType(SwitchToggle).last);
      await tester.pumpAndSettle();

      expect(capture.soundAsks, 1);
      expect(MirroringSettings(host.settings).sendSound, isTrue);
      expect(
        tester.widget<SwitchToggle>(find.byType(SwitchToggle).last).value,
        isTrue,
      );
    });

    testWidgets('a no from Android keeps it off and says where to change '
        'that', (tester) async {
      await startPhone(tester, sound: .needsPermission);
      capture.grantsSound = false;
      await pumpPhoneSettings(tester);

      await tester.tap(find.byType(SwitchToggle).last);
      await tester.pumpAndSettle();

      expect(MirroringSettings(host.settings).sendSound, isFalse);
      expect(find.textContaining('Android didn\'t allow it'), findsOneWidget);
    });

    testWidgets('an older Android says sound takes Android 10', (tester) async {
      await startPhone(tester);
      await pumpPhoneSettings(tester);

      expect(find.text('Send sound too'), findsNothing);
      expect(
        find.text('Sending sound takes Android 10 or newer.'),
        findsOneWidget,
      );
    });

    testWidgets('the card says when sound goes along', (tester) async {
      await startPhone(tester, sound: .ready);
      await feature.source?.setSendSound(true);
      await feature.source?.onRequest(
        mac,
        StartRequest(
          version: 1,
          codecs: const [.CODEC_H264],
          audioCodecs: const [.AUDIO_CODEC_OPUS],
        ),
      );
      await tester.pump();
      capture.answer(.granted);
      await tester.pump();
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) =>
                ui.buildHomeCard(context, featureContext()) ??
                const SizedBox.shrink(),
          ),
        ),
      );

      expect(
        find.text('Sharing screen and sound with MacBook'),
        findsOneWidget,
      );
      expect(find.textContaining('visible there, with sound'), findsOneWidget);
      await feature.source?.stop();
    });

    Future<void> pumpCard(WidgetTester tester) => tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) =>
              ui.buildHomeCard(context, featureContext()) ??
              const SizedBox.shrink(),
        ),
      ),
    );

    Future<void> shareWithMac(WidgetTester tester) async {
      await feature.source?.onRequest(
        mac,
        StartRequest(version: 1, codecs: const [.CODEC_H264]),
      );
      await tester.pump();
      capture.answer(.granted);
      await tester.pump();
    }

    testWidgets('a computer asking for control gets Always, Once and No, '
        'and Once shows who controls the phone, with Stop control', (
      tester,
    ) async {
      final service = FakeControlService(enabled: true);
      await startPhone(tester, controlService: service);
      await shareWithMac(tester);
      await feature.source?.control?.onAsk('mac');
      await pumpCard(tester);

      expect(
        find.text('Let MacBook control This device?'),
        findsOneWidget,
      );
      expect(find.text('Always'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      await tester.tap(find.text('Once'));
      await tester.pumpAndSettle();

      expect(find.text('Being controlled by MacBook'), findsOneWidget);
      expect(service.armed, isTrue);

      await tester.tap(find.text('Stop control'));
      await tester.pumpAndSettle();

      expect(service.armed, isFalse);
      expect(find.text('Sharing screen with MacBook'), findsOneWidget);
      await feature.source?.stop();
    });

    testWidgets('settings explain Ferret control before Android opens', (
      tester,
    ) async {
      final service = FakeControlService();
      await startPhone(tester, controlService: service);
      await pumpPhoneSettings(tester);

      expect(find.text('Control from a computer'), findsOneWidget);
      expect(
        find.textContaining('turn on Ferret control in Android'),
        findsOneWidget,
      );

      await tester.tap(find.text('Turn on Ferret control…'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('reads the text field you type into'),
        findsOneWidget,
      );
      expect(service.settingsOpened, 0, reason: 'explained first');

      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(service.settingsOpened, 1);
    });

    testWidgets('no Control section where nothing could control the '
        'phone', (tester) async {
      await startPhone(tester);
      await pumpPhoneSettings(tester);

      expect(find.text('Control from a computer'), findsNothing);
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

    testWidgets('a computer with nothing to switch and no history has no '
        'section', (tester) async {
      await startComputer(tester);
      await pumpComputerSettings(tester);

      expect(find.text('no section'), findsOneWidget);
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

    testWidgets('"Show screen" on every Android phone, connected or not, '
        'and health follows the last try', (tester) async {
      await startComputer(tester);
      final iphone = FakeSession('iphone', name: 'iPhone', flags: const []);
      final iphoneStatus = DeviceStatus(
        TrustedDevice(
          id: 'iphone',
          name: 'iPhone',
          platform: .PLATFORM_IOS,
          formFactor: .FORM_FACTOR_PHONE,
          publicKey: Uint8List(32),
          pairedAt: now,
        ),
        iphone,
      );
      final offline = DeviceStatus(status(pixel).device, null);
      late List<FeatureAction> offlineActions;
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
                iphoneStatus,
              );
              offlineActions = ui.deviceActions(
                buildContext,
                context,
                offline,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(pixelActions.single.label, 'Show screen');
      expect(pixelActions.single.homeOrder, 15, reason: 'after Send files');
      expect(offlineActions.single.label, 'Show screen');
      expect(iphoneActions, isEmpty, reason: 'nothing listens for it here');
      final untried = ui.healthFor(context, status(pixel));
      expect(untried?.state, FeatureHealthState.ok);
      expect(untried?.reason, 'Asks on Pixel every time');
      expect(ui.healthFor(context, iphoneStatus), isNull);

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

      await ui.viewerViewModel.show('pixel', 'Pixel');
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

    testWidgets('Screen is a section of the phone: the launcher first, the '
        'stage once Show screen opened the section', (tester) async {
      await startComputer(tester);
      final opened = <(String, String)>[];
      final context = featureContext(devices: [status(pixel)])
        ..onOpenSection = (deviceId, sectionId) async {
          opened.add((deviceId, sectionId));
        };
      late List<FeatureSection> sections;
      late List<FeatureAction> actions;
      await tester.pumpWidget(
        testApp(
          scroll: false,
          Builder(
            builder: (buildContext) {
              sections = ui.deviceSections(
                buildContext,
                context,
                status(pixel),
              );
              actions = ui.deviceActions(buildContext, context, status(pixel));
              return sections.single.builder(buildContext);
            },
          ),
        ),
      );

      final section = sections.single;
      expect(section.id, 'screen');
      expect(section.title, 'Screen');
      expect(section.order, 50);
      expect(section.fillsPane, isTrue);
      expect(find.text("See Pixel's screen on this computer"), findsOneWidget);
      expect(find.byType(MirrorPage), findsNothing);

      actions.single.onPressed?.call();
      await tester.pump();
      await tester.pump();

      expect(opened, [('pixel', 'screen')]);
      expect(find.byType(MirrorPage), findsOneWidget);
      expect(find.text("See Pixel's screen on this computer"), findsNothing);

      await ui.viewerViewModel.leaveStage('pixel');
      await tester.pump();

      expect(find.byType(MirrorPage), findsNothing);
      expect(find.text('Show screen'), findsOneWidget);
    });

    testWidgets('where the app has a window to give, Show screen opens one '
        'in the phone\'s shape, it turns with the phone, and the section '
        'says where things stand', (tester) async {
      await startComputer(tester);
      final windows = FakeWindows();
      final opened = <(String, String)>[];
      final context = featureContext(devices: [status(pixel)])
        ..windows = windows
        ..onOpenSection = (deviceId, sectionId) async {
          opened.add((deviceId, sectionId));
        };
      ui.stageWindow.attach(windows);
      late List<FeatureAction> actions;
      await tester.pumpWidget(
        testApp(
          scroll: false,
          ListenableBuilder(
            listenable: windows,
            builder: (buildContext, _) {
              actions = ui.deviceActions(buildContext, context, status(pixel));
              final section = ui
                  .deviceSections(buildContext, context, status(pixel))
                  .single;

              return Column(
                children: [
                  Expanded(child: section.builder(buildContext)),
                  if (windows.window case final window?)
                    Expanded(
                      key: ValueKey(window.id),
                      child: Builder(builder: window.builder),
                    ),
                ],
              );
            },
          ),
        ),
      );

      actions.single.onPressed?.call();
      await tester.pump();
      await tester.pump();

      expect(opened, isEmpty, reason: 'the stage is in its own window');
      expect(windows.window?.id, 'mirroring.pixel');
      expect(windows.window?.title, 'Pixel — Screen');
      expect(windows.shapes, [StageWindowViewModel.firstShape]);
      expect(find.byType(MirrorWindowPage), findsOneWidget);
      expect(find.byType(MirrorPage), findsNothing);
      expect(find.text("Pixel's screen has its own window"), findsOneWidget);

      final route = feature.routes?.ferret;
      if (route == null) {
        fail('The computer should be able to view');
      }

      void picture(int configId, int width, int height) {
        route
          ..onConfig(
            pixel,
            StreamConfig(
              configId: configId,
              codec: .CODEC_H264,
              width: width,
              height: height,
              sps: [0x67],
              pps: [0x68],
            ),
          )
          ..onFrame(
            pixel,
            Frame(
              configId: configId,
              sequence: Int64(configId),
              keyframe: true,
              data: [1],
            ),
          );
      }

      route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
      picture(1, 1080, 2400);
      await tester.pump();
      await tester.pump();

      expect(windows.shapes.last, const Size(1080, 2400));
      expect(find.text("Showing Pixel's screen"), findsOneWidget);

      picture(2, 2400, 1080);
      await tester.pump();
      await tester.pump();

      expect(windows.shapes.last, const Size(2400, 1080));

      final where = find.byType(ScreenStatusFrame);
      await tester.tap(
        find.descendant(of: where, matching: find.text('Bring to front')),
      );
      expect(windows.broughtToFront, 1);

      await tester.tap(
        find.descendant(of: where, matching: find.text('Stop')),
      );
      await tester.pump();
      await tester.pump();

      expect(windows.window, isNull);
      expect(find.byType(MirrorWindowPage), findsNothing);
      expect(ui.viewerViewModel.current?.isLive ?? false, isFalse);
      expect(find.text("See Pixel's screen on this computer"), findsOneWidget);
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

    testWidgets('a computer has no part until it has something to keep', (
      tester,
    ) async {
      await startComputer(tester);

      expect(await partsOf(tester, devices: [androidPhone]), isEmpty);

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
      final part = (await partsOf(tester)).single;

      expect(part.group, SettingsGroup.phone);
      expect(part.title, 'Screen');
      expect(part.isOn, isNull);
      expect(part.needsAttention, isFalse);
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

  group('this phone\'s camera for a computer', () {
    Future<void> pumpCard(WidgetTester tester) => tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: ui.shareViewModel,
          child: const ShareCardFrame(),
        ),
      ),
    );

    Future<void> askForCamera() => feature.onEnvelope(
      mac,
      envelopeOf(
        StartRequest(
          version: 1,
          codecs: const [.CODEC_H264],
          audioCodecs: const [.AUDIO_CODEC_OPUS],
          source: .SOURCE_CAMERA,
        ),
        expectsReply: true,
      ),
    );

    testWidgets('a computer asking gets Once, Always and No; Once turns the '
        'camera on with Stop, then leaves the audit line', (tester) async {
      final camera = FakeCamera();
      await startPhone(tester, camera: camera);
      var reveals = 0;
      final context = featureContext(onReveal: () async => reveals++);
      await ui.onAppStarted(context);

      await tester.runAsync(askForCamera);
      await pumpCard(tester);
      expect(find.text('MacBook wants to use your camera'), findsOneWidget);
      expect(find.text('Always'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(ui.hasHomeCard(context), isTrue);
      expect(ui.homeCardHoldsPrimary(context), isTrue);
      expect(reveals, 1);
      expect(camera.started, isEmpty);

      await tester.tap(find.text('Once'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Camera on for MacBook'), findsOneWidget);
      expect(find.textContaining('sees and hears'), findsOneWidget);
      expect(find.textContaining('Since 21:10'), findsOneWidget);
      expect(camera.texts.single.title, 'Camera on for MacBook');

      now = now.add(const Duration(minutes: 5));
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();

      expect(camera.stops, 1);
      expect(
        find.text("MacBook used this phone's camera for 5 min at 21:10"),
        findsOneWidget,
      );
      await tester.runAsync(ui.dispose);
    });

    testWidgets('with the microphone kept closed, the card says so', (
      tester,
    ) async {
      final camera = FakeCamera(microphoneGranted: false)
        ..grantsMicrophone = false;
      await startPhone(tester, camera: camera);
      await tester.runAsync(askForCamera);
      await feature.camera?.answer(.once);
      await pumpCard(tester);

      expect(find.textContaining('The microphone is off'), findsOneWidget);
      await feature.camera?.stop();
    });

    testWidgets('settings: computers may ask, and Ask every time forgets '
        'each Always', (tester) async {
      await startPhone(tester, camera: FakeCamera());
      await tester.runAsync(askForCamera);
      await feature.camera?.answer(.always);
      await feature.camera?.stop();
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) =>
                ui.buildSettings(context, featureContext()) ??
                const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('Camera for a computer'), findsOneWidget);
      expect(
        find.text('Let my computers ask to use this camera'),
        findsOneWidget,
      );
      expect(
        find.text('1 computer uses this camera without asking.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ask every time').last);
      await tester.pump();
      await tester.pump();

      expect(feature.camera?.alwaysAllowed, isEmpty);
      expect(
        find.text('1 computer uses this camera without asking.'),
        findsNothing,
      );
    });

    testWidgets('a phone without a camera has no Camera settings', (
      tester,
    ) async {
      await startPhone(tester, camera: FakeCamera(lenses: const []));
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) =>
                ui.buildSettings(context, featureContext()) ??
                const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('Camera for a computer'), findsNothing);
    });

    testWidgets('a computer offers "Use Pixel\'s camera" only for a phone '
        'that says it can send one', (tester) async {
      await startComputer(tester);
      final withCamera = FakeSession(
        'pixel',
        flags: const [MirroringFeature.shareFlag, MirroringFeature.cameraFlag],
      );
      final older = FakeSession('old', name: 'Old phone');
      host.sessions = [withCamera, older];
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
      final context = featureContext();
      late List<FeatureAction> pixelActions;
      late List<FeatureAction> olderActions;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (buildContext) {
              pixelActions = ui.deviceActions(
                buildContext,
                context,
                status(withCamera),
              );
              olderActions = ui.deviceActions(
                buildContext,
                context,
                status(older),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(pixelActions.map((action) => action.label), [
        'Show screen',
        "Use Pixel's camera",
      ]);
      expect(olderActions.map((action) => action.label), ['Show screen']);
    });
  });

  testWidgets('a finger on a computer\'s display is its mouse: a tap '
      'clicks where it lands, mouse and all', (tester) async {
    final actions = <InputAction>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: .ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 200,
            child: MirrorInput(
              abilities: const {
                ControlAbility.pointer,
                ControlAbility.keys,
                ControlAbility.mouse,
              },
              onAction: actions.add,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getTopLeft(find.byType(MirrorInput)) + const Offset(100, 50),
    );
    final pointers = [
      for (final action in actions)
        if (action is SendPointer) action.pointer,
    ];
    expect(
      [for (final pointer in pointers) pointer.phase],
      [PointerPhase.hover, PointerPhase.down, PointerPhase.up],
    );
    expect(pointers[1].x, closeTo(0.25, 0.0001));
    expect(pointers[1].y, closeTo(0.25, 0.0001));
  });
}
