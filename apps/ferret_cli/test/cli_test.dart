import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_cli/ferret_cli.dart';
import 'package:test/test.dart';

void main() {
  test('keeps its files in a cli folder of Ferret\'s home', () async {
    final environment = await CliEnvironment.forThisUser(
      environment: const {'FERRET_HOME': '/tmp/ferret_home'},
    );

    expect(
      environment.paths.root,
      FerretPaths('/tmp/ferret_home').nested('cli').root,
    );
  });

  test('a fresh install has an identity and no devices', () async {
    final directory = await Directory.systemTemp.createTemp('ferret_cli');
    addTearDown(() => directory.delete(recursive: true));
    final environment = CliEnvironment(FerretPaths(directory.path));

    final (identity, trust) = await environment.openStores();
    final (again, _) = await environment.openStores();

    expect(trust.devices, isEmpty);
    expect(again.deviceId, identity.deviceId);
  });

  test('the CLI pairs with another engine from its link', () async {
    final offering = await Directory.systemTemp.createTemp('ferret_cli_offer');
    final scanning = await Directory.systemTemp.createTemp('ferret_cli_scan');
    addTearDown(() => offering.delete(recursive: true));
    addTearDown(() => scanning.delete(recursive: true));

    final shower = await CliEnvironment(FerretPaths(offering.path))
        .createEngine(port: 0);
    await shower.start();
    addTearDown(shower.stop);
    final offer = await shower.createPairingOffer();
    final link = offer.qrText;

    final exit = await buildRunner(CliEnvironment(FerretPaths(scanning.path)))
        .run(['pair', _localLink(link)]);

    expect(exit, 0);
    expect(shower.trustStore.devices, hasLength(1));
  });

  group('scripting', () {
    late Directory home;
    late StringBuffer out;
    late StringBuffer err;
    late CliEnvironment environment;

    setUp(() async {
      home = await Directory.systemTemp.createTemp('ferret_cli_script');
      out = StringBuffer();
      err = StringBuffer();
      environment = CliEnvironment(
        FerretPaths(home.path).nested('cli'),
        appRoot: home.path,
        out: out,
        err: err,
      );
    });

    tearDown(() => home.delete(recursive: true));

    test('devices --json prints this device and an empty list', () async {
      final exit = await buildRunner(environment).run(['devices', '--json']);

      final json = jsonDecode(out.toString()) as Map<String, Object?>;
      expect(exit, ExitCodes.ok);
      expect(json['this_device'], isA<String>());
      expect(json['devices'], isEmpty);
    });

    test('send hands files to the running app', () async {
      final running = SendHandoff(home.path);
      final received = <List<String>>[];
      running.requests.listen(received.add);
      await running.listen();
      addTearDown(running.dispose);
      final file = File('${home.path}/photo.jpg')..writeAsStringSync('x');

      final exit = await buildRunner(environment).run(['send', file.path]);

      expect(exit, ExitCodes.ok);
      expect(received, [
        [file.path],
      ]);
      expect(out.toString(), contains('Handed 1 file'));
    });

    test('send hands a folder over whole', () async {
      final running = SendHandoff(home.path);
      final received = <List<String>>[];
      running.requests.listen(received.add);
      await running.listen();
      addTearDown(running.dispose);
      final folder = Directory('${home.path}/Photos')..createSync();
      File('${folder.path}/a.jpg').writeAsStringSync('x');

      final exit = await buildRunner(environment).run(['send', folder.path]);

      expect(exit, ExitCodes.ok);
      expect(received, [
        [folder.path],
      ]);
      expect(out.toString(), contains('Handed 1 folder'));
    });

    test('send says when the app is not running', () async {
      final file = File('${home.path}/photo.jpg')..writeAsStringSync('x');

      final exit = await buildRunner(environment).run(['send', file.path]);

      expect(exit, ExitCodes.unavailable);
      expect(err.toString(), contains("isn't running"));
    });

    test('send stops at a file that is not there', () async {
      final exit = await buildRunner(
        environment,
      ).run(['send', '${home.path}/missing.txt']);

      expect(exit, ExitCodes.noInput);
      expect(err.toString(), contains('No such file'));
    });

    test('ring asks the running app and says it rings', () async {
      final running = AppControl(home.path);
      final asked = <Map<String, Object?>>[];
      await running.listen((command, arguments) async {
        asked.add({'command': command, ...arguments});
        return {'ok': true, 'device': 'Pixel 7', 'result': 'ringing'};
      });
      addTearDown(running.dispose);

      final exit = await buildRunner(environment).run(['ring', 'Pixel', '7']);

      expect(exit, ExitCodes.ok);
      expect(asked, [
        {'command': 'ring', 'device': 'Pixel 7'},
      ]);
      expect(out.toString(), contains('Pixel 7 is ringing.'));
    });

    test('ring exits 75 when the device is not connected', () async {
      final running = AppControl(home.path);
      await running.listen(
        (_, _) async => {
          'ok': false,
          'error': 'not_connected',
          'device': 'Pixel 7',
        },
      );
      addTearDown(running.dispose);

      final exit = await buildRunner(
        environment,
      ).run(['ring', 'Pixel', '--json']);

      final json = jsonDecode(out.toString()) as Map<String, Object?>;
      expect(exit, ExitCodes.notConnected);
      expect(json['error'], 'not_connected');
    });

    test('ring says when the app is not running', () async {
      final exit = await buildRunner(environment).run(['ring', 'Pixel']);

      expect(exit, ExitCodes.unavailable);
      expect(err.toString(), contains("isn't running"));
    });

    test('open asks the running app to open the link there', () async {
      final running = AppControl(home.path);
      final asked = <Map<String, Object?>>[];
      await running.listen((command, arguments) async {
        asked.add({'command': command, ...arguments});
        return {'ok': true, 'device': 'Pixel 7', 'result': 'opened'};
      });
      addTearDown(running.dispose);

      final exit = await buildRunner(
        environment,
      ).run(['open', 'Pixel', '7', 'https://example.com']);

      expect(exit, ExitCodes.ok);
      expect(asked, [
        {
          'command': 'open',
          'device': 'Pixel 7',
          'link': 'https://example.com',
        },
      ]);
      expect(out.toString(), contains('Opened on Pixel 7.'));
    });

    test('notify says how to allow it when the device said no', () async {
      final running = AppControl(home.path);
      final asked = <Map<String, Object?>>[];
      await running.listen((command, arguments) async {
        asked.add({'command': command, ...arguments});
        return {'ok': false, 'device': 'Pixel 7', 'result': 'not_allowed'};
      });
      addTearDown(running.dispose);

      final exit = await buildRunner(
        environment,
      ).run(['notify', 'Pixel 7', 'Build done', 'All', 'green']);

      expect(exit, ExitCodes.failed);
      expect(asked.single, {
        'command': 'notify',
        'device': 'Pixel 7',
        'title': 'Build done',
        'body': 'All green',
      });
      expect(err.toString(), contains('show notices here'));
    });

    test('watch --json prints each event as one line of JSON', () async {
      final running = AppControl(home.path);
      final events = StreamController<Map<String, Object?>>();
      final asked = <Map<String, Object?>>[];
      await running.listen(
        (_, _) async => {'ok': true},
        watch: (arguments) {
          asked.add(arguments);
          return events.stream;
        },
      );
      addTearDown(running.dispose);

      final exit = buildRunner(
        environment,
      ).run(['watch', '--json', '--type', 'device,battery']);
      events
        ..add({'v': 1, 'type': 'ready', 'devices': <Object?>[]})
        ..add({'v': 1, 'type': 'battery', 'percent': 42});
      await events.close();

      expect(await exit, ExitCodes.unavailable);
      final lines = const LineSplitter().convert(out.toString());
      expect(lines, hasLength(2));
      expect(jsonDecode(lines.last), {
        'v': 1,
        'type': 'battery',
        'percent': 42,
      });
      expect(asked.single, {
        'include_content': false,
        'types': ['device', 'battery'],
      });
    });

    test('watch prints events in words and stops when asked', () async {
      final running = AppControl(home.path);
      final events = StreamController<Map<String, Object?>>.broadcast();
      await running.listen(
        (_, _) async => {'ok': true},
        watch: (_) => events.stream,
      );
      addTearDown(running.dispose);
      final stop = StreamController<Object?>();

      final exit = buildRunner(environment, stop: stop.stream).run(['watch']);
      for (var attempt = 0; attempt < 100 && !events.hasListener; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      events.add({
        'v': 1,
        'type': 'device.connected',
        'at': '2026-11-19T09:30:00.000Z',
        'device': {'id': 'aaaa', 'name': 'Pixel 7'},
      });
      for (var attempt = 0; attempt < 100 && out.isEmpty; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      stop.add(null);

      expect(await exit, ExitCodes.ok);
      expect(out.toString(), contains('Pixel 7 connected'));
    });

    test('watch says when the app is not running', () async {
      final exit = await buildRunner(environment).run(['watch']);

      expect(exit, ExitCodes.unavailable);
      expect(err.toString(), contains("isn't running"));
    });

    test('clipboard get prints the last clip', () async {
      final running = AppControl(home.path);
      await running.listen(
        (_, _) async => {'ok': true, 'text': 'hello', 'from': 'Pixel 7'},
      );
      addTearDown(running.dispose);

      final exit = await buildRunner(environment).run(['clipboard', 'get']);

      expect(exit, ExitCodes.ok);
      expect(out.toString().trim(), 'hello');
    });

    test('clipboard get exits 66 when nothing arrived yet', () async {
      final running = AppControl(home.path);
      await running.listen((_, _) async => {'ok': false, 'error': 'no_clip'});
      addTearDown(running.dispose);

      final exit = await buildRunner(environment).run(['clipboard', 'get']);

      expect(exit, ExitCodes.noInput);
    });

    test('clipboard send hands the text and the device over', () async {
      final running = AppControl(home.path);
      final asked = <Map<String, Object?>>[];
      await running.listen((command, arguments) async {
        asked.add({'command': command, ...arguments});
        return {'ok': true, 'result': 'sent', 'device': 'Pixel 7'};
      });
      addTearDown(running.dispose);

      final exit = await buildRunner(
        environment,
      ).run(['clipboard', 'send', 'hi', 'there', '--to', 'Pixel']);

      expect(exit, ExitCodes.ok);
      expect(asked, [
        {'command': 'clipboard_send', 'text': 'hi there', 'device': 'Pixel'},
      ]);
      expect(out.toString(), contains('Sent to Pixel 7.'));
    });

    test('action hands the computer and the action id to the app', () async {
      final running = AppControl(home.path);
      final asked = <Map<String, Object?>>[];
      await running.listen((command, arguments) async {
        asked.add({'command': command, ...arguments});
        return {
          'ok': true,
          'device': 'Family PC',
          'action': 'sleep',
          'result': 'done',
        };
      });
      addTearDown(running.dispose);

      final exit = await buildRunner(
        environment,
      ).run(['action', 'Family', 'PC', 'sleep']);

      expect(exit, ExitCodes.ok);
      expect(asked, [
        {'command': 'action_run', 'device': 'Family PC', 'action': 'sleep'},
      ]);
      expect(out.toString(), contains('Done on Family PC.'));
    });

    test('action with only a computer lists what it offers', () async {
      final running = AppControl(home.path);
      await running.listen(
        (command, _) async => {
          'ok': command == 'action_list',
          'device': 'Family PC',
          'actions': [
            {'id': 'sleep'},
            {'id': 'custom.1a2b', 'title': 'Backup'},
          ],
        },
      );
      addTearDown(running.dispose);

      final exit = await buildRunner(environment).run(['action', 'Family']);

      expect(exit, ExitCodes.ok);
      expect(out.toString(), 'sleep\ncustom.1a2b  Backup\n');
    });

    test('action says why when the owner said no', () async {
      final running = AppControl(home.path);
      await running.listen(
        (_, _) async => {
          'ok': false,
          'device': 'Family PC',
          'action': 'restart',
          'result': 'denied',
        },
      );
      addTearDown(running.dispose);

      final exit = await buildRunner(
        environment,
      ).run(['action', 'Family', 'restart']);

      expect(exit, ExitCodes.failed);
      expect(err.toString(), contains('Someone at Family PC said no.'));
    });

    test('--version prints the version', () async {
      final exit = await buildRunner(environment).run(['--version']);

      expect(exit, ExitCodes.ok);
      expect(out.toString().trim(), 'ferret-cli $cliVersion');
    });

    test('help lists the exit codes', () {
      expect(buildRunner(environment).usage, contains('69 the Ferret app'));
    });
  });
}

/// Points the link's offer at loopback, so the test doesn't depend on the
/// machine's network.
String _localLink(String link) {
  final offer = PairingCodes.parseOffer(link);
  if (offer == null) {
    fail('Not a pairing link: $link');
  }

  offer
    ..hosts.clear()
    ..hosts.add('127.0.0.1');
  return PairingCodes.offerUri(offer).toString();
}
