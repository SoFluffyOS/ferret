import 'dart:async';

import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  final self = Announce(deviceId: 'abc', name: 'iPhone', port: 47640);

  test('starting only remembers; release starts the way held back', () async {
    final inner = _CountingDiscovery();
    final held = HeldDiscovery(inner);

    await held.start(self);
    await held.announceNow();
    await held.scan();
    expect(inner.starts, isEmpty);
    expect(inner.announces, 0);
    expect(inner.scans, 0);
    expect(held.isBlocked, isFalse, reason: 'nothing was asked yet');

    await held.release();
    expect(inner.starts, [self]);
    expect(held.isRunning, isTrue);

    await held.scan();
    expect(inner.scans, 1);
  });

  test('released before the engine started, it starts with it', () async {
    final inner = _CountingDiscovery();
    final held = HeldDiscovery(inner);

    await held.release();
    expect(inner.starts, isEmpty);

    await held.start(self);
    expect(inner.starts, [self]);
  });

  test('released from the start, it is a plain pass-through', () async {
    final inner = _CountingDiscovery()..blocked = true;
    final held = HeldDiscovery(inner, released: true);

    await held.start(self);
    expect(inner.starts, [self]);
    expect(held.isBlocked, isTrue);
  });

  test('stopped while held, a later release starts nothing', () async {
    final inner = _CountingDiscovery();
    final held = HeldDiscovery(inner);

    await held.start(self);
    await held.stop();
    await held.release();

    expect(inner.starts, isEmpty);
    expect(inner.stops, 0);
  });

  test('quiet reaches the way held back, even before release', () async {
    final inner = MulticastDiscovery();
    final held = HeldDiscovery(inner);

    await held.setAnnouncing(false);

    expect(inner.isAnnouncing, isFalse);
    expect(held.isAnnouncing, isFalse);
  });

  test('passes on what the way held back finds', () async {
    final inner = _CountingDiscovery();
    final held = HeldDiscovery(inner, released: true);
    final found = <String>[];
    held.departures.listen(found.add);

    inner.departuresController.add('pixel');
    await Future<void>.delayed(Duration.zero);

    expect(found, ['pixel']);
  });
}

class _CountingDiscovery implements ActiveDiscovery {
  final List<Announce> starts = [];
  int stops = 0;
  int announces = 0;
  int scans = 0;
  bool blocked = false;
  final StreamController<String> departuresController = .broadcast();

  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Stream<String> get departures => departuresController.stream;

  @override
  bool get isBlocked => blocked;

  @override
  Future<void> start(Announce self) async => starts.add(self);

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> announceNow() async => announces++;

  @override
  Future<void> scan() async => scans++;
}
