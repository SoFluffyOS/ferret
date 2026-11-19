import 'package:ferret_wake/ferret_wake.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

const _ifconfig = '''
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=1203<RXCSUM,TXCSUM,TXSTATUS,SW_TIMESTAMP>
	inet 127.0.0.1 netmask 0xff000000
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=6460<TSO4,TSO6,CHANNEL_IO,PARTIAL_CSUM,ZEROINVERT_CSUM>
	ether 3c:22:fb:12:34:56
	inet6 fe80::1c2b:5f1a:9a0e:1b2c%en0 prefixlen 64 secured scopeid 0xb
	inet 192.168.1.23 netmask 0xffffff00 broadcast 192.168.1.255
	status: active
en7: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether a0:ce:c8:00:11:22
	inet 10.0.4.7 netmask 0xfffffc00 broadcast 10.0.7.255
	status: active
bridge0: flags=8822<BROADCAST,SMART,SIMPLEX,MULTICAST> mtu 1500
	ether 36:2a:11:22:33:44
	inet 192.168.2.1 netmask 0xffffff00 broadcast 192.168.2.255
utun3: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
	inet 100.101.102.103 --> 100.101.102.103 netmask 0xffffffff
awdl0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 9a:7c:aa:bb:cc:dd
''';

const _hardwarePorts = '''

Hardware Port: Wi-Fi
Device: en0
Ethernet Address: 3c:22:fb:12:34:56

Hardware Port: USB 10/100/1000 LAN
Device: en7
Ethernet Address: a0:ce:c8:00:11:22

Hardware Port: Thunderbolt Bridge
Device: bridge0
Ethernet Address: 36:2a:11:22:33:44

VLAN Configurations
===================
''';

const _pmset = '''
System-wide power settings:
Currently in use:
 standby              1
 Sleep On Power Button 1
 womp                 1
 hibernatefile        /var/vm/sleepimage
''';

const _ipAddr = '''
1: lo    inet 127.0.0.1/8 scope host lo\\       valid_lft forever preferred_lft forever
2: enp3s0    inet 192.168.1.10/24 brd 192.168.1.255 scope global dynamic noprefixroute enp3s0\\       valid_lft 85000sec preferred_lft 85000sec
3: wlp2s0    inet 192.168.1.11/24 brd 192.168.1.255 scope global dynamic wlp2s0\\       valid_lft 85000sec preferred_lft 85000sec
4: docker0    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0\\       valid_lft forever preferred_lft forever
5: tailscale0    inet 100.64.1.2/32 scope global tailscale0\\       valid_lft forever preferred_lft forever
''';

const _ethtoolOn = '''
Settings for enp3s0:
	Supported ports: [ TP MII ]
	Supports Wake-on: pumbg
	Wake-on: g
	Link detected: yes
''';

const _ethtoolOff = '''
Settings for wlp2s0:
	Supports Wake-on: pumbg
	Wake-on: d
''';

