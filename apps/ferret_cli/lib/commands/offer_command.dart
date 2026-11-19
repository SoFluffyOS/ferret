import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ferret_cli/cli_environment.dart';

/// Shows a one-time pairing link and waits for another device to use it.
class OfferCommand extends Command<int> {
  OfferCommand(this._environment);

  final CliEnvironment _environment;

  @override
  String get name => 'offer';

  @override
  String get description =>
      'Show a pairing link for another device to open or scan.';

  @override
  Future<int> run() async {
    final engine = await _environment.createEngine();
    await engine.start();

    final offer = await engine.createPairingOffer();
    stdout
      ..writeln('Open this link with Ferret on your other device:')
      ..writeln()
      ..writeln('  ${offer.qrText}')
      ..writeln()
      ..writeln('Waiting for up to 5 minutes…');

    try {
      final device = await offer.paired.timeout(
        offer.expiresAt.difference(DateTime.now()),
      );
      stdout.writeln('Paired with ${device.name}.');
      return 0;
    } on TimeoutException {
      stderr.writeln('The link expired. Run "ferret-cli offer" again.');
      return 1;
    } finally {
      await engine.stop();
    }
  }
}
