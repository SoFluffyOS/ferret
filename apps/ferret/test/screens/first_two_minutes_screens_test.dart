// The first two minutes, from install to the first file arriving on the
// other device, for six pairs of devices. Both apps run at once, each on
// its own engine on loopback, and the script taps through the real flow
// on both: the welcome, finding each other (or the QR code for an iPhone),
// comparing codes, and sending a photo. Every step is saved as
// `temp/screens/first2min/<pair>/NN_<side>_<step>_<size>_light.png`, and
// `script.md` next to them counts the screens, taps, waits, system prompts
// and words. Run from apps/ferret, one pair at a time if you like:
//
//   flutter test test/screens/first_two_minutes_screens_test.dart
//   flutter test test/screens/first_two_minutes_screens_test.dart \
//     --plain-name "first2min android_mac"
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_bonjour/ferret_bonjour.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';
import 'package:transport/transport.dart';

import 'screens_test.dart' show appFeatures;
import 'support/android_features.dart';
import 'support/ios_features.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

/// A Windows or Linux laptop's window when Ferret first opens (the
/// runners' default size).
const _window = CaptureSize('window', 1100, 720);

enum _Os {
  android('Android', 'Pixel 9', .android),
  ios('iPhone', 'iPhone 16', .iOS),
  mac('Mac', 'MacBook Air', .macOS),
  windows('Windows', 'Surface Laptop', .windows),
  linux('Linux', 'ThinkPad', .linux);

  const _Os(this.label, this.deviceName, this.platform);

  final String label;
  final String deviceName;
  final TargetPlatform platform;

  bool get isPhone => this == android || this == ios;

  CaptureSize get size => switch (this) {
    android => phone,
    ios => iphone,
    mac => popover,
    windows || linux => _window,
  };

  List<FeatureUi> features() => switch (this) {
    android => androidFeatures(),
    ios => iosFeatures(),
    _ => appFeatures(),
  };
}

/// One step of the script: who does what, on which device, and what kind
/// of step it is. Renders carry their file name; system prompts and
/// pickers Ferret doesn't draw have none.
class _Step {
  _Step(this.side, this.kind, this.what, {this.file, this.words = 0});

  final _Os side;
  final _Kind kind;
  final String what;
  final String? file;
  final int words;
}

enum _Kind { screen, tap, wait, system }

/// Two Ferrets side by side in one test: [a] is the device in the hand
/// (or the first computer), [b] the other. Only one shows at a time, at
/// its own size and platform; both keep running underneath.
class _Duo {
  _Duo(this.pair, this.aOs, this.bOs, this.a, this.b);

  final String pair;
  final _Os aOs;
  final _Os bOs;
  final ScreenRig a;
  final ScreenRig b;
  final shown = ValueNotifier<int>(0);
  final steps = <_Step>[];
  int _shots = 0;

  ScreenRig rigOf(_Os os) => os == aOs ? a : b;

  static Future<_Duo> start(
    WidgetTester tester,
    String pair,
    _Os aOs,
    _Os bOs, {
    LocalNetworkAsk Function()? iphoneAsk,
  }) async {
    Future<ScreenRig> make(_Os os) async {
      debugDefaultTargetPlatformOverride = os.platform;
      final rig = await ScreenRig.create(
        tester,
        features: os.features(),
        name: os.deviceName,
        asPhone: os == .android,
        asIphone: os == .ios,
      );
      if (os == .ios && iphoneAsk != null) {
        rig.featureContext.localNetwork = iphoneAsk();
      }

      return rig;
    }

    final a = await make(aOs);
    final b = await make(bOs);
    final duo = _Duo(pair, aOs, bOs, a, b);
    await tester.runAsync(
      () => Directory(
        '${screensDirectory.path}/first2min/$pair',
      ).create(recursive: true),
    );
    await tester.pumpWidget(
      ValueListenableBuilder<int>(
        valueListenable: duo.shown,
        builder: (_, index, _) => IndexedStack(
          alignment: Alignment.topLeft,
          index: index,
          children: [_own(aOs, a), _own(bOs, b)],
        ),
      ),
    );
    await a.settle(tester);
    return duo;
  }

