import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alert = RingAlert(
    title: 'Ringing',
    body: 'Phone is looking for this laptop',
    foundItLabel: 'Found it',
    maxDuration: Duration(seconds: 30),
  );

  test('Linux picks the first installed player and loops it', () async {
    final launcher = _Launcher();
    final find = DesktopFind(
      start: launcher.start,
      soundFile: () async => '/tmp/ring.wav',
      isWindows: false,
      environment: {'PATH': '/usr/local/bin:/usr/bin'},
      fileExists: (path) =>
          path == '/usr/bin/aplay' || path == '/usr/bin/paplay',
    );

    expect((await find.abilities()).canPlaySound, isTrue);
    await find.startAlert(alert);
    await _settle();
    launcher.processes.single.finish(0);
    await _settle();

    expect(launcher.calls, [
      ['paplay', '/tmp/ring.wav'],
      ['paplay', '/tmp/ring.wav'],
    ]);

    await find.stopAlert();
    await _settle();

    expect(launcher.processes.last.killed, isTrue);
    expect(launcher.calls, hasLength(2));
  });

  test('Linux without a player says so and refuses to ring', () async {
    final find = DesktopFind(
      start: _Launcher().start,
      soundFile: () async => '/tmp/ring.wav',
      isWindows: false,
      environment: {'PATH': '/usr/bin'},
      fileExists: (_) => false,
    );

    expect((await find.abilities()).canPlaySound, isFalse);
    await expectLater(
      find.startAlert(alert),
      throwsA(isA<FileSystemException>()),
    );
    await find.stopAlert();
  });

  test('a player that fails at once is not restarted in a loop', () async {
    final launcher = _Launcher();
    final find = DesktopFind(
      start: launcher.start,
      soundFile: () async => '/tmp/ring.wav',
      isWindows: false,
      environment: {'PATH': '/usr/bin'},
      fileExists: (path) => path == '/usr/bin/pw-play',
    );

    await find.startAlert(alert);
    await _settle();
    launcher.processes.single.finish(1);
    await _settle();

    expect(launcher.calls, hasLength(1));
    await find.stopAlert();
  });

  test('Windows loops the tone in one PowerShell, quoted safely', () async {
    final launcher = _Launcher();
    final find = DesktopFind(
      start: launcher.start,
      soundFile: () async => r"C:\Users\o'neil\ring.wav",
      isWindows: true,
    );

    await find.startAlert(alert);
    await find.stopAlert();

    final call = launcher.calls.single;
    expect(call.first, 'powershell');
    expect(call.last, contains(r"'C:\Users\o''neil\ring.wav'"));
    expect(call.last, contains('PlayLooping'));
    expect(launcher.processes.single.killed, isTrue);
  });

  test('a silent alert plays nothing and still times out', () {
    fakeAsync((async) {
      final launcher = _Launcher();
      final find = DesktopFind(
        start: launcher.start,
        soundFile: () async => '/tmp/ring.wav',
        isWindows: true,
      );
      final stops = <AlertStop>[];
      find.stops.listen(stops.add);

      unawaited(
        find.startAlert(
          const RingAlert(
            title: 'Ringing',
            body: '',
            foundItLabel: 'Found it',
            maxDuration: Duration(seconds: 5),
            silent: true,
          ),
        ),
      );
      async.elapse(const Duration(seconds: 6));

      expect(launcher.calls, isEmpty);
      expect(stops, [AlertStop.timeout]);
    });
  });
}

Future<void> _settle() async {
  for (var turn = 0; turn < 5; turn++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Launcher {
  final List<List<String>> calls = [];
  final List<_FakeProcess> processes = [];

  Future<Process> start(String executable, List<String> arguments) async {
    calls.add([executable, ...arguments]);
    final process = _FakeProcess();
    processes.add(process);
    return process;
  }
}

class _FakeProcess implements Process {
  final Completer<int> _exit = Completer();
  bool killed = false;

  void finish(int code) {
    if (!_exit.isCompleted) {
      _exit.complete(code);
    }
  }

  @override
  Future<int> get exitCode => _exit.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    finish(-15);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
