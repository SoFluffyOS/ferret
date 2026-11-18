import 'dart:async';
import 'dart:io';

import 'package:engine/engine.dart';

/// How one check came out.
enum DoctorStatus { running, ok, warning, problem }

/// Something the user can do about a check.
enum DoctorFix { tryAgain, connectByAddress, pairAgain, copyDiagnostics }

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

enum DoctorCheckKind { network, vpn, sameNetwork, reachable, accepted, port }

/// Works out why a paired device isn't connected, in the order people can
/// act on: this device's network, a VPN, different networks, the other
/// device not answering, the other device not accepting this one.
class ConnectionDoctor {
  ConnectionDoctor(this._engine);

  final FerretEngine _engine;

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

    if (deviceId == null) {
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

  /// A report to paste into an issue: no names, addresses only by their kind.
  String diagnostics(List<DoctorCheck> checks) {
    final lines = [
      'Ferret ${_engine.device.appVersion} on ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'Port ${_engine.port}',
      for (final check in checks) '${check.kind.name}: ${check.status.name}',
    ];
    return lines.join('\n');
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