  /// [rig]'s app at [os]'s own size whatever the view is now, so showing
  /// the other one never lays it out or rebuilds it as the other's size.
  static Widget _own(_Os os, ScreenRig rig) {
    final size = Size(os.size.width, os.size.height);
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: size.width,
      maxWidth: size.width,
      minHeight: size.height,
      maxHeight: size.height,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQueryData.fromView(View.of(context)).copyWith(size: size),
          child: RepaintBoundary(key: rig.boundaryKey, child: rig.app),
        ),
      ),
    );
  }

  /// Puts [os]'s app on screen, at its size and as its platform.
  Future<ScreenRig> look(WidgetTester tester, _Os os) async {
    final rig = rigOf(os);
    debugDefaultTargetPlatformOverride = os.platform;
    setScreen(tester, os.size, .light);
    shown.value = os == aOs ? 0 : 1;
    // Rebuilds this app, and only this one, as its platform says, like a
    // hot reload. The other keeps the tree its own platform built, so
    // what it has open (a pairing question) stays open.
    // A LayoutBuilder rebuilds what it holds in its own scope, at layout.
    final root = tester.element(
      find.byKey(rig.boundaryKey, skipOffstage: false),
    );
    void rebuild(Element element) {
      if (element.buildScope == root.buildScope) {
        element.markNeedsBuild();
      }

      element.visitChildren(rebuild);
    }

    rebuild(root);
    await tester.pump();
    await rig.settle(tester);
    return rig;
  }

  /// Saves what [os] shows now as the next numbered step.
  Future<void> shot(WidgetTester tester, _Os os, String step, String what) {
    return look(tester, os).then((rig) async {
      _shots++;
      final number = _shots.toString().padLeft(2, '0');
      final name = '${number}_${os.name}_$step';
      final words = _wordsOn(rig);
      await rig.capture(tester, 'first2min/$pair/$name', os.size, .light);
      steps.add(
        _Step(
          os,
          .screen,
          what,
          file: '${name}_${os.size.name}_light.png',
          words: words,
        ),
      );
    });
  }

  /// Saves [os]'s page for [other] right after pairing, beside the steps
  /// and not counted in them, then goes back to Home.
  Future<void> peekDevicePage(WidgetTester tester, _Os os, _Os other) async {
    final rig = await look(tester, os);
    await rig.open(
      tester,
      DevicePage(deviceId: rigOf(other).engine.identity.deviceId),
    );
    // Where "may" sits: the end of the page on a phone and in the popover.
    final page = find.descendant(
      of: find.byType(DevicePage),
      matching: find.byType(Scrollable),
    );
    for (final state in tester.stateList<ScrollableState>(page)) {
      state.position.jumpTo(state.position.maxScrollExtent);
    }

    await rig.settle(tester);
    await rig.capture(
      tester,
      'first2min/$pair/extra_${os.name}_device_page',
      os.size,
      .light,
    );
    rig.navigator?.pop();
    await rig.settle(tester);
  }

  void note(_Os os, _Kind kind, String what) =>
      steps.add(_Step(os, kind, what));

  /// Taps [text] on [os], inside the dialog when one is open.
  Future<bool> tap(WidgetTester tester, _Os os, String text) async {
    final rig = await look(tester, os);
    final inDialog = find.descendant(
      of: find.byType(PairingPromptDialog),
      matching: find.text(text),
    );
    // Buttons also lay their label out off screen, to measure it.
    final onScreen = find.text(text).hitTestable();
    final tapped = switch ((
      inDialog.evaluate().isNotEmpty,
      onScreen.evaluate().isNotEmpty,
    )) {
      (true, _) => await _tapFinder(tester, rig, inDialog.hitTestable()),
      (false, true) => await _tapFinder(tester, rig, onScreen),
      _ => await rig.tapText(tester, text),
    };
    steps.add(_Step(os, .tap, 'Tap **$text**'));
    return tapped;
  }

  Future<bool> _tapFinder(
    WidgetTester tester,
    ScreenRig rig,
    Finder finder,
  ) async {
    await tester.tap(finder.first, warnIfMissed: false);
    await rig.settle(tester);
    return true;
  }

  /// Every word drawn in [rig]'s view right now.
  int _wordsOn(ScreenRig rig) {
    final root = rig.boundaryKey.currentContext?.findRenderObject();
    if (root == null) {
      return 0;
    }

    var words = 0;
    void visit(RenderObject node) {
      if (node is RenderParagraph) {
        words += RegExp(
          r"[\p{L}\p{N}'’]+",
          unicode: true,
        ).allMatches(node.text.toPlainText()).length;
      }

      node.visitChildren(visit);
    }

    visit(root);
    return words;
  }

  Future<void> writeScript(WidgetTester tester) async {
    int count(_Kind kind) => steps.where((step) => step.kind == kind).length;
    final words = steps.fold<int>(0, (sum, step) => sum + step.words);
    final lines = [
      '# ${aOs.label} + ${bOs.label}: install → first file',
      '',
      '| # | Device | Kind | What | Words | Render |',
      '|---|---|---|---|---|---|',
      for (final (index, step) in steps.indexed)
        '| ${index + 1} | ${step.side.label} | ${step.kind.name} | '
            '${step.what} | ${step.words == 0 ? '' : step.words} | '
            '${step.file ?? ''} |',
      '',
      'Screens ${count(.screen)} · taps ${count(.tap)} · waits '
          '${count(.wait)} · system prompts/pickers ${count(.system)} · '
          'words on screen $words',
      '',
    ];
    await tester.runAsync(
      () => File(
        '${screensDirectory.path}/first2min/$pair/script.md',
      ).writeAsString(lines.join('\n')),
    );
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    a.app.pause.dispose();
    b.app.pause.dispose();
    await tester.runAsync(() async {
      for (final rig in [a, b]) {
        for (final other in rig.others) {
          await other.stop();
        }

        await rig.engine.stop();
      }
    });
  }
}

