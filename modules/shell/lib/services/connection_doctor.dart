import 'dart:async';
import 'dart:io';

import 'package:engine/engine.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:shell/services/linux_firewall.dart';
import 'package:shell/services/local_network_ask.dart';

/// How one check came out.
enum DoctorStatus { running, ok, warning, problem }

/// Something the user can do about a check.
enum DoctorFix {
  tryAgain,
  connectByAddress,
  pairAgain,
  allowFirewall,
  openFirewall,
  copyFirewallCommand,
  copyDiagnostics,

  /// Opens the device's "Reach away from home" page.
  reachOverVpn,

  /// Shows Android 17's question about the local network.
  allowLocalNetwork,

  /// Opens Ferret's page in Android's settings, where a local network
  /// permission turned down for good can still be allowed.
  openAppSettings,

  /// Opens Network & internet in Windows Settings, where a network's
  /// profile goes from Public to Private.
  openNetworkSettings,

  /// Opens Privacy & Security, Local Network in macOS System Settings, or
  /// Ferret's page in the iPhone's Settings.
  openLocalNetworkSettings,

  /// Says why Ferret needs the local network on an iPhone, then lets it
  /// look, which is when iOS asks.
  explainLocalNetwork,
}

/// One line of Fix connection: what was checked and what it found.
class DoctorCheck {
  const DoctorCheck({
    required this.kind,
    required this.status,
    this.detail = '',
    this.fixes = const [],
  });

  final DoctorCheckKind kind;
  final DoctorStatus status;

  /// Facts for the UI to put in words, such as an interface name or address.
  final String detail;
  final List<DoctorFix> fixes;
}

enum DoctorCheckKind {
  /// Android 17 keeps Ferret off the local network until it is allowed.
  /// [DoctorCheck.detail] is the [LocalNetworkAccess] name, or
  /// [ConnectionDoctor.macOSBlocked] when macOS refuses Ferret's packets.
  localNetwork,

  network,
  vpn,
  sameNetwork,
  reachable,
  accepted,
  port,
  firewall,

  /// Reaching the device over the user's own VPN: on, or worth turning on
  /// because this device is on a VPN.
  vpnReach,

  /// This device has mobile data and no Wi-Fi or Ethernet, so nothing
  /// nearby can be reached. Comes with the "Reach over your VPN" fix when
  /// that is still off for the device.
  mobileData,

  /// The network keeps its devices from talking to each other (client or
  /// AP isolation), as café, hotel, campus and guest Wi-Fi often do. A
  /// problem when a device on the same network didn't answer; a warning
  /// when Ferret only never heard anyone.
  isolated,

  /// The device's address is on this device's own network, yet the system
  /// sends traffic for it through another interface: a VPN that carries
  /// everything (a "full tunnel", as work VPNs often are).
  /// [DoctorCheck.detail] is that interface's name.
  vpnRoute,
}

/// How a knock on an address went.
enum Reach {
  /// It connected.
  answered,

  /// Something there said no right away: the address is reachable.
  refused,

  /// Nothing came back before the timeout.
  silent,
}

typedef NetworkInterfaces =
    Future<List<({String name, String address})>> Function();

typedef ReachProbe = Future<Reach> Function(
  String host,
  int port,
  Duration timeout,
);

/// The name of the interface the system sends traffic for `host` through,
/// or null when it can't tell.
typedef RouteLookup = Future<String?> Function(String host);

