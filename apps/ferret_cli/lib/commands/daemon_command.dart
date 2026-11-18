import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:engine/engine.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:transport/transport.dart';

/// Runs Ferret headless until Ctrl-C: listens, reconnects to paired devices,
/// and asks on the terminal before pairing with a new one.
class DaemonCommand extends Command<int> {
  DaemonCommand(this._environment) {
    argParser.addOption(
      'port',
      help: 'TCP port to listen on.',
      defaultsTo: '${FerretEngine.defaultPort}',
    );
  }

  final CliEnvironment _environment;

  @override
  String get name => 'daemon';

  @override
  String get description => 'Run Ferret in the background of this terminal.';

  @override
  Future<int> run() async {
    final port =
        int.tryParse(argResults?['port'] as String? ?? '') ??
        FerretEngine.defaultPort;
    final engine = await _environment.createEngine(port: port);
    await engine.start();
    stdout.writeln(
      'Ferret ${DeviceIdentity.format(engine.identity.deviceId)} on port ${engine.port}. Ctrl-C to stop.',
    );

    final lines = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    final subscriptions = [
      engine.sessionChanges.listen(
        (sessions) => stdout.writeln('Connected: ${_names(sessions)}'),
      ),
      engine.pairingPrompts.listen((prompt) => unawaited(_ask(prompt, lines))),
      engine.joins.listen(
        (joined) => stdout.writeln(
          '${joined.device.name} joined your devices '
          '(added by ${joined.introducer.name}).',
        ),
      ),
      engine.nearbyChanges.listen(
        (nearby) => stdout.writeln('Nearby: ${_nearbyNames(nearby)}'),
      ),
    ];

    await ProcessSignal.sigint.watch().first;
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }

    await engine.stop();
    return 0;
  }

  String _names(List<Session> sessions) {
    if (sessions.isEmpty) {
      return 'none';
    }

    return sessions
        .map((session) => session.remoteDevice?.name ?? session.remoteDeviceId)
        .join(', ');
  }

  String _nearbyNames(List<DiscoveredPeer> nearby) {
    if (nearby.isEmpty) {
      return 'none';
    }

    return nearby.map((peer) => peer.announce.name).join(', ');
  }

  Future<void> _ask(PairingPrompt prompt, Stream<String> lines) async {
    if (prompt.alsoDevices.isNotEmpty) {
      stdout.writeln(
        'You will also be connected to ${prompt.alsoDevices.join(', ')}.',
      );
    }

    stdout
      ..writeln('${prompt.device.name} wants to pair. Code: ${prompt.code}')
      ..write('Does ${prompt.device.name} show the same code? [y/N] ');
    final answer = await Future.any([
      lines.first,
      prompt.answer.then((_) => ''),
    ]);
    if (prompt.isDecided) {
      stdout.writeln('\n${prompt.device.name} stopped waiting.');
      return;
    }

    if (answer.trim().toLowerCase().startsWith('y')) {
      prompt.accept();
      return;
    }

    prompt.reject();
  }
}
