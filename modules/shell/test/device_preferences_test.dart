import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

final _now = DateTime(2026, 11, 19, 12);

DeviceStatus _offline(String id, String name, {Duration? away}) => DeviceStatus(
  TrustedDevice(
    id: id,
    name: name,
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: _now.subtract(const Duration(days: 365)),
    lastSeen: switch (away) {
      final away? => _now.subtract(away),
      null => null,
    },
  ),
  null,
);

DeviceStatus _reconnecting(String id, String name) =>
    DeviceStatus(_offline(id, name).device, null, isReconnecting: true);

List<String> _names(List<DeviceStatus> devices) => [
  for (final status in devices) status.device.name,
];

void main() {
  late MemorySettingsStore settings;
  late DevicePreferences preferences;

  setUp(() {
    settings = MemorySettingsStore();
    preferences = DevicePreferences(settings);
  });

  test('offline devices seen last come first, then by name', () {
    final arranged = preferences.arrange([
      _offline('a', 'iPad', away: const Duration(days: 40)),
      _offline('b', 'Desktop', away: const Duration(minutes: 20)),
      _offline('c', 'Never seen'),
      _offline('d', 'iPhone', away: const Duration(hours: 3)),
    ]);

    expect(_names(arranged), ['Desktop', 'iPhone', 'iPad', 'Never seen']);
  });

  test('up devices first, then pinned, then used last', () async {
    await preferences.setPinned('c', pinned: true);
    await preferences.markUsed('b', at: _now);
    await preferences.markUsed('d', at: _now.subtract(const Duration(days: 1)));

    final arranged = preferences.arrange([
      _offline('a', 'Seen just now', away: const Duration(minutes: 1)),
      _offline('b', 'Used today', away: const Duration(days: 2)),
      _offline('c', 'Pinned', away: const Duration(days: 9)),
      _offline('d', 'Used yesterday', away: const Duration(days: 3)),
      _reconnecting('e', 'Reconnecting'),
    ]);

    expect(_names(arranged), [
      'Reconnecting',
      'Pinned',
      'Used today',
      'Used yesterday',
      'Seen just now',
    ]);
  });

  test('unpinning and forgetting clear what was kept', () async {
    await preferences.setPinned('a', pinned: true);
    await preferences.markUsed('a', at: _now);

    await preferences.forget('a');

    expect(preferences.isPinned('a'), isFalse);
    expect(preferences.lastUsed('a'), isNull);
  });

  test('stale means offline for 30 days and not pinned', () async {
    final old = _offline('a', 'Old Pixel', away: const Duration(days: 45));
    final recent = _offline('b', 'iPhone', away: const Duration(days: 2));
    final neverSeen = _offline('c', 'Lost tablet');

    expect(preferences.isStale(old, now: _now), isTrue);
    expect(preferences.isStale(recent, now: _now), isFalse);
    expect(preferences.isStale(neverSeen, now: _now), isTrue);

    await preferences.setPinned('a', pinned: true);
    expect(preferences.isStale(old, now: _now), isFalse);
  });

  test('a used action marks its device as used', () async {
    await DeviceActionUsage(settings).record('a', 'clipboard.send');

    expect(preferences.lastUsed('a'), isNotNull);
  });

  group('a device just used', () {
    late int settled;
    late SettledUse use;

    setUp(() {
      settled = 0;
      use = SettledUse(
        settings,
        onSettled: () => settled++,
        delay: const Duration(milliseconds: 20),
      );
    });

    tearDown(() => use.dispose());

    List<String> arranged() => _names(
      preferences.arrange([
        _offline('a', 'iPad', away: const Duration(hours: 1)),
        _offline('b', 'Pixel', away: const Duration(hours: 2)),
      ], lastUsed: use.lastUsed),
    );

    test('keeps its place until the list has been still a while', () async {
      await preferences.markUsed('b');
      use.used();

      expect(arranged(), ['iPad', 'Pixel']);

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(settled, 1);
      expect(arranged(), ['Pixel', 'iPad']);
    });

    test('moves at once when the list is put away', () async {
      await preferences.markUsed('b');
      use
        ..used()
        ..settle();

      expect(settled, 1);
      expect(arranged(), ['Pixel', 'iPad']);
    });

    test('nothing new used, nothing redrawn', () {
      use.settle();

      expect(settled, 0);
    });
  });
}
