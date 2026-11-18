import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hex.dart';

final _identity = AirPlayIdentity(
  deviceId: unhex('0a1b2c3d4e5f'),
  signingSeed: Uint8List(32),
);

AirPlayServiceInfo _info(String name) => AirPlayServiceInfo(
  name: name,
  identity: _identity,
  publicKey: unhex('00ff' * 16),
);

void main() {
  group('AirPlayIdentity', () {
    test('the same secret always gives the same identity', () {
      final first = AirPlayIdentity.derive(const [1, 2, 3]);
      final second = AirPlayIdentity.derive(const [1, 2, 3]);

      expect(first.deviceId, second.deviceId);
      expect(first.signingSeed, second.signingSeed);
    });

    test('another secret gives another identity', () {
      final first = AirPlayIdentity.derive(const [1, 2, 3]);
      final second = AirPlayIdentity.derive(const [1, 2, 4]);

      expect(first.deviceId, isNot(second.deviceId));
      expect(first.signingSeed, isNot(second.signingSeed));
    });

    test('the device id is a locally administered, single-device address', () {
      for (var secret = 0; secret < 64; secret++) {
        final first = AirPlayIdentity.derive([secret]).deviceId.first;

        expect(first & 0x02, 0x02);
        expect(first & 0x01, 0);
      }
    });

    test('the signing seed is not the device id it publishes', () {
      final identity = AirPlayIdentity.derive(const [1, 2, 3]);

      expect(
        hex(identity.signingSeed),
        isNot(startsWith(hex(identity.deviceId))),
      );
    });

    test('writes the device id both ways AirPlay wants it', () {
      expect(_identity.deviceIdColons, '0a:1b:2c:3d:4e:5f');
      expect(_identity.deviceIdCompact, '0A1B2C3D4E5F');
    });

    test('refuses ids and seeds of the wrong size', () {
      expect(
        () =>
            AirPlayIdentity(deviceId: Uint8List(5), signingSeed: Uint8List(32)),
        throwsArgumentError,
      );
      expect(
        () =>
            AirPlayIdentity(deviceId: Uint8List(6), signingSeed: Uint8List(31)),
        throwsArgumentError,
      );
    });
  });

  group('AirPlayServiceInfo', () {
    test('the AirPlay TXT record names the device, its key and features', () {
      final txt = _info('Ferret').airplayTxt;

      expect(txt['deviceid'], '0a:1b:2c:3d:4e:5f');
      expect(txt['features'], '0x5A7FFEE6,0x0');
      expect(txt['model'], 'AppleTV3,2');
      expect(txt['srcvers'], '220.68');
      expect(txt['pk'], '00ff' * 16);
      expect(txt['flags'], '0x4');
    });

    test('the RAOP TXT record carries the same key and features', () {
      final txt = _info('Ferret').raopTxt;

      expect(txt['ft'], '0x5A7FFEE6,0x0');
      expect(txt['am'], 'AppleTV3,2');
      expect(txt['vs'], '220.68');
      expect(txt['pk'], '00ff' * 16);
      expect(txt['et'], '0,3,5');
    });

    test('names the two services, RAOP with the device id in front', () {
      final info = _info('Simon’s Mac');

      expect(info.airplayInstance, 'Simon’s Mac');
      expect(info.raopInstance, '0A1B2C3D4E5F@Simon’s Mac');
      expect(info.hostName, 'ferret-0a1b2c3d4e5f');
    });

    test('cuts long names to fit a DNS label, never inside a character', () {
      final info = _info('🦊' * 40);

      expect(utf8.encode(info.airplayInstance).length, lessThanOrEqualTo(63));
      expect(utf8.encode(info.raopInstance).length, lessThanOrEqualTo(63));
      expect(info.airplayInstance, '🦊' * 15);
      expect(info.raopInstance, '0A1B2C3D4E5F@${'🦊' * 12}');
    });

    test('both services point at the same host and port', () {
      final services = AirPlayAdvertiser.servicesFor(_info('Ferret'), 7100);

      expect(services.map((service) => service.type), [
        '_airplay._tcp',
        '_raop._tcp',
      ]);
      expect(services.map((service) => service.port), [7100, 7100]);
      expect(services.map((service) => service.host).toSet(), hasLength(1));
    });

    test('writes TXT entries each behind its length', () {
      expect(AirPlayServiceInfo.txtBytes(const {'a': '1', 'bc': 'de'}), [
        3, ...'a=1'.codeUnits, //
        5, ...'bc=de'.codeUnits,
      ]);
    });

    test(
      '/info describes the display phones should size their picture for',
      () {
        final info = AirPlayServiceInfo(
          name: 'Ferret',
          identity: _identity,
          publicKey: Uint8List(32),
          display: const AirPlayDisplay(width: 2560, height: 1440, maxFps: 60),
        ).toInfo();

        final display = (info['displays'] as List<Object?>).single;
        expect(display, containsPair('widthPixels', 2560));
        expect(display, containsPair('heightPixels', 1440));
        expect(display, containsPair('maxFPS', 60));
      },
    );
  });

  test('a timing request carries the time it was sent at as NTP time', () {
    final packet = TimingClient.request(
      DateTime.fromMicrosecondsSinceEpoch(1500000, isUtc: true),
    );

    expect(packet, hasLength(32));
    expect(packet.sublist(0, 4), [0x80, 0xd2, 0x00, 0x07]);
    final data = ByteData.sublistView(packet);
    expect(data.getUint32(24), 2208988801);
    expect(data.getUint32(28), 0x80000000);
  });
}
