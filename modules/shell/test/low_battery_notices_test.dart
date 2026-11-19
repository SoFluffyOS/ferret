import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';

class _Notifier implements LocalNotifier {
  final List<LocalNotice> shown = [];

  @override
  Future<void> show(LocalNotice notice) async => shown.add(notice);

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}

class _Session implements Session {
  _Session(int percent, {bool charging = false})
    : remotePresence = Presence(batteryPercent: percent, charging: charging);

  @override
  Presence remotePresence;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DeviceStatus _pixel(int percent, {bool charging = false}) => DeviceStatus(
  TrustedDevice(
    id: 'pixel',
    name: 'Pixel 7',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026, 11, 1),
  ),
  _Session(percent, charging: charging),
);

void main() {
  late StreamController<List<DeviceStatus>> devices;
  late _Notifier notifier;
  late MemorySettingsStore settings;

  setUp(() {
    devices = StreamController();
    notifier = _Notifier();
    settings = MemorySettingsStore();
    LowBatteryNotices(
      devices: devices.stream,
      notifier: notifier,
      settings: settings,
      nameOf: (_) => 'Pixel 7',
      l10n: () => lookupShellLocalizations(const Locale('en')),
    ).start();
  });

  tearDown(() => devices.close());

  Future<void> report(DeviceStatus status) async {
    devices.add([status]);
    await pumpEventQueue();
  }

  test('says once when a device drops to 15%', () async {
    await report(_pixel(40));
    await report(_pixel(15));
    await report(_pixel(14));
    await report(_pixel(10));

    expect(notifier.shown.map((notice) => notice.title), [
      'Pixel 7 is at 15%',
    ]);
  });

  test('says it again only after the device charged', () async {
    await report(_pixel(15));
    await report(_pixel(15, charging: true));
    await report(_pixel(14));

    expect(notifier.shown, hasLength(2));
  });

  test('a charging device is never low', () async {
    await report(_pixel(5, charging: true));

    expect(notifier.shown, isEmpty);
  });

  test('turned off, nothing shows', () async {
    await settings.set(LowBatteryNotices.enabledKey, false);

    await report(_pixel(12));

    expect(notifier.shown, isEmpty);
  });
}
