import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';
import 'package:transport/transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SpyEngine engine;
  late _FakeSystem system;
  late PauseController pause;
  late SystemBinding binding;

  void startBinding(FakeAsync async) {
    engine = _SpyEngine();
    system = _FakeSystem();
    pause = PauseController(engine);
    binding = SystemBinding(
      engine: engine,
      host: EngineHost(engine),
      pause: pause,
      system: system,
    );
    unawaited(binding.start());
    async.flushMicrotasks();
  }

  void change(FakeAsync async, NetworkChange change) {
    system.changes.add(change);
    async.flushMicrotasks();
  }

  void stopBinding(FakeAsync async) {
    unawaited(binding.dispose());
    async.flushMicrotasks();
  }

  test('a network change reconnects at 0.5, 3 and 8 seconds', () {
    fakeAsync((async) {
      startBinding(async);

      change(async, .available);
      async.elapse(const Duration(milliseconds: 499));
      expect(engine.reconnects, 0);

      async.elapse(const Duration(milliseconds: 1));
      expect(engine.reconnects, 1);

      async.elapse(const Duration(milliseconds: 2499));
      expect(engine.reconnects, 1);

      async.elapse(const Duration(milliseconds: 1));
      expect(engine.reconnects, 2);

      async.elapse(const Duration(seconds: 5));
      expect(engine.reconnects, 3);

      async.elapse(const Duration(minutes: 1));
      expect(engine.reconnects, 3);

      stopBinding(async);
    });
  });

  test('a burst of changes starts the schedule again', () {
    fakeAsync((async) {
      startBinding(async);

      change(async, .available);
      async.elapse(const Duration(milliseconds: 300));
      change(async, .changed);
      async.elapse(const Duration(milliseconds: 300));
      change(async, .wake);

      async.elapse(const Duration(milliseconds: 499));
      expect(engine.reconnects, 0);

      async.elapse(const Duration(milliseconds: 1));
      expect(engine.reconnects, 1);

      async.elapse(const Duration(seconds: 2));
      change(async, .changed);
      async.elapse(const Duration(milliseconds: 499));
      expect(engine.reconnects, 1);

      async.elapse(const Duration(minutes: 1));
      expect(engine.reconnects, 4);

      stopBinding(async);
    });
  });

  test('losing the network does nothing', () {
    fakeAsync((async) {
      startBinding(async);

      change(async, .lost);
      async.elapse(const Duration(minutes: 1));

      expect(engine.reconnects, 0);
      stopBinding(async);
    });
  });

  test('a lost network does not cancel a schedule already running', () {
    fakeAsync((async) {
      startBinding(async);

      change(async, .available);
      change(async, .lost);
      async.elapse(const Duration(minutes: 1));

      expect(engine.reconnects, 3);
      stopBinding(async);
    });
  });

  test('a paused Ferret skips the reconnects', () {
    fakeAsync((async) {
      startBinding(async);
      unawaited(pause.pause());
      async.flushMicrotasks();
      expect(engine.isRunning, isTrue);

      change(async, .available);
      async.elapse(const Duration(minutes: 1));

      expect(engine.reconnects, 0);
      stopBinding(async);
    });
  });

  test('a stopped engine skips the reconnects', () {
    fakeAsync((async) {
      startBinding(async);
      engine.running = false;

      change(async, .available);
      async.elapse(const Duration(seconds: 1));
      expect(engine.reconnects, 0);

      engine.running = true;
      async.elapse(const Duration(minutes: 1));
      expect(engine.reconnects, 2);

      stopBinding(async);
    });
  });

  test('dispose cancels the waiting reconnects', () {
    fakeAsync((async) {
      startBinding(async);

      change(async, .available);
      async.elapse(const Duration(seconds: 1));
      stopBinding(async);
      async.elapse(const Duration(minutes: 1));

      expect(engine.reconnects, 1);
    });
  });
}

class _SpyEngine extends Fake implements FerretEngine {
  @override
  final SettingsStore settings = MemorySettingsStore();

  bool running = true;
  int reconnects = 0;

  @override
  bool get isRunning => running;

  @override
  Future<void> reconnectNow({Duration probeTimeout = Duration.zero}) async {
    reconnects++;
  }

  /// Stays "running" so the pause alone is what skips the reconnects.
  @override
  Future<void> stop() async {}

  @override
  Stream<List<DeviceStatus>> get deviceChanges => const Stream.empty();

  @override
  Stream<List<DiscoveredPeer>> get nearbyChanges => const Stream.empty();

  @override
  Stream<PairingPrompt> get pairingPrompts => const Stream.empty();
}

class _FakeSystem extends Fake implements FerretSystem {
  final StreamController<NetworkChange> changes = .broadcast();

  @override
  bool get isAndroid => false;

  @override
  Stream<NetworkChange> get networkChanges => changes.stream;

  @override
  Stream<PauseState> get pauseChanges => const Stream.empty();

  @override
  Future<void> setPause(PauseState pause) async {}

  @override
  Future<void> releaseMulticastLock() async {}

  @override
  Future<void> acquireMulticastLock() async {}
}
