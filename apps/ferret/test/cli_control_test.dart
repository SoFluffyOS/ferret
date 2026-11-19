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

  group('wake', () {
    test('wakes an offline computer by name', () async {
      final woken = <String>[];
      final control = CliControl(
        devices: () => devices,
        wake: (deviceId) async {
          woken.add(deviceId);
          return 'waking';
        },
      );

      final answer = await control.handle('wake', {'device': 'pixel tab'});

      expect(woken, ['bbbb-2222']);
      expect(answer, {
        'ok': true,
        'device': 'Pixel Tablet',
        'result': 'waking',
      });
    });

    test('a connected computer is already awake', () async {
      final control = CliControl(
        devices: () => devices,
        wake: (_) async => fail('should not wake'),
      );

      final answer = await control.handle('wake', {'device': 'Family PC'});

      expect(answer['error'], 'already_connected');
    });

    test('says when the computer never told how to wake it', () async {
      final control = CliControl(
        devices: () => devices,
        wake: (_) async => 'no_wake_info',
      );

      final answer = await control.handle('wake', {'device': 'Pixel Tablet'});

      expect(answer, {
        'ok': false,
        'error': 'no_wake_info',
        'device': 'Pixel Tablet',
      });
    });
  });

  group('open', () {
    test('opens a link on the named device', () async {
      final opened = <(String, String)>[];
      final control = CliControl(
        devices: () => devices,
        openLink: (deviceId, link) async {
          opened.add((deviceId, link));
          return 'opened';
        },
      );

      final answer = await control.handle('open', {
        'device': 'pixel 7',
        'link': 'https://example.com',
      });

      expect(opened, [('aaaa-1111', 'https://example.com')]);
      expect(answer, {'ok': true, 'device': 'Pixel 7', 'result': 'opened'});
    });

    test('says when it is not a link', () async {
      final control = CliControl(
        devices: () => devices,
        openLink: (_, _) async => 'not_a_link',
      );

      final answer = await control.handle('open', {
        'device': 'Pixel 7',
        'link': 'hello',
      });

      expect(answer['ok'], isFalse);
      expect(answer['error'], 'not_a_link');
    });
  });

  group('notify', () {
    test('sends the title and body to the named device', () async {
      final sent = <(String, String, String)>[];
      final control = CliControl(
        devices: () => devices,
        notify: (deviceId, title, body) async {
          sent.add((deviceId, title, body));
          return 'shown';
        },
      );

      final answer = await control.handle('notify', {
        'device': 'Pixel 7',
        'title': 'Build done',
        'body': 'All green',
      });

      expect(sent, [('aaaa-1111', 'Build done', 'All green')]);
      expect(answer['ok'], isTrue);
    });

    test('passes on that the device has not allowed it', () async {
      final control = CliControl(
        devices: () => devices,
        notify: (_, _, _) async => 'not_allowed',
      );

      final answer = await control.handle('notify', {
        'device': 'Pixel 7',
        'title': 'Hi',
      });

      expect(answer, {
        'ok': false,
        'device': 'Pixel 7',
        'result': 'not_allowed',
      });
    });

    test('an empty notice is not sent', () async {
      final control = CliControl(
        devices: () => devices,
        notify: (_, _, _) async => fail('should not send'),
      );

      final answer = await control.handle('notify', {'device': 'Pixel 7'});

      expect(answer['error'], 'nothing_to_send');
    });
  });

  group('send files', () {
    test('sends the paths to the named device', () async {
      final sent = <(String, List<String>)>[];
      final control = CliControl(
        devices: () => devices,
        sendFiles: (deviceId, paths) async {
          sent.add((deviceId, paths));
          return 'sending';
        },
      );

      final answer = await control.handle('send_files', {
        'device': 'Family PC',
        'paths': ['/tmp/a.txt'],
      });

      expect(sent.single.$1, 'cccc-3333');
      expect(answer['ok'], isTrue);
    });
  });

  group('camera', () {
    test('asks the phone and answers with where the photo was saved', () async {
      final asked = <(String, bool)>[];
      final control = CliControl(
        devices: () => devices,
        takePicture: (deviceId, {required document}) async {
          asked.add((deviceId, document));
          return (result: 'done', path: '/Downloads/Ferret/photo.jpg');
        },
      );

      final answer = await control.handle('camera', {'device': 'pixel 7'});

      expect(asked, [('aaaa-1111', false)]);
      expect(answer, {
        'ok': true,
        'device': 'Pixel 7',
        'result': 'done',
        'path': '/Downloads/Ferret/photo.jpg',
      });
    });

    test('a scan asks for a document, and Not now is not ok', () async {
      final control = CliControl(
        devices: () => devices,
        takePicture: (_, {required document}) async =>
            (result: document ? 'declined' : 'done', path: null),
      );

      final answer = await control.handle('camera', {
        'device': 'Pixel 7',
        'kind': 'document',
      });

      expect(answer['ok'], isFalse);
      expect(answer['result'], 'declined');
      expect(answer.containsKey('path'), isFalse);
    });

    test('an offline phone is not asked', () async {
      final control = CliControl(
        devices: () => devices,
        takePicture: (_, {required document}) async =>
            throw StateError('asked'),
      );

      final answer = await control.handle('camera', {
        'device': 'Pixel Tablet',
      });

      expect(answer['ok'], isFalse);
      expect(answer['error'], 'not_connected');
    });
  });
}
