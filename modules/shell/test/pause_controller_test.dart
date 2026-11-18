import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';
import 'package:transport/transport.dart';

void main() {
  test('pausing stops the engine and resuming starts it again', () async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Laptop',
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      discovery: _SilentDiscovery(),
      port: 0,
    );
    await engine.start();
    final controller = PauseController(engine);

    await controller.pause(duration: const Duration(hours: 1));
    expect(controller.isPaused, isTrue);
    expect(controller.until, isNotNull);
    expect(engine.isRunning, isFalse);

    await controller.resume();
    expect(controller.isPaused, isFalse);
    expect(engine.isRunning, isTrue);

    await engine.stop();
    controller.dispose();
  });
}

class _SilentDiscovery implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
