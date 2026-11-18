import 'dart:io';

import 'package:path/path.dart' as p;

/// Where Ferret keeps its files on this device.
///
/// On computers everything lives in `<home>/.sofluffy/ferret`, like other
/// SoFluffy apps. On phones it is the app's own private folder, which only
/// the platform can tell (see [resolve]). `FERRET_HOME` moves the whole
/// root anywhere, for tests and power users.
class FerretPaths {
  FerretPaths(this.root, {p.Context? context}) : _path = context ?? p.context;

  /// The environment variable that replaces [root] on every platform.
  static const String homeVariable = 'FERRET_HOME';

  static const Set<String> _phones = {'android', 'ios'};

  /// The folder everything else sits in.
  final String root;

  final p.Context _path;

  /// Finds [root] for this device: `FERRET_HOME` when set, then
  /// `<home>/.sofluffy/ferret` on computers (home is `USERPROFILE` on
  /// Windows, `HOME` elsewhere), and [phoneDirectory] on Android and iOS.
  ///
  /// [environment] and [operatingSystem] default to this process's; tests
  /// pass their own. Throws a [StateError] when no root can be found.
  static Future<FerretPaths> resolve({
    Map<String, String>? environment,
    String? operatingSystem,
    Future<String> Function()? phoneDirectory,
  }) async {
    final variables = environment ?? Platform.environment;
    final system = operatingSystem ?? Platform.operatingSystem;
    final context = switch (system) {
      'windows' => p.Context(style: p.Style.windows),
      _ => p.Context(style: p.Style.posix),
    };

    if (variables[homeVariable] case final custom? when custom.isNotEmpty) {
      return FerretPaths(custom, context: context);
    }

    if (_phones.contains(system)) {
      if (phoneDirectory == null) {
        throw StateError('No app folder given for $system');
      }

      return FerretPaths(await phoneDirectory(), context: context);
    }

    final home = switch (system) {
      'windows' => variables['USERPROFILE'] ?? variables['HOME'],
      _ => variables['HOME'],
    };
    if (home == null || home.isEmpty) {
      throw StateError('No home folder for $system');
    }

    return FerretPaths(
      context.join(home, '.sofluffy', 'ferret'),
      context: context,
    );
  }

  /// `settings.json`, the app's preferences.
  String get settings => _path.join(root, 'settings');

  /// The device key, the paired devices and other keys, readable only by
  /// this user.
  String get secrets => _path.join(root, 'secrets');

  /// Helpers Ferret downloads, such as Android's platform tools and
  /// scrcpy's server.
  String get tools => _path.join(root, 'tools');

  /// Files Ferret can rebuild or throw away, such as unfinished downloads.
  String get cache => _path.join(root, 'cache');

  String get logs => _path.join(root, 'logs');

  /// A feature's own saved files, such as Messages' saved texts.
  String feature(String featureId) => _path.join(root, 'features', featureId);

  /// Paths rooted in a subfolder, such as the command line's own `cli`
  /// identity next to the app's.
  FerretPaths nested(String name) =>
      FerretPaths(_path.join(root, name), context: _path);

  /// Creates [folder] (one of the paths above) with every missing parent,
  /// readable only by this user on macOS and Linux. Phones keep each app's
  /// folders private already, and iOS can't start `chmod` at all.
  Future<Directory> create(String folder) async {
    final directory = await Directory(folder).create(recursive: true);
    if (!Platform.isMacOS && !Platform.isLinux) {
      return directory;
    }

    final private = [
      for (
        var current = folder;
        _path.isWithin(root, current) || _path.equals(root, current);
        current = _path.dirname(current)
      )
        current,
    ];
    await Process.run('chmod', ['700', ...private]);
    return directory;
  }
}
