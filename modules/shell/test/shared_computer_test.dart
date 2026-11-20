import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

import 'support/memory_discovery.dart';

void main() {
  late MemorySettingsStore settings;

  setUp(() => settings = MemorySettingsStore());

  SharedComputer shared(Map<String, String> environment) =>
      SharedComputer(settings, environment: environment);

  test('one account keeps the computer\'s own name', () {
    expect(shared(const {'USER': 'anna'}).nameFor('Family PC'), 'Family PC');
  });

  test('a shared computer goes by the account too', () async {
    await settings.set(SharedComputer.sharedKey, true);

    expect(
      shared(const {'USER': 'anna'}).nameFor('Family PC'),
      'Family PC (Anna)',
    );
    expect(
      shared(const {'USERNAME': 'Ben'}).nameFor('Family PC'),
      'Family PC (Ben)',
    );
  });

  test('a name that already says whose it is stays as it is', () async {
    await settings.set(SharedComputer.sharedKey, true);

    expect(
      shared(const {'USER': 'simon'}).nameFor('Simon’s MacBook Pro'),
      'Simon’s MacBook Pro',
    );
    expect(
      shared(const {'USER': 'anna'}).nameFor('Simon’s MacBook Pro'),
      'Simon’s MacBook Pro (Anna)',
    );
  });

  test('a name the person chose always wins', () async {
    await settings.set(SharedComputer.sharedKey, true);
    await settings.set(SharedComputer.nameKey, 'Anna\'s corner');

    expect(shared(const {'USER': 'anna'}).nameFor('Family PC'), 'Family PC');
  });

  test('no account name leaves the name alone', () async {
    await settings.set(SharedComputer.sharedKey, true);

    expect(shared(const {'USER': ' '}).nameFor('Family PC'), 'Family PC');
  });

  test('hearing another account renames this one, without saving it as '
      'a chosen name', () async {
    final bus = MemoryDiscoveryBus();
    final anna = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: settings,
      device: const LocalDevice(
        name: 'Family PC',
        platform: .PLATFORM_WINDOWS,
        formFactor: .FORM_FACTOR_DESKTOP,
      ),
      discovery: bus.join(),
      port: 0,
      sameAccount: _anotherAccount,
    );
    final ben = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Family PC',
        platform: .PLATFORM_WINDOWS,
        formFactor: .FORM_FACTOR_DESKTOP,
      ),
      discovery: bus.join(),
      port: 0,
      sameAccount: _anotherAccount,
    );
    addTearDown(anna.stop);
    addTearDown(ben.stop);
    final subscription = shared(const {
      'USER': 'anna',
    }).follow(anna, computerName: 'Family PC');
    addTearDown(subscription.cancel);

    await anna.start();
    await ben.start();
    await _until(() => anna.device.name != 'Family PC');

    expect(anna.device.name, 'Family PC (Anna)');
    expect(settings.get<bool>(SharedComputer.sharedKey), isTrue);
    expect(settings.get<String>(SharedComputer.nameKey), isNull);
  });

  group('only I use this computer', () {
    late FerretEngine engine;

    setUp(() async {
      await settings.set(SharedComputer.sharedKey, true);
      engine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: settings,
        device: const LocalDevice(
          name: 'Simon’s MacBook Pro (Simon)',
          platform: .PLATFORM_MACOS,
          formFactor: .FORM_FACTOR_DESKTOP,
        ),
        discovery: MemoryDiscoveryBus().join(),
        port: 0,
        sameAccount: _anotherAccount,
      );
    });

    test('takes the account out of the name and shows previews again, '
        'keeping what was chosen for a device', () async {
      final previews = PrivatePreviews(settings);
      await previews.setShows('PIXEL', shows: false);

      await shared(const {'USER': 'simon'}).onlyMe(engine);

      expect(SharedComputer(settings).isShared, isFalse);
      expect(engine.device.name, 'Simon’s MacBook Pro');
      expect(settings.get<String>(SharedComputer.nameKey), isNull);
      expect(previews.shownByDefault, isTrue);
      expect(previews.showsFrom('IPHONE'), isTrue);
      expect(previews.showsFrom('PIXEL'), isFalse);
    });

    test('keeps a name the person chose', () async {
      await engine.rename('Desk');

      await shared(const {'USER': 'simon'}).onlyMe(engine);

      expect(SharedComputer(settings).isShared, isFalse);
      expect(engine.device.name, 'Desk');
    });

    test('another account heard later marks it shared again', () async {
      final bus = MemoryDiscoveryBus();
      final anna = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: settings,
        device: const LocalDevice(
          name: 'Family PC',
          platform: .PLATFORM_WINDOWS,
          formFactor: .FORM_FACTOR_DESKTOP,
        ),
        discovery: bus.join(),
        port: 0,
        sameAccount: _anotherAccount,
      );
      final ben = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: const LocalDevice(
          name: 'Family PC',
          platform: .PLATFORM_WINDOWS,
          formFactor: .FORM_FACTOR_DESKTOP,
        ),
        discovery: bus.join(),
        port: 0,
        sameAccount: _anotherAccount,
      );
      addTearDown(anna.stop);
      addTearDown(ben.stop);
      final computer = shared(const {'USER': 'anna'});
      await computer.onlyMe(anna);
      final subscription = computer.follow(anna, computerName: 'Family PC');
      addTearDown(subscription.cancel);

      await anna.start();
      await ben.start();
      await _until(() => computer.isShared);

      expect(computer.isShared, isTrue);
    });
  });
}

/// Two engines in one test run in this same account; these stand for two.
final _anotherAccount = SameAccount(listens: (_) async => false);

Future<void> _until(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