void main() {
  group('macOS', () {
    test('lists hardware ports with an address, Wi-Fi told from wired', () {
      final cards = MacosCards.parse(
        ifconfig: _ifconfig,
        hardwarePorts: _hardwarePorts,
        pmset: _pmset,
      );

      expect([for (final card in cards) card.name], ['en0', 'en7']);
      expect(MacAddress.format(cards.first.mac), '3c:22:fb:12:34:56');
      expect(cards.first.address, '192.168.1.23');
      expect(cards.first.broadcast, '192.168.1.255');
      expect(cards.first.link, WakeLink.WAKE_LINK_WIFI);
      expect(cards.last.link, WakeLink.WAKE_LINK_WIRED);
      expect(cards.last.broadcast, '10.0.7.255');
      expect(
        {for (final card in cards) card.setting},
        {WakeSetting.WAKE_SETTING_ON},
      );
    });

    test('"Wake for network access" off reads as off; missing as unknown', () {
      final off = MacosCards.parse(
        ifconfig: _ifconfig,
        hardwarePorts: _hardwarePorts,
        pmset: ' womp                 0\n',
      );
      final unknown = MacosCards.parse(
        ifconfig: _ifconfig,
        hardwarePorts: _hardwarePorts,
        pmset: '',
      );

      expect(off.first.setting, WakeSetting.WAKE_SETTING_OFF);
      expect(unknown.first.setting, WakeSetting.WAKE_SETTING_UNSPECIFIED);
    });
  });

  group('Linux', () {
    test('names come from ip addr', () {
      expect(LinuxCards.names(_ipAddr), [
        'lo',
        'enp3s0',
        'wlp2s0',
        'docker0',
        'tailscale0',
      ]);
    });

    test('keeps hardware cards and reads Wake-on from ethtool', () {
      final cards = LinuxCards.parse(_ipAddr, const {
        'lo': LinuxCardFacts(
          mac: '00:00:00:00:00:00',
          isWireless: false,
          isHardware: false,
        ),
        'enp3s0': LinuxCardFacts(
          mac: '70:85:c2:aa:bb:cc',
          isWireless: false,
          isHardware: true,
          ethtool: _ethtoolOn,
        ),
        'wlp2s0': LinuxCardFacts(
          mac: 'f4:8c:50:11:22:33',
          isWireless: true,
          isHardware: true,
          ethtool: _ethtoolOff,
        ),
        'docker0': LinuxCardFacts(
          mac: '02:42:ac:11:00:01',
          isWireless: false,
          isHardware: false,
        ),
        'tailscale0': LinuxCardFacts(
          mac: '',
          isWireless: false,
          isHardware: false,
        ),
      });

      expect([for (final card in cards) card.name], ['enp3s0', 'wlp2s0']);
      expect(cards.first.link, WakeLink.WAKE_LINK_WIRED);
      expect(cards.first.setting, WakeSetting.WAKE_SETTING_ON);
      expect(cards.first.broadcast, '192.168.1.255');
      expect(cards.last.link, WakeLink.WAKE_LINK_WIFI);
      expect(cards.last.setting, WakeSetting.WAKE_SETTING_OFF);
    });

    test('without ethtool the setting is unknown', () {
      final cards = LinuxCards.parse(_ipAddr, const {
        'enp3s0': LinuxCardFacts(
          mac: '70:85:c2:aa:bb:cc',
          isWireless: false,
          isHardware: true,
        ),
      });

      expect(cards.single.setting, WakeSetting.WAKE_SETTING_UNSPECIFIED);
    });
  });

  group('Windows', () {
    test('reads a list of cards', () {
      const json =
          '[{"Name":"Ethernet","Mac":"70-85-C2-AA-BB-CC","Media":"802.3",'
          '"Address":"192.168.1.30","Prefix":24,"Magic":"Enabled"},'
          '{"Name":"Wi-Fi","Mac":"F4-8C-50-11-22-33","Media":"Native 802.11",'
          '"Address":"192.168.1.31","Prefix":24,"Magic":"Disabled"}]';

      final cards = WindowsCards.parse(json);

      expect([for (final card in cards) card.name], ['Ethernet', 'Wi-Fi']);
      expect(MacAddress.format(cards.first.mac), '70:85:c2:aa:bb:cc');
      expect(cards.first.link, WakeLink.WAKE_LINK_WIRED);
      expect(cards.first.setting, WakeSetting.WAKE_SETTING_ON);
      expect(cards.first.broadcast, '192.168.1.255');
      expect(cards.last.link, WakeLink.WAKE_LINK_WIFI);
      expect(cards.last.setting, WakeSetting.WAKE_SETTING_OFF);
    });

    test('reads one card, which PowerShell writes without a list', () {
      const json =
          '{"Name":"Ethernet 2","Mac":"70-85-C2-AA-BB-CD","Media":"802.3",'
          '"Address":"10.1.2.3","Prefix":16,"Magic":""}';

      final card = WindowsCards.parse(json).single;

      expect(card.broadcast, '10.1.255.255');
      expect(card.setting, WakeSetting.WAKE_SETTING_UNSPECIFIED);
    });

    test('skips a card without an address and survives garbage', () {
      const json = '{"Name":"Ethernet","Mac":"70-85-C2-AA-BB-CC"}';

      expect(WindowsCards.parse(json), isEmpty);
      expect(WindowsCards.parse(''), isEmpty);
      expect(WindowsCards.parse('Get-NetAdapter : not found'), isEmpty);
    });
  });

  group('Ipv4Broadcast', () {
    test('works out the broadcast address', () {
      expect(Ipv4Broadcast.of('192.168.1.20', 24), '192.168.1.255');
      expect(Ipv4Broadcast.of('10.0.4.7', 22), '10.0.7.255');
      expect(Ipv4Broadcast.of('172.16.5.4', 32), '172.16.5.4');
      expect(Ipv4Broadcast.of('fe80::1', 64), isNull);
      expect(Ipv4Broadcast.of('192.168.1.20', 33), isNull);
    });

    test('reads hex masks', () {
      expect(Ipv4Broadcast.prefixOfHexMask('0xffffff00'), 24);
      expect(Ipv4Broadcast.prefixOfHexMask('0xfffffc00'), 22);
      expect(Ipv4Broadcast.prefixOfHexMask('0xff00ff00'), isNull);
    });
  });

  test('a computer shares its wired cards first', () {
    final wifi = NetworkCard(
      name: 'en0',
      mac: MacAddress.parse('3c:22:fb:12:34:56') ?? .new(6),
      address: '192.168.1.23',
      broadcast: '192.168.1.255',
      link: .WAKE_LINK_WIFI,
    );
    final wired = NetworkCard(
      name: 'en7',
      mac: MacAddress.parse('a0:ce:c8:00:11:22') ?? .new(6),
      address: '192.168.1.24',
      broadcast: '192.168.1.255',
      link: .WAKE_LINK_WIRED,
    );

    final shared = NetworkCard.shareable([wifi, wired]);

    expect(
      [for (final card in shared.interfaces) card.link],
      [WakeLink.WAKE_LINK_WIRED, WakeLink.WAKE_LINK_WIFI],
    );
  });
}
