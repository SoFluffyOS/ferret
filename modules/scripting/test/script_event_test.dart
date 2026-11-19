import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scripting/scripting.dart';

void main() {
  final at = DateTime.utc(2026, 11, 19, 9, 30);

  group('schema', () {
    test('every event carries the version, type, time and device', () {
      final event = ScriptEvent(
        type: ScriptEventType.battery,
        at: at,
        deviceId: 'aaaa-1111',
        deviceName: 'Pixel 7',
        fields: const {'percent': 42},
      );

      expect(event.toJson(), {
        'v': 1,
        'type': 'battery',
        'at': '2026-11-19T09:30:00.000Z',
        'device': {'id': 'aaaa-1111', 'name': 'Pixel 7'},
        'percent': 42,
      });
    });

    test('content shows only when asked for', () {
      final event = ScriptEvent(
        type: ScriptEventType.clipboardReceived,
        at: at,
        deviceId: 'aaaa-1111',
        deviceName: 'Pixel 7',
        fields: const {'kind': 'text'},
        content: const {'text': 'secret'},
      );

      expect(event.toJson().containsKey('text'), isFalse);
      expect(event.toJson(includeContent: true)['text'], 'secret');
    });

    test('an event about no device has no device field', () {
      final event = ScriptEvent(type: ScriptEventType.ready, at: at);

      expect(event.toJson().containsKey('device'), isFalse);
    });

    test('the documented types stay the same', () {
      expect(ScriptEvent.schemaVersion, 1);
      expect(ScriptEventType.all, [
        'ready',
        'device.connected',
        'device.disconnected',
        'device.reconnecting',
        'battery',
        'clipboard.received',
        'file.received',
        'notification.received',
        'call.ringing',
        'call.ended',
        'transfer.progress',
        'transfer.done',
        'action.run',
      ]);
    });

    test('a type filter matches the type and the types under it', () {
      final event = ScriptEvent(type: ScriptEventType.deviceConnected, at: at);

      expect(event.matches(const []), isTrue);
      expect(event.matches(const ['device']), isTrue);
      expect(event.matches(const ['device.connected']), isTrue);
      expect(event.matches(const ['dev']), isFalse);
      expect(event.matches(const ['battery']), isFalse);
    });
  });

  group('watch', () {
    test('starts with the devices, then streams what matches', () async {
      final hub = ScriptEventHub(clock: () => at);
      addTearDown(hub.dispose);
      final lines = <Map<String, Object?>>[];

      final subscription = hub
          .watch(
            const {
              'types': ['battery'],
              'include_content': true,
            },
            devices: () => [
              {'id': 'aaaa-1111', 'name': 'Pixel 7', 'connected': true},
            ],
          )
          .listen(lines.add);
      await pumpEventQueue();
      hub
        ..add(ScriptEvent(type: ScriptEventType.deviceConnected, at: at))
        ..add(
          ScriptEvent(
            type: ScriptEventType.battery,
            at: at,
            fields: const {'percent': 80},
          ),
        );
      await pumpEventQueue();
      await subscription.cancel();

      expect(lines.length, 2);
      expect(lines.first['type'], 'ready');
      expect(lines.first['devices'], [
        {'id': 'aaaa-1111', 'name': 'Pixel 7', 'connected': true},
      ]);
      expect(lines.last['percent'], 80);
    });

    test('leaves content out unless the watcher asked for it', () async {
      final hub = ScriptEventHub(clock: () => at);
      addTearDown(hub.dispose);
      final lines = <Map<String, Object?>>[];

      final subscription = hub
          .watch(const {}, devices: () => const [])
          .listen(lines.add);
      await pumpEventQueue();
      hub.add(
        ScriptEvent(
          type: ScriptEventType.clipboardReceived,
          at: at,
          content: const {'text': 'secret'},
        ),
      );
      await pumpEventQueue();
      unawaited(subscription.cancel());

      expect(lines.last.containsKey('text'), isFalse);
    });
  });
}
