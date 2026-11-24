import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  test('a request still being written when the link dies fails quietly '
      'to its caller, with no stray error', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final serverKeys = await NoiseCrypto.generateKeyPair();
    final accepted = server.first.then(
      (socket) => SecureChannel.respond(SocketConnection(socket), serverKeys),
    );
    final client = await SecureChannel.initiate(
      await SocketConnection.connect('127.0.0.1', server.port),
      await NoiseCrypto.generateKeyPair(),
    );
    final responder = await accepted;
    final reading = responder.messages.listen((_) {})..pause();

    final strays = <Object>[];
    await runZonedGuarded(() async {
      final session = Session(
        channel: client,
        messages: client.messages,
        remoteDeviceId: 'phone',
        initiatedByLocal: true,
        initiatorDeviceId: 'laptop',
      );
      final stuck = client.send(List.filled(40 * 1024 * 1024, 7))..ignore();
      final request = session.request(
        'drop',
        Ping(sentAtMs: Int64(1)),
        timeout: const Duration(seconds: 30),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await reading.cancel();
      await responder.close();

      await expectLater(request, throwsA(anything));
      await stuck.then((_) {}, onError: (Object _) {});
      await session.closed;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }, (error, _) => strays.add(error));

    expect(strays, isEmpty);
  });

  test('a paired device that hangs up before its hello is logged as a '
      'closed session', () async {
    final laptop = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Laptop',
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      discovery: _SilentDiscovery(),
      port: 0,
    );
    await laptop.start();
    addTearDown(laptop.stop);

    final phoneKeys = await NoiseCrypto.generateKeyPair();
    final phoneKey = await NoiseCrypto.publicKeyOf(phoneKeys);
    final phoneId = await DeviceIdentity.deviceIdFor(phoneKey);
    await laptop.trustStore.save(
      TrustedDevice(
        id: phoneId,
        name: 'Phone',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
        publicKey: phoneKey,
        pairedAt: DateTime(2026),
      ),
    );

    final messages = <String>[];
    final logging = Log.records.listen(
      (record) => messages.add(record.message),
    );
    addTearDown(logging.cancel);

    final phone = await SecureChannel.initiate(
      await SocketConnection.connect('127.0.0.1', laptop.port),
      phoneKeys,
    );
    await phone.messages.first;
    await phone.close();

    final started = 'Session with $phoneId did not start';
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!messages.any((message) => message.startsWith(started))) {
      if (DateTime.now().isAfter(deadline)) {
        fail('The failed start was never logged');
      }

      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    expect(
      messages.firstWhere((message) => message.startsWith(started)),
      '$started: SessionClosedException',
    );
  });
}

class _SilentDiscovery implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
