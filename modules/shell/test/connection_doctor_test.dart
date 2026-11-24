import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'support/memory_discovery.dart';

void main() {
  late FerretEngine engine;

  setUp(() async {
    engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Laptop',
        platform: .PLATFORM_WINDOWS,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      discovery: MemoryDiscoveryBus().join(),
      port: 0,
    );
    await engine.start();
  });

  tearDown(() => engine.stop());

  WindowsFirewallRules windowsRules({
    required bool installed,
    List<String>? elevated,
    String categories = '',
    int blockRules = 0,
  }) {
    var present = installed;
    var blocks = blockRules;
    return WindowsFirewallRules(
      run: (executable, arguments) async {
        if (arguments.contains('-Command')) {
          final script = arguments.last;
          return ProcessResult(
            0,
            0,
            switch (script.contains('Get-NetConnectionProfile')) {
              true => categories,
              false => '$blocks\n',
            },
            '',
          );
        }
        if (executable == 'powershell.exe') {
          elevated?.add(arguments.last);
          present = true;
          blocks = 0;
        }
        return ProcessResult(
          0,
          switch (present) {
            true => 0,
            false => 1,
          },
          '',
          '',
        );
      },
    );
  }

  Future<List<DoctorCheck>> diagnose(
    String? deviceId, {
    required bool isWindows,
    bool rulesInstalled = false,
  }) => ConnectionDoctor(
    engine,
    isWindows: isWindows,
    isLinux: false,
    windowsFirewallRules: windowsRules(installed: rulesInstalled),
  ).diagnose(deviceId).last;

  Future<List<DoctorCheck>> diagnoseOnLinux({
    String ufwConfig = '',
    String firewalldState = 'not running',
  }) => ConnectionDoctor(
    engine,
    isWindows: false,
    isLinux: true,
    linuxFirewall: LinuxFirewall(
      readFile: (path) async => ufwConfig,
      run: (executable, arguments) async => ProcessResult(
        0,
        switch (firewalldState) {
          'running' => 0,
          _ => 252,
        },
        firewalldState,
        '',
      ),
    ),
  ).diagnose('nobody').last;

  bool isOnline(List<DoctorCheck> checks) =>
      checks.first.kind == .network && checks.first.status == .ok;

  test('on Windows, checking the network names the firewall and how to '
      'open it', () async {
    final checks = await diagnose(null, isWindows: true);

    final firewall = checks.where((check) => check.kind == .firewall);
    expect(firewall, hasLength(isOnline(checks) ? 1 : 0));
    for (final check in firewall) {
      expect(check.status, DoctorStatus.warning);
      expect(check.fixes, [DoctorFix.allowFirewall, DoctorFix.openFirewall]);
    }
  });

  test('Android 17 without the local network permission: that line alone, '
      'with Allow, or Open Settings once Android won\'t ask', () async {
    for (final (access, fix) in [
      (LocalNetworkAccess.notGranted, DoctorFix.allowLocalNetwork),
      (LocalNetworkAccess.blocked, DoctorFix.openAppSettings),
    ]) {
      final checks = await ConnectionDoctor(
        engine,
        isWindows: false,
        isLinux: false,
        localNetwork: () async => access,
      ).diagnose(null).last;

      expect(checks, hasLength(1));
      expect(checks.single.kind, DoctorCheckKind.localNetwork);
      expect(checks.single.status, DoctorStatus.problem);
      expect(checks.single.detail, access.name);
      expect(checks.single.fixes, [fix]);
    }
  });

  test('allowed, the local network line doesn\'t show', () async {
    final checks = await ConnectionDoctor(
      engine,
      isWindows: false,
      isLinux: false,
      localNetwork: () async => .granted,
    ).diagnose(null).last;

    expect(checks.where((check) => check.kind == .localNetwork), isEmpty);
  });

  test('on a Mac that drops everything Ferret sends, Fix connection says '
      'macOS blocks it and opens Local Network', () async {
    final checks = await ConnectionDoctor(
      engine,
      isWindows: false,
      isLinux: false,
      isMacOS: true,
      isDiscoveryBlocked: () => true,
    ).diagnose(null).last;

    final line = checks.first;
    expect(line.kind, DoctorCheckKind.localNetwork);
    expect(line.status, DoctorStatus.problem);
    expect(line.detail, ConnectionDoctor.macOSBlocked);
    expect(line.fixes, [DoctorFix.openLocalNetworkSettings]);
    expect(checks.where((check) => check.kind == .network), isNotEmpty);
  });

  test('on a Mac whose discovery gets out, no local network line', () async {
    final checks = await ConnectionDoctor(
      engine,
      isWindows: false,
      isLinux: false,
      isMacOS: true,
      isDiscoveryBlocked: () => false,
    ).diagnose(null).last;

    expect(checks.where((check) => check.kind == .localNetwork), isEmpty);
  });

  test('on Windows with the installer\'s rules in place, the firewall line '
      'says so and offers nothing', () async {
    final checks = await diagnose(null, isWindows: true, rulesInstalled: true);

    final firewall = checks.where((check) => check.kind == .firewall);
    expect(firewall, hasLength(isOnline(checks) ? 1 : 0));
    for (final check in firewall) {
      expect(check.status, DoctorStatus.ok);
      expect(check.detail, ConnectionDoctor.windowsRulesInstalled);
      expect(check.fixes, isEmpty);
    }
  });

  test(
    'Allow through firewall elevates once, then the line turns green',
    () async {
      final elevated = <String>[];
      final doctor = ConnectionDoctor(
        engine,
        isWindows: true,
        isLinux: false,
        windowsFirewallRules: windowsRules(
          installed: false,
          elevated: elevated,
        ),
      );

      final allowed = await doctor.allowThroughFirewall();
      final checks = await doctor.diagnose(null).last;

      expect(allowed, isTrue);
      expect(elevated, hasLength(1));
      for (final check in checks.where((check) => check.kind == .firewall)) {
        expect(check.status, DoctorStatus.ok);
      }
    },
  );

  test('a rule that blocks Ferret is the problem, and Allow through '
      'firewall removes it in the same prompt', () async {
    final elevated = <String>[];
    final doctor = ConnectionDoctor(
      engine,
      isWindows: true,
      isLinux: false,
      program: r'C:\Users\An\AppData\Local\Programs\Ferret\ferret.exe',
      windowsFirewallRules: windowsRules(
        installed: true,
        blockRules: 2,
        elevated: elevated,
      ),
    );

    final before = await doctor.diagnose(null).last;
    final blocked = before.where((check) => check.kind == .firewall);
    expect(blocked, hasLength(isOnline(before) ? 1 : 0));
    for (final check in blocked) {
      expect(check.status, DoctorStatus.problem);
      expect(check.detail, ConnectionDoctor.windowsBlocked);
      expect(check.fixes.first, DoctorFix.allowFirewall);
    }

    if (!isOnline(before)) {
      return;
    }

    await doctor.allowThroughFirewall();
    final bytes = base64.decode(elevated.single);
    final script = String.fromCharCodes([
      for (var index = 0; index < bytes.length; index += 2)
        bytes[index] | bytes[index + 1] << 8,
    ]);
    expect(
      script,
      contains(
        'netsh advfirewall firewall delete rule name=all dir=in '
        r'program=C:\Users\An\AppData\Local\Programs\Ferret\ferret.exe',
      ),
    );
    final after = await doctor.diagnose(null).last;
    for (final check in after.where((check) => check.kind == .firewall)) {
      expect(check.status, DoctorStatus.ok);
    }
  });

  test('with the rules in place on a Public network, the line says to make '
      'it Private', () async {
    final checks = await ConnectionDoctor(
      engine,
      isWindows: true,
      isLinux: false,
      windowsFirewallRules: windowsRules(
        installed: true,
        categories: 'Wi-Fi|Public\nvEthernet (WSL)|Public\n',
      ),
    ).diagnose(null).last;

    for (final check in checks.where((check) => check.kind == .firewall)) {
      expect(check.status, DoctorStatus.warning);
      expect(check.detail, ConnectionDoctor.windowsPublicNetwork);
      expect(check.fixes, [DoctorFix.openNetworkSettings]);
    }
  });

  test('the network Ferret uses decides Public or Private', () {
    const categories = {'Wi-Fi': 'Private', 'vEthernet (WSL)': 'Public'};

    expect(ConnectionDoctor.isPublicNetwork(categories, ['Wi-Fi']), isFalse);
    expect(
      ConnectionDoctor.isPublicNetwork({'Wi-Fi': 'Public'}, ['wi-fi']),
      isTrue,
    );
    expect(
      ConnectionDoctor.isPublicNetwork({'Ethernet 2': 'Public'}, ['Wi-Fi']),
      isTrue,
    );
    expect(ConnectionDoctor.isPublicNetwork(categories, ['Ethernet']), isFalse);
    expect(ConnectionDoctor.isPublicNetwork(const {}, ['Wi-Fi']), isFalse);
  });

  test('a device that was never reached gets the firewall hint on Windows '
      'too', () async {
    final checks = await diagnose('nobody', isWindows: true);

    expect(checks.any((check) => check.kind == .reachable), isTrue);
    expect(
      checks.where((check) => check.kind == .firewall),
      hasLength(isOnline(checks) ? 1 : 0),
    );
  });

  test('other systems never hear about Windows Firewall', () async {
    final network = await diagnose(null, isWindows: false);
    final device = await diagnose('nobody', isWindows: false);

    expect(
      [...network, ...device].where((check) => check.kind == .firewall),
      isEmpty,
    );
  });

  test('the copied report says the firewall was named', () async {
    final doctor = ConnectionDoctor(
      engine,
      isWindows: true,
      windowsFirewallRules: windowsRules(installed: false),
    );
    final checks = await doctor.diagnose(null).last;

    final report = doctor.diagnostics(checks);

    expect(report.contains('firewall: warning'), isOnline(checks));
  });

  test('on Linux, ufw that is on is named with a command to copy', () async {
    final checks = await diagnoseOnLinux(
      ufwConfig: '# comment\nENABLED=yes\nLOGLEVEL=low\n',
    );

    final firewall = checks.where((check) => check.kind == .firewall);
    expect(firewall, hasLength(isOnline(checks) ? 1 : 0));
    for (final check in firewall) {
      expect(check.detail, 'ufw');
      expect(check.fixes, [DoctorFix.copyFirewallCommand]);
    }
  });

  group('firewalld whose zones already let Ferret in', () {
    Future<List<DoctorCheck>> diagnoseWith(
      Map<String, String> answers,
    ) => ConnectionDoctor(
      engine,
      isWindows: false,
      isLinux: true,
      linuxFirewall: LinuxFirewall(
        readFile: (path) async => '',
        run: (executable, arguments) async {
          final answer = answers[arguments.join(' ')];
          return switch (answer) {
            final answer? => ProcessResult(0, 0, answer, ''),
            null => ProcessResult(0, 1, '', ''),
          };
        },
      ),
    ).diagnose('nobody').last;

    test("isn't named on Fedora Workstation, which opens every port "
        'from 1025 and mDNS', () async {
      final checks = await diagnoseWith({
        '--state': 'running',
        '--get-active-zones':
            'FedoraWorkstation (default)\n  interfaces: wlp0s20f3\n',
        '--zone=FedoraWorkstation --list-services':
            'dhcpv6-client mdns samba-client ssh',
        '--zone=FedoraWorkstation --list-ports':
            '1025-65535/udp 1025-65535/tcp',
      });

      expect(checks.where((check) => check.kind == .firewall), isEmpty);
    });

    test("isn't named once the ferret service is added", () async {
      final checks = await diagnoseWith({
        '--state': 'running',
        '--get-active-zones': 'public\n  interfaces: eth0\n',
        '--zone=public --list-services': 'ssh dhcpv6-client ferret',
        '--zone=public --list-ports': '',
      });

      expect(checks.where((check) => check.kind == .firewall), isEmpty);
    });

    test('is named when one zone in use lacks mDNS or the port', () async {
      final checks = await diagnoseWith({
        '--state': 'running',
        '--get-active-zones':
            'home\n  interfaces: wlan0\npublic\n  interfaces: eth0\n',
        '--zone=home --list-services': 'mdns ferret',
        '--zone=home --list-ports': '',
        '--zone=public --list-services': 'ssh mdns',
        '--zone=public --list-ports': '47641/udp',
      });

      final firewall = checks.where((check) => check.kind == .firewall);
      expect(firewall, hasLength(isOnline(checks) ? 1 : 0));
      for (final check in firewall) {
        expect(check.detail, 'firewalld');
      }
    });

    test("is named when the zones can't be read", () async {
      final checks = await diagnoseWith({'--state': 'running'});

      final firewall = checks.where((check) => check.kind == .firewall);
      expect(firewall, hasLength(isOnline(checks) ? 1 : 0));
      for (final check in firewall) {
        expect(check.detail, 'firewalld');
      }
    });
  });

  test('on Linux, a running firewalld is named', () async {
    final checks = await diagnoseOnLinux(firewalldState: 'running');

    final firewall = checks.where((check) => check.kind == .firewall);
    for (final check in firewall) {
      expect(check.detail, 'firewalld');
    }
  });

  test('on Linux with no firewall on, nothing blames one', () async {
    final checks = await diagnoseOnLinux(ufwConfig: 'ENABLED=no\n');

    expect(checks.where((check) => check.kind == .firewall), isEmpty);
  });

  test('the commands open the port, discovery and mDNS', () {
    for (final kind in LinuxFirewallKind.values) {
      expect(kind.allowCommand, contains('47640/tcp'));
      expect(kind.allowCommand, contains('47641/udp'));
      expect(kind.allowCommand, anyOf(contains('5353/udp'), contains('mdns')));
    }
  });

  group('a network that keeps devices apart', () {
    const peer = '192.168.1.20';
    const router = '192.168.1.1';

    Future<void> trustPhone() => engine.trustStore.save(
      TrustedDevice(
        id: 'phonephonephonep',
        name: 'Pixel 7',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
        publicKey: Uint8List(32),
        pairedAt: DateTime(2026),
        lastHost: peer,
        lastPort: 47640,
      ),
    );

    ConnectionDoctor doctorWith({
      required Reach phone,
      required Reach routerAnswer,
      Duration since = const Duration(minutes: 1),
      bool hearsOthers = true,
    }) => ConnectionDoctor(
      engine,
      isWindows: false,
      isLinux: false,
      hearsOthers: hearsOthers,
      interfaces: () async => [(name: 'en0', address: '192.168.1.5')],
      probe: (host, port, timeout) async => switch (host) {
        peer => phone,
        router => routerAnswer,
        _ => Reach.silent,
      },
      clock: () => (engine.startedAt ?? DateTime.now()).add(since),
    );

    test('says so when the router answers and the device is silent', () async {
      await trustPhone();

      final checks = await doctorWith(
        phone: .silent,
        routerAnswer: .refused,
      ).diagnose('phonephonephonep').last;

      final isolated = checks.where((check) => check.kind == .isolated);
      expect(isolated.single.status, DoctorStatus.problem);
      final reachable = checks.singleWhere((c) => c.kind == .reachable);
      expect(reachable.fixes, [DoctorFix.tryAgain]);
    });

    test('is not blamed when the router is silent too', () async {
      await trustPhone();

      final checks = await doctorWith(
        phone: .silent,
        routerAnswer: .silent,
      ).diagnose('phonephonephonep').last;

      expect(checks.where((check) => check.kind == .isolated), isEmpty);
    });

    test('is not blamed when the device refuses: it is reachable', () async {
      await trustPhone();

      final checks = await doctorWith(
        phone: .refused,
        routerAnswer: .answered,
      ).diagnose('phonephonephonep').last;

      expect(checks.where((check) => check.kind == .isolated), isEmpty);
    });

    test('is not blamed on an iPhone, which never hears anyone', () async {
      await trustPhone();

      final device = await doctorWith(
        phone: .silent,
        routerAnswer: .refused,
        hearsOthers: false,
      ).diagnose('phonephonephonep').last;
      final network = await doctorWith(
        phone: .silent,
        routerAnswer: .answered,
        hearsOthers: false,
      ).diagnose(null).last;

      expect(device.where((check) => check.kind == .isolated), isEmpty);
      expect(
        device.singleWhere((check) => check.kind == .reachable).fixes,
        [DoctorFix.tryAgain, DoctorFix.connectByAddress],
      );
      expect(network.where((check) => check.kind == .isolated), isEmpty);
    });

    test('away from where the device was last seen, a quiet network '
        'whose router answers may keep devices apart', () async {
      await trustPhone();
      ConnectionDoctor inCafe({Duration since = const Duration(minutes: 1)}) =>
          ConnectionDoctor(
            engine,
            isWindows: false,
            isLinux: false,
            interfaces: () async => [(name: 'en0', address: '10.0.7.23')],
            probe: (host, port, timeout) async => switch (host) {
              '10.0.7.1' => Reach.answered,
              _ => Reach.silent,
            },
            clock: () => (engine.startedAt ?? DateTime.now()).add(since),
          );

      ConnectionDoctor.isolatedSubnet.value = null;
      final checks = await inCafe().diagnose('phonephonephonep').last;
      expect(ConnectionDoctor.isolatedSubnet.value, '10.0.7');
      expect(
        checks.singleWhere((check) => check.kind == .isolated).status,
        DoctorStatus.warning,
      );
      expect(
        checks.singleWhere((check) => check.kind == .sameNetwork).status,
        DoctorStatus.warning,
      );

      final tooSoon = await inCafe(
        since: const Duration(seconds: 5),
      ).diagnose('phonephonephonep').last;
      expect(tooSoon.where((check) => check.kind == .isolated), isEmpty);
    });

    test('Check my network says it may, after a quiet while', () async {
      final quiet = await doctorWith(
        phone: .silent,
        routerAnswer: .answered,
      ).diagnose(null).last;
      final tooSoon = await doctorWith(
        phone: .silent,
        routerAnswer: .answered,
        since: const Duration(seconds: 5),
      ).diagnose(null).last;

      expect(
        quiet.singleWhere((check) => check.kind == .isolated).status,
        DoctorStatus.warning,
      );
      expect(tooSoon.where((check) => check.kind == .isolated), isEmpty);
    });
  });

  group('your own VPN', () {
    Future<void> trustPhone({required bool reachOverVpn}) =>
        engine.trustStore.save(
          TrustedDevice(
            id: 'phonephonephonep',
            name: 'Pixel 7',
            platform: .PLATFORM_ANDROID,
            formFactor: .FORM_FACTOR_PHONE,
            publicKey: Uint8List(32),
            pairedAt: DateTime(2026),
            lastHost: '192.168.1.20',
            lastPort: 47640,
            reachOverVpn: reachOverVpn,
            vpnAddresses: const ['100.101.102.103'],
          ),
        );

    Future<List<DoctorCheck>> diagnoseWithTailscale() => ConnectionDoctor(
      engine,
      isWindows: false,
      isLinux: false,
      interfaces: () async => [
        (name: 'en0', address: '192.168.1.5'),
        (name: 'tailscale0', address: '100.64.0.2'),
      ],
      probe: (host, port, timeout) async => Reach.silent,
    ).diagnose('phonephonephonep').last;

    test('offers to reach the device over it when it is off', () async {
      await trustPhone(reachOverVpn: false);

      final checks = await diagnoseWithTailscale();

      final reach = checks.singleWhere((check) => check.kind == .vpnReach);
      expect(reach.status, DoctorStatus.warning);
      expect(reach.fixes, [DoctorFix.reachOverVpn]);
      expect(checks.where((check) => check.kind == .vpn), hasLength(1));
    });

    test('says the VPN is tried, without blaming it, when it is on', () async {
      await trustPhone(reachOverVpn: true);

      final checks = await diagnoseWithTailscale();

      final reach = checks.singleWhere((check) => check.kind == .vpnReach);
      expect(reach.status, DoctorStatus.ok);
      expect(reach.detail, '100.101.102.103');
      expect(checks.where((check) => check.kind == .vpn), isEmpty);
    });
  });

  group('a work VPN that carries everything', () {
    const peer = '192.168.1.20';

    Future<void> trustPhone() => engine.trustStore.save(
      TrustedDevice(
        id: 'phonephonephonep',
        name: 'Pixel 7',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
        publicKey: Uint8List(32),
        pairedAt: DateTime(2026),
        lastHost: peer,
        lastPort: 47640,
      ),
    );

    Future<List<DoctorCheck>> diagnoseRoutedVia(
      String? routeName, {
      String vpnName = 'utun4',
    }) => ConnectionDoctor(
      engine,
      isWindows: false,
      isLinux: false,
      interfaces: () async => [
        (name: 'en0', address: '192.168.1.5'),
        (name: vpnName, address: '10.20.30.40'),
      ],
      probe: (host, port, timeout) async => switch (host) {
        peer => Reach.silent,
        _ => Reach.refused,
      },
      route: (host) async => routeName,
      clock: () => (engine.startedAt ?? DateTime.now()).add(
        const Duration(minutes: 1),
      ),
    ).diagnose('phonephonephonep').last;

    test('names the VPN as the cause, not the Wi-Fi, and offers no '
        'address or VPN reach', () async {
      await trustPhone();

      final checks = await diagnoseRoutedVia('utun4');

      final route = checks.singleWhere((check) => check.kind == .vpnRoute);
      expect(route.status, DoctorStatus.problem);
      expect(route.detail, 'utun4');
      expect(checks.where((check) => check.kind == .vpn), isEmpty);
      expect(checks.where((check) => check.kind == .vpnReach), isEmpty);
      expect(checks.where((check) => check.kind == .isolated), isEmpty);
      expect(
        checks.singleWhere((check) => check.kind == .reachable).fixes,
        [DoctorFix.tryAgain],
      );
    });

    test('catches a Windows VPN whose name says nothing', () async {
      await trustPhone();

      final checks = await diagnoseRoutedVia(
        'Ethernet 3',
        vpnName: 'Ethernet 3',
      );

      expect(
        checks.singleWhere((check) => check.kind == .vpnRoute).detail,
        'Ethernet 3',
      );
    });

    test('a route through the Wi-Fi itself blames nothing', () async {
      await trustPhone();

      for (final route in ['en0', null]) {
        final checks = await diagnoseRoutedVia(route);

        expect(checks.where((check) => check.kind == .vpnRoute), isEmpty);
      }
    });
  });

  group('mobile data only', () {
    Future<void> trustMac({bool reachOverVpn = false}) =>
        engine.trustStore.save(
          TrustedDevice(
            id: 'macmacmacmacmacm',
            name: 'MacBook',
            platform: .PLATFORM_MACOS,
            formFactor: .FORM_FACTOR_LAPTOP,
            publicKey: Uint8List(32),
            pairedAt: DateTime(2026),
            reachOverVpn: reachOverVpn,
          ),
        );

    ConnectionDoctor onMobileData() => ConnectionDoctor(
      engine,
      isWindows: false,
      isLinux: false,
      interfaces: () async => [(name: 'rmnet_data0', address: '100.70.1.2')],
      probe: (host, port, timeout) async => Reach.silent,
    );

    test('says the phone is on mobile data and offers the VPN', () async {
      await trustMac();

      final checks = await onMobileData().diagnose('macmacmacmacmacm').last;
      final line = checks.first;

      expect(line.kind, DoctorCheckKind.mobileData);
      expect(line.status, DoctorStatus.problem);
      expect(line.fixes, [DoctorFix.reachOverVpn]);
      expect(checks.where((check) => check.kind == .network), isEmpty);
      expect(checks.where((check) => check.kind == .vpnReach), isEmpty);
    });

    test('with the VPN on it is only a heads-up', () async {
      await trustMac(reachOverVpn: true);

      final checks = await onMobileData().diagnose('macmacmacmacmacm').last;

      expect(checks.first.kind, DoctorCheckKind.mobileData);
      expect(checks.first.status, DoctorStatus.warning);
      expect(checks.first.fixes, isEmpty);
    });

    test('Wi-Fi next to mobile data is a normal network', () async {
      final checks = await ConnectionDoctor(
        engine,
        isWindows: false,
        isLinux: false,
        interfaces: () async => [
          (name: 'rmnet_data0', address: '100.70.1.2'),
          (name: 'wlan0', address: '192.168.1.9'),
        ],
      ).diagnose(null).last;

      expect(checks.first.kind, DoctorCheckKind.network);
      expect(checks.first.detail, '192.168.1.9');
    });
  });

  group('inside WSL', () {
    Future<List<DoctorCheck>> diagnoseInWsl(
      String? deviceId, {
      String mode = 'nat',
    }) => ConnectionDoctor(
      engine,
      isWindows: false,
      isLinux: true,
      linuxFirewall: LinuxFirewall(
        readFile: (path) async => '',
        run: (executable, arguments) async =>
            ProcessResult(0, 252, 'not running', ''),
      ),
      wsl: WslNetwork(
        environment: const {'WSL_DISTRO_NAME': 'Ubuntu'},
        readFile: (path) async => null,
        networkingMode: () async => mode,
      ),
      hearsOthers: true,
      interfaces: () async => [(name: 'eth0', address: '172.28.1.5')],
      probe: (host, port, timeout) async => switch (host) {
        '172.28.1.1' => Reach.answered,
        _ => Reach.silent,
      },
      clock: () => (engine.startedAt ?? DateTime.now()).add(
        const Duration(minutes: 1),
      ),
    ).diagnose(deviceId).last;

    test('checking the network says WSL keeps devices apart, not that '
        'everything is fine', () async {
      final checks = await diagnoseInWsl(null);

      expect(
        checks.map((check) => check.kind),
        containsAllInOrder([DoctorCheckKind.network, DoctorCheckKind.wsl]),
      );
      expect(
        checks.where((check) => check.kind == .isolated),
        isEmpty,
        reason: 'WSL explains it better than a guess about the Wi-Fi',
      );
    });

    test('with mirrored networking, WSL is not named', () async {
      final checks = await diagnoseInWsl(null, mode: 'mirrored');

      expect(checks.where((check) => check.kind == .wsl), isEmpty);
      expect(checks.where((check) => check.kind == .isolated), hasLength(1));
    });

    test('a device never seen gets the WSL line too', () async {
      final checks = await diagnoseInWsl('nobody');

      expect(checks.where((check) => check.kind == .wsl), hasLength(1));
    });
  });
}
