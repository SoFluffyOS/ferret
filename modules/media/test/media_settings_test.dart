import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/media.dart';
import 'package:protocol/media.dart';
import 'package:protocol/protocol.dart';

import 'support/fake_host.dart';
import 'support/fake_media_backend.dart';
import 'support/test_app.dart';

/// A connected device that says which parts of Media it has.
class _Session implements Session {
  _Session({this.flags = const ['share', 'control'], this.hasMedia = true});

  final List<String> flags;
  final bool hasMedia;

  @override
  String get remoteDeviceId => 'pixel';

  @override
  FeatureSupport? remoteFeature(String featureId) => switch (hasMedia) {
    true => FeatureSupport(id: featureId, flags: flags),
    false => null,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A view model that sees one player on the phone.
class _PlayingModel extends MediaViewModel {
  _PlayingModel(super.feature);

  @override
  List<RemotePlayer> get players => [
    RemotePlayer(
      deviceId: 'pixel',
      deviceName: 'Pixel 9',
      player: MediaPlayer(playerId: 'spotify'),
      positionAtMs: 0,
      lastActiveAtMs: 0,
    ),
  ];
}

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // The default test display, 800 by 600, counts as a tablet's; these
  // strings are checked as a phone says them.
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.display
      ..devicePixelRatio = 1
      ..size = const Size(390, 844);
  });
  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.display.reset();
  });

  final featureContext = _NoContext();
  late FakeHost host;

  DeviceStatus statusOf(Session? session) => DeviceStatus(
    TrustedDevice(
      id: 'pixel',
      name: 'Pixel 9',
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: Uint8List(32),
      pairedAt: DateTime(2026),
    ),
    session,
  );

  Future<MediaFeatureUi> start(
    WidgetTester tester, {
    FakeMediaBackend? backend,
    MediaPlatform platform = .linux,
    bool shareByDefault = true,
    Map<String, bool> settings = const {},
  }) async {
    host = FakeHost();
    final feature = switch (backend) {
      final backend? => MediaFeature(
        backend: () => backend,
        shareByDefault: shareByDefault,
      ),
      null => MediaFeature(),
    };
    await tester.runAsync(() async {
      for (final MapEntry(:key, :value) in settings.entries) {
        await host.settings.set(key, value);
      }

      await feature.start(host);
      await Future<void>.delayed(Duration.zero);
    });
    final ui = MediaFeatureUi(feature: feature, platform: platform);
    addTearDown(ui.viewModel.dispose);
    return ui;
  }

  Future<FeatureSettings> section(
    WidgetTester tester,
    MediaFeatureUi ui,
  ) async {
    late List<FeatureSettings> sections;
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) {
            sections = ui.settingsSections(context, featureContext);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return sections.single;
  }

  group('the Settings part', () {
    testWidgets('sits under Continue & media and says what is on', (
      tester,
    ) async {
      final ui = await start(tester, backend: FakeMediaBackend());

      final part = await section(tester, ui);

      expect(part.group, SettingsGroup.continueAndMedia);
      expect(part.title, 'Media');
      expect(part.summary, 'Shows and shares what plays');
      expect(part.isOn, isTrue);
      expect(part.needsAttention, isFalse);
    });

    testWidgets('a device that never got access is quiet about it', (
      tester,
    ) async {
      final ui = await start(
        tester,
        backend: FakeMediaBackend(accessState: .notGranted),
        platform: .android,
      );

      final part = await section(tester, ui);

      expect(part.summary, 'Shows what your devices play');
      expect(part.needsAttention, isFalse);
    });

    testWidgets('sharing the person turned on, without access, needs them', (
      tester,
    ) async {
      final ui = await start(
        tester,
        backend: FakeMediaBackend(accessState: .notGranted),
        platform: .macos,
        shareByDefault: false,
        settings: {MediaSettings.share: true},
      );

      expect((await section(tester, ui)).needsAttention, isTrue);
    });

    testWidgets('everything off is off, and the row hears about it', (
      tester,
    ) async {
      final ui = await start(tester, backend: FakeMediaBackend());
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      await tester.runAsync(() async {
        await ui.viewModel.setShare(false);
        await ui.viewModel.setShowRemote(false);
      });

      final part = await section(tester, ui);
      expect(changes, greaterThan(0));
      expect(part.summary, 'Off');
      expect(part.isOn, isFalse);
    });
  });

  group('health with a device', () {
    testWidgets('nothing to say when it is not connected', (tester) async {
      final ui = await start(tester, backend: FakeMediaBackend());

      expect(ui.healthFor(featureContext, statusOf(null)), isNull);
    });

    testWidgets('says what each side sees', (tester) async {
      final ui = await start(
        tester,
        backend: FakeMediaBackend(),
        platform: .macos,
      );

      final health = ui.healthFor(featureContext, statusOf(_Session()));

      expect(health?.state, FeatureHealthState.ok);
      expect(health?.reason, 'Pixel 9 sees what plays on this Mac.');
    });

    testWidgets('a dash while nothing plays and nothing is shared', (
      tester,
    ) async {
      final ui = await start(
        tester,
        backend: FakeMediaBackend(),
        platform: .macos,
        shareByDefault: false,
      );

      final health = ui.healthFor(featureContext, statusOf(_Session()));

      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Nothing playing right now');
    });

    testWidgets('says so while something plays there', (tester) async {
      final feature = MediaFeature();
      await tester.runAsync(() => feature.start(FakeHost()));
      final model = _PlayingModel(feature);
      addTearDown(model.dispose);

      final health = mediaHealthOf(
        platformMediaL10n(),
        session: _Session(),
        name: 'Pixel 9',
        model: model,
      );

      expect(health?.state, FeatureHealthState.ok);
      expect(health?.reason, startsWith("Shares what's playing."));
    });

    testWidgets('lost access offers the fix', (tester) async {
      final backend = FakeMediaBackend(accessState: .notGranted);
      final ui = await start(
        tester,
        backend: backend,
        platform: .android,
        settings: {MediaSettings.share: true},
      );

      final health = ui.healthFor(featureContext, statusOf(_Session()));

      expect(health?.state, FeatureHealthState.needsAttention);
      expect(health?.reason, "Ferret can't see what plays on this phone");
      await tester.runAsync(() async {
        health?.onFix?.call();
        await Future<void>.delayed(Duration.zero);
      });
      expect(backend.settingsOpened, 1);
    });

    testWidgets('off here says where to turn it on', (tester) async {
      final ui = await start(
        tester,
        backend: FakeMediaBackend(),
        platform: .windows,
        settings: {MediaSettings.share: false, MediaSettings.showRemote: false},
      );

      final health = ui.healthFor(featureContext, statusOf(_Session()));

      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Off on this PC');
      expect(
        health?.help,
        'Settings → Continue & media → Show media from other devices',
      );
    });

    testWidgets('only this side could share, and it does not', (tester) async {
      final ui = await start(
        tester,
        backend: FakeMediaBackend(),
        platform: .macos,
        shareByDefault: false,
      );

      final health = ui.healthFor(
        featureContext,
        statusOf(_Session(flags: const ['control'])),
      );

      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Not shared from this Mac');
      expect(health?.help, 'Settings → Continue & media → Share my media');
    });

    testWidgets('two devices that cannot share have nothing to show', (
      tester,
    ) async {
      final ui = await start(tester, platform: .ios);

      expect(
        ui.healthFor(
          featureContext,
          statusOf(_Session(flags: const ['control'])),
        ),
        isNull,
      );
    });

    testWidgets('a device without Media needs an update', (tester) async {
      final ui = await start(tester, backend: FakeMediaBackend());

      final health = ui.healthFor(
        featureContext,
        statusOf(_Session(hasMedia: false)),
      );

      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Needs a Ferret update on Pixel 9');
    });
  });
}
