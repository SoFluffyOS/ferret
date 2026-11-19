import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_app_control');
  });

  tearDown(() => root.delete(recursive: true));

  test('a command reaches the running app and its answer comes back', () async {
    final running = AppControl(root.path);
    final asked = <(String, Map<String, Object?>)>[];
    await running.listen((command, arguments) async {
      asked.add((command, arguments));
      return {'ok': true, 'device': arguments['device']};
    });
    addTearDown(running.dispose);

    final answer = await AppControl(
      root.path,
    ).ask('ring', {'device': 'Pixel'});

    expect(answer, {'ok': true, 'device': 'Pixel'});
    expect(asked.single.$1, 'ring');
  });

  test('asking with no app running answers null', () async {
    expect(await AppControl(root.path).ask('ring'), isNull);
  });

  test('a stopped app no longer answers', () async {
    final running = AppControl(root.path);
    await running.listen((_, _) async => {'ok': true});
    await running.dispose();

    expect(await AppControl(root.path).ask('ring'), isNull);
  });

  test('watch streams events until the watcher hangs up', () async {
    final running = AppControl(root.path);
    final events = StreamController<Map<String, Object?>>.broadcast();
    final watched = <Map<String, Object?>>[];
    await running.listen(
      (_, _) async => {'ok': true},
      watch: (arguments) {
        watched.add(arguments);
        return events.stream;
      },
    );
    addTearDown(running.dispose);

    final stream = await AppControl(root.path).watch({'types': 'battery'});
    final received = <Map<String, Object?>>[];
    final subscription = stream?.listen(received.add);
    await _until(() => events.hasListener);
    events
      ..add({'type': 'battery', 'percent': 80})
      ..add({'type': 'battery', 'percent': 79});
    await _until(() => received.length == 2);
    await subscription?.cancel();
    await _until(() => !events.hasListener);

    expect(watched.single, {'types': 'battery'});
    expect(received.last, {'type': 'battery', 'percent': 79});
  });

  test('watching with no app running gives null', () async {
    expect(await AppControl(root.path).watch(), isNull);
  });

  test('an app without events says watch is not supported', () async {
    final running = AppControl(root.path);
    await running.listen((_, _) async => {'ok': true});
    addTearDown(running.dispose);

    final stream = await AppControl(root.path).watch();

    expect(await stream?.first, {'ok': false, 'error': 'not_supported'});
  });

  test('a wrong secret gets nothing back', () async {
    final running = AppControl(root.path);
    var asked = false;
    await running.listen((_, _) async {
      asked = true;
      return {'ok': true};
    });
    addTearDown(running.dispose);
    final address = File('${root.path}/app_control.json');
    final port = RegExp(r'"port":(\d+)')
        .firstMatch(
          await address.readAsString(),
        )
        ?.group(1);

    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      int.parse('$port'),
    );
    socket.writeln('{"secret":"guess","command":"ring","arguments":{}}');
    await socket.flush();
    final reply = await socket.toList();

    expect(reply, isEmpty);
    expect(asked, isFalse);
  });

  test('the address file is private to this user', () async {
    final running = AppControl(root.path);
    await running.listen((_, _) async => {'ok': true});
    addTearDown(running.dispose);

    final mode = (await File('${root.path}/app_control.json').stat()).mode;

    expect(mode & 0x3f, 0);
  }, testOn: '!windows');
}

Future<void> _until(bool Function() done) async {
  for (var attempt = 0; attempt < 200 && !done(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
