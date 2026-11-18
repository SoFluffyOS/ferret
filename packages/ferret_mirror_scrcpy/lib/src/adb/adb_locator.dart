import 'dart:io';

import 'package:path/path.dart' as p;

/// Finds an adb already on this computer: on the PATH, in the Android SDK,
/// or where the usual installers put it.
class AdbLocator {
  AdbLocator({
    Map<String, String>? environment,
    String? operatingSystem,
    bool Function(String path)? exists,
    this.extraDirectories = const [],
  }) : _environment = environment ?? Platform.environment,
       _operatingSystem = operatingSystem ?? Platform.operatingSystem,
       _exists = exists ?? _fileExists;

  final Map<String, String> _environment;
  final String _operatingSystem;
  final bool Function(String path) _exists;

  /// Looked in first, such as the folder Ferret downloaded adb into.
  final List<String> extraDirectories;

  bool get _isWindows => _operatingSystem == 'windows';

  String get executableName {
    if (_isWindows) {
      return 'adb.exe';
    }

    return 'adb';
  }

  p.Context get _path {
    if (_isWindows) {
      return p.windows;
    }

    return p.posix;
  }

  /// The path of adb, or null when there is none.
  String? find() {
    for (final directory in _directories()) {
      final candidate = _path.join(directory, executableName);
      if (_exists(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  Iterable<String> _directories() sync* {
    yield* extraDirectories;
    yield* _pathDirectories();
    for (final variable in const ['ANDROID_HOME', 'ANDROID_SDK_ROOT']) {
      if (_environment[variable] case final sdk? when sdk.isNotEmpty) {
        yield _path.join(sdk, 'platform-tools');
      }
    }
    yield* _usualDirectories();
  }

  Iterable<String> _pathDirectories() {
    final separator = switch (_isWindows) {
      true => ';',
      false => ':',
    };
    final pathVariable = _environment['PATH'] ?? _environment['Path'] ?? '';
    return pathVariable.split(separator).where((entry) => entry.isNotEmpty);
  }

  Iterable<String> _usualDirectories() {
    return switch (_operatingSystem) {
      'macos' => [
        if (_environment['HOME'] case final home?)
          _path.join(home, 'Library', 'Android', 'sdk', 'platform-tools'),
        '/opt/homebrew/bin',
        '/usr/local/bin',
      ],
      'windows' => [
        if (_environment['LOCALAPPDATA'] case final localAppData?)
          _path.join(localAppData, 'Android', 'Sdk', 'platform-tools'),
        if (_environment['USERPROFILE'] case final profile?)
          _path.join(profile, 'scoop', 'shims'),
        r'C:\Program Files (x86)\Android\android-sdk\platform-tools',
        r'C:\platform-tools',
      ],
      _ => [
        if (_environment['HOME'] case final home?)
          _path.join(home, 'Android', 'Sdk', 'platform-tools'),
        '/usr/bin',
        '/usr/local/bin',
        '/usr/lib/android-sdk/platform-tools',
      ],
    };
  }

  static bool _fileExists(String path) => File(path).existsSync();
}
