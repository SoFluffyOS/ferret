import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ferret_cli/cli_environment.dart';

/// Forgets a paired device, by name or id, and tells it if it is reachable.
class UnpairCommand extends Command<int> {
  UnpairCommand(this._environment);

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

    await engine.unpair(device.id);
    stdout.writeln('Forgot ${device.name}.');
    return 0;
  }
}
