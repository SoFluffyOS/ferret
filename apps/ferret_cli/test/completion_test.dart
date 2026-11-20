import 'dart:io';

import 'package:core/core.dart';
import 'package:ferret_cli/ferret_cli.dart';
import 'package:test/test.dart';

void main() {
  late Directory home;
  late StringBuffer out;

  setUp(() async {
    home = await Directory.systemTemp.createTemp('ferret_cli_completion');
    out = StringBuffer();
  });

  tearDown(() => home.delete(recursive: true));

  Future<String> script(String shell) async {
    final environment = CliEnvironment(
      FerretPaths(home.path).nested('cli'),
      appRoot: home.path,
      out: out,
      err: StringBuffer(),
    );
    final exit = await buildRunner(environment).run(['completion', shell]);
    expect(exit, ExitCodes.ok);
    return '$out';
  }

  test('every shell gets every command', () async {
    for (final shell in ['bash', 'zsh', 'fish']) {
      out.clear();
      final text = await script(shell);

      for (final command in ['ring', 'send', 'watch', 'clipboard', 'devices']) {
        expect(text, contains(command), reason: '$shell: $command');
      }
      expect(text, contains('devices --names'), reason: shell);
    }
  });

  test('an unknown shell is a usage error', () async {
    final environment = CliEnvironment(
      FerretPaths(home.path).nested('cli'),
      appRoot: home.path,
      out: out,
      err: StringBuffer(),
    );

    expect(
      buildRunner(environment).run(['completion', 'tcsh']),
      throwsA(isA<Exception>()),
    );
  });

  test('summaries are the first sentence', () {
    expect(CompletionSpec.summaryOf('Ask a phone. It waits.'), 'Ask a phone');
    expect(CompletionSpec.summaryOf('List devices.'), 'List devices');
  });

  test(
    'bash completes commands, devices, subcommands and event types',
    () async {
      final completion = File('${home.path}/ferret-cli.bash')
        ..writeAsStringSync(await script('bash'));
      final stubs = Directory('${home.path}/bin')..createSync();
      final stub = File('${stubs.path}/ferret-cli')
        ..writeAsStringSync("#!/bin/sh\nprintf 'Pixel 7\\nFamily PC\\n'\n");
      await Process.run('chmod', ['+x', stub.path]);

      Future<String> complete(String words) async {
        final result = await Process.run(
          'bash',
          [
            '-c',
            'source "${completion.path}"; COMP_WORDS=($words); '
                r'COMP_CWORD=$((${#COMP_WORDS[@]}-1)); _ferret_cli; '
                r'echo "${COMPREPLY[*]}"',
          ],
          environment: {
            'PATH': '${stubs.path}:${Platform.environment['PATH']}',
          },
        );
        expect(result.exitCode, 0, reason: '${result.stderr}');
        return '${result.stdout}'.trim();
      }

      expect(await complete('ferret-cli ri'), 'ring');
      expect(await complete('ferret-cli ring Pix'), r'Pixel\ 7');
      expect(await complete('ferret-cli clipboard s'), 'send');
      expect(await complete('ferret-cli send x --to F'), r'Family\ PC');
      expect(
        await complete('ferret-cli watch --type call.'),
        'call.ended call.ringing',
      );
    },
    skip: switch (Platform.isWindows) {
      true => 'No bash on Windows',
      false => false,
    },
  );

  test(
    'the bash and zsh scripts parse',
    () async {
      for (final shell in ['bash', 'zsh']) {
        out.clear();
        final file = File('${home.path}/completion.$shell')
          ..writeAsStringSync(await script(shell));
        final installed = await Process.run('which', [shell]);
        if (installed.exitCode != 0) {
          continue;
        }

        final result = await Process.run(shell, ['-n', file.path]);
        expect(result.exitCode, 0, reason: '$shell: ${result.stderr}');
      }
    },
    skip: switch (Platform.isWindows) {
      true => 'No bash or zsh on Windows',
      false => false,
    },
  );
}
