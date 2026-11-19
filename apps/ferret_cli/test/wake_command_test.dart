import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_cli/commands/commands.dart';
import 'package:ferret_cli/ferret_cli.dart';
import 'package:ferret_wake/ferret_wake.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

/// Keeps packets off the real network.
class _Sender implements WakeSender {
  final List<WakePacket> sent = [];

  @override
  Future<List<WakePacket>> send(List<WakePacket> packets) async {
    sent.addAll(packets);
    return packets;
  }
}

void main() {
  late Directory home;
  late StringBuffer out;
  late StringBuffer err;
  late CliEnvironment environment;
  late _Sender sender;

  CommandRunner<int> runner() =>
      CommandRunner<int>('ferret-cli', '')
        ..addCommand(WakeCommand(environment, sender: sender));

  setUp(() async {
    home = await Directory.systemTemp.createTemp('ferret_cli_wake');
    out = StringBuffer();
    err = StringBuffer();
    sender = _Sender();
    environment = CliEnvironment(
      FerretPaths(home.path).nested('cli'),
      appRoot: home.path,
      out: out,
      err: err,
    );
  });

  tearDown(() => home.delete(recursive: true));

  test('wakes a MAC address as is, without the app', () async {
    final exit = await runner().run(['wake', '3C-22-FB-12-34-56']);

    expect(exit, ExitCodes.ok);
    expect(sender.sent, isNotEmpty);
    expect(
      sender.sent.first.bytes.sublist(6, 12),
      [0x3c, 0x22, 0xfb, 0x12, 0x34, 0x56],
    );
    expect(out.toString(), contains('3c:22:fb:12:34:56'));
  });

  test('asks the running app, which wakes it', () async {
    final running = AppControl(home.path);
    final asked = <Map<String, Object?>>[];
    await running.listen((command, arguments) async {
      asked.add({'command': command, ...arguments});
      return {'ok': true, 'device': 'Family PC', 'result': 'waking'};
    });
    addTearDown(running.dispose);

    final exit = await runner().run(['wake', 'Family', 'PC']);

    expect(exit, ExitCodes.ok);
    expect(asked, [
      {'command': 'wake', 'device': 'Family PC'},
    ]);
    expect(sender.sent, isEmpty);
    expect(out.toString(), contains('Sent the wake signal to Family PC'));
  });

  test('says when the app knows no way to wake it', () async {
    final running = AppControl(home.path);
    await running.listen(
      (_, _) async => {
        'ok': false,
        'error': 'no_wake_info',
        'device': 'Family PC',
      },
    );
    addTearDown(running.dispose);

    final exit = await runner().run(['wake', 'Family PC']);

    expect(exit, ExitCodes.failed);
    expect(err.toString(), contains("hasn't told Ferret how to wake it"));
  });

  test('without the app, wakes a computer paired with the daemon', () async {
    final (_, trustStore) = await environment.openStores();
    await trustStore.save(
      TrustedDevice(
        id: 'nas',
        name: 'Home NAS',
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_SERVER,
        publicKey: Uint8List(32),
        pairedAt: DateTime(2026, 11),
        lastHost: '192.168.1.5',
        wake: WakeInfo(
          interfaces: [
            WakeInterface(
              mac: const [0x70, 0x85, 0xc2, 1, 2, 3],
              broadcast: '192.168.1.255',
              link: .WAKE_LINK_WIRED,
            ),
          ],
        ),
      ),
    );

    final exit = await runner().run(['wake', 'home', '--json']);

    expect(exit, ExitCodes.ok);
    expect(jsonDecode(out.toString()), {
      'ok': true,
      'device': 'Home NAS',
      'result': 'sent',
    });
    expect(
      {for (final packet in sender.sent) packet.address},
      {'192.168.1.255', '255.255.255.255', '192.168.1.5'},
    );
  });

  test('without the app, an unknown name fails and sends nothing', () async {
    final exit = await runner().run(['wake', 'Toaster']);

    expect(exit, ExitCodes.failed);
    expect(sender.sent, isEmpty);
    expect(err.toString(), contains('MAC address'));
  });
}
