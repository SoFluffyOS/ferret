@TestOn('mac-os || linux')
library;

import 'package:ferret_actions/ferret_actions.dart';
import 'package:test/test.dart';

void main() {
  group('CommandRunner', () {
    test('captures what the command prints and its exit code', () async {
      final outcome = await CommandRunner().run(['/bin/echo', 'all done']);

      expect(outcome.exitCode, 0);
      expect(outcome.succeeded, isTrue);
      expect(outcome.lastLine, 'all done');
      expect(outcome.timedOut, isFalse);
    });

    test('a failing command reports its exit code and errors', () async {
      final outcome = await CommandRunner().run([
        '/bin/sh',
        '-c',
        'echo oops >&2; exit 3',
      ]);

      expect(outcome.exitCode, 3);
      expect(outcome.succeeded, isFalse);
      expect(outcome.lastLine, 'oops');
    });

    test('a command that runs too long is stopped', () async {
      final watch = Stopwatch()..start();

      final outcome = await CommandRunner().run([
        '/bin/sleep',
        '30',
      ], timeout: const Duration(milliseconds: 200));

      expect(outcome.timedOut, isTrue);
      expect(outcome.exitCode, isNull);
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('a missing program never starts', () async {
      final outcome = await CommandRunner().run(['/nonexistent/ferret-tool']);

      expect(outcome.started, isFalse);
      expect(outcome.exitCode, isNull);
    });

    test('keeps only the first part of a long output', () async {
      final outcome = await CommandRunner(outputLimit: 10).run([
        '/bin/sh',
        '-c',
        'printf "%s" 0123456789abcdefghij',
      ]);

      expect(outcome.output, '0123456789');
    });

    test('an empty command never starts', () async {
      final outcome = await CommandRunner().run(const []);

      expect(outcome.started, isFalse);
    });
  });
}
