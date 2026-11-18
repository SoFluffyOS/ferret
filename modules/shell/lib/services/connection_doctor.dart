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
}

/// Works out why a paired device isn't connected, in the order people can
/// act on: this device's network, a VPN, different networks, the other
/// device not answering, the other device not accepting this one.
class ConnectionDoctor {
  ConnectionDoctor(
    this._engine, {
    bool? isWindows,
    bool? isLinux,
    LinuxFirewall? linuxFirewall,
  }) : _isWindows = isWindows ?? Platform.isWindows,
       _isLinux = isLinux ?? Platform.isLinux,
       _linuxFirewall = linuxFirewall ?? LinuxFirewall();

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

    final reachable = await _canReach(host, port);
    checks.removeLast();
    if (!reachable) {
      checks.add(
        DoctorCheck(
          kind: .reachable,
          status: .problem,
          detail: '$host:$port',
          fixes: const [.tryAgain, .connectByAddress],
        ),
      );
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

  Future<List<({String name, String address})>> _interfaces() async {
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

  Future<bool> _canReach(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } on Object {
      return false;
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
