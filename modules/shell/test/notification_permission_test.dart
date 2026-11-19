import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

void main() {
  late MemorySettingsStore settings;
  late StreamController<List<DeviceStatus>> devices;
  late int asked;

  setUp(() {
    settings = MemorySettingsStore();
    devices = StreamController<List<DeviceStatus>>.broadcast();
    asked = 0;
  });

  tearDown(() => devices.close());

  NotificationPermission permission({
    bool paired = false,
    bool asksHere = true,
  }) => NotificationPermission(
    devices: devices.stream,
    hasDevices: () => paired,
    settings: settings,
    request: () async => asked++,
    asksHere: asksHere,
  );

  test('asks at start when a device is already paired, once', () async {
    await permission(paired: true).start();
    await permission(paired: true).start();

    expect(asked, 1);
    expect(settings.get<bool>(NotificationPermission.askedKey), isTrue);
  });

  test('waits for the first paired device before asking', () async {
    final waiting = permission();
    await waiting.start();
    expect(asked, 0);

    devices.add(const []);
    await Future<void>.delayed(Duration.zero);
    expect(asked, 0);

    devices.add([_status()]);
    await Future<void>.delayed(Duration.zero);
    expect(asked, 1);

    devices.add([_status()]);
    await Future<void>.delayed(Duration.zero);
    expect(asked, 1);
    await waiting.dispose();
  });

  test('never asks where another screen asks instead', () async {
    await permission(paired: true, asksHere: false).start();

    expect(asked, 0);
  });
}

DeviceStatus _status() => DeviceStatus(
  TrustedDevice(
    id: 'pixel',
    name: 'Pixel 7',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  ),
  null,
);
