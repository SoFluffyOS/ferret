import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:ferret_phone_control/testing.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:ferret_power/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakePowerPlatform platform;
  late PowerCapabilities power;
  late FakeControlService service;
  late PhoneControl control;

  Future<void> create({
    bool shizuku = false,
    bool serviceOn = false,
    bool supported = true,
  }) async {
    platform = FakePowerPlatform(
      status: PowerStatus(
        supported: true,
        shizuku: switch (shizuku) {
          true => .ready,
          false => .notInstalled,
        },
      ),
    );
    power = PowerCapabilities.withPlatform(platform);
    await power.configure(shizuku: shizuku, root: false);
    service = FakeControlService(enabled: serviceOn);
    control = PhoneControl(
      power: power,
      service: service,
      supported: supported,
    );
    await control.start();
  }

  tearDown(() async {
    await control.dispose();
    await power.dispose();
  });

  group('which way', () {
    test('nothing until the owner turns something on', () async {
      await create();

      expect(control.path, ControlPath.none);
      expect(control.abilities, isEmpty);
      expect(control.buttons, isEmpty);
    });

    test('the service, once its owner turned it on', () async {
      await create(serviceOn: true);

      expect(control.path, ControlPath.service);
      expect(control.abilities, containsAll(PhoneAbility.values));
    });

    test('the power-ups first, when Shizuku is on too', () async {
      await create(shizuku: true, serviceOn: true);

      expect(control.path, ControlPath.powerUps);
    });

    test(
      'follows the service being turned on in the system settings',
      () async {
        await create();
        final changed = control.changes.first;

        service.turn(on: true);
        await changed;

        expect(control.path, ControlPath.service);
      },
    );

    test('an iPhone can never be controlled', () async {
      await create(shizuku: true, serviceOn: true, supported: false);

      expect(control.path, ControlPath.none);
    });
  });

  group('arming', () {
    test('refuses everything before arm and after disarm', () async {
      await create(serviceOn: true);

      expect(await control.touch(.down, 0.5, 0.5), isFalse);
      expect(service.done, isEmpty);

      await control.arm();
      expect(service.armed, isTrue);
      expect(await control.touch(.down, 0.5, 0.5), isTrue);

      await control.disarm();
      expect(service.armed, isFalse);
      expect(await control.touch(.up, 0.5, 0.5), isFalse);
      expect(service.done, ['touch:down']);
    });

    test('the service stays unarmed while the power-ups carry it', () async {
      await create(shizuku: true, serviceOn: true);

      await control.arm();
      await control.touch(.down, 0.25, 0.75);

      expect(service.armed, isFalse);
      expect(platform.injected, [const PowerTouch(.down, 0.25, 0.75)]);
    });

    test('disarming lifts what the power-ups left down', () async {
      await create(shizuku: true);
      await control.arm();

      await control.disarm();

      expect(platform.inputReleases, 1);
    });

    test('a service turned off mid-way just stops', () async {
      await create(serviceOn: true);
      await control.arm();

      service.turn(on: false);

      expect(control.path, ControlPath.none);
      expect(await control.text('hi'), isFalse);
    });
  });

  group('through the power-ups', () {
    setUp(() async {
      await create(shizuku: true);
      await control.arm();
    });

    test('scrolls down as the helper counts it: up is positive', () async {
      await control.scroll(0.5, 0.5, vertical: 2);

      expect(platform.injected, [const PowerScroll(0.5, 0.5, vertical: -2)]);
    });

    test('a button is a key press and release', () async {
      await control.press(.recents);

      expect(platform.injected, [
        const PowerKey(AndroidKeys.appSwitch, down: true),
        const PowerKey(AndroidKeys.appSwitch, down: false),
      ]);
    });

    test('keys and text go as they are', () async {
      await control.key(
        AndroidKeys.c,
        down: true,
        metaState: AndroidKeys.metaCtrl,
      );
      await control.text('héllo');

      expect(platform.injected, [
        const PowerKey(
          AndroidKeys.c,
          down: true,
          metaState: AndroidKeys.metaCtrl,
        ),
        const PowerText('héllo'),
      ]);
    });
  });

  group('through the service', () {
    setUp(() async {
      await create(serviceOn: true);
      await control.arm();
    });

    test('Back, Home, Recents and the shade are global actions', () async {
      for (final button in [
        PhoneButton.back,
        PhoneButton.home,
        PhoneButton.recents,
        PhoneButton.notifications,
        PhoneButton.power,
      ]) {
        await control.press(button);
      }

      expect(service.done, [
        'button:back',
        'button:home',
        'button:recents',
        'button:notifications',
        'button:lockScreen',
      ]);
    });

    test('copy, cut, paste and select all from their shortcuts', () async {
      for (final letter in [
        AndroidKeys.c,
        AndroidKeys.x,
        AndroidKeys.v,
        AndroidKeys.a,
      ]) {
        await control.key(letter, down: true, metaState: AndroidKeys.metaCtrl);
        await control.key(letter, down: false, metaState: AndroidKeys.metaCtrl);
      }

      expect(service.done, [
        'key:copy',
        'key:cut',
        'key:paste',
        'key:selectAll',
      ]);
    });

    test(
      'space types a space, and a key it has no stand-in for says no',
      () async {
        expect(await control.key(AndroidKeys.space, down: true), isTrue);
        expect(await control.key(AndroidKeys.arrowUp, down: true), isFalse);

        expect(service.typed, [' ']);
      },
    );

    test('typing without a text field in focus says no', () async {
      service.hasTextField = false;

      expect(await control.text('hi'), isFalse);
    });
  });
}
