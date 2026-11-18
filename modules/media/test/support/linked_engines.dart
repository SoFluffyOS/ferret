import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';

import 'memory_discovery.dart';

/// Two paired engines on loopback, each with its own media feature.
class LinkedEngines {
  LinkedEngines._(this.phone, this.laptop);

  final FerretEngine phone;
  final FerretEngine laptop;

  MediaFeature get phoneMedia => _media(phone);

  MediaFeature get laptopMedia => _media(laptop);

  static Future<LinkedEngines> start({
    required MediaFeature phoneFeature,
    required MediaFeature laptopFeature,
  }) async {
    final bus = MemoryDiscoveryBus();
    final phone = await _engine('Pixel', phoneFeature, bus);
    final laptop = await _engine('Laptop', laptopFeature, bus);

    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await phone.pairWithOffer(offer), isA<Paired>());
    await until(() => phone.sessions.isNotEmpty && laptop.sessions.isNotEmpty);
    return LinkedEngines._(phone, laptop);
  }

  Future<void> stop() async {
    await phone.stop();
    await laptop.stop();
  }

  static Future<FerretEngine> _engine(
    String name,
    MediaFeature feature,
    MemoryDiscoveryBus bus,
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
    return engine;
  }

  static MediaFeature _media(FerretEngine engine) {
    final feature = engine.feature<MediaFeature>();
    if (feature == null) {
      fail('The engine should run the media feature');
    }

    return feature;
  }
}

/// Waits until [condition] holds, or fails after [timeout].
Future<void> until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