/// Works out why a paired device isn't connected, in the order people can
/// act on: this device's network, a VPN, different networks, the other
/// device not answering, the other device not accepting this one.
class ConnectionDoctor {
  ConnectionDoctor(
    this._engine, {
    bool? isWindows,
    bool? isLinux,
    LinuxFirewall? linuxFirewall,
    WindowsFirewallRules? windowsFirewallRules,
    String? program,
    NetworkInterfaces? interfaces,
    ReachProbe? probe,
    RouteLookup? route,
    DateTime Function()? clock,
    Future<LocalNetworkAccess> Function()? localNetwork,
    bool? hearsOthers,
    bool? isMacOS,
    bool Function()? isDiscoveryBlocked,
    LocalNetworkAsk? iphoneAsk,
  }) : _iphoneAsk = iphoneAsk,
       _isWindows = isWindows ?? Platform.isWindows,
       _isMacOS = isMacOS ?? Platform.isMacOS,
       _isDiscoveryBlocked =
           isDiscoveryBlocked ?? (() => _engine.isDiscoveryBlocked),
       _hearsOthers = hearsOthers ?? defaultTargetPlatform != .iOS,
       _isLinux = isLinux ?? Platform.isLinux,
       _linuxFirewall = linuxFirewall ?? LinuxFirewall(),
       _windowsFirewallRules = windowsFirewallRules ?? WindowsFirewallRules(),
       _program = program ?? Platform.resolvedExecutable,
       _listInterfaces = interfaces ?? _systemInterfaces,
       _route =
           route ??
           switch (interfaces) {
             null => _systemRoute,
             _ => _noRoute,
           },
       _probe = probe ?? _knock,
       _clock = clock ?? DateTime.now,
       _localNetwork = localNetwork ?? _systemLocalNetwork;

  final FerretEngine _engine;

  /// Whether discovery hears other devices here at all. An iPhone never
  /// does, so its silence says nothing about the Wi-Fi.
  final bool _hearsOthers;

  /// Windows Firewall hides a computer from its network until the app is
  /// allowed, and a dismissed prompt never comes back. Nothing tells Ferret
  /// it happened, so it is named as a likely cause whenever the other
  /// device can't be found or doesn't answer.
  final bool _isWindows;

  /// macOS asks once about the local network and then silently drops
  /// everything Ferret sends while the switch is off. Discovery notices
  /// when nothing got out.
  final bool _isMacOS;
  final bool Function() _isDiscoveryBlocked;

  /// [DoctorCheck.detail] of the local network line when macOS blocks
  /// Ferret.
  static const macOSBlocked = 'macos';

  /// On an iPhone: Ferret hasn't looked on the network yet, or Local
  /// Network is off for it. Nothing else gets through either way.
  final LocalNetworkAsk? _iphoneAsk;

  /// [DoctorCheck.detail] while Ferret hasn't said why it looks yet.
  static const iphoneNotAsked = 'iphone_not_asked';

  /// [DoctorCheck.detail] when Local Network is off for Ferret.
  static const iphoneDenied = 'iphone_denied';

  /// ufw and firewalld block everything they weren't told about, and on
  /// Linux nothing ever asks. Named only when one of them is on.
  final bool _isLinux;
  final LinuxFirewall _linuxFirewall;

  /// The rules the installer, or [allowThroughFirewall], adds. With them
  /// in place the firewall line turns green.
  final WindowsFirewallRules _windowsFirewallRules;

  /// This running Ferret, which a Windows block rule names.
  final String _program;

  /// Whether the last check found a rule blocking [_program], so Allow
  /// through firewall removes it too.
  bool _blocked = false;
  final NetworkInterfaces _listInterfaces;

  /// Only asks the system when the interfaces are the system's too, so a
  /// made-up network is never compared with the real routing table.
  final RouteLookup _route;
  final ReachProbe _probe;
  final DateTime Function() _clock;
  final Future<LocalNetworkAccess> Function() _localNetwork;

  static Future<LocalNetworkAccess> _systemLocalNetwork() async {
    if (!Platform.isAndroid) {
      return .notNeeded;
    }

    return FerretSystem().localNetworkAccess();
  }

  /// Discovery announces every few seconds, so this long without hearing
  /// anyone means nothing gets through, not bad luck.
  static const _quietFor = Duration(seconds: 20);

  /// Ports a home or public router answers on, or refuses, but doesn't
  /// drop: DNS, the setup page, its secure version.
  static const _routerPorts = [53, 80, 443];

  static const _knockTimeout = Duration(seconds: 3);
  static const _routerTimeout = Duration(milliseconds: 1500);

  static const _windowsFirewall = DoctorCheck(
    kind: .firewall,
    status: .warning,
    fixes: [.allowFirewall, .openFirewall],
  );

  /// [DoctorCheck.detail] of the firewall line once Ferret's Windows rules
  /// are in place.
  static const windowsRulesInstalled = 'windows-rules';

