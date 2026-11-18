import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:engine/engine.dart';
import 'package:ferret_cli/cli_environment.dart';

/// Pairs with a device from its link, or by address and comparing codes.
class PairCommand extends Command<int> {
  PairCommand(this._environment);

  final CliEnvironment _environment;

  @override
  String get name => 'pair';

  @override
  String get description =>
      'Pair with a device: ferret pair <ferret://pair link> or ferret pair <host[:port]>.';

  @override
  String get invocation => 'ferret pair <link or host[:port]>';

  @override
  Future<int> run() async {
    final target = argResults?.rest.firstOrNull;
    if (target == null) {
      usageException(
        'Give the pairing link or the address of the other device.',
      );
    }

    final engine = await _environment.createEngine();
    await engine.start();

    try {
      final outcome = await _pair(engine, target);
      return _report(outcome);
    } finally {
      await engine.stop();
    }
  }

  Future<PairingOutcome> _pair(FerretEngine engine, String target) {
    if (PairingCodes.parseOffer(target) case final offer?) {
      return engine.pairWithOffer(offer);
    }

    final separator = target.lastIndexOf(':');
    final (host, port) = switch (separator > 0) {
      true => (
        target.substring(0, separator),
        int.tryParse(target.substring(separator + 1)) ??
            FerretEngine.defaultPort,
      ),
      false => (target, FerretEngine.defaultPort),
    };
    return engine.pairWithAddress(
      host,
      port,
      onCode: (code) => stdout.writeln(
        'Check that the other device shows $code, then accept there.',
      ),
    );
  }

  int _report(PairingOutcome outcome) {
    switch (outcome) {
      case Paired(:final device):
        stdout.writeln('Paired with ${device.name}.');
        return 0;
      case PairingFailed(:final reason, :final detail):
        stderr.writeln(
          'Pairing failed: ${reason.name}${switch (detail.isEmpty) {
            true => '',
            false => ' ($detail)',
          }}',
        );
        return 1;
    }
  }
}
