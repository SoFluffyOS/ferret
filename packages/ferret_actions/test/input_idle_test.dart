import 'dart:io';

import 'package:ferret_actions/ferret_actions.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxInputIdle', () {
    final now = DateTime.utc(2026, 11, 19, 10);

    test('xprintidle answers first on X11', () async {
      final ran = <String>[];
      final idle = LinuxInputIdle(
        environment: const {'XDG_SESSION_TYPE': 'x11'},
        run: (executable, arguments) async {
          ran.add(executable);
          return ProcessResult(1, 0, '93500\n', '');
        },
      );

      expect(await idle.idleTime(), const Duration(milliseconds: 93500));
      expect(ran, ['xprintidle']);
    });

    test('Wayland skips xprintidle and asks logind', () async {
      final since = now.subtract(const Duration(minutes: 3));
      final ran = <List<String>>[];
      final idle = LinuxInputIdle(
        environment: const {
          'XDG_SESSION_TYPE': 'wayland',
          'XDG_SESSION_ID': '4',
        },
        clock: () => now,
        run: (executable, arguments) async {
          ran.add([executable, ...arguments]);
          return ProcessResult(
            1,
            0,
            'IdleHint=yes\nIdleSinceHint=${since.microsecondsSinceEpoch}\n',
            '',
          );
        },
      );

      expect(await idle.idleTime(), const Duration(minutes: 3));
      expect(ran.single.take(3), ['loginctl', 'show-session', '4']);
    });

    test('logind saying not idle reads as active', () {
      expect(
        LinuxInputIdle.parseLoginctl('IdleHint=no\nIdleSinceHint=0\n', now),
        Duration.zero,
      );
    });

    test('nothing that answers reads as unknown', () async {
      final idle = LinuxInputIdle(
        environment: const {},
        run: (executable, arguments) async =>
            throw ProcessException(executable, arguments),
      );

      expect(await idle.idleTime(), isNull);
      expect(LinuxInputIdle.parseLoginctl('', now), isNull);
    });
  });

  test('the Mac reports how long it sat untouched', () async {
    final idle = await const MacInputIdle().idleTime();

    expect(idle, isNotNull);
    expect(idle?.isNegative, isFalse);
  }, testOn: 'mac-os');
}
