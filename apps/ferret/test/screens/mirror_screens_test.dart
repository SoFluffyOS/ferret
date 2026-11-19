// Renders every state of the mirror stage to temp/screens for review, at a
// narrow window, the popover and a wide window. Run from apps/ferret:
//
//   fvm flutter test test/screens/mirror_screens_test.dart
//
// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protocol/mirroring.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'support/mirror_fakes.dart';
import 'support/screen_fonts.dart';

const _ferretBlue = Color(0xFF0A66D6);
const _pixelRatio = 2.0;
final _directory = Directory('../../temp/screens');

/// A window the stage is rendered in.
class _Window {
  const _Window(this.name, this.width, this.height);

  final String name;
  final double width;
  final double height;
}

const _windows = [
  _Window('narrow', 390, 844),
  _Window('popover', 380, 560),
  _Window('window', 1000, 700),
];

/// Everything one screen needs: a computer with a paired Pixel, a cable
/// and a receiver, all in memory.
class _Rig {
  _Rig({
    required this.host,
    required this.pixel,
    required this.cable,
    required this.receiver,
    required this.feature,
    required this.viewModel,
  });

  final MirrorHost host;
  final MirrorSession pixel;
  final CableRoute cable;
  final AirReceiver receiver;
  final MirroringFeature feature;
  final ViewerViewModel viewModel;

  /// The stage's own window, as on a Mac.
  late final StageWindowViewModel stageWindow = StageWindowViewModel(viewModel)
    ..attach(_Windows());

  DateTime now = DateTime(2026, 11, 19, 21, 10);

  FerretRoute get ferret {
    final route = feature.routes?.ferret;
    if (route == null) {
      throw StateError('The computer should be able to view.');
    }

    return route;
  }

  Future<void> ask() => viewModel.show('pixel', 'Pixel 9');

  /// Ends what runs and every timer with it, so the test can finish.
  Future<void> letGo() async {
    final routes = feature.routes;
    for (final request in routes?.requests ?? const <IncomingRequest>[]) {
      routes?.answer(request, allow: false);
    }

    await viewModel.leaveStage('pixel');
    await feature.viewer?.stop();
    await routes?.disarmReceivers();
    stageWindow.dispose();
    viewModel.dispose();
  }

  /// The owner said yes and the first picture arrived over Ferret.
  Future<void> streamOverFerret({
    AudioAnswer sound = .AUDIO_ANSWER_UNSPECIFIED,
  }) async {
    await ask();
    ferret
      ..onAccept(
        pixel,
        StartAccept(version: 1, codec: .CODEC_H264, audio: sound),
      )
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
  }

  /// Pixel 9 plugged in with debugging allowed, shown over the cable.
  Future<void> streamOverCable() async {
    host.setSessions([]);
    cable.find([cable.target('2A13', 'Pixel 9')]);
    await Future<void>.microtask(() {});
    await ask();
    cable.feeds.last.play();
  }
}

/// One state of the stage: how to get there before the page shows, and
/// what to click once it does.
class _Screen {
  const _Screen(
    this.name, {
    this.before,
    this.after,
    this.deviceId = 'pixel',
    this.deviceName = 'Pixel 9',
    this.connected = true,
    this.systemMirrors = false,
    this.body,
    this.windows = _windows,
    this.turned = false,
  });

  final String name;
  final Future<void> Function(_Rig rig)? before;
  final Future<void> Function(WidgetTester tester, _Rig rig)? after;
  final String deviceId;
  final String deviceName;
  final bool connected;
  final bool systemMirrors;

  /// Shown in place of the mirror page, such as the settings.
  final Widget Function(_Rig rig)? body;

  /// The windows it is rendered in.
  final List<_Window> windows;

  /// The phone is turned on its side.
  final bool turned;
}

Finder _tool(IconData icon) => find.widgetWithIcon(ToolbarButton, icon);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

