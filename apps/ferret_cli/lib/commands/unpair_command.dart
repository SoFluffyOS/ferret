import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ferret_cli/cli_environment.dart';

/// Forgets a paired device, by name or id, and tells it if it is reachable.
class UnpairCommand extends Command<int> {
  UnpairCommand(this._environment) {
    argParser.addFlag(
      'everywhere',
      help: 'Also remove it from your other paired devices.',
      negatable: false,
    );
  }

  static const _connectWait = Duration(seconds: 3);
  static const _sendWait = Duration(milliseconds: 500);

  final CliEnvironment _environment;

  @override
  String get name => 'unpair';

  @override
  String get description =>
      'Forget a paired device: ferret unpair <name or id>.';

  @override
  Future<int> run() async {
    final query = argResults?.rest.firstOrNull?.toLowerCase();
    if (query == null) {
      usageException('Give the name or id of the device to forget.');
    }

    final engine = await _environment.createEngine();
    final matches = engine.trustStore.devices.where(
      (device) =>
          device.name.toLowerCase() == query ||
          device.id.startsWith(query.replaceAll('-', '')),
    );
    final device = matches.firstOrNull;
    if (device == null) {
      stderr.writeln(
        'No paired device called "$query". Run "ferret devices" to see them.',
      );
      return 1;
    }

    final everywhere = argResults?['everywhere'] as bool? ?? false;
    if (!everywhere) {
      await engine.unpair(device.id);
      stdout.writeln('Forgot ${device.name}.');
      return 0;
    }

    // Other devices hear about it over a connection, so wait for them.
    await engine.start();
    await Future<void>.delayed(_connectWait);
    await engine.unpair(device.id, everywhere: true);
    await Future<void>.delayed(_sendWait);
    await engine.stop();
    stdout.writeln(
      'Removed ${device.name} from your devices. '
      'Ones that are off hear about it when they connect to this computer.',
    );
    return 0;
  }
}