  /// [DoctorCheck.detail] when a Windows Firewall rule blocks Ferret itself.
  static const windowsBlocked = 'windows-blocked';

  /// [DoctorCheck.detail] when the rules are in place but Windows calls
  /// this network Public, where they don't apply.
  static const windowsPublicNetwork = 'windows-public';

  static const _vpnPrefixes = [
    'utun',
    'tun',
    'tap',
    'wg',
    'tailscale',
    'ppp',
    'ipsec',
    'zt',
  ];

  /// Runs every check for [deviceId], reporting each result as it lands.
  /// With no device, only this device's own network is checked.
  Stream<List<DoctorCheck>> diagnose(String? deviceId) async* {
    final checks = <DoctorCheck>[];
    final device = switch (deviceId) {
      final deviceId? => _engine.trustStore[deviceId],
      null => null,
    };
    _target = device;
    final localNetwork = await _localNetwork();
    if (localNetwork == .notGranted || localNetwork == .blocked) {
      // Nothing else gets through until Android lets Ferret on the network.
      yield [
        DoctorCheck(
          kind: .localNetwork,
          status: .problem,
          detail: localNetwork.name,
          fixes: switch (localNetwork) {
            .blocked => const [DoctorFix.openAppSettings],
            _ => const [DoctorFix.allowLocalNetwork],
          },
        ),
      ];
      return;
    }

    if (_iphoneAsk case final ask?) {
      final detail = switch ((ask.needsAsk, await ask.checkDenied())) {
        (true, _) => iphoneNotAsked,
        (false, true) => iphoneDenied,
        _ => null,
      };
      if (detail != null) {
        yield [
          DoctorCheck(
            kind: .localNetwork,
            status: .problem,
            detail: detail,
            fixes: switch (detail) {
              iphoneNotAsked => const [DoctorFix.explainLocalNetwork],
              _ => const [DoctorFix.openLocalNetworkSettings],
            },
          ),
        ];
        return;
      }
    }

    if (_isMacOS && _isDiscoveryBlocked()) {
      checks.add(
        const DoctorCheck(
          kind: .localNetwork,
          status: .problem,
          detail: macOSBlocked,
          fixes: [DoctorFix.openLocalNetworkSettings],
        ),
      );
      yield [...checks];
    }

    final interfaces = await _interfaces();
    final cellular = interfaces.any(
      (entry) => VpnAddresses.isCellularInterface(entry.name),
    );
    final local = interfaces
        .where(
          (entry) =>
              !_isVpn(entry.name) &&
              !VpnAddresses.isCellularInterface(entry.name),
        )
        .toList();
    final firewall = await _firewallHint(local);
    final reachesOverVpn = device?.reachOverVpn ?? false;
    final onMobileData = local.isEmpty && cellular;
    checks.add(
      switch (onMobileData) {
        true => DoctorCheck(
          kind: .mobileData,
          status: switch (reachesOverVpn) {
            true => DoctorStatus.warning,
            false => DoctorStatus.problem,
          },
          fixes: switch (device != null && !reachesOverVpn) {
            true => const [DoctorFix.reachOverVpn],
            false => const [],
          },
        ),
        false => DoctorCheck(
          kind: .network,
          status: switch (local.isEmpty) {
            true => DoctorStatus.problem,
            false => DoctorStatus.ok,
          },
          detail: local.map((entry) => entry.address).join(', '),
        ),
      },
    );
    yield [...checks];

    final vpn = interfaces
        .where((entry) => _isVpn(entry.name))
        .map((entry) => entry.name)
        .toSet();
    if (vpn.isNotEmpty && !reachesOverVpn) {
      checks.add(
        DoctorCheck(kind: .vpn, status: .warning, detail: vpn.join(', ')),
      );
      yield [...checks];
    }

    if (device != null &&
        !(onMobileData && !reachesOverVpn) &&
        (reachesOverVpn || vpn.isNotEmpty)) {
      checks.add(
        DoctorCheck(
          kind: .vpnReach,
          status: switch (reachesOverVpn) {
            true => DoctorStatus.ok,
            false => DoctorStatus.warning,
          },
          detail: device.vpnAddresses.join(', '),
          fixes: switch (reachesOverVpn) {
            true => const [],
            false => const [DoctorFix.reachOverVpn],
          },
        ),
      );
      yield [...checks];
    }

    if (_engine.port != FerretEngine.defaultPort) {
      checks.add(
        DoctorCheck(kind: .port, status: .warning, detail: '${_engine.port}'),
      );
      yield [...checks];
    }

    final online = local.isNotEmpty;
    if (deviceId == null) {
      if (online && await _seemsIsolated(local)) {
        checks.add(const DoctorCheck(kind: .isolated, status: .warning));
        yield [...checks];
      }

      if (firewall != null && online) {
        checks.add(firewall);
        yield [...checks];
      }
      return;
    }

    final (host, port) = (device?.lastHost, device?.lastPort);
    if (device == null || host == null || port == null) {
      checks.add(
        const DoctorCheck(
          kind: .reachable,
          status: .problem,
          fixes: [.connectByAddress],
        ),
      );
      if (firewall != null && online) {
        checks.add(firewall);
      }
      yield [...checks];
      return;
    }

    final neighbours = local.where(
      (entry) => _sameSubnet(entry.address, host),
    );
    final shared = neighbours.isNotEmpty;
    final routedVia = switch (shared) {
      true => await _route(host),
      false => null,
    };
    final capturedBy = switch (routedVia) {
      final name?
          when !neighbours.any((entry) => entry.name == name) &&
              !VpnAddresses.isCellularInterface(name) =>
        name,
      _ => null,
    };
    checks.add(
      DoctorCheck(
        kind: .sameNetwork,
        status: switch (shared) {
          true => DoctorStatus.ok,
          false => DoctorStatus.warning,
        },
        detail: host,
      ),
    );
    if (capturedBy != null) {
      // A VPN that takes the device's own address explains it better than
      // "a VPN is on", and reaching the device over a VPN doesn't help.
      checks
        ..removeWhere(
          (check) =>
              check.kind == .vpn ||
              (check.kind == .vpnReach && check.status != .ok),
        )
        ..add(
          DoctorCheck(kind: .vpnRoute, status: .problem, detail: capturedBy),
        );
    }
    yield [...checks];

    checks.add(
      DoctorCheck(kind: .reachable, status: .running, detail: '$host:$port'),
    );
    yield [...checks];

    final reach = await _probe(host, port, _knockTimeout);
    checks.removeLast();
    if (reach != .answered) {
      final isolated =
          capturedBy == null &&
          reach == .silent &&
          shared &&
          _hearsOthers &&
          !_heardOthersLately &&
          await _routerAnswers(local, host);
      checks.add(
        DoctorCheck(
          kind: .reachable,
          status: .problem,
          detail: '$host:$port',
          fixes: switch (isolated || capturedBy != null) {
            true => const [DoctorFix.tryAgain],
            false => const [DoctorFix.tryAgain, DoctorFix.connectByAddress],
          },
        ),
      );
      if (isolated) {
        checks.add(const DoctorCheck(kind: .isolated, status: .problem));
      }

      if (firewall != null) {
        checks.add(firewall);
      }
      yield [...checks];
      return;
    }

    checks
      ..add(DoctorCheck(kind: .reachable, status: .ok, detail: '$host:$port'))
      ..add(const DoctorCheck(kind: .accepted, status: .running));
    yield [...checks];

    await _engine.connect(host, port);
    final connected = await _waitForSession(deviceId);
    checks
      ..removeLast()
      ..add(
        DoctorCheck(
          kind: .accepted,
          status: switch (connected) {
            true => DoctorStatus.ok,
            false => DoctorStatus.problem,
          },
          fixes: switch (connected) {
            true => const [],
            false => const [DoctorFix.pairAgain],
          },
        ),
      );
    yield [...checks];
  }