final _screens = <_Screen>[
  _Screen(
    'mirror_01_asking',
    before: (rig) async {
      rig.pixel.answer = (_) => Completer<StartPending>().future;
      unawaited(rig.ask());
    },
  ),
  _Screen('mirror_02_waiting', before: (rig) => rig.ask()),
  _Screen(
    'mirror_03_waiting_quiet',
    before: (rig) => rig.ask(),
    after: (tester, rig) async {
      rig.now = rig.now.add(const Duration(seconds: 12));
      await tester.pump(const Duration(seconds: 12));
    },
  ),
  _Screen(
    'mirror_04_said_yes',
    before: (rig) async {
      await rig.ask();
      rig.ferret.onAccept(
        rig.pixel,
        StartAccept(version: 1, codec: .CODEC_H264),
      );
    },
  ),
  _Screen('mirror_05_view_only', before: (rig) => rig.streamOverFerret()),
  _Screen(
    'mirror_06_view_only_why',
    before: (rig) => rig.streamOverFerret(),
    after: (tester, rig) => _tap(tester, find.text('View only')),
  ),
  _Screen(
    'mirror_07_view_only_cable_offer',
    before: (rig) async {
      rig.cable.find([rig.cable.target('2A13', 'Pixel 9')]);
      await rig.streamOverFerret();
    },
    after: (tester, rig) async {
      await _tap(tester, find.byType(RawImage));
    },
  ),
  _Screen('mirror_08_control', before: (rig) => rig.streamOverCable()),
  _Screen(
    'mirror_09_more',
    before: (rig) => rig.streamOverCable(),
    after: (tester, rig) => _tap(tester, _tool(LucideIcons.ellipsis)),
  ),
  _Screen(
    'mirror_10_quality',
    before: (rig) => rig.streamOverCable(),
    after: (tester, rig) async {
      final mark = find.byType(QualityMark);
      if (mark.evaluate().isEmpty) {
        await _tap(tester, _tool(LucideIcons.ellipsis));
        await _tap(tester, find.text('Picture'));
        return;
      }

      await _tap(tester, mark);
    },
  ),
  _Screen(
    'mirror_11_keyboard',
    before: (rig) async {
      await rig.streamOverCable();
      rig.viewModel.openTextField();
    },
    after: (tester, rig) async {
      await tester.enterText(find.byType(EditableText), 'Voilà 🦊');
      await tester.pump();
    },
  ),
  _Screen(
    'mirror_12_pinned',
    before: (rig) async {
      await rig.feature.settings.setToolbarPinned(true);
      await rig.streamOverCable();
    },
  ),
  _Screen(
    'mirror_13_screen_off',
    before: (rig) async {
      await rig.streamOverCable();
      rig.cable.feeds.last.emit(const FeedSourceState(screenOff: true));
    },
  ),
  _Screen(
    'mirror_14_reconnecting',
    before: (rig) async {
      await rig.streamOverFerret();
      rig.host.setSessions([]);
      rig.ferret.onSessionClosed('pixel');
    },
  ),
  _Screen(
    'mirror_15_lost',
    before: (rig) async {
      await rig.streamOverFerret();
      rig.host.setSessions([]);
      rig.ferret.onSessionClosed('pixel');
    },
    after: (tester, rig) async {
      rig.now = rig.now.add(const Duration(seconds: 21));
      await tester.pump(const Duration(seconds: 21));
    },
  ),
  _Screen(
    'mirror_16_slow',
    before: (rig) async {
      await rig.streamOverFerret();
      rig.ferret.onStats(
        rig.pixel,
        Stats(
          echoSentAtMs: Int64(
            rig.now
                .subtract(const Duration(milliseconds: 620))
                .millisecondsSinceEpoch,
          ),
          bitrateKbps: 2000,
          droppedFrames: 14,
        ),
      );
    },
    after: (tester, rig) async {
      rig.now = rig.now.add(const Duration(seconds: 6));
      rig.ferret.onStats(
        rig.pixel,
        Stats(
          echoSentAtMs: Int64(
            rig.now
                .subtract(const Duration(milliseconds: 620))
                .millisecondsSinceEpoch,
          ),
          bitrateKbps: 2000,
          droppedFrames: 14,
        ),
      );
      await tester.pump();
    },
  ),
  _Screen(
    'mirror_17_cable_first_time',
    before: (rig) async {
      rig.host.setSessions([]);
      final tablet = rig.cable.target('R58', 'Galaxy S24');
      rig.cable.find([tablet]);
      await Future<void>.microtask(() {});
      await rig.viewModel.showTarget(tablet);
      rig.cable.feeds.last.play();
    },
    deviceId: 'adb:R58',
    deviceName: 'Galaxy S24',
  ),
  _Screen(
    'mirror_18_said_no',
    before: (rig) async {
      await rig.ask();
      rig.ferret.onDeny(rig.pixel, StartDeny(reason: .DENY_REASON_DENIED));
    },
    after: (tester, rig) async {
      rig.now = rig.now.add(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 6));
    },
  ),
  _Screen(
    'mirror_19_stopped_on_phone',
    before: (rig) async {
      await rig.streamOverFerret();
      rig.ferret.onStop(
        rig.pixel,
        Stop(reason: .STOP_REASON_STOPPED_ON_SOURCE),
      );
    },
  ),
  _Screen(
    'mirror_20_failed',
    before: (rig) async {
      await rig.streamOverFerret();
      rig.ferret.onStop(rig.pixel, Stop(reason: .STOP_REASON_FAILED));
    },
  ),
  _Screen(
    'mirror_21_not_connected',
    connected: false,
    before: (rig) => rig.ask(),
  ),
  _Screen(
    'mirror_22_setup_debugging',
    connected: false,
    before: (rig) async {
      rig.cable.statusNow = const RouteNeedsSetup(.enableDebugging);
      rig.viewModel.openCableGuide('pixel');
    },
  ),
  _Screen(
    'mirror_23_setup_brands',
    connected: false,
    before: (rig) async {
      rig.cable.statusNow = const RouteNeedsSetup(.enableDebugging);
      rig.viewModel.openCableGuide('pixel');
    },
    after: (tester, rig) async {
      rig.now = rig.now.add(const Duration(seconds: 22));
      await tester.pump(const Duration(seconds: 2));
      await _tap(tester, find.text('Samsung, Xiaomi, others'));
    },
  ),
  _Screen(
    'mirror_24_setup_allow',
    connected: false,
    before: (rig) async {
      rig.cable.statusNow = const RouteNeedsSetup(
        .authorizeComputer,
        detail: 'Pixel 9',
      );
      rig.viewModel.openCableGuide('pixel');
    },
  ),
  _Screen(
    'mirror_25_setup_tool',
    connected: false,
    before: (rig) async {
      rig.cable.statusNow = const RouteNeedsSetup(.installTool, detail: 'adb');
      rig.viewModel.openCableGuide('pixel');
    },
  ),
  _Screen(
    'mirror_26_iphone_steps',
    deviceId: 'iphone',
    deviceName: 'Simon’s iPhone',
    before: (rig) => rig.viewModel.openAirplayGuide('iphone'),
  ),
  _Screen(
    'mirror_27_iphone_connecting',
    deviceId: 'iphone',
    deviceName: 'Simon’s iPhone',
    before: (rig) async {
      await rig.viewModel.openAirplayGuide('iphone');
      unawaited(rig.receiver.ask('Simon’s iPhone'));
    },
  ),
  _Screen(
    'mirror_28_iphone_on_mac',
    deviceId: 'iphone',
    deviceName: 'Simon’s iPhone',
    systemMirrors: true,
    before: (rig) => rig.viewModel.openAirplayGuide('iphone'),
  ),
  _Screen(
    'mirror_29_replace',
    deviceId: 'adb:R58',
    deviceName: 'Galaxy S24',
    before: (rig) async {
      await rig.streamOverFerret();
      final galaxy = rig.cable.target('R58', 'Galaxy S24');
      rig.cable.find([galaxy]);
      await Future<void>.microtask(() {});
      await rig.viewModel.showTarget(galaxy);
    },
  ),
  _Screen(
    'mirror_30_settings',
    body: (rig) => const _Listed(child: ViewerSettingsFrame()),
    before: (rig) async {
      await rig.feature.settings.addRecord(
        MirrorRecord(
          deviceId: 'pixel',
          deviceName: 'Pixel 9',
          role: .viewed,
          startedAt: rig.now.subtract(const Duration(minutes: 40)),
          endedAt: rig.now.subtract(const Duration(minutes: 28)),
          end: .viewerDone,
        ),
      );
    },
  ),
  _Screen(
    'mirror_31_launcher',
    body: (rig) => ScreenSectionPage(
      deviceId: 'pixel',
      deviceName: 'Pixel 9',
      onShow: () {},
    ),
  ),
  _Screen(
    'mirror_32_section_while_in_window',
    body: (rig) => ScreenSectionPage(
      deviceId: 'pixel',
      deviceName: 'Pixel 9',
      onShow: () {},
    ),
    before: (rig) async {
      await rig.streamOverFerret();
      await rig.stageWindow.open(
        deviceId: 'pixel',
        title: 'Pixel 9 — Screen',
        builder: (_) => const SizedBox.shrink(),
      );
    },
  ),
  _Screen(
    'mirror_33_own_window',
    body: _ownWindow,
    before: (rig) => rig.streamOverFerret(),
    windows: _uprightWindows,
  ),
  _Screen(
    'mirror_34_own_window_control',
    body: _ownWindow,
    before: (rig) => rig.streamOverCable(),
    windows: _uprightWindows,
  ),
  _Screen(
    'mirror_35_own_window_turned',
    body: _ownWindow,
    before: (rig) => rig.streamOverCable(),
    windows: _turnedWindows,
    turned: true,
  ),
  _Screen(
    'mirror_36_own_window_quiet',
    body: _ownWindow,
    before: (rig) => rig.streamOverCable(),
    after: (tester, rig) => tester.pump(const Duration(seconds: 4)),
    windows: _uprightWindows,
  ),
  _Screen(
    'mirror_37_own_window_notice',
    body: _ownWindow,
    before: (rig) async {
      await rig.streamOverCable();
      await rig.viewModel.screenshot();
    },
    windows: _uprightWindows,
  ),
  _Screen(
    'mirror_38_own_window_keyboard',
    body: _ownWindow,
    before: (rig) async {
      await rig.streamOverCable();
      rig.viewModel.openTextField();
    },
    windows: _uprightWindows,
  ),
  _Screen(
    'mirror_39_own_window_more',
    body: _ownWindow,
    before: (rig) => rig.streamOverCable(),
    after: (tester, rig) => _tap(tester, _tool(LucideIcons.ellipsis)),
    windows: _uprightWindows,
  ),
  _Screen(
    'mirror_40_turned',
    before: (rig) => rig.streamOverCable(),
    turned: true,
  ),
  _Screen(
    'mirror_41_turned_view_only',
    before: (rig) => rig.streamOverFerret(),
    turned: true,
  ),
  _Screen(
    'mirror_42_sound_cable',
    before: (rig) async {
      await rig.streamOverCable();
      rig.cable.feeds.last.emit(
        const FeedAudioConfigured(MirrorAudioConfig(codec: .opus)),
      );
    },
    after: _openSound,
  ),
  _Screen(
    'mirror_43_sound_on_phone',
    before: (rig) async {
      await rig.feature.settings.setSound(false);
      await rig.streamOverCable();
    },
    after: _openSound,
  ),
  _Screen(
    'mirror_44_sound_wifi',
    before: (rig) async {
      await rig.streamOverFerret(sound: .AUDIO_ANSWER_SENDING);
      rig.ferret.onAudioConfig(
        rig.pixel,
        AudioConfig(
          codec: .AUDIO_CODEC_OPUS,
          sampleRate: 48000,
          channels: 2,
        ),
      );
    },
    after: _openSound,
  ),
  _Screen(
    'mirror_45_sound_wifi_not_sent',
    before: (rig) => rig.streamOverFerret(sound: .AUDIO_ANSWER_OFF),
    after: _openSound,
  ),
  _Screen(
    'mirror_46_sound_too_old',
    before: (rig) async {
      await rig.streamOverCable();
      rig.cable.feeds.last.emit(const FeedAudioUnavailable(.unsupported));
    },
    after: _openSound,
  ),
  _Screen(
    'mirror_47_sound_own_window',
    body: _ownWindow,
    before: (rig) async {
      await rig.streamOverCable();
      rig.cable.feeds.last.emit(
        const FeedAudioConfigured(MirrorAudioConfig(codec: .opus)),
      );
    },
    after: _openSound,
    windows: _uprightWindows,
  ),
  _Screen(
    'mirror_48_control_ask',
    before: (rig) async {
      await rig.streamOverFerret();
      rig.ferret.onControlState(
        rig.pixel,
        ControlState(status: .CONTROL_STATUS_CAN_ASK),
      );
    },
  ),
  _Screen(
    'mirror_49_control_asking',
    before: (rig) async {
      await rig.streamOverFerret();
      rig.ferret.onControlState(
        rig.pixel,
        ControlState(status: .CONTROL_STATUS_CAN_ASK),
      );
    },
    after: (tester, rig) async {
      await tester.pump();
      rig.ferret.onControlState(
        rig.pixel,
        ControlState(status: .CONTROL_STATUS_ASKING, timeoutSeconds: 60),
      );
      await tester.pump();
    },
  ),
  _Screen(
    'mirror_50_control_allowed',
    before: (rig) async {
      await rig.streamOverFerret();
      rig.ferret.onControlState(
        rig.pixel,
        ControlState(status: .CONTROL_STATUS_CAN_ASK),
      );
    },
    after: (tester, rig) async {
      await tester.pump();
      rig.ferret.onControlState(
        rig.pixel,
        ControlState(
          status: .CONTROL_STATUS_ALLOWED,
          kinds: const [
            .CONTROL_KIND_POINTER,
            .CONTROL_KIND_KEYS,
            .CONTROL_KIND_TEXT,
            .CONTROL_KIND_BUTTONS,
          ],
          buttons: const [
            .CONTROL_BUTTON_BACK,
            .CONTROL_BUTTON_HOME,
            .CONTROL_BUTTON_RECENTS,
            .CONTROL_BUTTON_NOTIFICATIONS,
            .CONTROL_BUTTON_POWER,
            .CONTROL_BUTTON_VOLUME_UP,
            .CONTROL_BUTTON_VOLUME_DOWN,
          ],
        ),
      );
      await tester.pump();
    },
  ),
  _Screen(
    'mirror_51_control_needs_setup',
    before: (rig) async {
      await rig.streamOverFerret();
      rig.ferret.onControlState(
        rig.pixel,
        ControlState(status: .CONTROL_STATUS_NEEDS_SETUP),
      );
    },
    after: (tester, rig) => _tap(tester, find.text('View only')),
  ),
];

