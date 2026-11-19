import 'package:ferret/wiring/wiring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final devices = <CliDevice>[
    (id: 'aaaa-1111', name: 'Pixel 7', isConnected: true),
    (id: 'bbbb-2222', name: 'Pixel Tablet', isConnected: false),
    (id: 'cccc-3333', name: 'Family PC', isConnected: true),
  ];

  group('ring', () {
    test('rings the device whose name starts with the query', () async {
      final rung = <String>[];
      final control = CliControl(
        devices: () => devices,
        ring: (deviceId) async {
          rung.add(deviceId);
          return 'ringing';
        },
      );

      final answer = await control.handle('ring', {'device': 'family'});

      expect(rung, ['cccc-3333']);
      expect(answer, {'ok': true, 'device': 'Family PC', 'result': 'ringing'});
    });

    test('an exact name wins over other names that start the same', () async {
      final control = CliControl(
        devices: () => [
          ...devices,
          (id: 'dddd-4444', name: 'Pixel', isConnected: true),
        ],
        ring: (_) async => 'ringing',
      );

      final answer = await control.handle('ring', {'device': 'pixel'});

      expect(answer['device'], 'Pixel');
    });

    test('a query that fits several devices lists them', () async {
      final control = CliControl(
        devices: () => devices,
        ring: (_) async => 'ringing',
      );

      final answer = await control.handle('ring', {'device': 'pix'});

      expect(answer['ok'], isFalse);
      expect(answer['error'], 'ambiguous_device');
      expect(answer['candidates'], ['Pixel 7', 'Pixel Tablet']);
    });

    test('an offline device is not rung', () async {
      final control = CliControl(
        devices: () => devices,
        ring: (_) async => fail('should not ring'),
      );

      final answer = await control.handle('ring', {'device': 'Pixel Tablet'});

      expect(answer, {
        'ok': false,
        'error': 'not_connected',
        'device': 'Pixel Tablet',
      });
    });

    test('an unknown name says so', () async {
      final control = CliControl(
        devices: () => devices,
        ring: (_) async => 'ringing',
      );

      final answer = await control.handle('ring', {'device': 'iPad'});

      expect(answer['error'], 'unknown_device');
    });
  });

  group('clipboard', () {
    test('get answers the last clip that arrived', () async {
      final at = DateTime.utc(2026, 11, 19, 9);
      final control = CliControl(
        devices: () => devices,
        latestClip: () => (text: 'hello', from: 'Pixel 7', at: at),
      );

      final answer = await control.handle('clipboard_get', const {});

      expect(answer, {
        'ok': true,
        'text': 'hello',
        'from': 'Pixel 7',
        'at': '2026-11-19T09:00:00.000Z',
      });
    });

    test('get without a clip says so', () async {
      final control = CliControl(
        devices: () => devices,
        latestClip: () => null,
      );

      final answer = await control.handle('clipboard_get', const {});

      expect(answer['error'], 'no_clip');
    });

    test('send goes to one device when named', () async {
      final sent = <(String, String?)>[];
      final control = CliControl(
        devices: () => devices,
        sendText: (text, deviceId) async {
          sent.add((text, deviceId));
          return 'sent';
        },
      );

      final answer = await control.handle('clipboard_send', {
        'text': 'hi',
        'device': 'Pixel 7',
      });

      expect(sent, [('hi', 'aaaa-1111')]);
      expect(answer, {'ok': true, 'result': 'sent', 'device': 'Pixel 7'});
    });

    test('send with no text sends nothing', () async {
      final control = CliControl(
        devices: () => devices,
        sendText: (_, _) async => fail('should not send'),
      );

      final answer = await control.handle('clipboard_send', {'text': ''});

      expect(answer['error'], 'nothing_to_send');
    });
  });

  group('action', () {
    const offered = <CliAction>[
      (id: 'sleep', title: ''),
      (id: 'restart', title: ''),
      (id: 'custom.1a2b', title: 'Backup'),
    ];

    test('runs the action with that id on the named computer', () async {
      final ran = <(String, String)>[];
      final control = CliControl(
        devices: () => devices,
        actionsOf: (_) => offered,
        runAction: (deviceId, actionId) async {
          ran.add((deviceId, actionId));
          return (result: 'done', exitCode: null);
        },
      );

      final answer = await control.handle('action_run', {
        'device': 'family',
        'action': 'sleep',
      });

      expect(ran, [('cccc-3333', 'sleep')]);
      expect(answer, {
        'ok': true,
        'device': 'Family PC',
        'action': 'sleep',
        'result': 'done',
      });
    });

    test('one of its owner\'s actions goes by its name too', () async {
      final ran = <String>[];
      final control = CliControl(
        devices: () => devices,
        actionsOf: (_) => offered,
        runAction: (_, actionId) async {
          ran.add(actionId);
          return (result: 'failed', exitCode: 2);
        },
      );

      final answer = await control.handle('action_run', {
        'device': 'Family PC',
        'action': 'backup',
      });

      expect(ran, ['custom.1a2b']);
      expect(answer['ok'], isFalse);
      expect(answer['exit_code'], 2);
    });

    test('never passes on a name the computer does not offer', () async {
      final control = CliControl(
        devices: () => devices,
        actionsOf: (_) => offered,
        runAction: (_, _) async => fail('should not run'),
      );

      final answer = await control.handle('action_run', {
        'device': 'Family PC',
        'action': 'rm -rf /',
      });

      expect(answer['error'], 'unknown_action');
      expect(answer['actions'], ['sleep', 'restart', 'custom.1a2b']);
    });

    test('lists what a connected computer offers', () async {
      final control = CliControl(
        devices: () => devices,
        actionsOf: (_) => offered,
        runAction: (_, _) async => fail('should not run'),
      );

      final answer = await control.handle('action_list', {'device': 'family'});

      expect(answer['actions'], [
        {'id': 'sleep'},
        {'id': 'restart'},
        {'id': 'custom.1a2b', 'title': 'Backup'},
      ]);
    });

    test('an offline computer is not asked', () async {
      final control = CliControl(
        devices: () => devices,
        actionsOf: (_) => offered,
        runAction: (_, _) async => fail('should not run'),
      );

      final answer = await control.handle('action_run', {
        'device': 'Pixel Tablet',
        'action': 'sleep',
      });

      expect(answer['error'], 'not_connected');
    });
  });
}
