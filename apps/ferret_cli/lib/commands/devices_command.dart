import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:engine/engine.dart';
import 'package:ferret_cli/cli_environment.dart';

/// Lists paired devices, without touching the network.
class DevicesCommand extends Command<int> {
  DevicesCommand(this._environment);

  final CliEnvironment _environment;

  @override
  String get name => 'devices';

  @override
  String get description => 'List paired devices.';

  @override
  Future<int> run() async {
    final (identity, trust) = await _environment.openStores();
    stdout.writeln('This device: ${DeviceIdentity.format(identity.deviceId)}');

    final devices = trust.devices;
    if (devices.isEmpty) {
      stdout.writeln(
        'No paired devices yet. Run "ferret offer" or "ferret pair".',
      );
      return 0;
    }

    for (final device in devices) {
      final address = switch ((device.lastHost, device.lastPort)) {
        (final host?, final port?) => '$host:$port',
        _ => 'unknown address',
      };
      stdout.writeln(
        '${device.name}  ${DeviceIdentity.format(device.id)}  $address',
      );
    }

    return 0;
  }
}
