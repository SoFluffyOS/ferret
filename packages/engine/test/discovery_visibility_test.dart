import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'support/quiet_bus.dart';

const _home = LocalNetwork(subnet: '127.0.0', gatewayMac: 'a4:2b:b0:01:02:03');
const _cafe = LocalNetwork(subnet: '10.0.7');

void main() {
  final engines = <FerretEngine>[];

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  /// A device that has met nobody yet on any network, unless [learning].
  Future<(FerretEngine, QuietMember)> engineOn(
    QuietBus bus,
    String name, {
    List<LocalNetwork> Function()? networks,
    bool learning = false,
    Set<String> own = const {},
  }) async {
    final discovery = bus.join();
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore({
        if (!learning) KnownNetworks.settingsKey: <String>[],
      }),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      discovery: discovery,
      port: 0,
      networks: () async => (networks ?? () => const [_home])(),
      ownAddresses: () async => own,
    );
    engines.add(engine);
    return (engine, discovery);
  }

  Future<void> pairWith(FerretEngine a, FerretEngine b) async {
    for (final (here, there) in [(a, b), (b, a)]) {
      await here.trustStore.save(
        TrustedDevice(
          id: there.identity.deviceId,
          name: there.device.name,
          platform: there.device.platform,
          formFactor: there.device.formFactor,
          publicKey: there.identity.publicKey,
          pairedAt: DateTime(2026),
        ),
      );
    }
  }

  Future<void> pairWithStranger(FerretEngine engine) => engine.trustStore.save(
    TrustedDevice(
      id: 'abcdabcdabcdabcd',
      name: 'Pixel 7',
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: Uint8List(32),
      pairedAt: DateTime(2026),
    ),
  );

  Future<void> connected(FerretEngine engine) => engine.deviceChanges
      .map((_) => engine.devices.any((device) => device.isConnected))
      .firstWhere((connected) => connected)
      .timeout(const Duration(seconds: 5));

  test('announces while nothing is paired yet', () async {
    final (engine, discovery) = await engineOn(QuietBus(), 'MacBook Air');
    await engine.start();

    expect(engine.isAnnouncing, isTrue);
    expect(discovery.isAnnouncing, isTrue);
  });

  test('a paired device only listens on a network where it met none', () async {
    final bus = QuietBus();
    final (engine, discovery) = await engineOn(bus, 'MacBook Air');
    await pairWithStranger(engine);
    await engine.start();

    expect(engine.isAnnouncing, isFalse);
    expect(discovery.isAnnouncing, isFalse);
    expect(discovery.announced, isEmpty, reason: 'nothing names it');
  });

  test(
    'right after the update it announces until it meets a paired device',
    () async {
      final (engine, discovery) = await engineOn(
        QuietBus(),
        'MacBook Air',
        learning: true,
      );
      await pairWithStranger(engine);
      await engine.start();

      expect(discovery.isAnnouncing, isTrue);
    },
  );

  test('Add a device makes it visible until the screen closes', () async {
    final (engine, discovery) = await engineOn(QuietBus(), 'MacBook Air');
    await pairWithStranger(engine);
    await engine.start();

    final first = engine.stayVisible();
    final second = engine.stayVisible();
    await pump();
    expect(discovery.isAnnouncing, isTrue);

    first
      ..release()
      ..release();
    await pump();
    expect(discovery.isAnnouncing, isTrue, reason: 'one screen is still open');

    second.release();
    await pump();
    expect(discovery.isAnnouncing, isFalse);
  });

  test('Always visible announces on every network', () async {
    final (engine, discovery) = await engineOn(QuietBus(), 'MacBook Air');
    await pairWithStranger(engine);
    await engine.start();

    await engine.setAlwaysVisible(true);
    expect(engine.alwaysVisible, isTrue);
    expect(discovery.isAnnouncing, isTrue);

    await engine.setAlwaysVisible(false);
    expect(discovery.isAnnouncing, isFalse);
  });

  test('a quiet device still finds a paired one that announces, and then '
      'announces on that network only', () async {
    final bus = QuietBus();
    var networks = const [_home];
    final (air, airWay) = await engineOn(
      bus,
      'MacBook Air',
      networks: () => networks,
    );
    final (studio, _) = await engineOn(bus, 'Mac Studio');
    await pairWith(air, studio);
    await studio.setAlwaysVisible(true);

    await studio.start();
    final joined = connected(air);
    await air.start();
    await joined;
    await pump();

    expect(airWay.isAnnouncing, isTrue, reason: 'it met a paired device here');

    networks = const [_cafe];
    await air.refresh();
    expect(airWay.isAnnouncing, isFalse);

    networks = const [_home];
    await air.refresh();
    expect(airWay.isAnnouncing, isTrue);
  });

  test('announces slow down while every paired device is connected, and '
      'come back with an announce when one drops', () async {
    final bus = QuietBus();
    final (air, airWay) = await engineOn(bus, 'MacBook Air');
    final (studio, _) = await engineOn(bus, 'Mac Studio');
    await pairWith(air, studio);
    await studio.setAlwaysVisible(true);
    await air.start();
    expect(airWay.isRelaxed, isFalse, reason: 'its paired device is away');

    final joined = connected(air);
    await studio.start();
    await joined;
    await pump();
    expect(airWay.isRelaxed, isTrue);

    final announcedBefore = airWay.announced.length;
    await studio.stop();
    await air.deviceChanges
        .firstWhere((_) => !air.devices.single.isConnected)
        .timeout(const Duration(seconds: 5));
    await pump();
    expect(airWay.isRelaxed, isFalse);
    expect(airWay.announced.length, greaterThan(announcedBefore));
  });

  test(
    'stops listening while every paired device is connected, listens '
    'again when one drops or a screen looks, and never while stopped',
    () async {
      final bus = QuietBus();
      final (air, airWay) = await engineOn(bus, 'MacBook Air');
      final (studio, _) = await engineOn(bus, 'Mac Studio');
      await pairWith(air, studio);
      await studio.setAlwaysVisible(true);
      expect(air.multicastNeed.isNeeded, isFalse, reason: 'not started yet');

      await air.start();
      expect(air.multicastNeed.isNeeded, isTrue, reason: 'Mac Studio is away');
      expect(air.multicastNeed.reasons, ['missing']);
      expect(airWay.isListening, isTrue);

      final joined = connected(air);
      await studio.start();
      await joined;
      await pump();
      expect(air.multicastNeed.isNeeded, isFalse);
      expect(airWay.isListening, isFalse);

      final looking = air.multicastNeed.hold('nearby');
      await pump();
      expect(airWay.isListening, isTrue, reason: 'Add a device is open');
      looking.release();
      await pump();
      expect(airWay.isListening, isFalse);

      await studio.stop();
      await air.deviceChanges
          .firstWhere((_) => !air.devices.single.isConnected)
          .timeout(const Duration(seconds: 5));
      await pump();
      expect(air.multicastNeed.isNeeded, isTrue);
      expect(airWay.isListening, isTrue);

      await air.stop();
      expect(air.multicastNeed.isNeeded, isFalse, reason: 'paused');
    },
  );

  test('nothing paired and nobody looking needs no listening', () async {
    final bus = QuietBus();
    final (air, airWay) = await engineOn(bus, 'MacBook Air');
    await air.start();
    expect(air.multicastNeed.isNeeded, isFalse);
    expect(airWay.isListening, isFalse);
  });

  test('announces keep their pace while one paired device is away', () async {
    final bus = QuietBus();
    final (air, airWay) = await engineOn(bus, 'MacBook Air');
    final (studio, _) = await engineOn(bus, 'Mac Studio');
    await pairWith(air, studio);
    await pairWithStranger(air);
    await studio.setAlwaysVisible(true);
    final joined = connected(air);
    await studio.start();
    await air.start();
    await joined;
    await pump();

    expect(airWay.isRelaxed, isFalse);
  });

  test('two quiet devices meet once one of them opens Add a device', () async {
    final bus = QuietBus();
    final (air, _) = await engineOn(bus, 'MacBook Air');
    final (studio, _) = await engineOn(bus, 'Mac Studio');
    await pairWith(air, studio);
    await air.start();
    await studio.start();
    await pump();
    expect(air.devices.single.isConnected, isFalse);

    final joined = connected(air);
    final hold = studio.stayVisible();
    await joined;
    hold.release();
  });

  test("a laptop joining a phone's hotspot finds the phone, which announces "
      'on the network it hosts', () async {
    final bus = QuietBus();
    final (phone, phoneWay) = await engineOn(
      bus,
      'Pixel 7',
      networks: () => const [
        LocalNetwork(subnet: '127.0.0', isHostedHere: true),
      ],
    );
    final (air, airWay) = await engineOn(
      bus,
      'MacBook Air',
      networks: () => const [_cafe],
    );
    await pairWith(air, phone);

    final joined = connected(air);
    await phone.start();
    await air.start();
    await joined;

    expect(phoneWay.isAnnouncing, isTrue);
    expect(airWay.isAnnouncing, isFalse, reason: 'the laptop stays quiet');
  });

  test(
    'its own ferret-cli calling from this computer marks no network',
    () async {
      final bus = QuietBus();
      final (air, airWay) = await engineOn(
        bus,
        'MacBook Air',
        own: {'127.0.0.1'},
      );
      final (cli, _) = await engineOn(bus, 'ferret-cli');
      await pairWith(air, cli);
      await cli.setAlwaysVisible(true);
      await cli.start();

      final joined = connected(air);
      await air.start();
      await joined;
      await pump();

      expect(airWay.isAnnouncing, isFalse);
    },
  );

  group('known networks', () {
    late MemorySettingsStore settings;
    var current = <LocalNetwork>[];

    KnownNetworks known() => KnownNetworks(
      settings,
      salt: 'saltsaltsaltsalt',
      source: () async => current,
    );

    setUp(() {
      settings = MemorySettingsStore();
      current = [];
    });

    test('a router tells two networks with the same addresses apart', () async {
      current = [_home];
      final networks = known();
      await networks.refresh();
      expect(await networks.rememberHost('127.0.0.9'), isTrue);
      expect(await networks.rememberHost('127.0.0.9'), isFalse);

      current = [
        const LocalNetwork(subnet: '127.0.0', gatewayMac: 'ff:ff:ff:00:00:01'),
      ];
      await networks.refresh();
      expect(await networks.isOnKnown(), isFalse);

      current = [const LocalNetwork(subnet: '127.0.0')];
      await networks.refresh();
      expect(await networks.isOnKnown(), isTrue, reason: 'router not seen');

      current = [_cafe];
      await networks.refresh();
      expect(await networks.isOnKnown(), isFalse);
    });

    test('a network this device hosts counts as known', () async {
      current = [
        _cafe,
        const LocalNetwork(subnet: '192.168.211', isHostedHere: true),
      ];
      final networks = known();
      await networks.refresh();
      expect(await networks.isOnKnown(), isTrue);

      current = [_cafe];
      await networks.refresh();
      expect(await networks.isOnKnown(), isFalse);
    });

    test('hotspot and tethering interfaces', () {
      for (final name in [
        'ap0',
        'swlan0',
        'softap0',
        'ap_br_wlan1',
        'rndis0',
        'ncm0',
        'bt-pan',
      ]) {
        expect(
          LocalNetworks.isHotspotInterface(name, isAndroid: false),
          isTrue,
          reason: name,
        );
      }

      expect(
        LocalNetworks.isHotspotInterface('wlan1', isAndroid: true),
        isTrue,
      );
      expect(
        LocalNetworks.isHotspotInterface('wlan1', isAndroid: false),
        isFalse,
      );
      for (final name in ['wlan0', 'en0', 'eth0', 'p2p-wlan0-0', 'awdl0']) {
        expect(
          LocalNetworks.isHotspotInterface(name, isAndroid: true),
          isFalse,
          reason: name,
        );
      }
    });

    test('a host on none of its networks is not kept', () async {
      current = [_cafe];
      final networks = known();
      await networks.refresh();

      expect(await networks.rememberHost('100.101.102.103'), isFalse);
      expect(networks.isLearning, isTrue);
    });

    test('the settings file says where without naming it', () async {
      current = [_home];
      final networks = known();
      await networks.refresh();
      await networks.rememberHost('127.0.0.9');

      final saved = settings.get<List<Object?>>(KnownNetworks.settingsKey);
      expect(saved, hasLength(1));
      expect('$saved', isNot(contains('127.0.0')));
      expect('$saved', isNot(contains('a4:2b')));
    });

    test('keeps the most recent networks only', () async {
      final networks = known();
      for (var i = 0; i < KnownNetworks.maxKept + 3; i++) {
        current = [LocalNetwork(subnet: '10.0.$i')];
        await networks.refresh();
        await networks.rememberHost('10.0.$i.2');
      }

      expect(
        settings.get<List<Object?>>(KnownNetworks.settingsKey),
        hasLength(KnownNetworks.maxKept),
      );
      current = [const LocalNetwork(subnet: '10.0.0')];
      await networks.refresh();
      expect(await networks.isOnKnown(), isFalse);
    });
  });

  group('reading the router', () {
    test('from macOS', () {
      expect(
        LocalNetworks.macGateway('''
   route to: default
destination: default
       mask: default
    gateway: 192.168.1.1
  interface: en0
'''),
        '192.168.1.1',
      );
      expect(
        LocalNetworks.arpMac(
          '? (192.168.1.1) at a4:2b:b0:1:2:3 on en0 ifscope [ethernet]\n',
        ),
        'a4:2b:b0:01:02:03',
      );
      expect(
        LocalNetworks.arpMac('192.168.1.1 (192.168.1.1) -- no entry'),
        isNull,
      );
    });

    test('from Linux', () {
      const route =
          'Iface\tDestination\tGateway \tFlags\tRefCnt\tUse\tMetric\tMask\n'
          'wlan0\t0001A8C0\t00000000\t0001\t0\t0\t600\t00FFFFFF\n'
          'wlan0\t00000000\t0101A8C0\t0003\t0\t0\t600\t00000000\n';
      const arp =
          'IP address       HW type     Flags       HW address            Mask     Device\n'
          '192.168.1.1      0x1         0x2         A4:2B:B0:01:02:03     *        wlan0\n';

      expect(LocalNetworks.linuxGateway(route), '192.168.1.1');
      expect(
        LocalNetworks.linuxArpMac(arp, '192.168.1.1'),
        'a4:2b:b0:01:02:03',
      );
      expect(LocalNetworks.linuxArpMac(arp, '192.168.1.2'), isNull);
    });
  });
}

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 50));
