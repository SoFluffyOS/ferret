import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  group('VpnAddresses.select', () {
    test('keeps VPN interfaces and Tailscale ranges only', () {
      final selected = VpnAddresses.select([
        _card('en0', ['192.168.1.20', 'fe80::1']),
        _card('tailscale0', ['100.101.102.103']),
        _card('utun4', ['fd7a:115c:a1e0::1', 'fe80::2']),
        _card('wg0', ['10.8.0.2']),
        _card('ztabcdef12', ['10.147.17.5']),
        _card('en1', ['100.80.0.1']),
        _card('lo0', ['127.0.0.1']),
      ]);

      expect(selected, [
        '100.101.102.103',
        'fd7a:115c:a1e0::1',
        '10.8.0.2',
        '10.147.17.5',
        '100.80.0.1',
      ]);
    });

    test('never shares a carrier address from mobile data', () {
      final selected = VpnAddresses.select([
        _card('rmnet_data0', ['100.70.1.1']),
        _card('pdp_ip0', ['100.72.4.4']),
      ]);

      expect(selected, isEmpty);
    });
  });

  group('VpnAddresses.accept', () {
    test('keeps IP addresses only, without repeats', () {
      const filter = VpnAddresses();

      final accepted = filter.accept([
        '100.101.102.103',
        'pixel.tail1234.ts.net',
        '127.0.0.1',
        '169.254.1.1',
        'fe80::1',
        '224.0.0.251',
        '0.0.0.0',
        '100.101.102.103',
        'fd7a:115c:a1e0::1',
      ]);

      expect(accepted, ['100.101.102.103', 'fd7a:115c:a1e0::1']);
    });

    test('keeps at most eight', () {
      const filter = VpnAddresses();

      final accepted = filter.accept([
        for (var index = 1; index <= 20; index++) '10.8.0.$index',
      ]);

      expect(accepted, hasLength(VpnAddresses.maxAddresses));
    });
  });

  test('parses typed addresses with and without a port', () {
    expect(VpnAddresses.parseTyped('100.64.1.2', 47640), ('100.64.1.2', 47640));
    expect(VpnAddresses.parseTyped(' pixel.ts.net:5000 ', 47640), (
      'pixel.ts.net',
      5000,
    ));
    expect(VpnAddresses.parseTyped('[fd7a::1]:5000', 47640), ('fd7a::1', 5000));
    expect(VpnAddresses.parseTyped('fd7a::1', 47640), ('fd7a::1', 47640));
  });

  test('tells VPN hosts apart from local ones', () {
    expect(VpnAddresses.isVpnHost('100.100.1.1', const []), isTrue);
    expect(VpnAddresses.isVpnHost('192.168.1.2', const []), isFalse);
    expect(VpnAddresses.isVpnHost('10.8.0.2', const ['10.8.0.2']), isTrue);
  });

  group('VpnReacher', () {
    test('waits longer after each miss and stops once reached', () async {
      final tries = <DateTime>[];
      final done = Completer<void>();
      final reacher = VpnReacher(
        delays: const [
          Duration(milliseconds: 20),
          Duration(milliseconds: 60),
          Duration(milliseconds: 120),
        ],
        attempt: (_) async {
          tries.add(DateTime.now());
          if (tries.length < 4) {
            return false;
          }

          done.complete();
          return true;
        },
      );

      final started = DateTime.now();
      reacher.reach('pixel');
      await done.future.timeout(const Duration(seconds: 3));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final gaps = [
        tries.first.difference(started),
        for (var index = 1; index < tries.length; index++)
          tries[index].difference(tries[index - 1]),
      ];
      expect(tries, hasLength(4));
      expect(gaps[1], greaterThanOrEqualTo(const Duration(milliseconds: 55)));
      expect(gaps[2], greaterThanOrEqualTo(const Duration(milliseconds: 110)));
      expect(gaps[3], greaterThanOrEqualTo(const Duration(milliseconds: 110)));
      expect(reacher.reaching, isEmpty);
    });

    test('stop ends the tries', () async {
      var tries = 0;
      final reacher = VpnReacher(
        delays: const [Duration(milliseconds: 20)],
        attempt: (_) async {
          tries++;
          return false;
        },
      );

      reacher.reach('pixel');
      await Future<void>.delayed(const Duration(milliseconds: 70));
      reacher.stop('pixel');
      final stoppedAt = tries;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(stoppedAt, greaterThan(0));
      expect(tries, stoppedAt);
    });
  });

  group('Hello', () {
    test('an older device reads a new Hello and ignores the VPN fields', () {
      final bytes = Hello(
        listenPort: 47640,
        vpnAddresses: ['100.101.102.103'],
        wantsVpnAddresses: true,
      ).writeToBuffer();

      final old = _OldHello.fromBuffer(bytes);

      expect(old.listenPort, 47640);
    });

    test('a Hello from an older device reads as no VPN reach', () {
      final bytes = (_OldHello()..listenPort = 47640).writeToBuffer();

      final hello = Hello.fromBuffer(bytes);

      expect(hello.listenPort, 47640);
      expect(hello.vpnAddresses, isEmpty);
      expect(hello.wantsVpnAddresses, isFalse);
    });

    test('the VPN fields come back the same', () {
      final hello = Hello(
        vpnAddresses: ['100.101.102.103', 'fd7a:115c:a1e0::1'],
        wantsVpnAddresses: true,
      );

      final read = Hello.fromBuffer(hello.writeToBuffer());

      expect(read.vpnAddresses, ['100.101.102.103', 'fd7a:115c:a1e0::1']);
      expect(read.wantsVpnAddresses, isTrue);
    });
  });

  test('a trusted device keeps its VPN settings across a restart', () {
    final device = TrustedDevice(
      id: 'pixel',
      name: 'Pixel 7',
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: .fromList([1, 2, 3]),
      pairedAt: DateTime(2026),
      reachOverVpn: true,
      reachAt: 'pixel.ts.net',
      vpnAddresses: const ['100.101.102.103'],
      sharesVpn: true,
    );

    final read = TrustedDevice.fromJson(device.toJson());
    final cleared = read.withReachAt(' ');

    expect(read.reachOverVpn, isTrue);
    expect(read.reachAt, 'pixel.ts.net');
    expect(read.vpnAddresses, ['100.101.102.103']);
    expect(read.sharesVpn, isTrue);
    expect(cleared.reachAt, isNull);
    expect(cleared.reachOverVpn, isTrue);
  });

  group('over loopback', () {
    final engines = <FerretEngine>[];

    tearDown(() async {
      for (final engine in engines) {
        await engine.stop();
      }

      engines.clear();
    });

    Future<FerretEngine> startEngine(
      String name, {
      List<String> vpn = const [],
    }) async {
      final engine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: LocalDevice(
          name: name,
          platform: .PLATFORM_LINUX,
          formFactor: .FORM_FACTOR_LAPTOP,
        ),
        discovery: _SilentDiscovery(),
        port: 0,
        vpnFilter: const VpnAddresses(allowLoopback: true),
        vpnAddressSource: () async => vpn,
        vpnDelays: const [Duration(milliseconds: 50)],
      );
      await engine.start();
      engines.add(engine);
      return engine;
    }

    Future<void> pair(FerretEngine scanner, FerretEngine shower) async {
      final handle = await shower.createPairingOffer();
      final offer = PairingCodes.parseOffer(handle.qrText);
      if (offer == null) {
        fail('The offer did not parse');
      }

      offer
        ..hosts.clear()
        ..hosts.add('127.0.0.1')
        ..port = shower.port;
      expect(await scanner.pairWithOffer(offer), isA<Paired>());
      await _until(
        () =>
            scanner.sessionFor(shower.identity.deviceId) != null &&
            shower.sessionFor(scanner.identity.deviceId) != null,
      );
    }

    TrustedDevice trusted(FerretEngine engine, FerretEngine other) {
      final device = engine.trustStore[other.identity.deviceId];
      if (device == null) {
        fail('Not paired');
      }

      return device;
    }

    DeviceStatus statusOf(FerretEngine engine, FerretEngine other) => engine
        .devices
        .firstWhere((status) => status.device.id == other.identity.deviceId);

    test('VPN addresses go only to a device that turned it on', () async {
      final phone = await startEngine('Phone', vpn: ['100.101.102.103']);
      final laptop = await startEngine('Laptop');
      final desktop = await startEngine('Desktop');
      await pair(laptop, phone);
      await pair(desktop, phone);

      await laptop.setReachOverVpn(phone.identity.deviceId, reach: true);
      await _until(
        () => trusted(laptop, phone).vpnAddresses.isNotEmpty,
      );

      expect(trusted(laptop, phone).vpnAddresses, ['100.101.102.103']);
      expect(trusted(phone, laptop).sharesVpn, isTrue);
      expect(trusted(desktop, phone).vpnAddresses, isEmpty);
      expect(trusted(phone, desktop).sharesVpn, isFalse);
      expect(
        desktop.sessionFor(phone.identity.deviceId)?.remoteHello?.vpnAddresses,
        isEmpty,
      );
    });

    test(
      'the next Hello carries them, and turning it off forgets them',
      () async {
        final phone = await startEngine('Phone', vpn: ['100.101.102.103']);
        final laptop = await startEngine('Laptop');
        await pair(laptop, phone);
        await laptop.setReachOverVpn(phone.identity.deviceId, reach: true);
        await _until(() => trusted(phone, laptop).sharesVpn);

        await laptop.sessionFor(phone.identity.deviceId)?.close();
        await _until(() => laptop.sessionFor(phone.identity.deviceId) != null);
        final hello = laptop.sessionFor(phone.identity.deviceId)?.remoteHello;
        await laptop.setReachOverVpn(phone.identity.deviceId, reach: false);
        await _until(() => !trusted(phone, laptop).sharesVpn);

        expect(hello?.vpnAddresses, ['100.101.102.103']);
        expect(trusted(laptop, phone).vpnAddresses, isEmpty);
      },
    );

    test('the local network is tried first while it works', () async {
      final phone = await startEngine('Phone', vpn: ['127.0.0.1']);
      final laptop = await startEngine('Laptop');
      await pair(laptop, phone);
      await laptop.setReachOverVpn(phone.identity.deviceId, reach: true);
      await laptop.setReachAt(phone.identity.deviceId, 'localhost');

      await laptop.sessionFor(phone.identity.deviceId)?.close();
      await _until(() => laptop.sessionFor(phone.identity.deviceId) != null);

      expect(
        laptop.sessionFor(phone.identity.deviceId)?.remoteHost,
        '127.0.0.1',
      );
    });

    test('a device the local network misses is reached over the VPN', () async {
      final phone = await startEngine('Phone', vpn: ['127.0.0.1']);
      final laptop = await startEngine('Laptop');
      await pair(laptop, phone);
      await laptop.setReachOverVpn(phone.identity.deviceId, reach: true);
      await _until(() => trusted(laptop, phone).vpnAddresses.isNotEmpty);
      await laptop.trustStore.save(
        trusted(laptop, phone).copyWith(lastHost: 'lan.invalid'),
      );

      await laptop.sessionFor(phone.identity.deviceId)?.close();
      await _until(() => laptop.sessionFor(phone.identity.deviceId) != null);

      expect(statusOf(laptop, phone).reachedOverVpn, isTrue);
      expect(trusted(laptop, phone).lastHost, 'lan.invalid');
    });

    test('a typed address, such as a MagicDNS name, is dialed too', () async {
      final phone = await startEngine('Phone');
      final laptop = await startEngine('Laptop');
      await pair(laptop, phone);
      await laptop.setReachOverVpn(phone.identity.deviceId, reach: true);
      await laptop.setReachAt(phone.identity.deviceId, 'localhost');
      await laptop.trustStore.save(
        trusted(laptop, phone).copyWith(lastHost: 'lan.invalid'),
      );

      await laptop.sessionFor(phone.identity.deviceId)?.close();
      await _until(() => laptop.sessionFor(phone.identity.deviceId) != null);

      expect(
        laptop.sessionFor(phone.identity.deviceId)?.remoteHost,
        'localhost',
      );
      expect(statusOf(laptop, phone).reachedOverVpn, isTrue);
    });

    test('nothing is dialed over the VPN while the switch is off', () async {
      final phone = await startEngine('Phone', vpn: ['127.0.0.1']);
      final laptop = await startEngine('Laptop');
      await pair(laptop, phone);
      await laptop.setReachAt(phone.identity.deviceId, 'localhost');
      await laptop.trustStore.save(
        trusted(laptop, phone).copyWith(lastHost: 'lan.invalid'),
      );

      await laptop.sessionFor(phone.identity.deviceId)?.close();
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(laptop.sessionFor(phone.identity.deviceId), isNull);
      expect(trusted(laptop, phone).vpnAddresses, isEmpty);
    });
  });
}

Future<void> _until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _SilentDiscovery implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}

({String name, List<InternetAddress> addresses}) _card(
  String name,
  List<String> addresses,
) => (
  name: name,
  addresses: [for (final text in addresses) InternetAddress(text)],
);

/// `Hello` as devices from before VPN reach know it.
class _OldHello extends GeneratedMessage {
  _OldHello();

  factory _OldHello.fromBuffer(List<int> bytes) =>
      _OldHello()..mergeFromBuffer(bytes);

  static final BuilderInfo _info =
      BuilderInfo(
          'Hello',
          package: const PackageName('ferret.v1'),
          createEmptyInstance: _OldHello.new,
        )
        ..aOM<DeviceInfo>(1, 'device', subBuilder: DeviceInfo.new)
        ..pPM<FeatureSupport>(2, 'features', subBuilder: FeatureSupport.new)
        ..aI(3, 'listenPort', fieldType: PbFieldType.OU3)
        ..hasRequiredFields = false;

  @override
  BuilderInfo get info_ => _info;

  @override
  _OldHello createEmptyInstance() => _OldHello();

  @override
  _OldHello clone() => deepCopy();

  int get listenPort => $_getIZ(2);
  set listenPort(int value) => $_setUnsignedInt32(2, value);
}
