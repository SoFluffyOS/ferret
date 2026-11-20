import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:engine/engine.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/app_devices.dart';

/// Lists paired devices: the ones the Ferret app running here reaches, and
/// the ones this command line paired with on its own for `daemon`.
class DevicesCommand extends Command<int> {
  DevicesCommand(this._environment) {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help:
            'Print JSON, for scripts: this command line\'s own pairings under '
            '"devices", the app\'s devices under "app".',
      )
      ..addFlag(
        'names',
        negatable: false,
        help:
            'Print only the names, one per line, for completions and pickers '
            'such as fzf.',
      );
  }

  final CliEnvironment _environment;

  @override
  String get name => 'devices';

  @override
  String get description =>
      'List paired devices, and which ones are connected right now.';

  @override
  Future<int> run() async {
    final (identity, trust) = await _environment.openStores();
    final appDevices = await AppDevices.read(_environment.appRoot);
    final own = trust.devices;

    if (argResults?['names'] == true) {
      _printNames(appDevices, own);
      return 0;
    }

    if (argResults?['json'] == true) {
      _environment.out.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'this_device': DeviceIdentity.format(identity.deviceId),
          'devices': [for (final device in own) _json(device)],
          'app': switch (appDevices) {
            final devices? => {
              'running': true,
              'devices': [for (final device in devices) _appJson(device)],
            },
            null => {'running': false},
          },
        }),
      );
      return 0;
    }

    _printWords(identity, appDevices, own);
    return 0;
  }

  void _printNames(
    List<Map<String, Object?>>? appDevices,
    List<TrustedDevice> own,
  ) {
    final names = <String>{
      for (final device in appDevices ?? const <Map<String, Object?>>[])
        if (device['name'] case final String name) name,
      for (final device in own) device.name,
    };
    for (final name in names) {
      _environment.out.writeln(name);
    }
  }

  void _printWords(
    DeviceIdentity identity,
    List<Map<String, Object?>>? appDevices,
    List<TrustedDevice> own,
  ) {
    final out = _environment.out;
    if (appDevices == null && own.isNotEmpty) {
      _environment.err.writeln(
        "The Ferret app isn't running here, so its devices aren't listed. "
        'Open it to see them.',
      );
    }

    if (appDevices case final devices? when devices.isNotEmpty) {
      out.writeln('Paired with the Ferret app:');
      for (final device in devices) {
        out.writeln('  ${device['name']}  ${_stateOf(device)}');
      }
    }

    if (appDevices case final devices? when devices.isEmpty) {
      out.writeln(
        'The Ferret app has no paired devices yet. Open it and click Add a '
        'device.',
      );
    }

    if (own.isNotEmpty) {
      out.writeln('Paired with ferret-cli itself, for ferret-cli daemon:');
      for (final device in own) {
        final address = switch ((device.lastHost, device.lastPort)) {
          (final host?, final port?) => '$host:$port',
          _ => 'unknown address',
        };
        out.writeln(
          '  ${device.name}  ${DeviceIdentity.format(device.id)}  $address',
        );
      }
    }

    if (appDevices == null && own.isEmpty) {
      out.writeln(
        'No paired devices yet. Open the Ferret app, or run "ferret-cli '
        'offer" to pair this command line on its own.',
      );
    }

    out.writeln(
      "ferret-cli's own id: ${DeviceIdentity.format(identity.deviceId)}",
    );
  }

  static String _stateOf(Map<String, Object?> device) {
    final state = switch (device) {
      {'connected': true} => 'connected',
      {'reconnecting': true} => 'reconnecting',
      _ => 'not connected',
    };

    return switch (device['battery']) {
      final int percent => '$state · battery $percent%',
      _ => state,
    };
  }

  /// Ids stay as `watch` prints them, so a script can match the two.
  static Map<String, Object?> _appJson(Map<String, Object?> device) => {
    'name': device['name'],
    'id': device['id'],
    'connected': device['connected'] == true,
    'reconnecting': device['reconnecting'] == true,
    'battery': ?device['battery'],
  };

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
