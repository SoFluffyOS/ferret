import 'dart:convert';
import 'dart:io';

import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the rules are in place when netsh finds each one', () async {
    final asked = <String>[];
    final rules = WindowsFirewallRules(
      run: (executable, arguments) async {
        asked.add(arguments.last);
        return ProcessResult(0, 0, '', '');
      },
    );

    expect(await rules.areInstalled(), isTrue);
    expect(asked, [
      for (final rule in WindowsFirewallRules.rules) 'name=${rule.name}',
    ]);
  });

  test('a missing rule or a missing netsh means not in place', () async {
    final missing = WindowsFirewallRules(
      run: (executable, arguments) async =>
          ProcessResult(0, 1, 'No rules match the specified criteria.', ''),
    );
    final noNetsh = WindowsFirewallRules(
      run: (executable, arguments) => throw const ProcessException('netsh', []),
    );

    expect(await missing.areInstalled(), isFalse);
    expect(await noNetsh.areInstalled(), isFalse);
  });

  test('allowing asks for elevation once and adds every rule', () async {
    final elevated = <List<String>>[];
    var added = false;
    final rules = WindowsFirewallRules(
      run: (executable, arguments) async {
        if (executable == 'powershell.exe') {
          elevated.add(arguments);
          added = true;
        }
        return ProcessResult(
          0,
          switch (added) {
            true => 0,
            false => 1,
          },
          '',
          '',
        );
      },
    );

    final allowed = await rules.allow();

    expect(allowed, isTrue);
    expect(elevated, hasLength(1));
    final encoded = elevated.single.last;
    final bytes = base64.decode(encoded);
    final script = String.fromCharCodes([
      for (var index = 0; index < bytes.length; index += 2)
        bytes[index] | bytes[index + 1] << 8,
    ]);
    expect(script, startsWith('Start-Process -FilePath cmd.exe -Verb RunAs'));
    expect(
      script,
      contains(
        'netsh advfirewall firewall add rule name="Ferret (47640/tcp)" '
        'dir=in action=allow protocol=TCP localport=47640 profile=private',
      ),
    );
    expect(script, contains('localport=47642-47649'));
    expect(script, contains('localport=47641'));
    expect(script, contains('localport=5353'));
  });

  test('networks come back by name with their category', () async {
    final rules = WindowsFirewallRules(
      run: (executable, arguments) async => ProcessResult(
        0,
        0,
        'Wi-Fi|Public\r\nvEthernet (WSL)|Private\r\n',
        '',
      ),
    );

    expect(await rules.networkCategories(), {
      'Wi-Fi': 'Public',
      'vEthernet (WSL)': 'Private',
    });
  });

  test('a block rule for the program counts; none, or no PowerShell, '
      'does not', () async {
    WindowsFirewallRules answering(String output) => WindowsFirewallRules(
      run: (executable, arguments) async => ProcessResult(0, 0, output, ''),
    );
    final noPowerShell = WindowsFirewallRules(
      run: (executable, arguments) =>
          throw const ProcessException('powershell.exe', []),
    );

    expect(await answering('2\r\n').blocksProgram(r'C:\F\ferret.exe'), isTrue);
    expect(await answering('0\r\n').blocksProgram(r'C:\F\ferret.exe'), isFalse);
    expect(await noPowerShell.blocksProgram(r'C:\F\ferret.exe'), isFalse);
  });

  test('the block check quotes the path for PowerShell', () {
    final script = WindowsFirewallRules.blockRulesScript(
      r"C:\O'Neil\ferret.exe",
    );

    expect(script, startsWith(r"$p = 'C:\O''Neil\ferret.exe'; "));
    expect(script, contains('-Action Block'));
  });

  test('a declined UAC prompt reads as not allowed', () async {
    final rules = WindowsFirewallRules(
      run: (executable, arguments) async => ProcessResult(0, 1, '', ''),
    );

    expect(await rules.allow(), isFalse);
  });

  test('the installer adds the same rules as the app', () async {
    final script = await File(
      '../../packaging/windows/ferret.iss',
    ).readAsString();

    for (final rule in WindowsFirewallRules.rules) {
      expect(script, contains('name="${rule.name}"'));
      expect(script, contains('localport=${rule.ports}'));
    }
    expect(script, contains('profile=${WindowsFirewallRules.profile}'));
  });
}