/// More, then Sound.
Future<void> _openSound(WidgetTester tester, _Rig rig) async {
  await _tap(tester, _tool(LucideIcons.ellipsis));
  await _tap(tester, find.text('Sound'));
}

/// The phone's own window as a Mac draws it: the bar on top, the picture
/// in its own shape under it.
Widget _ownWindow(_Rig rig) => MirrorWindowPage(
  deviceId: 'pixel',
  deviceName: 'Pixel 9',
  onClose: () {},
  clock: () => rig.now,
);

const _bar = 32.0;

/// The phone's window at the size it opens at, and at its smallest.
const _uprightWindows = [
  _Window('upright', 360, 360 * 2400 / 1080 + _bar),
  _Window('upright_small', 240, 240 * 2400 / 1080 + _bar),
];

const _turnedWindows = [
  _Window('turned', 800, 800 * 540 / 1200 + _bar),
];

/// The app's windows for features, as a Mac has them: one opens, and
/// stays open.
class _Windows extends ChangeNotifier implements FeatureWindows {
  FeatureWindow? _window;

  @override
  bool get canOpen => true;

  @override
  String? get openId => _window?.id;

  @override
  Future<bool> open(FeatureWindow window) async {
    _window = window;
    notifyListeners();
    return true;
  }

  @override
  Future<void> setContentSize(Size contentSize) async {}

