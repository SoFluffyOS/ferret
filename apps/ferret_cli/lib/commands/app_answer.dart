import 'dart:convert';

import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/exit_codes.dart';

/// Prints what the running app answered to a command, as text or JSON,
/// and picks the exit code.
abstract final class AppAnswer {
  static const String _notRunning =
      "The Ferret app isn't running on this computer. Open it, then try again.";

  /// Prints [answer] and returns the exit code. [describe] says what a
  /// successful answer means in words.
  static int report(
    CliEnvironment environment,
    Map<String, Object?>? answer, {
    required bool asJson,
    required String Function(Map<String, Object?> answer) describe,
  }) {
    if (answer == null) {
      if (asJson) {
        environment.out.writeln(
          jsonEncode({'ok': false, 'error': 'app_not_running'}),
        );
      }
      environment.err.writeln(_notRunning);
      return ExitCodes.unavailable;
    }

    final code = exitCodeOf(answer);
    if (asJson) {
      environment.out.writeln(jsonEncode(answer));
      return code;
    }

    if (code == ExitCodes.ok) {
      environment.out.writeln(describe(answer));
      return code;
    }

    environment.err.writeln(problemOf(answer));
    return code;
  }

  static int exitCodeOf(Map<String, Object?> answer) {
    if (answer['ok'] == true) {
      return ExitCodes.ok;
    }

    return switch (answer['error']) {
      'not_connected' => ExitCodes.notConnected,
      'no_clip' => ExitCodes.noInput,
      'nothing_to_send' => ExitCodes.usage,
      _ => ExitCodes.failed,
    };
  }

  static String problemOf(Map<String, Object?> answer) {
    final device = answer['device'];
    return switch ((answer['error'], answer['result'])) {
      ('unknown_device', _) =>
        'No paired device has that name. "ferret-cli devices" lists them.',
      ('ambiguous_device', _) =>
        'Several devices fit that name: '
            '${_names(answer['candidates'])}. Use more of the name.',
      ('not_connected', _) =>
        "$device isn't connected right now. It rings once it's back on the "
            'same network.',
      ('no_clip', _) => 'No clip has arrived from your devices yet.',
      ('nothing_to_send', _) => 'There is no text to send.',
      ('not_supported', _) => "This Ferret can't do that.",
      ('not_a_link', _) =>
        "That isn't a web or map link. Start it with https:// or geo:.",
      ('unknown_action', _) =>
        '$device has no action by that name. '
            '"ferret-cli action <computer>" lists them.',
      (_, 'denied') => 'Someone at $device said no.',
      (_, 'declined') => 'Someone at $device said not now.',
      (_, 'unsupported') => "$device can't take that kind of picture.",
      (_, 'noPermission') =>
        "$device didn't let Ferret use its camera. Allow it in its settings.",
      (_, 'expired') => 'Nobody took the photo on $device in time.',
      (_, 'offline') => "$device isn't connected right now.",
      (_, 'not_answered') => 'Nobody answered on $device.',
      (_, 'busy') => '$device is busy with another request.',
      (_, 'turned_off') => 'Actions are turned off on $device.',
      (_, 'cancelled') => 'Someone at $device cancelled it.',
      (_, 'timed_out') => 'It ran too long on $device and was stopped.',
      (_, 'failed') when answer['exit_code'] != null =>
        'It ended with code ${answer['exit_code']} on $device.',
      (_, 'notSupported') => "Ferret on $device can't ring. Update it there.",
      (_, 'noSound') => "$device couldn't play a sound.",
      (_, 'noDevices') => 'No connected device takes clipboard items.',
      (_, 'duplicate') => 'That text was just sent.',
      (_, 'tooLarge') => 'That text is over the size limit.',
      (_, 'sensitive') => 'That text is marked private, so it stays here.',
      (_, 'unreachable') => "$device didn't answer.",
      (_, 'not_allowed') =>
        "$device doesn't take notices from this computer's scripts yet. On "
            "$device, open this computer's page and turn on Let scripts on "
            'it show notices here.',
      (_, 'too_many') =>
        '$device got too many notices in a minute. Try again in a moment.',
      (_, 'not_supported') =>
        "Ferret on $device can't do that. Update it there.",
      _ => "It didn't work.",
    };
  }

  static String _names(Object? names) => switch (names) {
    final List<Object?> list => list.join(', '),
    _ => '',
  };
}
