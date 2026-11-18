import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';
import 'helpers/memory_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryDiscoveryBus bus;
  final engines = <FerretEngine>[];

  setUp(() => bus = MemoryDiscoveryBus());

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> startEngine(
    String name,
    RemoteInputFeature feature,
  ) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [feature],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> until(bool Function() condition) async {
    for (var attempt = 0; attempt < 200; attempt++) {
      if (condition()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    fail('Timed out waiting');
  }

  test('a phone asks, the owner allows, input arrives, Stop cuts it', () async {
    final injector = FakeInjector();
    final laptopFeature = RemoteInputFeature(
      injector: () => injector,
      canBeControlled: true,
      canControl: false,
    );
    final phoneFeature = RemoteInputFeature(
      injector: UnsupportedInjector.new,
      canBeControlled: false,
      canControl: true,
    );
    final laptop = await startEngine('Laptop', laptopFeature);
    final phone = await startEngine('Phone', phoneFeature);
    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await phone.pairWithOffer(offer), isA<Paired>());
    await until(() => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty);

    final phoneSession = phone.sessions.single;
    final laptopId = phoneSession.remoteDeviceId;
    expect(phoneFeature.canControlDevice(phoneSession), isTrue);

    final client = phoneFeature.client;
    final controlHost = laptopFeature.controlHost;
    if (client == null || controlHost == null) {
      fail('Both sides should be set up');
    }

    final waiting = await client.start(laptopId);
    expect(waiting.phase, OutgoingPhase.waitingForConsent);
    expect(controlHost.pending?.deviceName, 'Phone');

    await controlHost.answer(.always);
    await until(() => client.current?.isActive ?? false);
    expect(controlHost.active?.deviceName, 'Phone');

    client
      ..move(12, -4)
      ..click(.left)
      ..type('hello');
    await until(() => injector.injected.length >= 4);
    expect(injector.injected, const [
      MoveAction(12, -4),
      ButtonAction(.left, pressed: true),
      ButtonAction(.left, pressed: false),
      TextAction('hello'),
    ]);

    await controlHost.stop();
    await until(() => client.current?.phase == .stopped);
    expect(client.current?.stop, OutgoingStop.stoppedOnHost);
    expect(injector.releases, 1);
    expect(laptopFeature.settings.history.single.deviceName, 'Phone');

    await client.stop();
    final again = await client.start(laptopId);
    expect(again.phase, OutgoingPhase.active);
    expect(again.always, isTrue);
  });
}
