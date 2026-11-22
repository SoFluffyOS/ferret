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
///
/// firewalld also lists what each zone lets in to anyone, so a zone that
/// already lets Ferret in, such as Fedora Workstation's (every port from
/// 1025 and mDNS), isn't named as a problem.
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
      if (await _firewalldLetsFerretIn()) {
        return null;
      }

      return .firewalld;
    }

    return null;
  }

  /// Whether every zone in use lets in Ferret's port, its discovery and
  /// mDNS, by port, port range or service. False when it can't tell.
  Future<bool> _firewalldLetsFerretIn() async {
    final zones = await _lines(['--get-active-zones']);
    final names = [
      for (final line in zones)
        if (!line.startsWith(RegExp(r'\s')) && line.trim().isNotEmpty)
          line.trim().split(' ').first,
    ];
    if (names.isEmpty) {
      return false;
    }

    for (final zone in names) {
      final services = (await _lines([
        '--zone=$zone',
        '--list-services',
      ])).expand((line) => line.split(' ')).toSet();
      final ports = (await _lines([
        '--zone=$zone',
        '--list-ports',
      ])).expand((line) => line.split(' ')).toList();
      bool open(int port, String protocol) =>
          ports.any((entry) => _covers(entry, port, protocol));
      final ferret =
          services.contains('ferret') ||
          (open(47640, 'tcp') && open(47641, 'udp'));
      // Ferret's own service (the .deb's profile) has mDNS in it.
      final mdns =
          services.contains('ferret') ||
          services.contains('mdns') ||
          open(5353, 'udp');
      if (!ferret || !mdns) {
        return false;
      }
    }

    return true;
  }

  Future<List<String>> _lines(List<String> arguments) async {
    final result = await _run('firewall-cmd', arguments);
    if (result == null || result.exitCode != 0) {
      return const [];
    }

    return '${result.stdout}'.split('\n');
  }

  /// Whether [entry], such as `47640/tcp` or `1025-65535/udp`, covers
  /// [port] over [protocol].
  static bool _covers(String entry, int port, String protocol) {
    final [range, kind] = switch (entry.trim().split('/')) {
      [final range, final kind] => [range, kind],
      _ => ['', ''],
    };
    if (kind != protocol) {
      return false;
    }

    final bounds = [for (final bound in range.split('-')) int.tryParse(bound)];
    return switch (bounds) {
      [final only?] => only == port,
      [final low?, final high?] => low <= port && port <= high,
      _ => false,
    };
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
