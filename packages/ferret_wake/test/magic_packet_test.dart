import 'package:ferret_wake/ferret_wake.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('MagicPacket', () {
    test('is six 0xFF bytes, then the MAC sixteen times', () {
      const mac = [0x3c, 0x22, 0xfb, 0x12, 0x34, 0x56];

      final packet = MagicPacket.of(mac);

      expect(packet, hasLength(102));
      expect(packet.sublist(0, 6), everyElement(0xff));
      for (var copy = 0; copy < 16; copy++) {
        final start = 6 + copy * 6;
        expect(packet.sublist(start, start + 6), mac);
      }
    });

    test('refuses an address that is not six bytes', () {
      expect(() => MagicPacket.of(const [1, 2, 3]), throwsArgumentError);
    });
  });

  group('MacAddress', () {
    test('reads the ways systems write it', () {
      const expected = [0x3c, 0x22, 0xfb, 0x12, 0x34, 0x56];

      expect(MacAddress.parse('3c:22:fb:12:34:56'), expected);
      expect(MacAddress.parse('3C-22-FB-12-34-56'), expected);
      expect(MacAddress.parse('3c22.fb12.3456'), expected);
      expect(MacAddress.parse(' 3c22fb123456\n'), expected);
    });

    test('rejects what is not one, and a card with no address', () {
      expect(MacAddress.parse(''), isNull);
      expect(MacAddress.parse('3c:22:fb:12:34'), isNull);
      expect(MacAddress.parse('zz:22:fb:12:34:56'), isNull);
      expect(MacAddress.parse('00:00:00:00:00:00'), isNull);
    });

    test('writes it lower case with colons', () {
      expect(
        MacAddress.format(const [0x3c, 0x22, 0xfb, 0x02, 0x34, 0x5]),
        '3c:22:fb:02:34:05',
      );
    });
  });

  group('WakePackets', () {
    test('go to the network, everywhere and the last address, on 9 and 7', () {
      final info = WakeInfo(
        interfaces: [
          WakeInterface(
            mac: const [0x3c, 0x22, 0xfb, 1, 2, 3],
            broadcast: '192.168.1.255',
          ),
        ],
      );

      final packets = WakePackets.of(info, lastAddress: '192.168.1.20');

      expect(
        [for (final packet in packets) '${packet.address}:${packet.port}'],
        [
          '192.168.1.255:9',
          '192.168.1.255:7',
          '255.255.255.255:9',
          '255.255.255.255:7',
          '192.168.1.20:9',
          '192.168.1.20:7',
        ],
      );
      expect(
        [for (final packet in packets) packet.isBroadcast],
        [true, true, true, true, false, false],
      );
      expect(
        packets.first.bytes,
        MagicPacket.of(const [0x3c, 0x22, 0xfb, 1, 2, 3]),
      );
    });

    test('skip cards without a usable MAC and odd addresses', () {
      final info = WakeInfo(
        interfaces: [
          WakeInterface(mac: const [0, 0, 0, 0, 0, 0], broadcast: '10.0.0.255'),
          WakeInterface(mac: const [1, 2, 3, 4, 5, 6], broadcast: 'nope'),
        ],
      );

      final packets = WakePackets.of(info, lastAddress: 'fe80::1');

      expect(
        {for (final packet in packets) packet.address},
        {'255.255.255.255'},
      );
    });

    test('are none without a card', () {
      expect(WakePackets.of(WakeInfo(), lastAddress: '192.168.1.20'), isEmpty);
    });
  });
}