  TrustedDevice? _target;

  /// Whether discovery heard another Ferret device recently. On a network
  /// that keeps devices apart it never does.
  bool get _heardOthersLately {
    final heard = _engine.lastHeardOthers;
    if (heard == null) {
      return false;
    }

    return _clock().difference(heard) < const Duration(minutes: 10);
  }

  /// Nothing heard for a while, nothing connected, and yet the router
  /// answers: the network itself is likely keeping devices apart.
  Future<bool> _seemsIsolated(
    List<({String name, String address})> local,
  ) async {
    final startedAt = _engine.startedAt;
    if (startedAt == null || _engine.sessions.isNotEmpty || !_hearsOthers) {
      return false;
    }

    if (_heardOthersLately || _clock().difference(startedAt) < _quietFor) {
      return false;
    }

    return _routerAnswers(local, null);
  }

  /// Knocks on the router, guessed as `.1` of this device's network (the
  /// one shared with [peer] when given). A refusal counts: it means the
  /// path is open, only the port is closed.
  Future<bool> _routerAnswers(
    List<({String name, String address})> local,
    String? peer,
  ) async {
    final own = switch (peer) {
      final peer? => local.where((entry) => _sameSubnet(entry.address, peer)),
      null => local,
    };
    if (own.isEmpty) {
      return false;
    }

    final parts = own.first.address.split('.');
    if (parts.length != 4) {
      return false;
    }

    final router = '${parts.take(3).join('.')}.1';
    if (router == own.first.address) {
      return false;
    }

    final answers = await Future.wait([
      for (final port in _routerPorts) _probe(router, port, _routerTimeout),
    ]);
    return answers.any((reach) => reach != .silent);
  }

