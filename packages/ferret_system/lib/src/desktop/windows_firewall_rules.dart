import 'dart:convert';
import 'dart:io';

import 'package:ferret_system/src/desktop/start_at_login.dart';

/// One inbound port Ferret needs open in Windows Firewall.
typedef WindowsFirewallRule = ({String name, String protocol, int port});

/// Ferret's inbound rules in Windows Firewall: its connection port,
/// discovery and mDNS, on Private networks only.
///
/// The installer adds the same rules (`packaging/windows/ferret.iss`), so
/// the app can tell whether they are there and add them itself with one
/// UAC prompt when they aren't.
class WindowsFirewallRules {
  WindowsFirewallRules({RunProcess? run}) : _run = run ?? Process.run;

  static const List<WindowsFirewallRule> rules = [
    (name: 'Ferret (47640/tcp)', protocol: 'TCP', port: 47640),
    (name: 'Ferret discovery (47641/udp)', protocol: 'UDP', port: 47641),
    (name: 'Ferret mDNS (5353/udp)', protocol: 'UDP', port: 5353),
  ];

  /// Rules apply on networks Windows calls Private. A Public network (a
  /// café, a new Wi-Fi Windows wasn't told about) stays closed.
  static const profile = 'private';

  final RunProcess _run;

  /// The `netsh` arguments that add [rule].
  static List<String> addArguments(WindowsFirewallRule rule) => [
    'advfirewall',
    'firewall',
    'add',
    'rule',
    'name=${rule.name}',
    'dir=in',
    'action=allow',
    'protocol=${rule.protocol}',
    'localport=${rule.port}',
    'profile=$profile',
  ];

  /// The `netsh` arguments that remove [rule].
  static List<String> deleteArguments(WindowsFirewallRule rule) => [
    'advfirewall',
    'firewall',
    'delete',
    'rule',
    'name=${rule.name}',
  ];

  /// Whether every rule is in place. Reading rules needs no admin rights;
  /// `netsh` exits 1 with "No rules match" for a missing one.
  Future<bool> areInstalled() async {
    for (final rule in rules) {
      final result = await _quietly('netsh', [
        'advfirewall',
        'firewall',
        'show',
        'rule',
        'name=${rule.name}',
      ]);
      if (result == null || result.exitCode != 0) {
        return false;
      }
    }

    return true;
  }

  /// Adds the rules as administrator: Windows shows its UAC prompt once
  /// for all three. Returns whether they are in place afterwards, so a
  /// declined prompt reads as false.
  Future<bool> allow() async {
    final commands = [
      for (final rule in rules) ...[
        'netsh ${deleteArguments(rule).map(_quoted).join(' ')} >nul',
        'netsh ${addArguments(rule).map(_quoted).join(' ')}',
      ],
    ].join(' & ');

    await _quietly('powershell.exe', elevatedArguments(commands));

    return areInstalled();
  }

  /// PowerShell's `Start-Process -Verb RunAs` is the ShellExecute "runas"
  /// verb: the one documented way to ask for elevation from an app that
  /// doesn't run elevated. `-Wait` lets [allow] check the result. The
  /// script goes base64-encoded, so no quote is lost between Dart,
  /// PowerShell and cmd.
  static List<String> elevatedArguments(String commands) => [
    '-NoProfile',
    '-NonInteractive',
    '-WindowStyle',
    'Hidden',
    '-EncodedCommand',
    base64.encode(_utf16le(elevationScript(commands))),
  ];

  /// The PowerShell line that runs [commands] in an elevated `cmd.exe`.
  static String elevationScript(String commands) =>
      'Start-Process -FilePath cmd.exe -Verb RunAs -WindowStyle Hidden -Wait '
      "-ArgumentList '/c ${commands.replaceAll("'", "''")}'";

  static List<int> _utf16le(String text) => [
    for (final unit in text.codeUnits) ...[unit & 0xff, unit >> 8],
  ];

  /// `name=Ferret (47640/tcp)` becomes `name="Ferret (47640/tcp)"`, the
  /// form cmd and netsh expect.
  static String _quoted(String argument) {
    final separator = argument.indexOf('=');
    if (!argument.contains(' ') || separator < 0) {
      return argument;
    }

    final key = argument.substring(0, separator + 1);
    final value = argument.substring(separator + 1);
    return '$key"$value"';
  }

  Future<ProcessResult?> _quietly(
    String executable,
    List<String> arguments,
  ) async {
    try {
      return await _run(executable, arguments);
    } on ProcessException {
      return null;
    }
  }
}
