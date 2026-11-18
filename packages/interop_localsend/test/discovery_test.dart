import 'dart:convert';
import 'dart:io';

import 'package:interop_localsend/interop_localsend.dart';
import 'package:test/test.dart';

const _self = LocalSendInfo(
  alias: 'Ferret Mac',
  fingerprint: 'AA11',
  port: 53317,
  protocol: 'https',
);

List<int> _packet(Map<String, Object?> fields) =>
    utf8.encode(jsonEncode(fields));

Map<String, Object?> _orange({bool announce = true}) => {
  'alias': 'Nice Orange',
  'version': '2.0',
  'deviceModel': 'Samsung',
  'deviceType': 'mobile',
  'fingerprint': 'bb22',
  'port': 53317,
  'protocol': 'https',
  'download': true,
  'announce': announce,
};

void main() {
  final phone = InternetAddress('192.168.1.20');

  group('announcement packets', () {
    test('reads the announcement from the protocol', () {
      final announcement = LocalSendAnnouncement.decode(_packet(_orange()));

      expect(announcement?.announce, isTrue);
      expect(announcement?.info.alias, 'Nice Orange');
      expect(announcement?.info.deviceType, LocalSendDeviceType.mobile);
      expect(announcement?.info.fingerprint, 'bb22');
    });

    test('a missing announce field means an answer', () {
      final fields = _orange()..remove('announce');

      expect(LocalSendAnnouncement.decode(_packet(fields))?.announce, isFalse);
    });

    test('writes a packet other members can read', () {
      final packet = const LocalSendAnnouncement(
        info: _self,
        announce: true,
      ).encode();

      expect(jsonDecode(utf8.decode(packet)), {
        'alias': 'Ferret Mac',
        'version': '2.0',
        'deviceModel': null,
        'deviceType': 'desktop',
        'fingerprint': 'AA11',
        'port': 53317,
        'protocol': 'https',
        'download': false,
        'announce': true,
      });
    });

    test('ignores anything that is not an announcement', () {
      expect(LocalSendAnnouncement.decode(const []), isNull);
      expect(LocalSendAnnouncement.decode(utf8.encode('hello')), isNull);
      expect(LocalSendAnnouncement.decode(const [0xff, 0xfe, 0x00]), isNull);
      expect(LocalSendAnnouncement.decode(_packet({'alias': 'x'})), isNull);
      expect(LocalSendAnnouncement.decode(utf8.encode('[1, 2]')), isNull);
      expect(
        LocalSendAnnouncement.decode(
          _packet({..._orange(), 'alias': 'x' * 5000}),
        ),
        isNull,
      );
    });
  });

  group('discovery', () {
    test('lists a member that announced itself, with its address', () {
      final discovery = LocalSendDiscovery(self: () => _self);
      addTearDown(discovery.dispose);

      discovery.onPacket(_packet(_orange()), phone);

      final peer = discovery.peers.single;
      expect(peer.info.alias, 'Nice Orange');
      expect(peer.address, phone);
      expect(peer.port, 53317);
      expect(
        peer.route('upload', {'sessionId': 's'}).toString(),
        'https://192.168.1.20:53317/api/localsend/v2/upload?sessionId=s',
      );
    });

    test('never lists this device, whatever the letter case', () {
      final discovery = LocalSendDiscovery(self: () => _self);
      addTearDown(discovery.dispose);

      discovery.onPacket(_packet({..._orange(), 'fingerprint': 'aa11'}), phone);

      expect(discovery.peers, isEmpty);
    });

    test('a member heard twice is listed once, at its newest address', () {
      final discovery = LocalSendDiscovery(self: () => _self);
      addTearDown(discovery.dispose);
      final moved = InternetAddress('192.168.1.99');

      discovery
        ..onPacket(_packet(_orange()), phone)
        ..onPacket(_packet(_orange(announce: false)), moved);

      expect(discovery.peers.single.address, moved);
    });

    test('members that went quiet drop off the list', () {
      var now = DateTime(2026, 11, 18, 10);
      final discovery = LocalSendDiscovery(
        self: () => _self,
        clock: () => now,
        peerLifetime: const Duration(minutes: 3),
      );
      addTearDown(discovery.dispose);

      discovery.onPacket(_packet(_orange()), phone);
      now = now.add(const Duration(minutes: 2));
      expect(discovery.peers, hasLength(1));

      now = now.add(const Duration(minutes: 2));
      expect(discovery.peers, isEmpty);
    });

    test('stays silent to announcements while not receiving', () async {
      final registered = <LocalSendPeer>[];
      final discovery = LocalSendDiscovery(
        self: () => _self,
        register: (peer) async {
          registered.add(peer);
          return true;
        },
      );
      addTearDown(discovery.dispose);

      discovery.onPacket(_packet(_orange()), phone);
      await Future<void>.delayed(Duration.zero);

      expect(registered, isEmpty);
      expect(discovery.peers, hasLength(1));
    });

    test('answers announcements over HTTP while receiving', () async {
      final registered = <LocalSendPeer>[];
      final discovery = LocalSendDiscovery(
        self: () => _self,
        shouldAnswer: () => true,
        register: (peer) async {
          registered.add(peer);
          return true;
        },
      );
      addTearDown(discovery.dispose);

      discovery
        ..onPacket(_packet(_orange()), phone)
        ..onPacket(_packet(_orange(announce: false)), phone);
      await Future<void>.delayed(Duration.zero);

      expect(registered.single.address, phone);
    });

    test('a failing HTTP answer is not an error', () async {
      final discovery = LocalSendDiscovery(
        self: () => _self,
        shouldAnswer: () => true,
        register: (peer) async => throw const LocalSendException(.unreachable),
      );
      addTearDown(discovery.dispose);

      discovery.onPacket(_packet(_orange()), phone);
      await Future<void>.delayed(Duration.zero);

      expect(discovery.peers, hasLength(1));
    });

    test('tells listeners when the list changes', () async {
      final discovery = LocalSendDiscovery(self: () => _self);
      addTearDown(discovery.dispose);
      final lists = <int>[];
      discovery.changes.listen((peers) => lists.add(peers.length));

      discovery.onPacket(_packet(_orange()), phone);
      discovery.clear();
      await Future<void>.delayed(Duration.zero);

      expect(lists, [1, 0]);
    });
  });

  group('address scan', () {
    test('asks the rest of a private /24 network', () {
      final neighbours = LegacyScanner.neighbours(
        InternetAddress('192.168.1.20'),
      );

      expect(neighbours, hasLength(253));
      expect(neighbours.first.address, '192.168.1.1');
      expect(neighbours.last.address, '192.168.1.254');
      expect(neighbours, isNot(contains(InternetAddress('192.168.1.20'))));
    });

    test('never sweeps public or loopback networks', () {
      expect(LegacyScanner.neighbours(InternetAddress('8.8.8.8')), isEmpty);
      expect(LegacyScanner.neighbours(InternetAddress('127.0.0.1')), isEmpty);
      expect(LegacyScanner.neighbours(InternetAddress('::1')), isEmpty);
    });

    test('knows which addresses are local', () {
      expect(LocalNetworks.contains(InternetAddress('10.0.0.5')), isTrue);
      expect(LocalNetworks.contains(InternetAddress('172.16.4.1')), isTrue);
      expect(LocalNetworks.contains(InternetAddress('172.32.0.1')), isFalse);
      expect(LocalNetworks.contains(InternetAddress('192.168.0.9')), isTrue);
      expect(LocalNetworks.contains(InternetAddress('169.254.3.3')), isTrue);
      expect(LocalNetworks.contains(InternetAddress('127.0.0.1')), isTrue);
      expect(LocalNetworks.contains(InternetAddress('1.1.1.1')), isFalse);
      expect(LocalNetworks.contains(InternetAddress('fd12::1')), isTrue);
      expect(LocalNetworks.contains(InternetAddress('2001:db8::1')), isFalse);
    });
  });
}
