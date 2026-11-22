import 'dart:io';

import 'package:core/core.dart';

/// An id of this computer that a copy of Ferret's data doesn't bring along:
/// the Mac's hardware UUID, Windows' MachineGuid, Linux's machine-id.
///
/// Null on phones (Android and iOS keep Ferret's keys on the device
/// themselves) and whenever it can't be read for sure: a wrong id would make
/// Ferret start over as a new device.
abstract final class MachineId {
  static Future<String?> ofThisComputer() async {
    try {
      if (Platform.isMacOS) {
        final result = await Process.run('/usr/sbin/ioreg', [
          '-rd1',
          '-c',
          'IOPlatformExpertDevice',
        ]);
        return result.exitCode == 0 ? fromIoreg('${result.stdout}') : null;
      }

      if (Platform.isWindows) {
        final result = await Process.run('reg', [
          'query',
          r'HKLM\SOFTWARE\Microsoft\Cryptography',
          '/v',
          'MachineGuid',
        ]);
        return result.exitCode == 0 ? fromReg('${result.stdout}') : null;
      }

      if (Platform.isLinux) {
        for (final path in ['/etc/machine-id', '/var/lib/dbus/machine-id']) {
          final file = File(path);
          if (await file.exists()) {
            if (fromMachineIdFile(await file.readAsString()) case final id?) {
              return id;
            }
          }
        }
      }
    } on Object catch (error) {
      printWarning('No machine id', error);
    }

    return null;
  }

  static final _uuid = RegExp(
    r'[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}',
  );

  /// The `IOPlatformUUID` in `ioreg -rd1 -c IOPlatformExpertDevice`.
  static String? fromIoreg(String output) {
    final match = RegExp(
      '"IOPlatformUUID" = "(${_uuid.pattern})"',
    ).firstMatch(output);
    return match?.group(1)?.toLowerCase();
  }

  /// The `MachineGuid` in `reg query …\Cryptography /v MachineGuid`.
  static String? fromReg(String output) {
    final match = RegExp(
      'MachineGuid\\s+REG_SZ\\s+(${_uuid.pattern})',
    ).firstMatch(output);
    return match?.group(1)?.toLowerCase();
  }

  /// The 32 hex digits of `/etc/machine-id`; an empty or unset one (a
  /// system image before first boot) isn't an id.
  static String? fromMachineIdFile(String contents) {
    final id = contents.trim().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(id) ||
        RegExp(r'^0+$').hasMatch(id)) {
      return null;
    }

    return id;
  }
}
