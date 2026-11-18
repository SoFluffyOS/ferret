import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:ferret_iphone/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iphone/iphone.dart';

import 'helpers/fakes.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = IphoneFeatureUi();

    expect(ui.featureId, IphoneFeature.featureId);
    expect(ui.feature.id, IphoneFeature.featureId);
  });

  test('is never offered to other Ferret devices', () {
    expect(IphoneFeature().isAvailable, isFalse);
  });

  test('does nothing on a platform that can not do it', () async {
    final transport = FakeAppleTransport();
    final feature = IphoneFeature(
      transport: () => transport,
      isSupported: false,
    );

    await feature.start(FakeHost(pairedSettings()));
    await settle();

    expect(feature.link.phase, LinkPhase.unsupported);
    expect(transport.connects, isEmpty);
    expect(await feature.devices(), isEmpty);
    expect(await feature.sendMedia(.play), isFalse);
    expect(await feature.openBluetoothSettings(), isFalse);

    await feature.stop();
  });

  test('starting never waits for the iPhone', () async {
    final rig = await Rig.start(
      settings: pairedSettings(),
      transport: FakeAppleTransport()
        ..connectHold = Future<void>.delayed(
          const Duration(milliseconds: 50),
        ),
      retryDelays: const [],
    );
    await settle();

    expect(rig.feature.link.phase, LinkPhase.connecting);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(rig.feature.link.phase, LinkPhase.connected);

    await rig.feature.stop();
  });

  test('follows what the iPhone plays and sends it commands', () async {
    final rig = await Rig.start(
      settings: pairedSettings(),
      retryDelays: const [],
    );
    await settle();
    var changes = 0;
    rig.feature.changes.listen((_) => changes++);

    rig.iphone.play(title: 'Song', artist: 'Artist');
    final sent = await rig.feature.sendMedia(.togglePlayPause);

    expect(rig.feature.media.title, 'Song');
    expect(rig.feature.media.isPlaying, isTrue);
    expect(changes, greaterThan(0));
    expect(sent, isTrue);
    expect(rig.iphone.commands, [AmsCommand.togglePlayPause]);

    await rig.feature.stop();
  });

  test('a command that does not get there reports false', () async {
    final rig = await Rig.start(
      settings: pairedSettings(),
      retryDelays: const [],
    );
    await settle();
    rig.transport.writeError = const GattException(.notConnected);

    expect(await rig.feature.sendMedia(.nextTrack), isFalse);
    expect(await rig.feature.perform(1, .negative), isFalse);

    await rig.feature.stop();
  });

  test('lists the paired devices and opens the Bluetooth settings', () async {
    final rig = await Rig.start(
      settings: {IphoneSettings.enabledKey: true},
      retryDelays: const [],
    );
    await settle();

    final devices = await rig.feature.devices();
    final opened = await rig.feature.openBluetoothSettings();

    expect(devices.single.name, iphoneDevice.name);
    expect(opened, isTrue);
    expect(rig.transport.settingsOpened, 1);

    await rig.feature.stop();
  });

  test('remembers when the iPhone last said something', () async {
    var now = DateTime(2026, 11, 18, 12);
    final rig = await Rig.start(
      settings: pairedSettings(),
      clock: () => now,
      retryDelays: const [],
    );
    await settle();

    now = now.add(const Duration(minutes: 3));
    rig.iphone.play();

    expect(rig.feature.lastActivity, now);

    await rig.feature.stop();
  });
}