  @override
  Future<void> bringToFront() async {}

  @override
  Future<void> startDrag() async {}

  @override
  Future<void> close() async {
    _window = null;
    notifyListeners();
  }
}

/// A frame as it sits on Home or in Settings: on the page's background,
/// with the page's margins.
class _Listed extends StatelessWidget {
  const _Listed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.palette.background,
    child: ListView(padding: EdgeInsets.all(Spacing.d12), children: [child]),
  );
}

void main() {
  ui.Image? drawn;
  ui.Image? drawnTurned;

  setUpAll(loadScreenFonts);

  for (final screen in _screens) {
    for (final window in screen.windows) {
      for (final brightness in Brightness.values) {
        testWidgets('${screen.name} ${window.name} ${brightness.name}', (
          tester,
        ) async {
          tester.view
            ..devicePixelRatio = 1
            ..physicalSize = Size(window.width, window.height);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(() {
            tester.view.reset();
            tester.platformDispatcher.clearPlatformBrightnessTestValue();
          });
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = .macOS;
          final reportError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed')) {
              debugPrint('screens: overflow in ${screen.name} ${window.name}');
              return;
            }

            reportError?.call(details);
          };
          try {
            final upright = drawn ??= await tester.runAsync(
              _drawPhoneScreen,
            );
            if (upright == null) {
              fail('The phone screen should be drawn.');
            }

            final phoneScreen = switch (screen.turned) {
              false => upright,
              true => drawnTurned ??= await tester.runAsync(
                () => _turn(upright),
              ),
            };
            if (phoneScreen == null) {
              fail('The turned phone screen should be drawn.');
            }

            await _run(tester, screen, window, brightness, phoneScreen);
          } finally {
            FlutterError.onError = reportError;
            debugDisableShadows = true;
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  }
}

Future<void> _run(
  WidgetTester tester,
  _Screen screen,
  _Window window,
  Brightness brightness,
  ui.Image phoneScreen,
) async {
  final rig = await _startRig(tester, screen, phoneScreen);
  await screen.before?.call(rig);
  await tester.pump();

  final boundary = GlobalKey();
  final page = switch (screen.body) {
    final body? => body(rig),
    null => MirrorPage(
      deviceId: screen.deviceId,
      deviceName: screen.deviceName,
      clock: () => rig.now,
    ),
  };
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: _App(
        brightness: brightness,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: rig.viewModel),
            ChangeNotifierProvider.value(value: rig.stageWindow),
          ],
          child: page,
        ),
      ),
    ),
  );
  for (var frame = 0; frame < 3; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  await screen.after?.call(tester, rig);
  await tester.pump(const Duration(milliseconds: 300));
  await _capture(
    tester,
    boundary,
    '${screen.name}_${window.name}_${brightness.name}',
  );

  await tester.pumpWidget(const SizedBox.shrink());
  await rig.letGo();
  await tester.pump();
}

