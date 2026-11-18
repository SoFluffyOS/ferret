import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:ferret_power/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

void main() {
  final featureContext = _NoContext();
  late FakeHost host;
  late ClipboardFeature feature;
  late ClipboardFeatureUi ui;

  Future<void> start(
    WidgetTester tester, {
    ClipboardAccess access = .always,
    Map<String, Object?>? settings,
    PowerCapabilities? power,
  }) async {
    await tester.runAsync(() async {
      host = await FakeHost.create(settings: settings);
      feature = ClipboardFeature(
        clipboard: () => FakeClipboard(access: access),
        power: switch (power) {
          final power? => () => power,
          null => null,
        },
      );
      await feature.start(host);
    });
    ui = ClipboardFeatureUi(feature: feature);
    addTearDown(() async {
      await ui.dispose();
      await feature.stop();
    });
  }

  Future<FeatureSettings> section(WidgetTester tester) async {
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

  DeviceStatus statusOf(Session? session) => DeviceStatus(
    TrustedDevice(
      id: 'pixelpixelpixelp',
      name: 'Pixel 9',
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: Uint8List(32),
      pairedAt: DateTime(2026),
    ),
    session,
  );

  testWidgets('a computer syncs by itself, under Clipboard', (tester) async {
    await start(tester);

    final part = await section(tester);

    expect(part.group, SettingsGroup.clipboard);
    expect(part.title, 'Clipboard');
    expect(part.summary, 'Syncs by itself');
    expect(part.isOn, isTrue);
    expect(part.needsAttention, isFalse);
  });

  testWidgets('a phone that can only read on request sends by hand', (
    tester,
  ) async {
    await start(tester, access: .foreground);

    final part = await section(tester);

    expect(part.summary, 'Send by hand');
    expect(part.isOn, isTrue);
    expect(part.needsAttention, isFalse);
  });

  testWidgets('receiving off leaves only sending', (tester) async {
    await start(tester, settings: {ClipboardSettings.autoReceiveKey: false});

    expect((await section(tester)).summary, 'Sends by itself');
  });

  testWidgets('everything automatic off counts as off', (tester) async {
    await start(
      tester,
      settings: {
        ClipboardSettings.autoSendKey: false,
        ClipboardSettings.autoReceiveKey: false,
      },
    );

    final part = await section(tester);

    expect(part.summary, 'Send by hand');
    expect(part.isOn, isFalse);
  });

  testWidgets('background sending that lost its power-up needs attention', (
    tester,
  ) async {
    final power = PowerCapabilities.withPlatform(
      FakePowerPlatform(
        status: const PowerStatus(supported: true, shizuku: .notRunning),
      ),
    );
    addTearDown(power.dispose);
    await start(
      tester,
      access: .foreground,
      settings: {ClipboardSettings.backgroundSendKey: true},
      power: power,
    );

    final part = await section(tester);

    expect(part.needsAttention, isTrue);
    expect(part.summary, 'Send by hand');
  });

  testWidgets('the row follows the settings', (tester) async {
    await start(tester);
    var changes = 0;
    ui.uiChanges.addListener(() => changes++);

    await tester.runAsync(() async {
      await feature.settings.setAutoReceive(false);
      await settle();
    });

    expect(changes, greaterThan(0));
    expect((await section(tester)).summary, 'Sends by itself');
  });

  group('health with a device', () {
    testWidgets('nothing to say about a device that is not connected', (
      tester,
    ) async {
      await start(tester);

      expect(ui.healthFor(featureContext, statusOf(null)), isNull);
    });

    testWidgets('both sides send by themselves', (tester) async {
      await start(tester);

      final health = ui.healthFor(
        featureContext,
        statusOf(FakeSession('pixelpixelpixelp')),
      );

      expect(health?.state, FeatureHealthState.ok);
      expect(health?.reason, 'Syncs by itself');
    });

    testWidgets('says which side sends by hand', (tester) async {
      await start(tester);
      final manualPhone = FakeSession(
        'pixelpixelpixelp',
        flags: const ['receive'],
      );

      expect(
        ui.healthFor(featureContext, statusOf(manualPhone))?.reason,
        'Sends by itself. Pixel 9 sends by hand.',
      );
    });

    testWidgets('a phone says to send by hand from here', (tester) async {
      await start(tester, access: .foreground);

      expect(
        ui
            .healthFor(
              featureContext,
              statusOf(FakeSession('pixelpixelpixelp')),
            )
            ?.reason,
        'Pixel 9 sends by itself. Send by hand from here.',
      );
      expect(
        ui
            .healthFor(
              featureContext,
              statusOf(
                FakeSession('pixelpixelpixelp', flags: const ['receive']),
              ),
            )
            ?.reason,
        'Send by hand',
      );
    });

    testWidgets('a device without Clipboard needs an update', (tester) async {
      await start(tester);

      final health = ui.healthFor(
        featureContext,
        statusOf(_OldSession('pixelpixelpixelp')),
      );

      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Needs a Ferret update on Pixel 9');
    });
  });
}

class _OldSession extends FakeSession {
  _OldSession(super.remoteDeviceId);

  @override
  bool supports(String featureId) => false;
}

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
