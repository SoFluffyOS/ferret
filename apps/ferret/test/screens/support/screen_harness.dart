// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';
import 'package:transport/transport.dart';

import 'screen_fonts.dart';

/// A screen size the harness captures.
class ScreenSize {
  const ScreenSize(this.name, this.width, this.height);

  final String name;
  final double width;
  final double height;
}

const phone = ScreenSize('phone', 390, 844);
const popover = ScreenSize('popover', 380, 560);
const sizes = [phone, popover];

/// Pixel ratio of the saved PNGs.
const capturePixelRatio = 2.0;

/// Where the PNGs land, relative to `apps/ferret` (the test's working
/// directory): the repo's gitignored `temp/screens`.
final screensDirectory = Directory('../../temp/screens');

/// One running Ferret: the engine the app shows, plus a second engine on
/// loopback when the screen needs a connected phone.
class ScreenRig {
  ScreenRig._(this.engine, this.app, this.featureContext, this._discovery);

  final FerretEngine engine;
  final FerretApp app;
  final FeatureContext featureContext;
  final SilentDiscovery _discovery;
  final List<FerretEngine> _others = [];
  final GlobalKey boundaryKey = GlobalKey();

  NavigatorState? get navigator => featureContext.navigatorKey.currentState;

  /// Builds the app like `runFerret` does, with in-memory storage, no
  /// discovery and an ephemeral port.
  static Future<ScreenRig> create(
    WidgetTester tester, {
    required List<FeatureUi> features,
    String name = 'MacBook Air',
    bool onboarded = true,
    bool asPhone = false,
  }) async {
    final rig = await tester.runAsync(() async {
      final discovery = SilentDiscovery();
      final engine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: switch (asPhone) {
          true => const LocalDevice(
            name: 'Pixel 9',
            platform: .PLATFORM_ANDROID,
            formFactor: .FORM_FACTOR_PHONE,
            appVersion: '0.1.0',
          ),
          false => LocalDevice(
            name: name,
            platform: .PLATFORM_MACOS,
            formFactor: .FORM_FACTOR_LAPTOP,
            appVersion: '0.1.0',
          ),
        },
        features: [for (final feature in features) feature.feature],
        discovery: discovery,
        port: 0,
      );
      await engine.start();
      if (onboarded) {
        await engine.settings.set(OnboardingPage.doneKey, true);
      }

      final featureContext = FeatureContext(
        engine: engine,
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: QuietNotifier(),
      );
      for (final feature in features) {
        try {
          await feature
              .onAppStarted(featureContext)
              .timeout(const Duration(seconds: 2));
        } on Object catch (error) {
          debugPrint('screens: ${feature.featureId}.onAppStarted: $error');
        }
      }

      final app = FerretApp(
        host: EngineHost(engine),
        pause: PauseController(engine),
        features: features,
        featureContext: featureContext,
      );
      return ScreenRig._(engine, app, featureContext, discovery);
    });
    if (rig == null) {
      throw StateError('Could not start the engine.');
    }

