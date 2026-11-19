import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_cli/ferret_cli.dart';
import 'package:test/test.dart';

void main() {
  test('keeps its files in a cli folder of Ferret\'s home', () async {
    final environment = await CliEnvironment.forThisUser(
      environment: const {'FERRET_HOME': '/tmp/ferret_home'},
    );

    expect(
      environment.paths.root,
      FerretPaths('/tmp/ferret_home').nested('cli').root,
    );
  });

  test('a fresh install has an identity and no devices', () async {
    final directory = await Directory.systemTemp.createTemp('ferret_cli');
    addTearDown(() => directory.delete(recursive: true));
    final environment = CliEnvironment(FerretPaths(directory.path));

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

    final shower = await CliEnvironment(FerretPaths(offering.path))
        .createEngine(port: 0);
    await shower.start();
    addTearDown(shower.stop);
    final offer = await shower.createPairingOffer();
    final link = offer.qrText;

    final exit = await buildRunner(CliEnvironment(FerretPaths(scanning.path)))
        .run(['pair', _localLink(link)]);

    expect(exit, 0);
    expect(shower.trustStore.devices, hasLength(1));
  });

  group('scripting', () {
    late Directory home;
    late StringBuffer out;
    late StringBuffer err;
    late CliEnvironment environment;

    setUp(() async {
      home = await Directory.systemTemp.createTemp('ferret_cli_script');
      out = StringBuffer();
      err = StringBuffer();
      environment = CliEnvironment(
        FerretPaths(home.path).nested('cli'),
        appRoot: home.path,
        out: out,
        err: err,
      );
    });

    tearDown(() => home.delete(recursive: true));

    test('devices --json prints this device and an empty list', () async {
      final exit = await buildRunner(environment).run(['devices', '--json']);

      final json = jsonDecode(out.toString()) as Map<String, Object?>;
      expect(exit, ExitCodes.ok);
      expect(json['this_device'], isA<String>());
      expect(json['devices'], isEmpty);
    });

    test('send hands files to the running app', () async {
      final running = SendHandoff(home.path);
      final received = <List<String>>[];
      running.requests.listen(received.add);
      await running.listen();
      addTearDown(running.dispose);
      final file = File('${home.path}/photo.jpg')..writeAsStringSync('x');

      final exit = await buildRunner(environment).run(['send', file.path]);

      expect(exit, ExitCodes.ok);
      expect(received, [
        [file.path],
      ]);
      expect(out.toString(), contains('Handed 1 file'));
    });

    test('send says when the app is not running', () async {
      final file = File('${home.path}/photo.jpg')..writeAsStringSync('x');

      final exit = await buildRunner(environment).run(['send', file.path]);

      expect(exit, ExitCodes.unavailable);
      expect(err.toString(), contains("isn't running"));
    });

    test('send stops at a file that is not there', () async {
      final exit = await buildRunner(
        environment,
      ).run(['send', '${home.path}/missing.txt']);

      expect(exit, ExitCodes.noInput);
      expect(err.toString(), contains('No such file'));
    });

    test('--version prints the version', () async {
      final exit = await buildRunner(environment).run(['--version']);

      expect(exit, ExitCodes.ok);
      expect(out.toString().trim(), 'ferret-cli $cliVersion');
    });

    test('help lists the exit codes', () {
      expect(buildRunner(environment).usage, contains('69 the Ferret app'));
    });
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
