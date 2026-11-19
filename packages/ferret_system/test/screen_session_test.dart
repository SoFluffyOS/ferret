import 'dart:async';

import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts from how things are and reports only flips', () async {
    final source = _FakeSource(active: false);
    final session = ScreenSession(source);
    final seen = <bool>[];
    session.changes.listen(seen.add);

    await session.start();
    source.emit(false);
    source.emit(true);
    source.emit(true);
    await pumpEventQueue();

    expect(seen, [false, true]);
    expect(session.isActive, isTrue);
    await session.stop();
    expect(source.started, isFalse);
  });

  test('a polled probe reports each answer', () async {
    var active = true;
    final source = PollingSessionSource(
      probe: () => active,
      interval: const Duration(milliseconds: 10),
    );
    final seen = <bool>[];
    source.changes.listen(seen.add);

    await source.start();
    active = false;
    await Future<void>.delayed(const Duration(milliseconds: 25));
    await source.stop();
    final count = seen.length;
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(seen, isNotEmpty);
    expect(seen.every((value) => !value), isTrue);
    expect(seen, hasLength(count));
  });

  test('a locked or switched-away Linux session is not active', () {
    expect(LogindSessionSource.activeFrom(active: true, locked: false), isTrue);
    expect(LogindSessionSource.activeFrom(active: true, locked: true), isFalse);
    expect(
      LogindSessionSource.activeFrom(active: false, locked: false),
      isFalse,
    );
  });
}

class _FakeSource implements ScreenSessionSource {
  _FakeSource({required bool active}) : _active = active;

  final bool _active;
  final StreamController<bool> _changes = .broadcast();
  bool started = false;

  void emit(bool active) => _changes.add(active);

  @override
  Future<bool> isActive() async => _active;

  @override
  Stream<bool> get changes => _changes.stream;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> stop() async => started = false;
}
