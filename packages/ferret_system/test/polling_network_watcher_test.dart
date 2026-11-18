import 'dart:async';

import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late List<String> addresses;
  late PollingNetworkWatcher watcher;
  late List<NetworkChange> changes;
  late StreamSubscription<NetworkChange> subscription;

  setUp(() {
    now = DateTime(2026, 11, 18, 9);
    addresses = ['en0 192.168.1.20'];
    watcher = PollingNetworkWatcher(
      addresses: () async => addresses,
      clock: () => now,
    );
    changes = [];
    subscription = watcher.changes.listen(changes.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await watcher.dispose();
  });

  Future<void> checkAfter(Duration elapsed) async {
    now = now.add(elapsed);
    await watcher.check();
    await pumpEventQueue();
  }

  test('the first look reports nothing', () async {
    await checkAfter(Duration.zero);

    expect(changes, isEmpty);
  });

  test('a new address is a change', () async {
    await checkAfter(Duration.zero);
    addresses = ['en0 10.0.0.4'];
    await checkAfter(const Duration(seconds: 10));

    expect(changes, [NetworkChange.changed]);
  });

  test('losing and finding a network', () async {
    await checkAfter(Duration.zero);
    addresses = [];
    await checkAfter(const Duration(seconds: 10));
    addresses = ['en0 10.0.0.4'];
    await checkAfter(const Duration(seconds: 10));

    expect(changes, [NetworkChange.lost, NetworkChange.available]);
  });

  test('a gap in the clock is a wake from sleep', () async {
    await checkAfter(Duration.zero);
    await checkAfter(const Duration(minutes: 40));

    expect(changes, [NetworkChange.wake]);
  });

  test('a steady network on time reports nothing', () async {
    await checkAfter(Duration.zero);
    await checkAfter(const Duration(seconds: 10));
    await checkAfter(const Duration(seconds: 11));

    expect(changes, isEmpty);
  });
}
