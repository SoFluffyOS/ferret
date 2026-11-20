import 'dart:io';

/// The app that turned on macOS secure input, by name, so a blocked switch
/// can say "Bitwarden" instead of a password field the person can't see.
/// macOS keeps its process id in the I/O registry while it is on.
class SecureInputHolder {
  const SecureInputHolder._();

  static final _pid = RegExp(r'"kCGSSessionSecureInputPID"\s*=\s*(\d+)');

  /// Null off macOS, when nothing holds it, or when it is the login window.
  static Future<String?> find() async {
    if (!Platform.isMacOS) {
      return null;
    }

    try {
      final registry = await Process.run('/usr/sbin/ioreg', [
        '-l',
        '-w',
        '0',
        '-d',
        '1',
      ]);
      final pid = _pid.firstMatch('${registry.stdout}')?.group(1);
      if (pid == null || int.parse(pid) == 0) {
        return null;
      }

      final process = await Process.run('/bin/ps', ['-p', pid, '-o', 'comm=']);
      return appName('${process.stdout}'.trim());
    } on Object {
      return null;
    }
  }

  /// "Bitwarden" from `/Applications/Bitwarden.app/Contents/MacOS/Bitwarden`;
  /// the outermost app wins, so a helper inside an app names the app.
  static String? appName(String path) {
    if (path.isEmpty) {
      return null;
    }

    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    final app = parts.where((part) => part.endsWith('.app')).firstOrNull;
    final name = switch (app) {
      final app? => app.substring(0, app.length - '.app'.length),
      null => parts.lastOrNull ?? '',
    };
    if (name.isEmpty || name == 'loginwindow') {
      return null;
    }

    return name;
  }
}
