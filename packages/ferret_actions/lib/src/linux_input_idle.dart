import 'dart:io';

import 'package:ferret_actions/src/computer_actions.dart';
import 'package:ferret_actions/src/input_idle.dart';

/// `xprintidle` on X11, then logind's `IdleHint` for the session, which
/// GNOME and KDE set once their own idle delay passed (Wayland too). With
/// neither, null.
class LinuxInputIdle implements InputIdle {
  LinuxInputIdle({
    RunProcess? run,
    Map<String, String>? environment,
    DateTime Function()? clock,
  }) : _run = run ?? Process.run,
       _environment = environment ?? Platform.environment,
       _clock = clock ?? DateTime.now;

  final RunProcess _run;
  final Map<String, String> _environment;
  final DateTime Function() _clock;

  @override
  Future<Duration?> idleTime() async {
    if (_environment['XDG_SESSION_TYPE'] != 'wayland') {
      if (await _xprintidle() case final idle?) {
        return idle;
      }
    }

    return _logind();
  }

  Future<Duration?> _xprintidle() async {
    final output = await _output('xprintidle', const []);
    if (int.tryParse(output.trim()) case final milliseconds?) {
      return Duration(milliseconds: milliseconds);
    }

    return null;
  }

  Future<Duration?> _logind() async {
    final session = _environment['XDG_SESSION_ID'] ?? 'auto';
    final output = await _output('loginctl', [
      'show-session',
      session,
      '--property=IdleHint',
      '--property=IdleSinceHint',
    ]);

    return parseLoginctl(output, _clock());
  }

  /// Reads `IdleHint=yes` and `IdleSinceHint=<µs since 1970>`. Not idle
  /// reads as no time at all.
  static Duration? parseLoginctl(String output, DateTime now) {
    final values = {
      for (final line in output.split('\n'))
        if (line.split('=') case [final key, final value])
          key.trim(): value.trim(),
    };

    final hint = values['IdleHint'];
    if (hint == 'no') {
      return Duration.zero;
    }

    if (hint != 'yes') {
      return null;
    }

    final since = int.tryParse(values['IdleSinceHint'] ?? '');
    if (since == null || since == 0) {
      return null;
    }

    final idle = now.difference(DateTime.fromMicrosecondsSinceEpoch(since));
    if (idle.isNegative) {
      return Duration.zero;
    }

    return idle;
  }

  Future<String> _output(String executable, List<String> arguments) async {
    try {
      final result = await _run(executable, arguments);
      if (result.exitCode != 0) {
        return '';
      }

      return '${result.stdout}';
    } on ProcessException {
      return '';
    }
  }
}