/// A photo the phone sends, in a folder of its own.
Future<String> _photo(WidgetTester tester) async {
  final path = await tester.runAsync(() async {
    final folder = await Directory.systemTemp.createTemp('ferret_first2min');
    final file = File('${folder.path}/IMG_0412.jpg');
    await file.writeAsBytes(List<int>.filled(48 * 1024, 7));
    return file.path;
  });
  return path!;
}

/// Sends the photo from [from] to [to] as the file picker would hand it
/// to Ferret, and waits until it arrived.
Future<void> _send(WidgetTester tester, _Duo duo, _Os from, _Os to) async {
  final sender = duo.rigOf(from);
  final receiver = duo.rigOf(to);
  final drop = sender.app.features.whereType<DropFeatureUi>().single;
  final path = await _photo(tester);
  await tester.runAsync(() async {
    await drop.feature.sendFiles(receiver.engine.identity.deviceId, [path]);
    await Future<void>.delayed(const Duration(seconds: 1));
  });
  await sender.settle(tester);
}

/// Two devices that find each other on the Wi-Fi: [hand] taps Pair on
/// [other], both compare the code, and [hand] sends a photo.
Future<void> _nearby(WidgetTester tester, _Duo duo, _Os hand, _Os other) async {
  final handRig = duo.rigOf(hand);
  final otherRig = duo.rigOf(other);
  await duo.shot(tester, hand, 'welcome', 'First launch: the welcome');
  await duo.shot(tester, other, 'welcome', 'First launch: the welcome');
  if (hand == .ios) {
    await duo.tap(tester, hand, 'Continue');
    duo.note(
      hand,
      .system,
      'iOS: "Ferret would like to find devices on your local network" '
      '→ Allow',
    );
  }

  duo.note(other, .wait, 'Both look on the Wi-Fi (Bonjour), ~1–3 s');
  await handRig.hear(tester, otherRig);
  await otherRig.hear(tester, handRig);
  await duo.shot(tester, hand, 'nearby', '${other.label} shows under Nearby');
  await duo.shot(tester, other, 'nearby', '${hand.label} shows under Nearby');
  await duo.tap(tester, hand, 'Pair');
  await handRig.settle(tester, real: const Duration(milliseconds: 600));
  await duo.shot(tester, hand, 'code', 'Six digits to compare');
  await duo.shot(tester, other, 'prompt', 'Pair with ${hand.deviceName}?');
  await duo.tap(tester, hand, 'They match');
  await duo.shot(tester, hand, 'waiting', 'Waiting for the other side');
  await duo.tap(tester, other, 'Pair');
  await otherRig.settle(tester, real: const Duration(milliseconds: 600));
  await duo.shot(tester, other, 'paired', 'Paired: Home with the device');
  await duo.shot(tester, hand, 'paired', 'Paired: Home with the device');
  if (duo.pair == 'android_mac') {
    await duo.peekDevicePage(tester, hand, other);
    await duo.peekDevicePage(tester, other, hand);
  }

  await _firstFile(tester, duo, hand, other);
}