    return rig;
  }

  /// Adds an offline paired phone straight to the trust store.
  Future<void> addOfflinePhone(WidgetTester tester, {String name = 'Pixel 9'}) {
    return tester
        .runAsync(() async {
          await engine.trustStore.save(
            TrustedDevice(
              id: 'a1b2c3d4e5f60718',
              name: name,
              platform: .PLATFORM_ANDROID,
              formFactor: .FORM_FACTOR_PHONE,
              publicKey: Uint8List(32),
              pairedAt: DateTime.now().subtract(const Duration(days: 2)),
              lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
            ),
          );
        })
        .then((_) {});
  }

  /// Pairs a second engine (an Android phone) over loopback with a QR offer,
  /// so the app shows a real connected device with a live session.
  Future<String?> pairConnectedPhone(
    WidgetTester tester, {
    required List<FeatureUi> phoneFeatures,
    String name = 'Pixel 9',
  }) => _pairOther(
    tester,
    features: phoneFeatures,
    device: LocalDevice(
      name: name,
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      appVersion: '0.1.0',
    ),
  );

  /// Same as [pairConnectedPhone], for a phone rig: pairs a Mac.
  Future<String?> pairConnectedComputer(
    WidgetTester tester, {
    required List<FeatureUi> computerFeatures,
  }) => _pairOther(
    tester,
    features: computerFeatures,
    device: const LocalDevice(
      name: 'MacBook Air',
      platform: .PLATFORM_MACOS,
      formFactor: .FORM_FACTOR_LAPTOP,
      appVersion: '0.1.0',
    ),
  );

  Future<String?> _pairOther(
    WidgetTester tester, {
    required List<FeatureUi> features,
    required LocalDevice device,
  }) async {
    final phoneFeatures = features;
    return tester.runAsync<String?>(() async {
      final phoneEngine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: device,
        features: [for (final feature in phoneFeatures) feature.feature],
        discovery: SilentDiscovery(),
        port: 0,
      );
      await phoneEngine.start();
      _others.add(phoneEngine);

      final handle = await engine.createPairingOffer();
      final offer = PairingCodes.parseOffer(handle.qrText);
      if (offer == null) {
        return null;
      }

      offer
        ..hosts.clear()
        ..hosts.add('127.0.0.1');
      final outcome = await phoneEngine.pairWithOffer(offer);
      if (outcome is! Paired) {
        debugPrint('screens: pairing failed: $outcome');
        return null;
      }

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (engine.sessions.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      return phoneEngine.identity.deviceId;
    });
  }

  /// Makes an unpaired device show up under "Devices near you". Nobody
  /// answers at its address.
  Future<void> addNearby(
    WidgetTester tester, {
    required String name,
    Platform platform = .PLATFORM_ANDROID,
    FormFactor formFactor = .FORM_FACTOR_PHONE,
  }) async {
    _discovery.find(
      DiscoveredPeer(
        announce: Announce(
          deviceId: 'nearby${name.hashCode.abs()}',
          name: name,
          platform: platform,
          formFactor: formFactor,
          port: 9,
        ),
        host: '127.0.0.1',
      ),
    );
    await settle(tester);
  }

  /// Starts a real second device and shows it under "Devices near you", so
  /// pairing with it gets as far as the code. Returns its engine.
  Future<FerretEngine?> startNearby(
    WidgetTester tester, {
    String name = 'Pixel 9',
    List<String> alreadyPairedWith = const [],
  }) async {
    final other = await tester.runAsync(() async {
      final secrets = MemorySecretStore();
      final other = await FerretEngine.create(
        secrets: secrets,
        settings: MemorySettingsStore(),
        device: LocalDevice(
          name: name,
          platform: .PLATFORM_ANDROID,
          formFactor: .FORM_FACTOR_PHONE,
          appVersion: '0.1.0',
        ),
        discovery: SilentDiscovery(),
        port: 0,
      );
      for (final (index, paired) in alreadyPairedWith.indexed) {
        await other.trustStore.save(
          TrustedDevice(
            id: 'alreadypaired$index',
            name: paired,
            platform: .PLATFORM_MACOS,
            formFactor: .FORM_FACTOR_LAPTOP,
            publicKey: Uint8List(32),
            pairedAt: DateTime.now(),
          ),
        );
      }

      await other.start();
      _others.add(other);
      return other;
    });
    if (other == null) {
      return null;
    }

    _discovery.find(
      DiscoveredPeer(
        announce: Announce(
          deviceId: other.identity.deviceId,
          name: name,
          platform: .PLATFORM_ANDROID,
          formFactor: .FORM_FACTOR_PHONE,
          port: other.port,
        ),
        host: '127.0.0.1',
      ),
    );
    await settle(tester);
    return other;
  }

  /// Shows the app inside a boundary the harness can capture.
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(RepaintBoundary(key: boundaryKey, child: app));
    await settle(tester);
  }

  /// Opens [page] on top of the home page, without a transition.
  Future<void> open(WidgetTester tester, Widget page) async {
    unawaited(
      navigator?.push(
        PageRouteBuilder<void>(pageBuilder: (_, _, _) => page),
      ),
    );
    await settle(tester);
  }

  /// Runs the "Turn on more" action of [featureId], as tapping its Set up
  /// button does. Returns false when that feature makes no offer.
  Future<bool> openOffer(WidgetTester tester, String featureId) async {
    await settle(tester);
    final home = find.byType(HomePage);
    if (home.evaluate().isEmpty) {
      return false;
    }

    final context = tester.element(home);
    for (final feature in app.features) {
      if (feature.featureId != featureId) {
        continue;
      }

      final offer = feature.offerFor(context, featureContext);
      if (offer == null) {
        debugPrint('screens: $featureId makes no offer');
        return false;
      }

      offer.onAction();
      await settle(tester);
      return true;
    }

    return false;
  }

  /// Taps the first widget showing [text], if the screen has one. Returns
  /// whether it did, so a script can stop when the UI changed.
  Future<bool> tapText(
    WidgetTester tester,
    String text, {
    int index = 0,
  }) async {
    final finder = find.text(text);
    if (finder.evaluate().length <= index) {
      await settle(tester);
    }

    final scrollable = find.byType(Scrollable);
    for (var step = 0; step < 12; step++) {
      if (finder.evaluate().length > index || scrollable.evaluate().isEmpty) {
        break;
      }

      await tester.drag(scrollable.first, const Offset(0, -300));
      await tester.pump();
    }

    // A tap on a list that is still flinging only stops the fling.
    await tester.pump(const Duration(seconds: 2));

    if (finder.evaluate().length <= index) {
      debugPrint('screens: no "$text" #$index to tap');
      return false;
    }

    final target = finder.at(index);
    await tester.ensureVisible(target);
    await tester.tap(target, warnIfMissed: false);
    await settle(tester);
    return true;
  }

  /// Lets real async work (sockets, futures) run, then draws a few frames.
  /// Never `pumpAndSettle`: some pages animate forever (spinners, QR timers).
  Future<void> settle(
    WidgetTester tester, {
    Duration real = const Duration(milliseconds: 300),
  }) async {
    for (var round = 0; round < 3; round++) {
      await tester.runAsync(() => Future<void>.delayed(real));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Saves what is on screen as `temp/screens/<name>_<size>_<mode>.png`.
  Future<void> capture(
    WidgetTester tester,
    String name,
    ScreenSize size,
    Brightness brightness,
  ) async {
    final mode = switch (brightness) {
      Brightness.light => 'light',
      Brightness.dark => 'dark',
    };
    final file = File(
      '${screensDirectory.path}/${name}_${size.name}_$mode.png',
    );

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
      final image = await boundary.toImage(pixelRatio: capturePixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) {
        throw StateError('Could not encode $name.');
      }

      await screensDirectory.create(recursive: true);
      await file.writeAsBytes(bytes.buffer.asUint8List());
    });
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      for (final other in _others) {
        await other.stop();
      }

      await engine.stop();
    });
  }
}

/// Answers the plugin calls a desktop app makes at startup that throw in
/// tests when nobody answers, such as asking for the Downloads folder.
void mockPlugins(WidgetTester tester) {
  final folder = Directory.systemTemp.createTempSync('ferret_screens');
  AppPaths.use(FerretPaths(folder.path));
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => folder.path,
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });
}

/// Sizes the test window and sets light or dark mode.
void setScreen(WidgetTester tester, ScreenSize size, Brightness brightness) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(size.width, size.height);
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}

/// Finds no one by itself; the screens set up devices themselves, and
/// [find] puts one under "Devices near you".
class SilentDiscovery implements Discovery {
  final StreamController<DiscoveredPeer> _peers = .broadcast();

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  void find(DiscoveredPeer peer) => _peers.add(peer);

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}

/// Swallows notices; screenshots never show system notifications.
class QuietNotifier implements LocalNotifier {
  @override
  Future<void> show(LocalNotice notice) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}
