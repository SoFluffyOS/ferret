import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:path/path.dart' as p;
import 'package:scripting/models/models.dart';

/// How one hook run ended.
enum HookOutcome {
  /// It exited; [HookRun.exitCode] says how.
  exited,

  /// It ran past the timeout and was stopped.
  timedOut,

  /// It couldn't start.
  failed,

  /// Too many runs of the same hook were waiting, so this one was skipped.
  dropped,
}

/// One run of a hook script.
typedef HookRun = ({String hook, HookOutcome outcome, int? exitCode});

/// Starts a hook process. Swapped in tests.
typedef HookStarter = Future<Process> Function(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required Map<String, String> environment,
});

/// Runs your own scripts when something happens: the executable
/// `<directory>/<event type>`, such as `~/.sofluffy/ferret/hooks/
/// device.connected`, with the event's JSON on stdin and its basics in
/// `FERRET_*` environment variables.
///
/// Nothing runs unless that file exists and is executable, and not
/// writable by other users. A hook gets no content (no copied text, no
/// notification text), and no private names when previews from the
/// device are off. Each run is stopped after [timeout]; runs of one hook
/// wait for each other, and past [maxWaiting] the newest is skipped.
class HookRunner {
  HookRunner(
    this.directory, {
    this.timeout = const Duration(seconds: 10),
    this.maxWaiting = 4,
    HookStarter? start,
  }) : _start = start ?? _startProcess;

  final String directory;
  final Duration timeout;
  final int maxWaiting;
  final HookStarter _start;
  final Map<String, Future<void>> _queues = {};
  final Map<String, int> _waiting = {};
  StreamSubscription<ScriptEvent>? _subscription;

  static const String folderName = 'hooks';

  static const _windowsExtensions = ['.exe', '.cmd', '.bat'];

  /// Runs hooks for every event of [events] from now on.
  void attach(Stream<ScriptEvent> events) {
    _subscription ??= events.listen((event) => unawaited(run(event)));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// The hooks in [directory] that would run, by event type.
  Future<List<String>> installed() async {
    final found = <String>[];
    for (final type in ScriptEventType.all) {
      if (await _hookFor(type) != null) {
        found.add(type);
      }
    }

    return found;
  }

  /// Runs the hook for [event], if there is one. Null when there is none.
  Future<HookRun?> run(ScriptEvent event) async {
    final hook = await _hookFor(event.type);
    if (hook == null) {
      return null;
    }

    final waiting = _waiting[hook] ?? 0;
    if (waiting >= maxWaiting) {
      printWarning('Hook ${event.type} is busy; skipped one event');
      return (hook: event.type, outcome: HookOutcome.dropped, exitCode: null);
    }

    _waiting[hook] = waiting + 1;
    final previous = _queues[hook] ?? Future<void>.value();
    final done = Completer<HookRun>();
    final next = previous.then((_) async {
      done.complete(await _runNow(hook, event));
    });
    _queues[hook] = next;
    final result = await done.future;
    _waiting[hook] = (_waiting[hook] ?? 1) - 1;
    return result;
  }

  Future<HookRun> _runNow(String hook, ScriptEvent event) async {
    final Process process;
    try {
      process = await _start(
        hook,
        const [],
        workingDirectory: directory,
        environment: _environmentOf(event),
      );
    } on Object catch (error) {
      printWarning('Hook ${event.type} could not start', error);
      return (hook: event.type, outcome: HookOutcome.failed, exitCode: null);
    }

    unawaited(process.stdout.drain<void>());
    unawaited(process.stderr.drain<void>());
    try {
      process.stdin.writeln(jsonEncode(event.toJson()));
      await process.stdin.close();
    } on Object {
      printDebug('Hook ${event.type} did not read its input');
    }

    try {
      final exitCode = await process.exitCode.timeout(timeout);
      return (
        hook: event.type,
        outcome: HookOutcome.exited,
        exitCode: exitCode,
      );
    } on TimeoutException {
      process.kill();
      await _killLater(process);
      printWarning('Hook ${event.type} ran over ${timeout.inSeconds} s');
      return (hook: event.type, outcome: HookOutcome.timedOut, exitCode: null);
    }
  }

  static Future<void> _killLater(Process process) async {
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
    }
  }

  Map<String, String> _environmentOf(ScriptEvent event) => {
    'FERRET_EVENT': event.type,
    'FERRET_EVENT_VERSION': '${ScriptEvent.schemaVersion}',
    'FERRET_DEVICE_ID': ?event.deviceId,
    'FERRET_DEVICE_NAME': ?event.deviceName,
  };

  /// The runnable file for [type], or null.
  Future<String?> _hookFor(String type) async {
    if (!ScriptEventType.all.contains(type)) {
      return null;
    }

    if (Platform.isWindows) {
      for (final extension in _windowsExtensions) {
        final path = p.join(directory, '$type$extension');
        if (await File(path).exists()) {
          return path;
        }
      }

      return null;
    }

    final path = p.join(directory, type);
    final stat = await FileStat.stat(path);
    if (stat.type != FileSystemEntityType.file) {
      return null;
    }

    final isExecutable = stat.mode & 0x49 != 0;
    final othersMayWrite = stat.mode & 0x12 != 0;
    if (othersMayWrite) {
      printWarning('Hook $type is writable by other users; not running it');
      return null;
    }

    if (!isExecutable) {
      return null;
    }

    return path;
  }

  static Future<Process> _startProcess(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required Map<String, String> environment,
  }) => Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    runInShell: Platform.isWindows,
  );
}