/// The iPhone scans the computer's code.
Future<void> _qr(WidgetTester tester, _Duo duo, _Os computer) async {
  const phone = _Os.ios;
  final phoneRig = duo.rigOf(phone);
  final computerRig = duo.rigOf(computer);
  await duo.shot(tester, phone, 'welcome', 'First launch: the welcome');
  await duo.shot(tester, computer, 'welcome', 'First launch: the welcome');
  await duo.tap(tester, computer, 'Use a QR code');
  await duo.shot(tester, computer, 'qr', 'The QR code');
  await duo.tap(tester, phone, 'Scan the code');
  await duo.shot(tester, phone, 'why_look', 'Why Ferret looks on the Wi-Fi');
  await duo.tap(tester, phone, 'Continue');
  duo
    ..note(
      phone,
      .system,
      'iOS: "Ferret would like to find devices on '
      'your local network" → Allow',
    )
    ..note(phone, .system, 'iOS: camera access → OK');
  await phoneRig.settle(tester);
  await duo.shot(tester, phone, 'scan', 'The camera');
  final shown = tester.widget<QrCodeView>(
    find.byType(QrCodeView, skipOffstage: false),
  );
  final parsed = PairingCodes.parseOffer(shown.data)!
    ..hosts.clear()
    ..hosts.add('127.0.0.1');
  duo.note(phone, .wait, 'Point the camera at the code');
  phoneRig.navigator!.pop(PairingCodes.offerUri(parsed).toString());
  await phoneRig.settle(tester, real: const Duration(milliseconds: 800));
  await duo.shot(tester, phone, 'paired_note', 'Paired with the computer');
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 1));
  await duo.shot(tester, phone, 'paired', 'Paired: Home with the computer');
  await computerRig.settle(tester, real: const Duration(seconds: 2));
  // "Paired with iPhone 16" shows for 1.5 s before the code page closes.
  await tester.pump(const Duration(seconds: 2));
  await duo.shot(tester, computer, 'paired', 'Paired: Home with the iPhone');
  await _firstFile(tester, duo, phone, computer);
}

Future<void> _firstFile(
  WidgetTester tester,
  _Duo duo,
  _Os from,
  _Os to,
) async {
  if (!from.isPhone) {
    duo.note(
      from,
      .system,
      'Notifications: "Ferret would like to send you notifications" → Allow',
    );
  }

  if (!to.isPhone) {
    duo.note(
      to,
      .system,
      'Notifications: "Ferret would like to send you notifications" → Allow',
    );
  }

  final label = switch (from.isPhone) {
    true => 'Send files',
    false => 'Send files…',
  };
  duo
    ..note(from, .tap, 'Tap **$label** on the ${to.label} row')
    ..note(from, .system, 'The system picker: choose the photo');
  await _send(tester, duo, from, to);
  await duo.shot(tester, from, 'sent', 'The photo went');
  await duo.shot(tester, to, 'arrived', 'The photo arrived');
}

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  final pairs = <String, (_Os, _Os)>{
    'iphone_mac': (.ios, .mac),
    'iphone_mac_nearby': (.ios, .mac),
    'android_windows': (.android, .windows),
    'android_mac': (.android, .mac),
    'iphone_windows': (.ios, .windows),
    'mac_windows': (.mac, .windows),
    'android_linux': (.android, .linux),
  };

  for (final MapEntry(key: pair, value: (a, b)) in pairs.entries) {
    testWidgets('first2min $pair', (tester) async {
      mockPlugins(tester);
      debugDisableShadows = false;
      // The test font is wider than the real one; captures check overflow
      // again with the real font (overflows.txt).
      final reportError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          return;
        }

        reportError?.call(details);
      };
      try {
        final duo = await _Duo.start(
          tester,
          pair,
          a,
          b,
          iphoneAsk: () => LocalNetworkAsk(
            settings: MemorySettingsStore(),
            held: HeldDiscovery(_Quiet()),
            hasDevices: () => false,
            probe: const _Allowed(),
          ),
        );
        switch (a) {
          case .ios when !pair.endsWith('nearby'):
            await _qr(tester, duo, b);
          case _:
            await _nearby(tester, duo, a, b);
        }

        await duo.writeScript(tester);
        await duo.dispose(tester);
      } finally {
        FlutterError.onError = reportError;
        debugDisableShadows = true;
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  _deadEnds();
}

/// Where the first two minutes can stop: the camera turned off for
/// Ferret on the scan page.
void _deadEnds() {
  testWidgets('first2min dead_end camera_off', (tester) async {
    mockPlugins(tester);
    setScreen(tester, iphone, .light);
    debugDefaultTargetPlatformOverride = iphone.platform;
    try {
      final rig = await ScreenRig.create(
        tester,
        features: iosFeatures(),
        asIphone: true,
      );
      await tester.runAsync(
        () => Directory(
          '${screensDirectory.path}/first2min/dead_ends',
        ).create(recursive: true),
      );
      await rig.show(tester);
      await rig.open(tester, const ScanPage(cameraOff: true));
      await rig.capture(
        tester,
        'first2min/dead_ends/scan_camera_off',
        iphone,
        .light,
      );
      await rig.dispose(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _Allowed extends LocalNetworkProbe {
  const _Allowed() : super(isIos: true);

  @override
  Future<LocalNetworkState> check() async => .allowed;
}

class _Quiet implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
