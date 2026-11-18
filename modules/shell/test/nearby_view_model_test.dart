import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'support/memory_discovery.dart';

void main() {
  late MemoryDiscoveryBus bus;
  final engines = <FerretEngine>[];
  final viewModels = <NearbyViewModel>[];

  setUp(() => bus = MemoryDiscoveryBus());

  tearDown(() async {
    for (final viewModel in viewModels) {
      viewModel.dispose();
    }

    for (final engine in engines) {
      await engine.stop();
    }

    viewModels.clear();
    engines.clear();
  });

  Future<FerretEngine> startEngine(String name) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
      ),
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  NearbyViewModel watch(FerretEngine engine) {
    final viewModel = NearbyViewModel(engine, looks: 1);
    viewModels.add(viewModel);
    return viewModel;
  }

  test('lists the devices near you, without any scanning by hand', () async {
    final mac = await startEngine('MacBook Pro');
    await startEngine('Pixel 7');
    await startEngine('Alpha tablet');

    final nearby = watch(mac);
    await _until(() => nearby.hasLooked && !nearby.isLooking);

    expect(nearby.peers.map((peer) => peer.announce.name), [
      'Alpha tablet',
      'Pixel 7',
    ]);
  });

  test('pairs when both sides agree on the same code', () async {
    final mac = await startEngine('MacBook Pro');
    final pixel = await startEngine('Pixel 7');
    final nearby = watch(mac);
    await _until(() => nearby.peers.isNotEmpty);
    final prompt = pixel.pairingPrompts.first;

    unawaited(nearby.pair(nearby.peers.single));
    await _until(() => nearby.attempt is NearbyComparing);
    final shown = await prompt;
    final comparing = nearby.attempt as NearbyComparing;
    expect(comparing.code, shown.code);
    expect(comparing.confirmedHere, isFalse);
    expect(mac.trustStore.devices, isEmpty);

    nearby.confirm();
    expect((nearby.attempt as NearbyComparing).confirmedHere, isTrue);
    shown.accept();

    await _until(() => nearby.attempt is NearbyPaired);
    expect(mac.trustStore.isTrusted(pixel.identity.deviceId), isTrue);
    expect(pixel.trustStore.isTrusted(mac.identity.deviceId), isTrue);
    expect(nearby.peers.single.announce.name, 'Pixel 7');
    nearby.dismiss();
    expect(nearby.peers, isEmpty);
  });

  test('cancelling clears the row and the other device\'s prompt', () async {
    final mac = await startEngine('MacBook Pro');
    final pixel = await startEngine('Pixel 7');
    final nearby = watch(mac);
    await _until(() => nearby.peers.isNotEmpty);
    final prompt = pixel.pairingPrompts.first;

    unawaited(nearby.pair(nearby.peers.single));
    await _until(() => nearby.attempt is NearbyComparing);
    nearby.cancel();

    await _until(() => nearby.attempt == null);
    expect(await (await prompt).answer, PairingAnswer.withdrawn);
    expect(mac.trustStore.devices, isEmpty);
    expect(pixel.trustStore.devices, isEmpty);
  });

  test('says so when the other device answers not now', () async {
    final mac = await startEngine('MacBook Pro');
    final pixel = await startEngine('Pixel 7');
    final nearby = watch(mac);
    await _until(() => nearby.peers.isNotEmpty);
    unawaited(pixel.pairingPrompts.first.then((prompt) => prompt.reject()));

    unawaited(nearby.pair(nearby.peers.single));

    await _until(() => nearby.attempt is NearbyFailed);
    expect((nearby.attempt as NearbyFailed).reason, PairingFailure.rejected);
    nearby.dismiss();
    expect(nearby.attempt, isNull);
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
