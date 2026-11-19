import 'dart:io';

import 'package:ferret_actions/src/computer_action.dart';
import 'package:ferret_actions/src/computer_actions.dart';

/// logind over D-Bus for sleep, restart and power off (polkit lets the
/// active session do them without a password), then `systemctl` for
/// systems without `dbus-send`. Sound goes through PipeWire's `wpctl`,
/// then PulseAudio's `pactl`, then ALSA's `amixer`.
class LinuxComputerActions implements ComputerActions {
  LinuxComputerActions({RunProcess? run}) : _run = run ?? Process.run;

  final RunProcess _run;

  static const _volumeStep = '5%';

  @override
  Set<ComputerAction> get supported => ComputerAction.values.toSet();

  @override
  Future<bool> run(ComputerAction action) async {
    for (final (executable, arguments) in waysFor(action)) {
      try {
        final result = await _run(executable, arguments);
        if (result.exitCode == 0) {
          return true;
        }
      } on ProcessException {
        continue;
      }
    }

    return false;
  }

  /// Every way to do [action], the best first.
  static List<(String, List<String>)> waysFor(ComputerAction action) =>
      switch (action) {
        .sleep => [
          _logind('Suspend'),
          ('systemctl', ['suspend']),
        ],
        .restart => [
          _logind('Reboot'),
          ('systemctl', ['reboot']),
        ],
        .shutDown => [
          _logind('PowerOff'),
          ('systemctl', ['poweroff']),
        ],
        .toggleMute => [
          ('wpctl', ['set-mute', '@DEFAULT_AUDIO_SINK@', 'toggle']),
          ('pactl', ['set-sink-mute', '@DEFAULT_SINK@', 'toggle']),
          ('amixer', ['-q', 'set', 'Master', 'toggle']),
        ],
        .volumeUp => [
          (
            'wpctl',
            [
              'set-volume',
              '-l',
              '1.0',
              '@DEFAULT_AUDIO_SINK@',
              '$_volumeStep+',
            ],
          ),
          ('pactl', ['set-sink-volume', '@DEFAULT_SINK@', '+$_volumeStep']),
          ('amixer', ['-q', 'set', 'Master', '$_volumeStep+']),
        ],
        .volumeDown => [
          ('wpctl', ['set-volume', '@DEFAULT_AUDIO_SINK@', '$_volumeStep-']),
          ('pactl', ['set-sink-volume', '@DEFAULT_SINK@', '-$_volumeStep']),
          ('amixer', ['-q', 'set', 'Master', '$_volumeStep-']),
        ],
      };

  /// `interactive` true: polkit may ask for a password where the session
  /// isn't allowed, instead of failing without a word.
  static (String, List<String>) _logind(String method) => (
    'dbus-send',
    [
      '--system',
      '--print-reply',
      '--dest=org.freedesktop.login1',
      '/org/freedesktop/login1',
      'org.freedesktop.login1.Manager.$method',
      'boolean:true',
    ],
  );
}
