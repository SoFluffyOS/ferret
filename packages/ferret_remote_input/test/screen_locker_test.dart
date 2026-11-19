import 'dart:io';

import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Linux', () {
    test('locks the session through logind', () async {
      final ran = <String>[];
      final locker = LinuxScreenLocker(
        run: (executable, arguments) async {
          ran.add('$executable ${arguments.join(' ')}');
          return ProcessResult(0, 0, '', '');
        },
      );

      expect(await locker.lock(), isTrue);
      expect(ran, ['loginctl lock-session']);
    });

    test('falls back to the screensaver when logind fails', () async {
      final ran = <String>[];
      final locker = LinuxScreenLocker(
        run: (executable, arguments) async {
          ran.add(executable);
          if (executable == 'loginctl') {
            return ProcessResult(0, 1, '', 'no session');
          }

          if (executable == 'xdg-screensaver') {
            throw const ProcessException('xdg-screensaver', []);
          }

          return ProcessResult(0, 0, '', '');
        },
      );

      expect(await locker.lock(), isTrue);
      expect(ran, ['loginctl', 'xdg-screensaver', 'dbus-send']);
    });

    test('says so when nothing could lock', () async {
      final locker = LinuxScreenLocker(
        run: (_, _) async => ProcessResult(0, 1, '', ''),
      );

      expect(await locker.lock(), isFalse);
    });
  });

  test('phones have nothing to lock', () async {
    const locker = UnsupportedScreenLocker();

    expect(locker.isSupported, isFalse);
    expect(await locker.lock(), isFalse);
  });
}
