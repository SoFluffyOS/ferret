import 'dart:io';

/// The firewalls a Linux desktop usually runs: ufw on Ubuntu and Mint,
/// firewalld on Fedora and openSUSE.
enum LinuxFirewallKind {
  ufw,
  firewalld;

  /// The terminal command that lets Ferret through: its own port, the
  /// ports Ferret in another account moves to, discovery and mDNS.
  String get allowCommand => switch (this) {
    .ufw =>
      'sudo ufw allow 47640/tcp && sudo ufw allow 47642:47649/tcp && '
          'sudo ufw allow 47641/udp && sudo ufw allow 5353/udp',
    .firewalld =>
      'sudo firewall-cmd --permanent --add-port=47640/tcp '
          '--add-port=47642-47649/tcp --add-port=47641/udp '
          '--add-service=mdns && '
          'sudo firewall-cmd --reload',
  };
}

/// Finds which firewall is on, without asking for root: ufw writes its
/// state to a file anyone can read, and firewalld answers `--state`.
class LinuxFirewall {
  LinuxFirewall({
    Future<String?> Function(String path)? readFile,
    Future<ProcessResult?> Function(String executable, List<String> arguments)?
    run,
  }) : _readFile = readFile ?? _read,
       _run = run ?? _runQuietly;

  static const ufwConfig = '/etc/ufw/ufw.conf';

  final Future<String?> Function(String path) _readFile;
  final Future<ProcessResult?> Function(
    String executable,
    List<String> arguments,
  )
  _run;

  /// The firewall that is on, or null when neither is.
  Future<LinuxFirewallKind?> active() async {
    final ufw = await _readFile(ufwConfig) ?? '';
    final ufwOn = ufw
        .split('\n')
        .map((line) => line.trim())
        .any((line) => line == 'ENABLED=yes');
    if (ufwOn) {
      return .ufw;
    }

    final firewalld = await _run('firewall-cmd', ['--state']);
    if (firewalld != null &&
        firewalld.exitCode == 0 &&
        '${firewalld.stdout}'.trim() == 'running') {
      return .firewalld;
    }

    return null;
  }

  static Future<String?> _read(String path) async {
    try {
      return await File(path).readAsString();
    } on FileSystemException {
      return null;
    }
  }

  static Future<ProcessResult?> _runQuietly(
    String executable,
    List<String> arguments,
  ) async {
    try {
      return await Process.run(executable, arguments);
    } on ProcessException {
      return null;
    }
  }
}
