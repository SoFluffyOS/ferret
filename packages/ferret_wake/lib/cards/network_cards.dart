import 'dart:io';

import 'package:ferret_wake/cards/linux_card_facts.dart';
import 'package:ferret_wake/cards/linux_cards.dart';
import 'package:ferret_wake/cards/macos_cards.dart';
import 'package:ferret_wake/cards/network_card.dart';
import 'package:ferret_wake/cards/windows_cards.dart';

/// Runs [executable] with [arguments] and returns what it printed, or null
/// when it is missing or failed.
typedef RunCommand = Future<String?> Function(
  String executable,
  List<String> arguments,
);

/// Reads this computer's wired and Wi-Fi cards. Phones have none to share:
/// they can't be woken over the network.
class NetworkCards {
  const NetworkCards({RunCommand? run}) : _run = run ?? _runProcess;

  final RunCommand _run;

  /// The cards on macOS, Linux or Windows; empty elsewhere or when the
  /// system won't say.
  Future<List<NetworkCard>> read() async {
    try {
      if (Platform.isMacOS) {
        return await _macos();
      }

      if (Platform.isLinux) {
        return await _linux();
      }

      if (Platform.isWindows) {
        return await _windows();
      }
    } on Object {
      return const [];
    }

    return const [];
  }

  Future<List<NetworkCard>> _macos() async => MacosCards.parse(
    ifconfig: await _run('/sbin/ifconfig', const []) ?? '',
    hardwarePorts:
        await _run('/usr/sbin/networksetup', const [
          '-listallhardwareports',
        ]) ??
        '',
    pmset: await _run('/usr/bin/pmset', const ['-g']) ?? '',
  );

  Future<List<NetworkCard>> _linux() async {
    final ipAddr = await _run('ip', const ['-o', '-4', 'addr', 'show']) ?? '';
    final facts = <String, LinuxCardFacts>{};
    for (final name in LinuxCards.names(ipAddr)) {
      final folder = '/sys/class/net/$name';
      final mac = File('$folder/address');
      if (!mac.existsSync()) {
        continue;
      }

      facts[name] = LinuxCardFacts(
        mac: mac.readAsStringSync().trim(),
        isWireless:
            Directory('$folder/wireless').existsSync() ||
            FileSystemEntity.isLinkSync('$folder/phy80211'),
        isHardware: FileSystemEntity.isLinkSync('$folder/device'),
        ethtool:
            await _run('ethtool', [name]) ??
            await _run('/usr/sbin/ethtool', [name]),
      );
    }

    return LinuxCards.parse(ipAddr, facts);
  }

  Future<List<NetworkCard>> _windows() async => WindowsCards.parse(
    await _run('powershell', const [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          WindowsCards.script,
        ]) ??
        '',
  );

  static Future<String?> _runProcess(
    String executable,
    List<String> arguments,
  ) async {
    try {
      final result = await Process.run(executable, arguments);
      if (result.exitCode != 0) {
        return null;
      }

      return '${result.stdout}';
    } on ProcessException {
      return null;
    }
  }
}
