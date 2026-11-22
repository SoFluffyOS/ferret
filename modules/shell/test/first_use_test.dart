import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

void main() {
  final now = DateTime(2026, 11, 22, 10);

  TrustedDevice pairedAt(DateTime at) => TrustedDevice(
    id: 'a1b2c3d4e5f60718',
    name: 'Pixel 9',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: at,
  );

  const nothing = ActivityFeed(pinned: [], recent: []);
  const arrived = ActivityFeed(
    pinned: [],
    recent: [
      ActivityItem(
        id: 't1',
        icon: IconData(0),
        title: 'IMG_0412.jpg from Pixel 9',
      ),
    ],
  );

  test('right after the first pairing, nothing has worked yet', () {
    final seen = FirstUse.seen(
      tips: Tips(MemorySettingsStore()),
      devices: [pairedAt(now.subtract(const Duration(minutes: 1)))],
      feed: nothing,
      now: now,
    );

    expect(seen, isFalse);
  });

  test('the first file or clip that went through counts', () {
    final seen = FirstUse.seen(
      tips: Tips(MemorySettingsStore()),
      devices: [pairedAt(now)],
      feed: arrived,
      now: now,
    );

    expect(seen, isTrue);
  });

  test('a tip done or waved off counts', () async {
    final settings = MemorySettingsStore();
    await settings.set(Tips.copyDoneKey, true);

    final seen = FirstUse.seen(
      tips: Tips(settings),
      devices: [pairedAt(now)],
      feed: nothing,
      now: now,
    );

    expect(seen, isTrue);
  });

  test('a pairing a day old counts, as for anyone who updated', () {
    final seen = FirstUse.seen(
      tips: Tips(MemorySettingsStore()),
      devices: [pairedAt(now.subtract(const Duration(days: 2)))],
      feed: nothing,
      now: now,
    );

    expect(seen, isTrue);
  });
}
