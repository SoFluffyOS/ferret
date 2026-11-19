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
}

Future<void> _until(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
