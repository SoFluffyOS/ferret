import 'dart:io';

/// Whether Ferret runs inside WSL on Windows with its default NAT network.
/// Discovery's multicast never gets into that virtual machine, so nothing
/// nearby shows up, however fine the network looks from inside. WSL's
/// mirrored networking shares Windows' own network and doesn't have this
/// problem.
class WslNetwork {
  WslNetwork({
    Map<String, String>? environment,
    Future<String?> Function(String path)? readFile,
    Future<String?> Function()? networkingMode,
  }) : _environment = environment ?? Platform.environment,
       _readFile = readFile ?? _read,
       _networkingMode = networkingMode ?? _askWslinfo;

  /// Never inside WSL, for checks that stand in for another computer.
  WslNetwork.none()
    : _environment = const {},
      _readFile = _nothing,
      _networkingMode = _noMode;

  static const procVersion = '/proc/version';

  final Map<String, String> _environment;
  final Future<String?> Function(String path) _readFile;

  /// What `wslinfo --networking-mode` says, such as `nat` or `mirrored`.
  /// Null when it can't tell, as on WSL versions without `wslinfo`.
  final Future<String?> Function() _networkingMode;

  /// Whether this is WSL, and not on mirrored networking. When WSL can't
  /// say which networking it uses, it counts as NAT, the default.
  Future<bool> keepsDevicesApart() async {
    if (!await isWsl()) {
      return false;
    }

    final mode = await _networkingMode();
    return mode?.trim().toLowerCase() != 'mirrored';
  }

  /// WSL sets `WSL_DISTRO_NAME` in every shell it starts, and its kernel
  /// says "microsoft" in its version.
  Future<bool> isWsl() async {
    if (_environment['WSL_DISTRO_NAME']?.isNotEmpty ?? false) {
      return true;
    }

    final version = await _readFile(procVersion) ?? '';
    return version.toLowerCase().contains('microsoft');
  }

  static Future<String?> _read(String path) async {
    try {
      return await File(path).readAsString();
    } on FileSystemException {
      return null;
    }
  }

  static Future<String?> _nothing(String path) async => null;

  static Future<String?> _noMode() async => null;

  static Future<String?> _askWslinfo() async {
    try {
      final result = await Process.run('wslinfo', [
        '--networking-mode',
      ]).timeout(const Duration(seconds: 3));
      if (result.exitCode != 0) {
        return null;
      }

      return '${result.stdout}';
    } on Object {
      return null;
    }
  }
}
