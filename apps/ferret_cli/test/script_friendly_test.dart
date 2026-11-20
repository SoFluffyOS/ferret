import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:ferret_cli/ferret_cli.dart';
import 'package:test/test.dart';

void main() {
  late Directory home;
  late StringBuffer out;
  late StringBuffer err;

  setUp(() async {
    home = await Directory.systemTemp.createTemp('ferret_cli_friendly');
    out = StringBuffer();
    err = StringBuffer();
  });

  tearDown(() => home.delete(recursive: true));

  CliEnvironment environment({String? input}) => CliEnvironment(
    FerretPaths(home.path).nested('cli'),
    appRoot: home.path,
    out: out,
    err: err,
    input: switch (input) {
      final text? => Stream.value(utf8.encode(text)),
      null => const Stream.empty(),
    },
  );

  /// A running app that answers commands with [answer] and lists [devices]
  /// at the start of a watch.
  Future<List<Map<String, Object?>>> runApp({
    Map<String, Object?> answer = const {'ok': true},
    List<Map<String, Object?>> devices = const [],
  }) async {
    final asked = <Map<String, Object?>>[];
    final running = AppControl(home.path);
    await running.listen(
      (command, arguments) async {
        asked.add({'command': command, ...arguments});
        return answer;
      },
      watch: (_) => Stream.value({'v': 1, 'type': 'ready', 'devices': devices}),
    );
    addTearDown(running.dispose);
    return asked;
  }

  group('devices', () {
    const phone = {
      'id': 'aaaa',
      'name': 'Pixel 7',
      'connected': true,
      'battery': 64,
    };
    const computer = {'id': 'bbbb', 'name': 'Family PC', 'connected': false};

    test('lists the app\'s devices and whether they are connected', () async {
      await runApp(devices: [phone, computer]);

      final exit = await buildRunner(environment()).run(['devices']);

      expect(exit, ExitCodes.ok);
      expect(out.toString(), contains('Paired with the Ferret app:'));
      expect(out.toString(), contains('Pixel 7  connected · battery 64%'));
      expect(out.toString(), contains('Family PC  not connected'));
    });

    test('--json keeps its fields and adds the app\'s devices', () async {
      await runApp(devices: [phone]);

      await buildRunner(environment()).run(['devices', '--json']);

      final json = jsonDecode(out.toString()) as Map<String, Object?>;
      expect(json['this_device'], isA<String>());
      expect(json['devices'], isEmpty);
      expect(json['app'], {
        'running': true,
        'devices': [
          {
            'name': 'Pixel 7',
            'id': 'aaaa',
            'connected': true,
            'reconnecting': false,
            'battery': 64,
          },
        ],
      });
    });

    test('--json says when the app is not running', () async {
      await buildRunner(environment()).run(['devices', '--json']);

      final json = jsonDecode(out.toString()) as Map<String, Object?>;
      expect(json['app'], {'running': false});
    });

    test('--names prints one name per line', () async {
      await runApp(devices: [phone, computer]);

      await buildRunner(environment()).run(['devices', '--names']);

      expect(out.toString(), 'Pixel 7\nFamily PC\n');
    });

    test('says how to pair when nothing is paired anywhere', () async {
      await buildRunner(environment()).run(['devices']);

      expect(out.toString(), contains('Open the Ferret app'));
    });
  });

  group('send', () {
    test('--to sends straight to that device', () async {
      final asked = await runApp(
        answer: {'ok': true, 'device': 'Pixel 7', 'result': 'sending'},
      );
      final file = File('${home.path}/report.pdf')..writeAsStringSync('x');

      final exit = await buildRunner(
        environment(),
      ).run(['send', file.path, '--to', 'pix']);

      expect(exit, ExitCodes.ok);
      expect(asked.single, {
        'command': 'send_files',
        'device': 'pix',
        'paths': [file.path],
      });
      expect(out.toString(), contains('Sending it to Pixel 7.'));
    });

    test('- reads the paths from standard input', () async {
      final asked = await runApp(
        answer: {'ok': true, 'device': 'Pixel 7', 'result': 'sending'},
      );
      final first = File('${home.path}/a.txt')..writeAsStringSync('a');
      final second = File('${home.path}/b.txt')..writeAsStringSync('b');

      final exit = await buildRunner(
        environment(input: '${first.path}\n\n${second.path}\n'),
      ).run(['send', '-', '--to', 'Pixel 7']);

      expect(exit, ExitCodes.ok);
      expect(asked.single['paths'], [first.path, second.path]);
    });

    test('--json says when the app is not running', () async {
      final file = File('${home.path}/a.txt')..writeAsStringSync('a');

      final exit = await buildRunner(
        environment(),
      ).run(['send', file.path, '--json']);

      expect(exit, ExitCodes.unavailable);
      expect(jsonDecode(out.toString()), {
        'ok': false,
        'error': 'app_not_running',
      });
    });

    test('--json names the missing file', () async {
      final exit = await buildRunner(
        environment(),
      ).run(['send', 'nope.txt', '--json']);

      expect(exit, ExitCodes.noInput);
      expect(jsonDecode(out.toString()), {
        'ok': false,
        'error': 'no_such_file',
        'path': 'nope.txt',
      });
    });

    test('--to an unknown name exits 67', () async {
      await runApp(answer: {'ok': false, 'error': 'unknown_device'});
      final file = File('${home.path}/a.txt')..writeAsStringSync('a');

      final exit = await buildRunner(
        environment(),
      ).run(['send', file.path, '--to', 'Toaster']);

      expect(exit, ExitCodes.noDevice);
      expect(err.toString(), contains('ferret-cli devices'));
    });
  });

  group('clipboard send', () {
    test('sends what is piped in', () async {
      final asked = await runApp(answer: {'ok': true, 'result': 'sent'});

      final exit = await buildRunner(
        environment(input: 'hello from a pipe\n'),
      ).run(['clipboard', 'send']);

      expect(exit, ExitCodes.ok);
      expect(asked.single['text'], 'hello from a pipe');
    });

    test('nothing to send is a usage error, before asking the app', () async {
      final asked = await runApp();

      await expectLater(
        buildRunner(environment(input: '')).run(['clipboard', 'send']),
        throwsA(
          isA<Exception>().having(
            (error) => '$error',
            'message',
            contains('pipe it in'),
          ),
        ),
      );
      expect(asked, isEmpty);
    });
  });

  test('an ambiguous name exits 67 and lists the candidates', () async {
    await runApp(
      answer: {
        'ok': false,
        'error': 'ambiguous_device',
        'candidates': ['Pixel 7', 'Pixel Tablet'],
      },
    );

    final exit = await buildRunner(environment()).run(['ring', 'pix']);

    expect(exit, ExitCodes.noDevice);
    expect(err.toString(), contains('Pixel 7, Pixel Tablet'));
  });

  test('an older app says to update it', () async {
    await runApp(answer: {'ok': false, 'error': 'unknown_command'});
    final file = File('${home.path}/a.txt')..writeAsStringSync('a');

    final exit = await buildRunner(
      environment(),
    ).run(['send', file.path, '--to', 'Pixel']);

    expect(exit, ExitCodes.failed);
    expect(err.toString(), contains('Update it'));
  });

  test('help lists every exit code and links the scripting guide', () {
    final usage = buildRunner(environment()).usage;

    expect(usage, contains('67 no device has that name'));
    expect(
      usage,
      contains('https://ferret.sofluffy.io/docs/features/scripting'),
    );
  });
}
