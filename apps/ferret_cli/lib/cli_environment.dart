import 'dart:io' as io;

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/protocol.dart';

/// Where the CLI keeps its identity, pairings and settings, and how it starts
/// an engine.
class CliEnvironment {
  CliEnvironment({String? directory})
    : directory = directory ?? defaultDirectory();

  final String directory;

  /// `$XDG_CONFIG_HOME/ferret`, `~/.config/ferret`, or `%APPDATA%\Ferret`.
  static String defaultDirectory() {
    final environment = io.Platform.environment;
    if (io.Platform.isWindows) {
      return p.join(environment['APPDATA'] ?? '.', 'Ferret');
    }

    if (environment['XDG_CONFIG_HOME'] case final config?
        when config.isNotEmpty) {
      return p.join(config, 'ferret');
    }

    return p.join(environment['HOME'] ?? '.', '.config', 'ferret');
  }

  Future<FerretEngine> createEngine({
    int port = FerretEngine.defaultPort,
  }) async {
    final settings = await JsonFileSettingsStore.open(directory);
    final name =
        settings.get<String>('device.name') ??
        '${await _computerName()} · Terminal';

    return FerretEngine.create(
      secrets: FileSecretStore(directory),
      settings: settings,
      device: LocalDevice(
        name: name,
        platform: _platform(),
        formFactor: .FORM_FACTOR_DESKTOP,
        model: 'ferret-cli',
      ),
      port: port,
    );
  }

  /// Opens only the identity and pairings, without touching the network.
  Future<(DeviceIdentity, TrustStore)> openStores() async {
    final secrets = FileSecretStore(directory);
    return (
      await DeviceIdentity.loadOrCreate(secrets),
      await TrustStore.open(secrets),
    );
  }

  /// The name people gave this computer: macOS's Computer Name, otherwise
  /// the host name.
  Future<String> _computerName() async {
    if (io.Platform.isMacOS) {
      final result = await io.Process.run('scutil', ['--get', 'ComputerName']);
      final name = '${result.stdout}'.trim();
      if (result.exitCode == 0 && name.isNotEmpty) {
        return name;
      }
    }

    return io.Platform.localHostname;
  }

  Platform _platform() => switch (io.Platform.operatingSystem) {
    'macos' => .PLATFORM_MACOS,
    'windows' => .PLATFORM_WINDOWS,
    'linux' => .PLATFORM_LINUX,
    _ => .PLATFORM_CLI,
  };
}
