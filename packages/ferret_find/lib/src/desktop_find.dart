import 'dart:async';
import 'dart:io';

import 'package:ferret_find/src/alert_stop.dart';
import 'package:ferret_find/src/audio_state.dart';
import 'package:ferret_find/src/find_platform.dart';
import 'package:ferret_find/src/ring_abilities.dart';
import 'package:ferret_find/src/ring_alert.dart';
import 'package:ferret_find/src/ring_sound.dart';

/// Starts a command, such as a sound player.
typedef StartProcess = Future<Process> Function(
  String executable,
  List<String> arguments,
);

/// Ringing on Windows and Linux, from Dart: plays the bundled tone with the
/// system's own player and leaves the volume alone. The app shows the
/// "Found it" notice.
class DesktopFind implements FindPlatform {
  DesktopFind({
    StartProcess? start,
    Future<String> Function()? soundFile,
    bool? isWindows,
    Map<String, String>? environment,
    bool Function(String path)? fileExists,
  }) : _start = start ?? Process.start,
       _soundFile = soundFile ?? RingSound.file,
       _isWindows = isWindows ?? Platform.isWindows,
       _environment = environment ?? Platform.environment,
       _fileExists = fileExists ?? ((path) => File(path).existsSync());

  /// Linux players to try, best first: PipeWire, PulseAudio, then ALSA.
  static const linuxPlayers = [
    ('pw-play', <String>[]),
    ('paplay', <String>[]),
    ('aplay', ['-q']),
  ];

  /// A player that quits faster than this failed; don't spin on it.
  static const _minimumPlay = Duration(milliseconds: 200);

  final StartProcess _start;
  final Future<String> Function() _soundFile;
  final bool _isWindows;
  final Map<String, String> _environment;
  final bool Function(String path) _fileExists;
  final StreamController<AlertStop> _stops = .broadcast();

  Process? _player;
  Timer? _limit;
  int _generation = 0;

  @override
  Stream<AlertStop> get stops => _stops.stream;

  @override
  Future<RingAbilities> abilities() async => RingAbilities(
    canPlaySound: _isWindows || _linuxPlayer() != null,
  );

  @override
  Future<AudioState?> readAudio() async => null;

  @override
  Future<void> applyAudio(AudioState state) async {}

  @override
  Future<void> startAlert(RingAlert alert) async {
    await stopAlert();
    final generation = _generation;
    _limit = Timer(alert.maxDuration, () {
      unawaited(stopAlert());
      _stops.add(.timeout);
    });

    if (alert.silent) {
      return;
    }

    final path = await _soundFile();
    if (generation != _generation) {
      return;
    }

    if (_isWindows) {
      await _playOnWindows(path, alert.maxDuration, generation);
      return;
    }

    final player = _linuxPlayer();
    if (player == null) {
      throw const FileSystemException('No sound player found');
    }

    unawaited(_loopOnLinux(player, path, generation));
  }

  @override
  Future<void> stopAlert() async {
    _generation++;
    _limit?.cancel();
    _limit = null;
    _player?.kill();
    _player = null;
  }

  @override
  Future<void> openDndAccessSettings() async {}

  @override
  Future<void> openFullScreenSettings() async {}

  /// One PowerShell process loops the tone for the whole ring; killing it
  /// stops the sound.
  Future<void> _playOnWindows(
    String path,
    Duration duration,
    int generation,
  ) async {
    final quoted = path.replaceAll("'", "''");
    final script =
        "\$player = New-Object System.Media.SoundPlayer '$quoted'; "
        '\$player.PlayLooping(); '
        'Start-Sleep -Seconds ${duration.inSeconds + 1}';
    final process = await _start('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      script,
    ]);
    if (generation != _generation) {
      process.kill();
      return;
    }

    _player = process;
  }

  Future<void> _loopOnLinux(
    (String, List<String>) player,
    String path,
    int generation,
  ) async {
    final (executable, arguments) = player;
    while (generation == _generation) {
      final started = DateTime.now();
      final Process process;
      try {
        process = await _start(executable, [...arguments, path]);
      } on Object {
        return;
      }

      if (generation != _generation) {
        process.kill();
        return;
      }

      _player = process;
      final exitCode = await process.exitCode;
      final tooQuick = DateTime.now().difference(started) < _minimumPlay;
      if (exitCode != 0 && tooQuick) {
        return;
      }
    }
  }

  (String, List<String>)? _linuxPlayer() {
    final directories = (_environment['PATH'] ?? '/usr/bin:/bin').split(':');
    for (final player in linuxPlayers) {
      final (executable, _) = player;
      for (final directory in directories) {
        if (directory.isNotEmpty && _fileExists('$directory/$executable')) {
          return player;
        }
      }
    }

    return null;
  }
}