  /// The firewall line for this computer: Windows Firewall always, a Linux
  /// firewall when one is on, with its name in [DoctorCheck.detail].
  Future<DoctorCheck?> _firewallHint(
    List<({String name, String address})> local,
  ) async {
    if (_isWindows) {
      return _windowsFirewallHint(local);
    }

    if (!_isLinux) {
      return null;
    }

    final kind = await _linuxFirewall.active();
    if (kind == null) {
      return null;
    }

    return DoctorCheck(
      kind: .firewall,
      status: .warning,
      detail: kind.name,
      fixes: const [.copyFirewallCommand],
    );
  }

  /// A rule blocking Ferret first, since it beats every allow rule; then
  /// missing rules; then a Public network, where the rules don't apply.
  Future<DoctorCheck> _windowsFirewallHint(
    List<({String name, String address})> local,
  ) async {
    _blocked = await _windowsFirewallRules.blocksProgram(_program);
    if (_blocked) {
      return const DoctorCheck(
        kind: .firewall,
        status: .problem,
        detail: windowsBlocked,
        fixes: [.allowFirewall, .openFirewall],
      );
    }

    if (!await _windowsFirewallRules.areInstalled()) {
      return _windowsFirewall;
    }

    final categories = await _windowsFirewallRules.networkCategories();
    if (isPublicNetwork(categories, [for (final entry in local) entry.name])) {
      return const DoctorCheck(
        kind: .firewall,
        status: .warning,
        detail: windowsPublicNetwork,
        fixes: [.openNetworkSettings],
      );
    }

    return const DoctorCheck(
      kind: .firewall,
      status: .ok,
      detail: windowsRulesInstalled,
    );
  }

  /// Whether Windows calls the network Ferret uses Public: the category of
  /// [interfaces] by name, or, when none of them is listed (Windows' and
  /// Dart's names differ), every listed network being Public.
  @visibleForTesting
  static bool isPublicNetwork(
    Map<String, String> categories,
    List<String> interfaces,
  ) {
    bool isPublic(String category) => category.toLowerCase() == 'public';
    final names = {for (final name in interfaces) name.toLowerCase()};
    final ours = [
      for (final MapEntry(:key, :value) in categories.entries)
        if (names.contains(key.toLowerCase())) value,
    ];
    if (ours.isNotEmpty) {
      return ours.any(isPublic);
    }

    return categories.isNotEmpty && categories.values.every(isPublic);
  }

  /// Adds Ferret's Windows Firewall rules behind a UAC prompt, removing a
  /// rule that blocks Ferret in the same prompt. False when the prompt was
  /// declined or the rules still aren't there.
  Future<bool> allowThroughFirewall() => _windowsFirewallRules.allow(
    unblock: switch (_blocked) {
      true => _program,
      false => null,
    },
  );

