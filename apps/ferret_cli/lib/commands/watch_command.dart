import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/watch_line.dart';
import 'package:ferret_cli/exit_codes.dart';

/// `ferret-cli watch`: prints what happens in the Ferret app running here,
/// one line per event, until you stop it or the app quits. With `--json`,
/// one JSON object per line (see the Scripting docs for the schema).
class WatchCommand extends Command<int> {
  WatchCommand(this._environment, {Stream<Object?>? stop}) : _stop = stop {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'One JSON object per line, for scripts.',
      )
      ..addFlag(
        'include-content',
        negatable: false,
        help:
            'Also print copied text and notification text, when the device '
            "shows previews here and the item isn't marked private.",
      )
      ..addMultiOption(
        'type',
        valueHelp: 'device,battery,…',
        help:
            'Only these events. A name matches the events under it: '
            '"device" matches device.connected and device.disconnected.',
      );
  }

  final CliEnvironment _environment;
  final Stream<Object?>? _stop;

  static const String _notRunning =
      "The Ferret app isn't running on this computer. Open it, then try again.";

  @override
  String get name => 'watch';

  @override
  String get description =>
      'Print what happens with your devices as it happens: connected, '
      'battery, files, clips, notifications, calls, transfers.';

  @override
  Future<int> run() async {
    final asJson = argResults?['json'] == true;
    final types = switch (argResults?['type']) {
      final List<String> list => list,
      _ => const <String>[],
    };
    final events = await AppControl(_environment.appRoot).watch({
      'include_content': argResults?['include-content'] == true,
      'types': types,
    });
    if (events == null) {
      _environment.err.writeln(_notRunning);
      return ExitCodes.unavailable;
    }

    final stopped = Completer<int>();
    final subscription = events.listen(
      (event) => _print(event, asJson: asJson),
      onDone: () {
        if (!stopped.isCompleted) {
          _environment.err.writeln('The Ferret app stopped.');
          stopped.complete(ExitCodes.unavailable);
        }
      },
    );
    final stop = (_stop ?? _interrupts()).listen((_) {
      if (!stopped.isCompleted) {
        stopped.complete(ExitCodes.ok);
      }
    });
    final code = await stopped.future;
    await stop.cancel();
    await subscription.cancel();
    return code;
  }

  void _print(Map<String, Object?> event, {required bool asJson}) {
    if (event case {'ok': false, 'error': 'not_supported'}) {
      _environment.err.writeln("This Ferret can't stream events. Update it.");
      return;
    }

    if (asJson) {
      _environment.out.writeln(jsonEncode(event));
      return;
    }

    if (event['type'] == 'ready') {
      _environment.err.writeln('Watching. Press Ctrl-C to stop.');
      return;
    }

    _environment.out.writeln(WatchLine.of(event));
  }

  static Stream<Object?> _interrupts() {
    if (Platform.isWindows) {
      return ProcessSignal.sigint.watch();
    }

    final signals = StreamController<Object?>();
    final subscriptions = [
      ProcessSignal.sigint.watch().listen(signals.add),
      ProcessSignal.sigterm.watch().listen(signals.add),
    ];
    signals.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
    return signals.stream;
  }
}