Future<_Rig> _startRig(
  WidgetTester tester,
  _Screen screen,
  ui.Image phoneScreen,
) async {
  final host = await tester.runAsync(MirrorHost.create);
  if (host == null) {
    throw StateError('Could not start the host.');
  }

  await tester.runAsync(() async {
    await host.trustStore.save(
      TrustedDevice(
        id: 'pixel',
        name: 'Pixel 9',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
        publicKey: Uint8List(32),
        pairedAt: DateTime(2026, 11),
      ),
    );
    await host.settings.set(MirroringSettings.lookForCableKey, true);
  });
  final pixel = MirrorSession(
    'pixel',
    name: 'Pixel 9',
    answer: (_) => StartPending(timeoutSeconds: 60),
  );
  host.sessions = [if (screen.connected) pixel];
  final cable = CableRoute();
  final receiver = AirReceiver();
  late final _Rig rig;
  final feature = MirroringFeature(
    decoder: () => StillDecoder(phoneScreen),
    codecs: const [.h264, .jpeg],
    audioSink: QuietSpeaker.new,
    audioCodecs: const [.opus, .pcm],
    routes: [cable],
    receivers: [receiver],
    canShare: false,
    canView: true,
    clock: () => rig.now,
  );
  await feature.start(host);
  rig = _Rig(
    host: host,
    pixel: pixel,
    cable: cable,
    receiver: receiver,
    feature: feature,
    viewModel: ViewerViewModel(
      feature,
      window: const FixedMirrorWindow(),
      systemMirrors: screen.systemMirrors,
      clock: () => rig.now,
    ),
  );
  await tester.pump();
  return rig;
}

