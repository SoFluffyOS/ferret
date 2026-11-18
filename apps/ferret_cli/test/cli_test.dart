import 'dart:io';

import 'package:engine/engine.dart';
import 'package:ferret_cli/ferret_cli.dart';
import 'package:test/test.dart';

void main() {
  test('a fresh install has an identity and no devices', () async {
    final directory = await Directory.systemTemp.createTemp('ferret_cli');
    addTearDown(() => directory.delete(recursive: true));
    final environment = CliEnvironment(directory: directory.path);

    final (identity, trust) = await environment.openStores();
    final (again, _) = await environment.openStores();

    expect(trust.devices, isEmpty);
    expect(again.deviceId, identity.deviceId);
  });

  test('the CLI pairs with another engine from its link', () async {
    final offering = await Directory.systemTemp.createTemp('ferret_cli_offer');
    final scanning = await Directory.systemTemp.createTemp('ferret_cli_scan');
    addTearDown(() => offering.delete(recursive: true));
    addTearDown(() => scanning.delete(recursive: true));

    final shower = await CliEnvironment(directory: offering.path)
        .createEngine(port: 0);
    await shower.start();
    addTearDown(shower.stop);
    final offer = await shower.createPairingOffer();
    final link = offer.qrText;

    final exit = await buildRunner(CliEnvironment(directory: scanning.path))
        .run(['pair', _localLink(link)]);

    expect(exit, 0);
    expect(shower.trustStore.devices, hasLength(1));
  });
}

/// Points the link's offer at loopback, so the test doesn't depend on the
/// machine's network.
String _localLink(String link) {
  final offer = PairingCodes.parseOffer(link);
  if (offer == null) {
    fail('Not a pairing link: $link');
  }

  offer
    ..hosts.clear()
    ..hosts.add('127.0.0.1');
  return PairingCodes.offerUri(offer).toString();
}
