import 'dart:async';
import 'dart:io';

import 'package:engine/engine.dart';
import 'package:shell/services/linux_firewall.dart';

/// How one check came out.
enum DoctorStatus { running, ok, warning, problem }

/// Something the user can do about a check.
enum DoctorFix {
  tryAgain,
  connectByAddress,
  pairAgain,
  openFirewall,
  copyFirewallCommand,
  copyDiagnostics,
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
  network,
  vpn,
  sameNetwork,
  reachable,
  accepted,
  port,
  firewall,

  /// The network keeps its devices from talking to each other (client or
  /// AP isolation), as café, hotel, campus and guest Wi-Fi often do. A
  /// problem when a device on the same network didn't answer; a warning
  /// when Ferret only never heard anyone.
  isolated,
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

/// Works out why a paired device isn't connected, in the order people can
/// act on: this device's network, a VPN, different networks, the other
/// device not answering, the other device not accepting this one.
class ConnectionDoctor {
  ConnectionDoctor(
    this._engine, {
    bool? isWindows,
    bool? isLinux,
    LinuxFirewall? linuxFirewall,
    NetworkInterfaces? interfaces,
    ReachProbe? probe,
    DateTime Function()? clock,
  }) : _isWindows = isWindows ?? Platform.isWindows,
       _isLinux = isLinux ?? Platform.isLinux,
       _linuxFirewall = linuxFirewall ?? LinuxFirewall(),
       _listInterfaces = interfaces ?? _systemInterfaces,
       _probe = probe ?? _knock,
       _clock = clock ?? DateTime.now;

  final FerretEngine _engine;

  /// Windows Firewall hides a computer from its network until the app is
  /// allowed, and a dismissed prompt never comes back. Nothing tells Ferret
  /// it happened, so it is named as a likely cause whenever the other
  /// device can't be found or doesn't answer.
  final bool _isWindows;

  /// ufw and firewalld block everything they weren't told about, and on
  /// Linux nothing ever asks. Named only when one of them is on.
  final bool _isLinux;
  final LinuxFirewall _linuxFirewall;
  final NetworkInterfaces _listInterfaces;
  final ReachProbe _probe;
  final DateTime Function() _clock;

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
    fixes: [.openFirewall],
  );

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
    final firewall = await _firewallHint();

    final interfaces = await _interfaces();
    final local = interfaces.where((entry) => !_isVpn(entry.name)).toList();
    checks.add(
      DoctorCheck(
        kind: .network,
        status: switch (local.isEmpty) {
          true => DoctorStatus.problem,
          false => DoctorStatus.ok,
        },
        detail: local.map((entry) => entry.address).join(', '),
      ),
    );
    yield [...checks];

    final vpn = interfaces
        .where((entry) => _isVpn(entry.name))
        .map((entry) => entry.name)
        .toSet();
    if (vpn.isNotEmpty) {
      checks.add(
        DoctorCheck(kind: .vpn, status: .warning, detail: vpn.join(', ')),
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

    final shared = local.any((entry) => _sameSubnet(entry.address, host));
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
    yield [...checks];

    checks.add(
      DoctorCheck(kind: .reachable, status: .running, detail: '$host:$port'),
    );
    yield [...checks];

    final reach = await _probe(host, port, _knockTimeout);
    checks.removeLast();
    if (reach != .answered) {
      final isolated =
          reach == .silent &&
          shared &&
          !_heardOthersLately &&
          await _routerAnswers(local, host);
      checks.add(
        DoctorCheck(
          kind: .reachable,
          status: .problem,
          detail: '$host:$port',
          fixes: switch (isolated) {
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
    if (startedAt == null || _engine.sessions.isNotEmpty) {
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
  Future<DoctorCheck?> _firewallHint() async {
    if (_isWindows) {
      return _windowsFirewall;
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