/// The theme, strings and navigator the app gives its pages.
class _App extends StatelessWidget {
  const _App({required this.brightness, required this.child});

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fallback = FluffyThemeData.fallback(brightness: brightness);
    final theme = fallback.copyWith(
      platform: defaultTargetPlatform,
      colors: fallback.colors.copyWith(primary: _ferretBlue),
    );

    return WidgetsApp(
      color: _ferretBlue,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        MirroringLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: MirroringLocalizations.supportedLocales,
      builder: (context, navigator) => FluffyTheme(
        data: theme,
        child: Builder(
          builder: (context) => DefaultTextStyle(
            style: theme.typography.base1.copyWith(color: context.palette.text),
            child: ScreenSizeScope(child: navigator ?? const SizedBox.shrink()),
          ),
        ),
      ),
      onGenerateRoute: (_) =>
          PageRouteBuilder<void>(pageBuilder: (_, _, _) => child),
    );
  }
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name,
) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    throw StateError('Nothing to capture for $name.');
  }

  for (var pass = 0; pass < 5; pass++) {
    final changed = applyScreenFont(boundary);
    tester.binding.rootPipelineOwner.flushLayout();
    if (changed == 0) {
      break;
    }
  }

  tester.binding.rootPipelineOwner
    ..flushCompositingBits()
    ..flushPaint();
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      throw StateError('Could not encode $name.');
    }

    await _directory.create(recursive: true);
    await File(
      '${_directory.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List());
  });
}

