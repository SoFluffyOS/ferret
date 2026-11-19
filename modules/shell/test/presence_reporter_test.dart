import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'support/memory_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FerretEngine engine;

  setUp(() async {
    engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Family iMac',
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_DESKTOP,
      ),
      features: const [],
      discovery: MemoryDiscoveryBus().join(),
      port: 0,
    );
  });

  tearDown(() => engine.stop());

  test('a computer is in use while the person is at its screen', () async {
    final reporter = PresenceReporter(engine, isPhoneOrTablet: false);
    addTearDown(reporter.dispose);

    await reporter.start();

    expect(engine.localPresence.userActive, isTrue);
    expect(engine.localPresence.away, isFalse);
  });

  test('a locked screen or another account in front reads as away, and '
      'coming back as in use', () async {
    final screen = StreamController<bool>();
    addTearDown(screen.close);
    final reporter = PresenceReporter(
      engine,
      isAtScreen: () => true,
      atScreenChanges: screen.stream,
      isPhoneOrTablet: false,
    );
    addTearDown(reporter.dispose);
    await reporter.start();

    screen.add(false);
    await pumpEventQueue();

    expect(engine.localPresence.away, isTrue);
    expect(engine.localPresence.userActive, isFalse);

    screen.add(true);
    await pumpEventQueue();

    expect(engine.localPresence.away, isFalse);
    expect(engine.localPresence.userActive, isTrue);
  });

  test('a computer that starts locked says so from the start', () async {
    final reporter = PresenceReporter(
      engine,
      isAtScreen: () => false,
      isPhoneOrTablet: false,
    );
    addTearDown(reporter.dispose);

    await reporter.start();

    expect(engine.localPresence.away, isTrue);
  });

  test('a phone is never away, only in front or not', () async {
    final reporter = PresenceReporter(
      engine,
      isAtScreen: () => false,
      isPhoneOrTablet: true,
    );
    addTearDown(reporter.dispose);

    await reporter.start();

    expect(engine.localPresence.away, isFalse);
  });
}