  /// A report to paste into an issue: no names, addresses only by their kind.
  /// It says what kind of device was checked and when it was last seen, so
  /// an iPhone asleep in the background reads differently from a blocked
  /// port.
  String diagnostics(List<DoctorCheck> checks, {DateTime? now}) {
    final target = _target;
    final lines = [
      'Ferret ${_engine.device.appVersion} on ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'Port ${_engine.port}',
      if (target != null)
        'Checked: ${target.platform.name.replaceFirst('PLATFORM_', '').toLowerCase()} '
            '${target.formFactor.name.replaceFirst('FORM_FACTOR_', '').toLowerCase()}, '
            '${_seen(target.lastSeen, now ?? DateTime.now())}',
      for (final check in checks) '${check.kind.name}: ${check.status.name}',
    ];
    return lines.join('\n');
  }

  static String _seen(DateTime? lastSeen, DateTime now) {
    if (lastSeen == null) {
      return 'never connected';
    }

    final ago = now.difference(lastSeen);
    if (ago.inMinutes < 1) {
      return 'last seen just now';
    }
    if (ago.inHours < 1) {
      return 'last seen ${ago.inMinutes} min ago';
    }
    if (ago.inDays < 1) {
      return 'last seen ${ago.inHours} h ago';
    }
    return 'last seen ${ago.inDays} d ago';
  }

  Future<List<({String name, String address})>> _interfaces() =>
      _listInterfaces();

  static Future<List<({String name, String address})>>
  _systemInterfaces() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      return [
        for (final interface in interfaces)
          for (final address in interface.addresses)
            if (!address.isLoopback && !address.isLinkLocal)
              (name: interface.name, address: address.address),
      ];
    } on Object {
      return const [];
    }
  }

  static Future<String?> _noRoute(String host) async => null;

  /// Asks the routing table which interface carries traffic for [host]:
  /// `route` on a Mac, `ip` on Linux, `Find-NetRoute` on Windows (whose
  /// alias is the name Dart lists interfaces by). None of them needs admin
  /// rights. Phones aren't asked.
  static Future<String?> _systemRoute(String host) async {
    if (InternetAddress.tryParse(host)?.type != InternetAddressType.IPv4) {
      return null;
    }

    final (executable, arguments, pattern) = switch (Platform.operatingSystem) {
      'macos' => ('route', ['-n', 'get', host], RegExp(r'interface:\s*(\S+)')),
      'linux' => ('ip', ['-o', 'route', 'get', host], RegExp(r'\bdev\s+(\S+)')),
      'windows' => (
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          "(Find-NetRoute -RemoteIPAddress '$host' | "
              'Select-Object -First 1).InterfaceAlias',
        ],
        RegExp(r'^\s*(\S.*?)\s*$', multiLine: true),
      ),
      _ => (null, const <String>[], null),
    };
    if (executable == null || pattern == null) {
      return null;
    }

    try {
      final result = await Process.run(
        executable,
        arguments,
      ).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) {
        return null;
      }

      return pattern.firstMatch('${result.stdout}')?.group(1);
    } on Object {
      return null;
    }
  }

  bool _isVpn(String name) =>
      _vpnPrefixes.any((prefix) => name.toLowerCase().startsWith(prefix));

  bool _sameSubnet(String a, String b) {
    final left = a.split('.');
    final right = b.split('.');
    if (left.length != 4 || right.length != 4) {
      return false;
    }

    return left.take(3).join('.') == right.take(3).join('.');
  }

  /// ECONNREFUSED on macOS and iOS, Linux and Android, and Windows.
  static const _refusedCodes = {61, 111, 10061};

  static Future<Reach> _knock(String host, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return .answered;
    } on SocketException catch (error) {
      if (_refusedCodes.contains(error.osError?.errorCode)) {
        return .refused;
      }

      return .silent;
    } on Object {
      return .silent;
    }
  }

  Future<bool> _waitForSession(String deviceId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(deadline)) {
      if (_engine.sessionFor(deviceId) != null) {
        return true;
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    return false;
  }
}
