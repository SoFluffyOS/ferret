import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:engine/engine.dart';
import 'package:ferret_cli/cli_environment.dart';

/// Lists paired devices, without touching the network.
class DevicesCommand extends Command<int> {
  DevicesCommand(this._environment) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Print JSON, for scripts: this device and a list of devices.',
    );
  }

  final CliEnvironment _environment;

  @override
  String get name => 'devices';

  @override
  String get description => 'List paired devices.';

  @override
  Future<int> run() async {
    final (identity, trust) = await _environment.openStores();
    final out = _environment.out;
    final devices = trust.devices;

    if (argResults?['json'] == true) {
      out.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'this_device': DeviceIdentity.format(identity.deviceId),
          'devices': [for (final device in devices) _json(device)],
        }),
      );
      return 0;
    }

    out.writeln('This device: ${DeviceIdentity.format(identity.deviceId)}');
    if (devices.isEmpty) {
      out.writeln(
        'No paired devices yet. Run "ferret offer" or "ferret pair".',
      );
      return 0;
    }

    for (final device in devices) {
      final address = switch ((device.lastHost, device.lastPort)) {
        (final host?, final port?) => '$host:$port',
        _ => 'unknown address',
      };
      out.writeln(
        '${device.name}  ${DeviceIdentity.format(device.id)}  $address',
      );
    }

    return 0;
  }

  static Map<String, Object?> _json(TrustedDevice device) => {
    'name': device.name,
    'id': DeviceIdentity.format(device.id),
    'platform': device.platform.name
        .replaceFirst('PLATFORM_', '')
        .toLowerCase(),
    'form_factor': device.formFactor.name
        .replaceFirst('FORM_FACTOR_', '')
        .toLowerCase(),
    'address': switch ((device.lastHost, device.lastPort)) {
      (final host?, final port?) => '$host:$port',
      _ => null,
    },
    'paired_at': device.pairedAt.toUtc().toIso8601String(),
    'last_seen': device.lastSeen?.toUtc().toIso8601String(),
  };
}
