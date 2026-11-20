import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => Log.redactErrors = false);

  LogRecord record(Object error) => LogRecord(
    level: .warning,
    message: 'Failed',
    time: DateTime(2026),
    error: error,
  );

  test('errors are written whole unless redacted', () {
    const error = FormatException('Bad link', 'https://bank.example/secret');

    expect('${record(error)}', contains('bank.example'));
  });

  test('redacted errors keep their kind, never what they failed on', () {
    Log.redactErrors = true;

    final lines = [
      for (final error in <Object>[
        const FormatException('Bad link', 'https://bank.example/secret'),
        const FileSystemException(
          'Cannot open',
          '/Users/me/secret.pdf',
          OSError('No such file', 2),
        ),
        ArgumentError.value('hunter2', 'password'),
        StateError('clip: hunter2'),
        TimeoutException('waited for hunter2'),
      ])
        '${record(error)}',
    ];

    expect(lines, everyElement(isNot(contains('secret'))));
    expect(lines, everyElement(isNot(contains('hunter2'))));
    expect(lines[0], '[warning] Failed: FormatException: Bad link');
    expect(
      lines[1],
      '[warning] Failed: FileSystemException: Cannot open (No such file, 2)',
    );
    expect(lines[2], '[warning] Failed: ArgumentError');
  });
}
