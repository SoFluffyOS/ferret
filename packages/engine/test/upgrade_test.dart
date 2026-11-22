import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:transport/transport.dart';

import 'support/quiet_bus.dart';

/// Data folders that older builds wrote, each started by this one.
///
/// `test/fixtures/upgrade/<date>/` holds what the engine at the commit in
/// its `manifest.json` saved: a Mac, a Pixel and an iPad paired over
/// loopback (the iPad joined the Pixel through the Mac), an old phone
/// removed everywhere, a nickname and a feature turned off. The keys are
/// test keys made for these folders and nothing else.
void main() {
  for (final date in ['2026-11-19', '2026-11-20']) {
    group('from the build of $date', () {
      late Directory home;
      late _Manifest manifest;
      final engines = <FerretEngine>[];

      setUp(() async {
        home = await Directory.systemTemp.createTemp('ferret_upgrade');
        await _copy(
          Directory(p.join('test', 'fixtures', 'upgrade', date)),
          home,
        );
        manifest = _Manifest(
          jsonDecode(
            await File(p.join(home.path, 'manifest.json')).readAsString(),
          ) as Map<String, dynamic>,
        );
      });

      tearDown(() async {
        for (final engine in engines) {
          await engine.stop();
        }

        engines.clear();
        await home.delete(recursive: true);
      });

      Future<FerretEngine> open(
        String device, {
        SecretStore Function(FileSecretStore file)? secrets,
        Discovery? discovery,
        List<LocalNetwork> networks = const [_home],
      }) async {
        final root = p.join(home.path, device);
        final file = FileSecretStore(p.join(root, 'secrets'));
        final engine = await FerretEngine.create(
          secrets: secrets?.call(file) ?? file,
          settings: await JsonFileSettingsStore.open(p.join(root, 'settings')),
          device: LocalDevice(
            name: manifest.name(device),
            platform: .PLATFORM_MACOS,
            formFactor: .FORM_FACTOR_LAPTOP,
          ),
          discovery: discovery ?? QuietBus().join(),
          port: 0,
          networks: () async => networks,
          ownAddresses: () async => const {},
          // Updating with the copy check on: the old folder's key stays.
          machineId: 'upgrade-test-$device',
        );
        engines.add(engine);
        return engine;
      }

      test('keeps its device id, paired devices, names and removals', () async {
        final mac = await open('mac');
        final pixel = await open('pixel');

        expect(mac.identity.deviceId, manifest.id('mac'));
        expect(pixel.identity.deviceId, manifest.id('pixel'));
        expect(
          {for (final device in mac.trustStore.devices) device.id},
          manifest.trusted('mac'),
        );
        expect(
          mac.trustStore[manifest.id('pixel')]?.name,
          'My Pixel',
          reason: 'the nickname given on the Mac',
        );
        expect(
          pixel.trustStore[manifest.id('ipad')]?.introducedBy,
          manifest.id('mac'),
          reason: 'joined through the Mac, and still trusted: no request',
        );
        expect(
          mac.trustStore.forgottenOf(manifest.removed)?.by,
          ForgottenBy.everywhere,
        );
        expect(pixel.trustStore.isTrusted(manifest.removed), isFalse);
        expect(mac.access.blockedFor(manifest.id('ipad')), {'clipboard'});
      });

      test('keeps the settings it had and defaults the new ones', () async {
        final mac = await open('mac');
        await mac.start();

        expect(mac.settings.get<String>('shell.language'), 'vi');
        expect(mac.sharesPairings, isTrue);
        expect(mac.alwaysVisible, isFalse);
        expect(mac.isAnnouncing, isTrue, reason: 'it is still learning');

        await mac.settings.set('shell.language', 'en');
        final saved = jsonDecode(
          await File(
            p.join(home.path, 'mac', 'settings', 'settings.json'),
          ).readAsString(),
        ) as Map<String, dynamic>;
        expect(saved['power.card_dismissed'], isTrue, reason: 'kept as is');
        expect(saved['shell.pinned_devices'], [manifest.id('pixel')]);
      });

      test('on a Mac its key moves to the keychain on the first start, and '
          'it stays the same device after', () async {
        final keychain = MemorySecretStore();
        final original = (jsonDecode(
          await File(
            p.join(home.path, 'mac', 'secrets', 'secrets.json'),
          ).readAsString(),
        ) as Map<String, dynamic>)[DeviceIdentity.storageKey];
        SecretStore inKeychain(FileSecretStore file) =>
            KeychainIdentityStore(file: file, keychain: keychain);

        final first = await open('mac', secrets: inKeychain);
        expect(first.identity.deviceId, manifest.id('mac'));
        expect(
          await keychain.read(
            KeychainIdentityStore.accountFor(manifest.id('mac')),
          ),
          original,
        );
        final file = FileSecretStore(p.join(home.path, 'mac', 'secrets'));
        expect(
          await file.read(DeviceIdentity.storageKey),
          'keychain:${manifest.id('mac')}',
        );

        final again = await open('mac', secrets: inKeychain);
        expect(again.identity.deviceId, manifest.id('mac'));
        expect(
          {for (final device in again.trustStore.devices) device.id},
          manifest.trusted('mac'),
        );
      });

      test('a keychain that turns the key away leaves it in its file, and '
          'the device is still itself', () async {
        SecretStore refusing(FileSecretStore file) =>
            KeychainIdentityStore(file: file, keychain: _RefusingKeychain());

        final mac = await open('mac', secrets: refusing);

        expect(mac.identity.deviceId, manifest.id('mac'));
        final file = FileSecretStore(p.join(home.path, 'mac', 'secrets'));
        expect(
          KeychainIdentityStore.markedDeviceId(
            (await file.read(DeviceIdentity.storageKey))!,
          ),
          isNull,
        );
        expect(mac.trustStore.devices, hasLength(2));
      });

      test('two updated devices on their home network find each other, and '
          'keep announcing there', () async {
        final bus = QuietBus();
        final macWay = bus.join();
        final pixelWay = bus.join();
        final mac = await open('mac', discovery: macWay);
        final pixel = await open('pixel', discovery: pixelWay);

        await mac.start();
        expect(macWay.isAnnouncing, isTrue);
        await pixel.start();
        await _until(
          () => mac.sessionFor(manifest.id('pixel')) != null,
          'the two meet',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(macWay.isAnnouncing, isTrue);
        expect(pixelWay.isAnnouncing, isTrue);
        expect(
          mac.settings.get<List<Object?>>(KnownNetworks.settingsKey),
          hasLength(1),
          reason: 'home is learned',
        );
      });

      test('for two weeks after the update it announces on networks it '
          'never met them on too, then only where it did', () async {
        final start = DateTime(2026, 11, 22, 9);
        var now = start;
        await withClock(Clock(() => now), () async {
          final bus = QuietBus();
          final macWay = bus.join();
          final pixelWay = bus.join();
          final mac = await open('mac', discovery: macWay);
          final pixel = await open('pixel', discovery: pixelWay);
          await mac.start();
          await pixel.start();
          await _until(
            () => mac.sessionFor(manifest.id('pixel')) != null,
            'the two meet at home',
          );
          await pixel.stop();
          await mac.stop();

          final atOffice = await open(
            'mac',
            discovery: QuietBus().join(),
            networks: const [_office],
          );
          await atOffice.start();
          expect(atOffice.isAnnouncing, isTrue, reason: 'still learning');
          await atOffice.stop();

          now = start.add(
            KnownNetworks.learningAfterUpdate + const Duration(hours: 1),
          );
          final later = await open(
            'mac',
            discovery: QuietBus().join(),
            networks: const [_office],
          );
          await later.start();
          expect(later.isAnnouncing, isFalse);
          await later.stop();

          final backHome = await open('mac', discovery: QuietBus().join());
          await backHome.start();
          expect(backHome.isAnnouncing, isTrue);
        });
      });

      test('settings in shapes it doesn\'t expect don\'t stop it', () async {
        final settings = File(
          p.join(home.path, 'mac', 'settings', 'settings.json'),
        );
        final values =
            jsonDecode(await settings.readAsString()) as Map<String, dynamic>;
        values.addAll({
          KnownNetworks.settingsKey: 'not a list',
          KnownNetworks.learningUntilKey: 'soon',
          FerretEngine.alwaysVisibleKey: 'yes',
          FerretEngine.keptRemovalsKey: {'odd': 1},
          'access.blocked_features': [1, 2, 3],
          'a.key.from.the.future': {'nested': true},
        });
        await settings.writeAsString(jsonEncode(values));

        final mac = await open('mac');
        await mac.start();

        expect(mac.identity.deviceId, manifest.id('mac'));
        expect(mac.isAnnouncing, isTrue);
        expect(mac.access.blockedFor(manifest.id('ipad')), isEmpty);
      });
    });
  }
}

const _home = LocalNetwork(subnet: '127.0.0', gatewayMac: 'a4:2b:b0:01:02:03');
const _office = LocalNetwork(subnet: '10.20.30');

class _Manifest {
  _Manifest(this._json);

  final Map<String, dynamic> _json;

  Map<String, dynamic> _device(String name) =>
      (_json['devices'] as Map<String, dynamic>)[name] as Map<String, dynamic>;

  String id(String device) => _device(device)['id'] as String;

  String name(String device) => _device(device)['name'] as String;

  Set<String> trusted(String device) => {
    ...(_device(device)['trusted'] as List).cast<String>(),
  };

  String get removed => _json['removed_everywhere'] as String;
}

class _RefusingKeychain implements SecretStore {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) =>
      Future.error(const FileSystemException('errSecInteractionNotAllowed'));

  @override
  Future<void> delete(String key) async {}
}

Future<void> _copy(Directory from, Directory to) async {
  await for (final entity in from.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }

    final target = File(
      p.join(to.path, p.relative(entity.path, from: from.path)),
    );
    await target.parent.create(recursive: true);
    await entity.copy(target.path);
  }
}

Future<void> _until(bool Function() condition, String what) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting: $what');
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
