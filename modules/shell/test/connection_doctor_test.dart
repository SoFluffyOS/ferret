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
  }) => ConnectionDoctor(engine, isWindows: isWindows).diagnose(deviceId).last;

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
}