/// [upright] on its side, as a phone turned to landscape shows it.
Future<ui.Image> _turn(ui.Image upright) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..translate(upright.height.toDouble(), 0)
    ..rotate(1.5707963267948966)
    ..drawImage(upright, Offset.zero, Paint());

  return recorder.endRecording().toImage(upright.height, upright.width);
}

/// A stand-in for a phone's home screen: a wallpaper, a status bar, rows
/// of app icons and a dock, so the picture reads as a phone at a glance.
Future<ui.Image> _drawPhoneScreen() async {
  const width = 540.0;
  const height = 1200.0;
  const iconColors = [
    Color(0xFF34C759),
    Color(0xFFFF9F0A),
    Color(0xFF0A84FF),
    Color(0xFFFF453A),
    Color(0xFFBF5AF2),
    Color(0xFFFFD60A),
    Color(0xFF64D2FF),
    Color(0xFFFF375F),
  ];
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(width, height),
        [
          const Color(0xFF1B2A6B),
          const Color(0xFF7B3FA0),
          const Color(0xFFE8825A),
        ],
        const [0, 0.55, 1],
      ),
  );
  final white = Paint()..color = const Color(0xE6FFFFFF);
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(32, 26, 76, 16),
        const Radius.circular(8),
      ),
      white,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(width - 112, 26, 80, 16),
        const Radius.circular(8),
      ),
      white,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 120, 300, 64),
        const Radius.circular(12),
      ),
      white,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 200, 180, 20),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0x99FFFFFF),
    );
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 4; column++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(44 + column * 120, 420 + row * 140, 92, 92),
          const Radius.circular(26),
        ),
        Paint()..color = iconColors[(row * 3 + column) % iconColors.length],
      );
    }
  }

  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 1020, width - 48, 124),
        const Radius.circular(40),
      ),
      Paint()..color = const Color(0x40FFFFFF),
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(width / 2 - 70, 1172, 140, 8),
        const Radius.circular(4),
      ),
      white,
    );
  for (var column = 0; column < 4; column++) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(44 + column * 120, 1036, 92, 92),
        const Radius.circular(26),
      ),
      Paint()..color = iconColors[(column + 5) % iconColors.length],
    );
  }

  return recorder.endRecording().toImage(width.toInt(), height.toInt());
}
