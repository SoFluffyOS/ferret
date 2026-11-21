import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_bonjour/ferret_bonjour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';
import 'package:transport/transport.dart';

import 'support/memory_discovery.dart';

void main() {
  late MemorySettingsStore settings;
  late _Inner inner;
  late HeldDiscovery held;
  late bool hasDevices;
  late StreamController<Object?> devices;
  late _Probe probe;

  LocalNetworkAsk ask() => LocalNetworkAsk(
    settings: settings,
    held: held,
    hasDevices: () => hasDevices,
    deviceChanges: devices.stream,
    probe: probe,
  );

  setUp(() {
    settings = MemorySettingsStore();
    inner = _Inner();
    held = HeldDiscovery(inner);
    hasDevices = false;
    devices = StreamController.broadcast();
    probe = _Probe(.denied);
  });

  tearDown(() => devices.close());

  test('first launch with nothing paired: nothing looks until Continue', () {
    expect(
      LocalNetworkAsk.releasedAtLaunch(settings, hasDevices: false),
      isFalse,
    );
    expect(ask().needsAsk, isTrue);
  });

  test('paired devices, or a Continue before, look from launch', () async {
    expect(
      LocalNetworkAsk.releasedAtLaunch(settings, hasDevices: true),
      isTrue,
    );

    await settings.set(LocalNetworkAsk.explainedKey, true);
    expect(
      LocalNetworkAsk.releasedAtLaunch(settings, hasDevices: false),
      isTrue,
    );
  });

  test('Continue starts discovery and is remembered', () async {
    final gate = ask();
    await held.start(Announce(deviceId: 'me', name: 'iPhone', port: 1));
    expect(inner.started, isFalse);

    await gate.allow();

    expect(inner.started, isTrue);
    expect(gate.needsAsk, isFalse);
    expect(settings.get<bool>(LocalNetworkAsk.explainedKey), isTrue);
  });

  test('the first pairing lets discovery run without the card', () async {
    final gate = ask();
    hasDevices = true;
    devices.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(gate.needsAsk, isFalse);
  });

  test('asks iOS whether Local Network is off only once it looks', () async {
    final gate = ask();
    expect(await gate.checkDenied(), isFalse);
    expect(probe.checks, 0, reason: 'asking iOS is looking');

    await gate.allow();
    await gate.refresh();

    expect(gate.isDenied, isTrue);
    expect(probe.checks, greaterThan(0));

    probe.state = .allowed;
    await gate.refresh();
    expect(gate.isDenied, isFalse);
  });

  group('Fix connection on an iPhone', () {
    late FerretEngine engine;

    setUp(() async {
      engine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: const LocalDevice(
          name: 'iPhone',
          platform: .PLATFORM_IOS,
          formFactor: .FORM_FACTOR_PHONE,
        ),
        discovery: MemoryDiscoveryBus().join(),
        port: 0,
      );
    });

    test('before Continue it says why and offers Continue, nothing '
        'else', () async {
      final checks = await ConnectionDoctor(
        engine,
        isWindows: false,
        isLinux: false,
        localNetwork: () async => .notNeeded,
        iphoneAsk: ask(),
      ).diagnose(null).last;

      expect(checks, hasLength(1));
      expect(checks.single.detail, ConnectionDoctor.iphoneNotAsked);
      expect(checks.single.fixes, [DoctorFix.explainLocalNetwork]);
    });

    test('with Local Network off it says so and opens Settings', () async {
      final gate = ask();
      await gate.allow();
      final checks = await ConnectionDoctor(
        engine,
        isWindows: false,
        isLinux: false,
        localNetwork: () async => .notNeeded,
        iphoneAsk: gate,
      ).diagnose(null).last;

      expect(checks.single.detail, ConnectionDoctor.iphoneDenied);
      expect(checks.single.fixes, [DoctorFix.openLocalNetworkSettings]);
    });

    test('allowed, the usual checks run', () async {
      probe.state = .allowed;
      final gate = ask();
      await gate.allow();
      final checks = await ConnectionDoctor(
        engine,
        isWindows: false,
        isLinux: false,
        localNetwork: () async => .notNeeded,
        iphoneAsk: gate,
      ).diagnose(null).last;

      expect(checks.where((check) => check.kind == .localNetwork), isEmpty);
    });
  });
}

class _Probe extends LocalNetworkProbe {
  _Probe(this.state) : super(isIos: true);

  LocalNetworkState state;
  int checks = 0;

  @override
  Future<LocalNetworkState> check() async {
    checks++;
    return state;
  }
}

class _Inner implements Discovery {
  bool started = false;

  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async => started = true;

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async => started = false;
}
