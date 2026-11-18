import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/protocol.dart' hide Platform;
import 'package:transport/transport.dart';

import 'support/files.dart';

void main() {
  late Directory root;
  final engines = <FerretEngine>[];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_drop_engine');
  });

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
    await root.delete(recursive: true);
  });

  test(
    'two engines on loopback move a multi-chunk file over Noise',
    () async {
      final bus = _Bus();
      final laptopInbox = Directory(p.join(root.path, 'laptop'));
      final phoneInbox = Directory(p.join(root.path, 'phone'));
      final laptopDrop = DropFeature(store: folderStore(laptopInbox));
      final phoneDrop = DropFeature(store: folderStore(phoneInbox));

      Future<FerretEngine> start(String name, DropFeature drop) async {
        final engine = await FerretEngine.create(
          secrets: MemorySecretStore(),
          settings: MemorySettingsStore(),
          device: LocalDevice(
            name: name,
            platform: .PLATFORM_LINUX,
            formFactor: .FORM_FACTOR_LAPTOP,
          ),
          features: [drop],
          discovery: bus.join(),
          port: 0,
        );
        await engine.start();
        engines.add(engine);
        return engine;
      }

      final laptop = await start('Laptop', laptopDrop);
      final phone = await start('Phone', phoneDrop);
      final handle = await laptop.createPairingOffer();
      final offer = PairingCodes.parseOffer(handle.qrText);
      if (offer == null) {
        fail('The offer did not parse');
      }

      offer
        ..hosts.clear()
        ..hosts.add('127.0.0.1');
      expect(await phone.pairWithOffer(offer), isA<Paired>());
      await until(() => laptopDrop.targets.isNotEmpty);

      final source = await randomFile(root, 'video.mp4', 1300 * 1024);
      final sent = await laptopDrop.sendFiles(phone.identity.deviceId, [
        source.path,
      ]);
      if (sent == null) {
        fail('Nothing was sent');
      }

      await until(() => laptopDrop.registry[sent.id]?.status == .done);
      final received = phoneDrop.registry[sent.id];
      expect(received?.status, TransferStatus.done);
      expect(received?.deviceName, 'Laptop');
      expect(
        await File(p.join(phoneInbox.path, 'video.mp4')).readAsBytes(),
        await source.readAsBytes(),
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

class _Bus {
  final List<_BusDiscovery> members = [];

  Discovery join() {
    final member = _BusDiscovery(this);
    members.add(member);
    return member;
  }
}

class _BusDiscovery implements Discovery {
  _BusDiscovery(this.bus);

  final _Bus bus;
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  Announce? self;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start(Announce self) async {
    this.self = self;
    await announceNow();
  }

  @override
  Future<void> announceNow() async {
    final announce = self;
    if (announce == null) {
      return;
    }

    for (final member in bus.members) {
      if (member != this) {
        member._peers.add(
          DiscoveredPeer(announce: announce, host: '127.0.0.1'),
        );
      }
    }
  }

  @override
  Future<void> stop() async => self = null;
}
