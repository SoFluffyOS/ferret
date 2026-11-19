import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/app_answer.dart';
import 'package:ferret_cli/exit_codes.dart';
import 'package:ferret_wake/ferret_wake.dart';
import 'package:protocol/protocol.dart';

/// `ferret-cli wake <device>`: wakes a sleeping computer with a
/// Wake-on-LAN magic packet. Asks the Ferret app running here first, since
/// it knows every paired computer; without it, wakes the computers paired
/// with `ferret-cli daemon`, or a MAC address given as is.
class WakeCommand extends Command<int> {
  WakeCommand(this._environment, {WakeSender sender = const UdpWakeSender()})
    : _sender = sender {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Print the answer as JSON, for scripts.',
    );
  }

  final CliEnvironment _environment;
  final WakeSender _sender;

  static const String appCommand = 'wake';

  @override
  String get name => 'wake';

  @override
  String get description =>
      'Wake a sleeping computer over the network (Wake-on-LAN).';

  @override
  String get invocation => 'ferret-cli wake <device or MAC address>';

  bool get _asJson => argResults?['json'] == true;

  @override
  Future<int> run() async {
    final words = argResults?.rest ?? const [];
    if (words.isEmpty) {
      usageException('Name the computer to wake, or give its MAC address.');
    }

    final query = words.join(' ');
    if (MacAddress.parse(query) case final mac?) {
      return _send(
        MacAddress.format(mac),
        WakeInfo(interfaces: [WakeInterface(mac: mac)]),
      );
    }

    final answer = await AppControl(
      _environment.appRoot,
    ).ask(appCommand, {'device': query});
    if (answer != null && answer['error'] != 'unknown_command') {
      return _reportApp(answer);
    }

    return _wakeFromOwnPairings(query);
  }

  int _reportApp(Map<String, Object?> answer) {
    final device = answer['device'];
    final problem = switch (answer['error']) {
      'no_wake_info' =>
        "$device hasn't told Ferret how to wake it. Open Ferret on it once, "
            'with a cable or Wi-Fi connected.',
      'already_connected' => '$device is already awake.',
      'not_sent' => "Couldn't send the wake signal. Is this computer online?",
      _ => null,
    };
    if (problem != null && !_asJson) {
      _environment.err.writeln(problem);
      return ExitCodes.failed;
    }

    return AppAnswer.report(
      _environment,
      answer,
      asJson: _asJson,
      describe: (answer) => _waking('${answer['device']}'),
    );
  }

  /// Wakes a computer paired with this command line's own Ferret, such as
  /// on a home server that runs `ferret-cli daemon` and no app.
  Future<int> _wakeFromOwnPairings(String query) async {
    final (_, trustStore) = await _environment.openStores();
    final wanted = query.trim().toLowerCase();
    final wakeable = [
      for (final device in trustStore.devices)
        if (device.wake?.interfaces.isNotEmpty ?? false) device,
    ];
    final exact = wakeable.where((device) => _named(device) == wanted);
    final starts = wakeable.where(
      (device) => _named(device).startsWith(wanted),
    );
    final found = switch ((exact.toList(), starts.toList())) {
      ([final device], _) => [device],
      (_, final candidates) => candidates,
    };

    return switch (found) {
      [] => _fail(
        'unknown_device',
        'No computer that told Ferret how to wake it has that name. '
            'Is the Ferret app open? You can also give a MAC address.',
      ),
      [final device] => _send(
        device.name,
        device.wake ?? WakeInfo(),
        lastAddress: device.lastHost,
      ),
      final several => _fail(
        'ambiguous_device',
        'Several computers fit that name: '
            '${several.map((device) => device.name).join(', ')}.',
      ),
    };
  }

  String _named(TrustedDevice device) => device.name.toLowerCase();

  Future<int> _send(
    String name,
    WakeInfo info, {
    String? lastAddress,
  }) async {
    final packets = WakePackets.of(info, lastAddress: lastAddress);
    final sent = await _sender.send(packets);
    if (sent.isEmpty) {
      return _fail('not_sent', "Couldn't send the wake signal.");
    }

    if (_asJson) {
      _environment.out.writeln(
        jsonEncode({'ok': true, 'device': name, 'result': 'sent'}),
      );
      return ExitCodes.ok;
    }

    _environment.out.writeln(_waking(name));
    return ExitCodes.ok;
  }

  int _fail(String error, String message) {
    if (_asJson) {
      _environment.out.writeln(jsonEncode({'ok': false, 'error': error}));
      return ExitCodes.failed;
    }

    _environment.err.writeln(message);
    return ExitCodes.failed;
  }

  static String _waking(String name) =>
      'Sent the wake signal to $name. It connects within a minute when '
      'Wake-on-LAN is on.';
}
