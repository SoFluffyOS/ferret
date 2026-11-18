import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
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

  Future<List<DoctorCheck>> diagnose(
    String? deviceId, {
    required bool isWindows,
  }) => ConnectionDoctor(
    engine,
    isWindows: isWindows,
    isLinux: false,
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
      expect(check.fixes, [DoctorFix.openFirewall]);
    }
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
    final doctor = ConnectionDoctor(engine, isWindows: true);
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
}
