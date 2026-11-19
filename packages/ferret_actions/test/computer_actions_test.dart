import 'dart:io';

import 'package:ferret_actions/ferret_actions.dart';
import 'package:test/test.dart';

void main() {
  group('MacComputerActions', () {
    test('sleep is pmset, restart and shut down go through System Events', () {
      final (sleep, sleepArguments) = MacComputerActions.commandFor(.sleep);
      final (restart, restartArguments) = MacComputerActions.commandFor(
        .restart,
      );
      final (_, shutDownArguments) = MacComputerActions.commandFor(.shutDown);

      expect(sleep, 'pmset');
      expect(sleepArguments, ['sleepnow']);
      expect(restart, 'osascript');
      expect(restartArguments, [
        '-e',
        'tell application "System Events" to restart',
      ]);
      expect(shutDownArguments, [
        '-e',
        'tell application "System Events" to shut down',
      ]);
    });

    test('reports whether the command worked', () async {
      final ran = <String>[];
      var exitCode = 0;
      final actions = MacComputerActions(
        run: (executable, arguments) async {
          ran.add(executable);
          return ProcessResult(1, exitCode, '', '');
        },
      );

      expect(await actions.run(.toggleMute), isTrue);
      exitCode = 1;
      expect(await actions.run(.volumeUp), isFalse);
      expect(ran, ['osascript', 'osascript']);
    });
  });

  group('LinuxComputerActions', () {
    test('asks logind first, then systemctl', () async {
      final ran = <String>[];
      final actions = LinuxComputerActions(
        run: (executable, arguments) async {
          ran.add(executable);
          if (executable == 'dbus-send') {
            throw const ProcessException('dbus-send', []);
          }

          return ProcessResult(1, 0, '', '');
        },
      );

      expect(await actions.run(.sleep), isTrue);
      expect(ran, ['dbus-send', 'systemctl']);
    });

    test('tries each sound tool until one works', () async {
      final ran = <String>[];
      final actions = LinuxComputerActions(
        run: (executable, arguments) async {
          ran.add(executable);
          return ProcessResult(1, 1, '', '');
        },
      );

      expect(await actions.run(.toggleMute), isFalse);
      expect(ran, ['wpctl', 'pactl', 'amixer']);
    });

    test('power off calls logind PowerOff', () {
      final (executable, arguments) = LinuxComputerActions.waysFor(
        .shutDown,
      ).first;

      expect(executable, 'dbus-send');
      expect(arguments, contains('org.freedesktop.login1.Manager.PowerOff'));
    });
  });

  test('phones have no actions', () async {
    const actions = UnsupportedComputerActions();

    expect(actions.supported, isEmpty);
    expect(await actions.run(.sleep), isFalse);
  });
}
