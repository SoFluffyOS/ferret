import 'dart:async';
import 'dart:io';

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
}
