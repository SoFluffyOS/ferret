import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

const _pairings = 'ferret.trusted_devices';

void main() {
  const key = DeviceIdentity.storageKey;

  late Directory folder;
  late FileSecretStore file;
  late _FakeKeychain keychain;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('ferret_keychain_');
    file = FileSecretStore(folder.path);
    keychain = _FakeKeychain();
  });

  tearDown(() => folder.delete(recursive: true));

  KeychainIdentityStore store({bool moves = true}) => KeychainIdentityStore(
    file: file,
    keychain: keychain,
    moves: moves,
    readRetries: const [Duration.zero, Duration.zero],
  );

  Future<String> savedKey() async => base64Encode(
    await NoiseCrypto.privateKeyOf(await NoiseCrypto.generateKeyPair()),
  );

  Future<Map<String, dynamic>> fileContents() async =>
      jsonDecode(await File('${folder.path}/secrets.json').readAsString())
          as Map<String, dynamic>;

  test('a key in the file moves to the keychain and leaves a marker', () async {
    final saved = await savedKey();
    final deviceId = (await DeviceIdentity.fromSaved(saved)).deviceId;
    await file.write(key, saved);
    await file.write(_pairings, '[]');

    final identity = await DeviceIdentity.loadOrCreate(store());

    expect(identity.deviceId, deviceId);
    expect(keychain.items, {
      KeychainIdentityStore.accountFor(deviceId): saved,
    });
    final contents = await fileContents();
    expect(contents[key], 'keychain:$deviceId');
    expect(contents[_pairings], '[]');
    expect(contents.values.join(), isNot(contains(saved)));
  });

  test('the next start reads the key back from the keychain', () async {
    final saved = await savedKey();
    await file.write(key, saved);
    final first = await DeviceIdentity.loadOrCreate(store());

    final again = await DeviceIdentity.loadOrCreate(
      KeychainIdentityStore(
        file: FileSecretStore(folder.path),
        keychain: keychain,
      ),
    );

    expect(again.deviceId, first.deviceId);
    expect(keychain.writes, 1);
  });

  test('a keychain that refuses the write keeps the key in the file and tries '
      'again next start', () async {
    final saved = await savedKey();
    await file.write(key, saved);
    keychain.failWrites = true;

    final identity = await DeviceIdentity.loadOrCreate(store());

    expect(identity.deviceId, (await DeviceIdentity.fromSaved(saved)).deviceId);
    expect((await fileContents())[key], saved);

    keychain.failWrites = false;
    await DeviceIdentity.loadOrCreate(store());

    expect((await fileContents())[key], 'keychain:${identity.deviceId}');
  });

  test('a keychain that gives back something else keeps the file', () async {
    final saved = await savedKey();
    await file.write(key, saved);
    keychain.garbleReads = true;

    await DeviceIdentity.loadOrCreate(store());

    expect((await fileContents())[key], saved);
  });

  test('a keychain that fails the read-back keeps the file', () async {
    final saved = await savedKey();
    await file.write(key, saved);
    keychain.failReads = true;

    await DeviceIdentity.loadOrCreate(store());

    expect((await fileContents())[key], saved);
  });

  test('a new device puts its new key straight in the keychain', () async {
    final identity = await DeviceIdentity.loadOrCreate(store());

    expect((await fileContents())[key], 'keychain:${identity.deviceId}');
    expect(
      keychain.items.keys,
      [KeychainIdentityStore.accountFor(identity.deviceId)],
    );
  });

  test(
    'a new device whose keychain refuses keeps the key in the file',
    () async {
      keychain.failWrites = true;

      final identity = await DeviceIdentity.loadOrCreate(store());

      final kept = (await fileContents())[key] as String;
      expect(kept, isNot(startsWith('keychain:')));
      expect(
        (await DeviceIdentity.fromSaved(kept)).deviceId,
        identity.deviceId,
      );
    },
  );

  test(
    'without moving, a key stays in the file but a marker is still read',
    () async {
      final saved = await savedKey();
      await file.write(key, saved);

      await DeviceIdentity.loadOrCreate(store(moves: false));
      expect((await fileContents())[key], saved);
      expect(keychain.items, isEmpty);

      final moved = await DeviceIdentity.loadOrCreate(store());
      final read = await DeviceIdentity.loadOrCreate(store(moves: false));
      expect(read.deviceId, moved.deviceId);
    },
  );

  test('a keychain that keeps failing stops the start instead of making a new '
      'identity', () async {
    final identity = await DeviceIdentity.loadOrCreate(store());
    keychain.failReads = true;

    await expectLater(
      DeviceIdentity.loadOrCreate(store()),
      throwsA(isA<KeychainIdentityException>()),
    );
    expect((await fileContents())[key], 'keychain:${identity.deviceId}');
    expect(keychain.reads, greaterThanOrEqualTo(3));
  });

  test('a keychain that fails once is read again', () async {
    final identity = await DeviceIdentity.loadOrCreate(store());
    keychain.failNextReads = 2;

    final again = await DeviceIdentity.loadOrCreate(store());

    expect(again.deviceId, identity.deviceId);
  });

  test('a keychain item holding another key is refused', () async {
    final identity = await DeviceIdentity.loadOrCreate(store());
    keychain.items[KeychainIdentityStore.accountFor(identity.deviceId)] =
        await savedKey();

    await expectLater(
      DeviceIdentity.loadOrCreate(store()),
      throwsA(isA<KeychainIdentityException>()),
    );
  });

  test(
    'a deleted keychain item makes a new identity and keeps the old marker',
    () async {
      final old = await DeviceIdentity.loadOrCreate(store());
      keychain.items.clear();

      final fresh = await DeviceIdentity.loadOrCreate(store());

      expect(fresh.deviceId, isNot(old.deviceId));
      final contents = await fileContents();
      expect(contents[key], 'keychain:${fresh.deviceId}');
      expect(
        contents[KeychainIdentityStore.lostKey],
        'keychain:${old.deviceId}',
      );
    },
  );

  test('two data folders keep two keychain items', () async {
    final other = await Directory.systemTemp.createTemp('ferret_keychain_');
    addTearDown(() => other.delete(recursive: true));

    final first = await DeviceIdentity.loadOrCreate(store());
    final second = await DeviceIdentity.loadOrCreate(
      KeychainIdentityStore(
        file: FileSecretStore(other.path),
        keychain: keychain,
      ),
    );

    expect(second.deviceId, isNot(first.deviceId));
    expect(keychain.items, hasLength(2));
    expect(
      (await DeviceIdentity.loadOrCreate(store())).deviceId,
      first.deviceId,
    );
  });

  test('other secrets stay in the file', () async {
    final secrets = store();
    await secrets.write(_pairings, '[]');

    expect(await secrets.read(_pairings), '[]');
    expect(keychain.items, isEmpty);
  });

  test('deleting the key removes the keychain item too', () async {
    final secrets = store();
    await DeviceIdentity.loadOrCreate(secrets);

    await secrets.delete(key);

    expect(keychain.items, isEmpty);
    expect(await file.read(key), isNull);
  });

  test('the app still knows its ferret-cli by a marker', () async {
    final cli = await DeviceIdentity.loadOrCreate(store());

    final same = SameAccount(
      siblingSecrets: [folder.path],
      listens: (_) async => false,
    );

    expect(
      await same.runs(
        DiscoveredPeer(
          announce: Announce(deviceId: cli.deviceId, port: 1),
          host: '127.0.0.1',
        ),
      ),
      isTrue,
    );
  });
}

class _FakeKeychain implements SecretStore {
  final Map<String, String> items = {};
  bool failWrites = false;
  bool failReads = false;
  bool garbleReads = false;
  int failNextReads = 0;
  int writes = 0;
  int reads = 0;

  @override
  Future<String?> read(String key) async {
    reads++;
    if (failReads) {
      throw const FileSystemException('errSecInteractionNotAllowed');
    }

    if (failNextReads > 0) {
      failNextReads--;
      throw const FileSystemException('errSecInteractionNotAllowed');
    }

    final value = items[key];
    if (garbleReads && value != null) {
      return '${value}x';
    }

    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) {
      throw const FileSystemException('errSecAuthFailed');
    }

    writes++;
    items[key] = value;
  }

  @override
  Future<void> delete(String key) async => items.remove(key);
}
