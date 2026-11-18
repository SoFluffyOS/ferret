import 'dart:io';

/// Where a picture of the mirrored screen goes, and how it is shown in its
/// folder afterwards: `Downloads/Ferret`, next to the files other devices
/// send.
class ScreenshotStore {
  ScreenshotStore({
    String? downloads,
    Future<void> Function(String executable, List<String> arguments)? run,
  }) : _downloads = downloads ?? _homeDownloads(),
       _run = run ?? _runDetached;

  static const _folderName = 'Ferret';

  final String _downloads;
  final Future<void> Function(String executable, List<String> arguments) _run;

  String get folder => '$_downloads${Platform.pathSeparator}$_folderName';

  /// The folder as people read it.
  String get folderLabel => 'Downloads › $_folderName';

  /// A file for [deviceName]'s screen at [at], named so that two taken in
  /// a row sort in order and never collide.
  String pathFor(String deviceName, DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');

    final safeName = deviceName.replaceAll(
      RegExp(r'[\\/:*?"<>|\x00-\x1F]'),
      ' ',
    );
    final day = '${at.year}-${two(at.month)}-${two(at.day)}';
    final time = '${two(at.hour)}.${two(at.minute)}.${two(at.second)}';
    return '$folder${Platform.pathSeparator}${safeName.trim()} $day at $time.png';
  }

  /// Opens the folder with the file at [path] picked out, where the
  /// system's file manager can do that.
  Future<void> reveal(String path) async {
    if (Platform.isMacOS) {
      await _run('open', ['-R', path]);
      return;
    }

    if (Platform.isWindows) {
      await _run('explorer', ['/select,', path]);
      return;
    }

    await _run('xdg-open', [File(path).parent.path]);
  }

  static String _homeDownloads() {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    return '$home${Platform.pathSeparator}Downloads';
  }

  static Future<void> _runDetached(
    String executable,
    List<String> arguments,
  ) async {
    await Process.start(executable, arguments, mode: .detached);
  }
}
