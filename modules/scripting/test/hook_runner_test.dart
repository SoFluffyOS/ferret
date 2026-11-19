@TestOn('mac-os || linux')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scripting/scripting.dart';

void main() {
  late Directory hooks;

  setUp(() async {
    hooks = await Directory.systemTemp.createTemp('ferret_hooks');
  });

  tearDown(() => hooks.delete(recursive: true));

  Future<File> writeHook(
    String type,
    String body, {
    String mode = '700',
  }) async {
    final file = File('${hooks.path}/$type');
    await file.writeAsString('#!/bin/sh\n$body\n');
    await Process.run('chmod', [mode, file.path]);
    return file;
  }

  final event = ScriptEvent(
    type: ScriptEventType.deviceConnected,
    at: DateTime.utc(2026, 11, 19),
    deviceId: 'aaaa-1111',
    deviceName: 'Pixel 7',
    content: const {'text': 'never for hooks'},
  );

  test('a hook gets the event on stdin and its basics in the environment', () async {
    final out = File('${hooks.path}/out.txt');
    await writeHook(
      'device.connected',
      'cat > "${out.path}"; echo "\$FERRET_EVENT|\$FERRET_DEVICE_NAME" >> "${out.path}"',
    );

    final run = await HookRunner(hooks.path).run(event);

    expect(run?.outcome, HookOutcome.exited);
    expect(run?.exitCode, 0);
    final lines = await out.readAsLines();
    final json = jsonDecode(lines.first) as Map<String, Object?>;
    expect(json['type'], 'device.connected');
    expect(json['v'], 1);
    expect(json.containsKey('text'), isFalse);
    expect(lines.last, 'device.connected|Pixel 7');
  });

  test('a hook that runs too long is stopped', () async {
    await writeHook('device.connected', 'sleep 30');

    final started = DateTime.now();
    final run = await HookRunner(
      hooks.path,
      timeout: const Duration(milliseconds: 300),
    ).run(event);

    expect(run?.outcome, HookOutcome.timedOut);
    expect(
      DateTime.now().difference(started),
      lessThan(const Duration(seconds: 5)),
    );
  });

  test('no file, no run', () async {
    expect(await HookRunner(hooks.path).run(event), isNull);
  });

  test('a file that is not executable does not run', () async {
    await writeHook('device.connected', 'exit 0', mode: '600');

    expect(await HookRunner(hooks.path).run(event), isNull);
  });

  test('a file other users may change does not run', () async {
    await writeHook('device.connected', 'exit 0', mode: '777');

    expect(await HookRunner(hooks.path).run(event), isNull);
  });

  test('only event names count as hooks', () async {
    await writeHook('device.connected', 'exit 0');
    await writeHook('not-an-event', 'exit 0');

    expect(await HookRunner(hooks.path).installed(), ['device.connected']);
  });

  test('runs of one hook wait their turn, and a pile-up is skipped', () async {
    await writeHook('device.connected', 'sleep 0.2');
    final runner = HookRunner(hooks.path, maxWaiting: 2);

    final runs = await Future.wait([
      runner.run(event),
      runner.run(event),
      runner.run(event),
    ]);

    expect(
      [for (final run in runs) run?.outcome],
      [
        HookOutcome.exited,
        HookOutcome.exited,
        HookOutcome.dropped,
      ],
    );
  });
}
