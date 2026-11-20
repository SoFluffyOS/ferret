import 'dart:convert';
import 'dart:io' as io;

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protocol/protocol.dart';

/// Where the CLI keeps its identity, pairings and settings, and how it starts
/// an engine.
class CliEnvironment {
  CliEnvironment(
    this.paths, {
    String? appRoot,
    StringSink? out,
    StringSink? err,
    Stream<List<int>>? input,
  }) : appRoot = appRoot ?? io.Directory(paths.root).parent.path,
       out = out ?? io.stdout,
       err = err ?? io.stderr,
       _input = input;

  /// The CLI's own folders: `~/.sofluffy/ferret/cli`, so its identity stays
  /// apart from the app's on the same computer.
  final FerretPaths paths;

  /// The app's folder, `~/.sofluffy/ferret`, where a running app says how
  /// to hand it files.
  final String appRoot;

  /// Where results go, and where problems go.
  final StringSink out;
  final StringSink err;

  final Stream<List<int>>? _input;

  static const String folderName = FerretPaths.cliFolder;

  /// The CLI's folders for this user, under `FERRET_HOME` when it is set.
  /// [environment] defaults to this process's.
  static Future<CliEnvironment> forThisUser({
    Map<String, String>? environment,
  }) async {
    final paths = await FerretPaths.resolve(environment: environment);
    return CliEnvironment(paths.nested(folderName), appRoot: paths.root);
  }

  /// Everything piped into the command, or null when standard input is a
  /// terminal and nothing was piped.
  Future<String?> readInput() async {
    final piped = _input;
    if (piped != null) {
      return piped.transform(utf8.decoder).join();
    }

    if (io.stdin.hasTerminal) {
      return null;
    }

    return io.stdin.transform(utf8.decoder).join();
  }

  Future<FerretEngine> createEngine({
    int port = FerretEngine.defaultPort,
    List<Feature> features = const [],
  }) async {
    final settings = await JsonFileSettingsStore.open(
      (await paths.create(paths.settings)).path,
    );
    final name =
        settings.get<String>('device.name') ??
        '${await _computerName()} · Terminal';

    return FerretEngine.create(
      secrets: await _secrets(),
      settings: settings,
      device: LocalDevice(
        name: name,
        platform: _platform(),
        formFactor: .FORM_FACTOR_DESKTOP,
        model: 'ferret-cli',
      ),
      features: features,
      port: port,
    );
  }

  /// Opens only the identity and pairings, without touching the network.
  Future<(DeviceIdentity, TrustStore)> openStores() async {
    final secrets = await _secrets();
    return (
      await DeviceIdentity.loadOrCreate(secrets),
      await TrustStore.open(secrets),
    );
  }

  Future<SecretStore> _secrets() async =>
      FileSecretStore((await paths.create(paths.secrets)).path);

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
