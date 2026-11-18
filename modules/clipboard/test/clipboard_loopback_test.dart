import 'package:clipboard/clipboard.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'helpers/memory_discovery.dart';

void main() {
  late MemoryDiscoveryBus bus;
  final engines = <FerretEngine>[];

  setUp(() => bus = MemoryDiscoveryBus());

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> startEngine(String name, FakeClipboard clipboard) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [ClipboardFeature(clipboard: () => clipboard)],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  test('a copy on one device lands on the other, and only once', () async {
    final laptopClipboard = FakeClipboard();
    final phoneClipboard = FakeClipboard();
    final laptop = await startEngine('Laptop', laptopClipboard);
    final phone = await startEngine('Phone', phoneClipboard);

    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await phone.pairWithOffer(offer), isA<Paired>());
    await _until(() => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty);

    laptopClipboard.copy(const .text('copied on the laptop'));
    await _until(() => phoneClipboard.writes.isNotEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(phoneClipboard.writes.single.text, 'copied on the laptop');
    expect(laptopClipboard.writes, isEmpty);

    final phoneFeature = phone.feature<ClipboardFeature>();
    expect(phoneFeature?.latest?.deviceNames, ['Laptop']);
    expect(phoneFeature?.latest?.onClipboard, isTrue);
  });
}

Future<void> _until(
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
