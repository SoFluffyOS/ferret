import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/identity/identity.dart';
import 'package:transport/transport.dart';

/// Whether something of this account listens for connections on a TCP port
/// of this computer.
typedef ListenerCheck = Future<bool> Function(int port);

/// Tells Ferret that this same account runs on this computer, such as its
/// ferret-cli or a copy started with another data folder, apart from Ferret
/// in another account.
///
/// Another account's files and processes are out of this account's reach:
/// an identity it can read, or a listener it can see, is its own. When
/// neither can be checked, the announcer counts as another account.
class SameAccount {
  SameAccount({this.siblingSecrets = const [], ListenerCheck? listens})
    : _listens = listens ?? listensHere;

  /// Secrets folders of this account's other Ferret pieces, such as
  /// ferret-cli's `~/.sofluffy/ferret/cli/secrets`.
  final List<String> siblingSecrets;

  final ListenerCheck _listens;
  final Set<String> _siblingIds = {};

  /// Whether [peer], announcing from this computer, runs in this account.
  Future<bool> runs(DiscoveredPeer peer) async {
    if (_siblingIds.contains(peer.deviceId)) {
      return true;
    }

    _siblingIds.addAll(await _readSiblingIds());
    if (_siblingIds.contains(peer.deviceId)) {
      return true;
    }

    try {
      return await _listens(peer.port);
    } on Object {
      return false;
    }
  }

  /// Read again on each check, so a ferret-cli set up after the app
  /// started is known too.
  Future<Set<String>> _readSiblingIds() async {
    final ids = <String>{};
    for (final folder in siblingSecrets) {
      try {
        final saved = await FileSecretStore(
          folder,
        ).read(DeviceIdentity.storageKey);
        if (saved == null) {
          continue;
        }

        if (KeychainIdentityStore.markedDeviceId(saved) case final id?) {
          ids.add(id);
          continue;
        }

        final identity = await DeviceIdentity.fromSaved(saved);
        ids.add(identity.deviceId);
      } on Object {
        continue;
      }
    }

    return ids;
  }

  /// Whether a process of this account listens on [port], by what the
  /// system shows this account: its own processes on a Mac and Windows,
  /// and the owner of each socket on Linux.
  static Future<bool> listensHere(int port) async {
    try {
      if (Platform.isMacOS) {
        return await _listensOnMac(port);
      }

      if (Platform.isLinux) {
        return await _listensOnLinux(port);
      }

      if (Platform.isWindows) {
        return await _listensOnWindows(port);
      }
    } on Object {
      return false;
    }

    return false;
  }

  static Future<bool> _listensOnMac(int port) async {
    final id = await Process.run('id', ['-u']);
    final uid = '${id.stdout}'.trim();
    if (id.exitCode != 0 || uid.isEmpty) {
      return false;
    }

    final result = await Process.run('lsof', [
      '-nP',
      '-a',
      '-u',
      uid,
      '-iTCP:$port',
      '-sTCP:LISTEN',
      '-t',
    ]);
    return result.exitCode == 0 && '${result.stdout}'.trim().isNotEmpty;
  }

  static Future<bool> _listensOnLinux(int port) async {
    final status = await File('/proc/self/status').readAsLines();
    final uidLine = status.firstWhere((line) => line.startsWith('Uid:'));
    final uid = uidLine.split(RegExp(r'\s+'))[1];

    for (final table in ['/proc/net/tcp', '/proc/net/tcp6']) {
      final file = File(table);
      if (!await file.exists()) {
        continue;
      }

      for (final line in (await file.readAsLines()).skip(1)) {
        final fields = line.trim().split(RegExp(r'\s+'));
        if (fields.length < 8 || fields[3] != '0A') {
          continue;
        }

        final local = int.tryParse(fields[1].split(':').last, radix: 16);
        if (local == port && fields[7] == uid) {
          return true;
        }
      }
    }

    return false;
  }

  /// Windows names the user of another account's process only to an
  /// administrator, so a match is this account's own.
  static Future<bool> _listensOnWindows(int port) async {
    final netstat = await Process.run('netstat', ['-ano', '-p', 'TCP']);
    final netstat6 = await Process.run('netstat', ['-ano', '-p', 'TCPv6']);
    final pids = <String>{
      for (final line in '${netstat.stdout}\n${netstat6.stdout}'.split('\n'))
        ?_listenerPid(line.trim(), port),
    };

    final user = Platform.environment['USERNAME']?.toLowerCase();
    final domain = Platform.environment['USERDOMAIN']?.toLowerCase();
    if (user == null || user.isEmpty) {
      return false;
    }

    for (final pid in pids) {
      final task = await Process.run('tasklist', [
        '/FI',
        'PID eq $pid',
        '/V',
        '/FO',
        'CSV',
        '/NH',
      ]);
      final columns = '${task.stdout}'.trim().split('","');
      if (columns.length < 7) {
        continue;
      }

      final owner = columns[6].replaceAll('"', '').toLowerCase();
      if (owner == user || owner == '$domain\\$user') {
        return true;
      }
    }

    return false;
  }

  static String? _listenerPid(String line, int port) {
    final fields = line.split(RegExp(r'\s+'));
    if (fields.length < 5 || fields[0] != 'TCP' || fields[3] != 'LISTENING') {
      return null;
    }

    if (!fields[1].endsWith(':$port')) {
      return null;
    }

    return fields[4];
  }
}
