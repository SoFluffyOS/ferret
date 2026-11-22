import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A copy of Ferret's data on another computer (Migration Assistant, a
/// restored backup, a copied folder) starts over as a new device; the same
/// computer, and a computer updating from a build without the check, keep
/// their key.
void main() {
  late Directory folder;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('ferret_home_');
  });

  tearDown(() => folder.delete(recursive: true));

  Future<FerretEngine> open(
    String machineId, {
    String? root,
    SecretStore Function(FileSecretStore file)? secrets,
  }) async {
    final dir = root ?? folder.path;
    final file = FileSecretStore(p.join(dir, 'secrets'));
    return FerretEngine.create(
      secrets: secrets?.call(file) ?? file,
      settings: await JsonFileSettingsStore.open(p.join(dir, 'settings')),
      device: const LocalDevice(
        name: 'MacBook Air',
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      port: 0,
      machineId: machineId,
    );
  }

  Future<TrustedDevice> pixel() async {
    final identity = await DeviceIdentity.generate();
    return TrustedDevice(
      id: identity.deviceId,
      name: 'Pixel 7',
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: identity.publicKey,
      pairedAt: DateTime.utc(2026, 11),
    );
  }

  Future<void> copyTo(String target) async {
    await for (final entry in folder.list(recursive: true)) {
      if (entry is File) {
        final to = File(
          p.join(target, p.relative(entry.path, from: folder.path)),
        );
        await to.parent.create(recursive: true);
        await entry.copy(to.path);
      }
    }
  }

  test('the same computer keeps its key and pairings', () async {
    final first = await open('mac-a');
    await first.trustStore.save(await pixel());

    final again = await open('mac-a');

    expect(again.identity.deviceId, first.identity.deviceId);
    expect(again.trustStore.devices.single.name, 'Pixel 7');
    expect(IdentityHome.movedFrom(again.settings), isNull);
  });

  test('an install from before the check keeps its key and pairings, and '
      'learns this is home', () async {
    final old = await FerretEngine.create(
      secrets: FileSecretStore(p.join(folder.path, 'secrets')),
      settings: await JsonFileSettingsStore.open(
        p.join(folder.path, 'settings'),
      ),
      device: const LocalDevice(
        name: 'MacBook Air',
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      port: 0,
    );
    await old.trustStore.save(await pixel());

    final updated = await open('mac-a');
    expect(updated.identity.deviceId, old.identity.deviceId);
    expect(updated.trustStore.devices, hasLength(1));

    final copy = Directory(
      p.join(folder.path, '..', '${p.basename(folder.path)}_b'),
    );
    await copyTo(copy.path);
    addTearDown(() => copy.delete(recursive: true));
    final moved = await open('mac-b', root: copy.path);
    expect(moved.identity.deviceId, isNot(old.identity.deviceId));
  });

  test('a copy on another computer starts over as a new device and keeps '
      'a note of what was paired', () async {
    final original = await open('mac-a');
    final phone = await pixel();
    await original.trustStore.save(phone);
    await original.trustStore.rename(phone.id, "Simon's phone");
    await original.settings.set(KnownNetworks.settingsKey, ['10.0.0:aa']);

    final copy = Directory(
      p.join(folder.path, '..', '${p.basename(folder.path)}_b'),
    );
    await copyTo(copy.path);
    addTearDown(() => copy.delete(recursive: true));

    final moved = await open('mac-b', root: copy.path);

    expect(moved.identity.deviceId, isNot(original.identity.deviceId));
    expect(moved.trustStore.devices, isEmpty);
    expect(moved.trustStore.forgotten, isEmpty);
    expect(
      moved.settings.get<List<Object?>>(KnownNetworks.settingsKey),
      isEmpty,
    );
    expect(moved.isAnnouncing, isTrue);
    final note = IdentityHome.movedFrom(moved.settings)!;
    expect(note.devices.single.id, phone.id);
    expect(note.devices.single.name, "Simon's phone");
    expect(note.devices.single.platform.name, 'PLATFORM_ANDROID');

    final next = await open('mac-b', root: copy.path);
    expect(next.identity.deviceId, moved.identity.deviceId);

    await IdentityHome.dismiss(next.settings);
    expect(IdentityHome.movedFrom(next.settings), isNull);

    final back = await open('mac-a');
    expect(back.identity.deviceId, original.identity.deviceId);
    expect(back.trustStore.devices.single.id, phone.id);
  });

  test('a key in a copied keychain is let go, and a keychain that will not '
      'open here does not stop the start', () async {
    final keychain = _Keychain();
    SecretStore withKeychain(FileSecretStore file) =>
        KeychainIdentityStore(file: file, keychain: keychain);

    final original = await open('mac-a', secrets: withKeychain);
    final oldAccount = KeychainIdentityStore.accountFor(
      original.identity.deviceId,
    );
    expect(keychain.items.keys, [oldAccount]);

    keychain.locked = true;
    final copy = Directory(
      p.join(folder.path, '..', '${p.basename(folder.path)}_b'),
    );
    await copyTo(copy.path);
    addTearDown(() => copy.delete(recursive: true));
    final moved = await open('mac-b', root: copy.path, secrets: withKeychain);

    expect(moved.identity.deviceId, isNot(original.identity.deviceId));
    keychain.locked = false;
    expect(keychain.items.keys, [oldAccount]);
  });

  test('no machine id, no check', () async {
    final secrets = MemorySecretStore();
    final settings = MemorySettingsStore();

    expect(
      await IdentityHome.settle(
        secrets: secrets,
        settings: settings,
        machineId: null,
      ),
      isNull,
    );
    expect(await secrets.read(IdentityHome.storageKey), isNull);
  });

  test('the machine id is never saved as it is', () async {
    final secrets = MemorySecretStore();
    await IdentityHome.settle(
      secrets: secrets,
      settings: MemorySettingsStore(),
      machineId: '8c6e1e0a-0000-4000-8000-123456789abc',
    );

    final saved = await secrets.read(IdentityHome.storageKey);
    expect(saved, isNotNull);
    expect(saved, isNot(contains('8c6e1e0a')));
  });

  group('MachineId', () {
    test('reads the Mac hardware UUID', () {
      const output = '''
+-o J413AP  <class IOPlatformExpertDevice, id 0x100000254>
    {
      "IOPlatformSerialNumber" = "XXXXXXXXXX"
      "IOPlatformUUID" = "4A1B2C3D-1111-2222-3333-444455556666"
    }''';
      expect(
        MachineId.fromIoreg(output),
        '4a1b2c3d-1111-2222-3333-444455556666',
      );
      expect(MachineId.fromIoreg('"IOPlatformUUID" = ""'), isNull);
    });

    test("reads Windows' MachineGuid", () {
      const output = r'''

HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography
    MachineGuid    REG_SZ    0f9e8d7c-6b5a-4938-2716-a5b4c3d2e1f0

''';
      expect(MachineId.fromReg(output), '0f9e8d7c-6b5a-4938-2716-a5b4c3d2e1f0');
      expect(MachineId.fromReg('ERROR: The system was unable'), isNull);
    });

    test("reads Linux' machine-id, but not an unset one", () {
      expect(
        MachineId.fromMachineIdFile('3F2A0718B1C24D5E9F00112233445566\n'),
        '3f2a0718b1c24d5e9f00112233445566',
      );
      expect(MachineId.fromMachineIdFile(''), isNull);
      expect(MachineId.fromMachineIdFile('uninitialized\n'), isNull);
      expect(MachineId.fromMachineIdFile('0' * 32), isNull);
    });
  });
}

/// A keychain that, like one copied from another Mac, may not open.
class _Keychain implements SecretStore {
  final Map<String, String> items = {};
  bool locked = false;

  void _check() {
    if (locked) {
      throw const FileSystemException('errSecInvalidKeychain');
    }
  }

  @override
  Future<String?> read(String key) async {
    _check();
    return items[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _check();
    items[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _check();
    items.remove(key);
  }
}
