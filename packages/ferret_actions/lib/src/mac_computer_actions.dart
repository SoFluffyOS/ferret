import 'dart:io';

import 'package:ferret_actions/src/computer_action.dart';
import 'package:ferret_actions/src/computer_actions.dart';

/// `pmset sleepnow` for sleep, System Events for restart and shut down (so
/// apps get to save, as from the Apple menu; macOS asks for Automation
/// access once), and AppleScript's own `set volume` for sound.
class MacComputerActions implements ComputerActions {
  MacComputerActions({RunProcess? run}) : _run = run ?? Process.run;

  final RunProcess _run;

  /// How far one volume step moves, out of 100: the volume keys' 16 steps.
  static const volumeStep = 6;

  @override
  Set<ComputerAction> get supported => ComputerAction.values.toSet();

  @override
  Future<bool> run(ComputerAction action) async {
    final (executable, arguments) = commandFor(action);

    try {
      final result = await _run(executable, arguments);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  static (String, List<String>) commandFor(ComputerAction action) =>
      switch (action) {
        .sleep => ('pmset', ['sleepnow']),
        .restart => _script(['tell application "System Events" to restart']),
        .shutDown => _script([
          'tell application "System Events" to shut down',
        ]),
        .toggleMute => _script([
          'set volume output muted '
              '(not (output muted of (get volume settings)))',
        ]),
        .volumeUp => _script(_volumeBy(volumeStep)),
        .volumeDown => _script(_volumeBy(-volumeStep)),
      };

  static List<String> _volumeBy(int step) => [
    'set level to (output volume of (get volume settings)) + ($step)',
    'if level > 100 then set level to 100',
    'if level < 0 then set level to 0',
    'set volume output volume level',
  ];

  static (String, List<String>) _script(List<String> lines) => (
    'osascript',
    [
      for (final line in lines) ...['-e', line],
    ],
  );
}
