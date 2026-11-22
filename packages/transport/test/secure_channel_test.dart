import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  late ServerSocket server;

  setUp(() async {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  });

  tearDown(() => server.close());

  Future<(SecureChannel, SecureChannel)> connectPair() async {
    final clientKeys = await NoiseCrypto.generateKeyPair();
    final serverKeys = await NoiseCrypto.generateKeyPair();

    final accepted = server.first.then(
      (socket) => SecureChannel.respond(SocketConnection(socket), serverKeys),
    );
    final client = await SecureChannel.initiate(
      await SocketConnection.connect('127.0.0.1', server.port),
      clientKeys,
    );
    final responder = await accepted;

    expect(client.remoteStaticKey, await NoiseCrypto.publicKeyOf(serverKeys));
    expect(
      responder.remoteStaticKey,
      await NoiseCrypto.publicKeyOf(clientKeys),
    );
    expect(client.handshakeHash, responder.handshakeHash);
    return (client, responder);
  }

  test('a caller that refuses the answering key never shows its own', () async {
    final clientKeys = await NoiseCrypto.generateKeyPair();
    final serverKeys = await NoiseCrypto.generateKeyPair();
    final seen = <List<int>>[];

    final accepted = server.first.then(
      (socket) => SecureChannel.respond(SocketConnection(socket), serverKeys),
    );
    final client = SecureChannel.initiate(
      await SocketConnection.connect('127.0.0.1', server.port),
      clientKeys,
      acceptRemote: (key) {
        seen.add(key);
        return false;
      },
    );

    await expectLater(client, throwsA(isA<NoiseHandshakeException>()));
    await expectLater(accepted, throwsA(anything));
    expect(seen.single, await NoiseCrypto.publicKeyOf(serverKeys));
  });

  test('a caller that accepts the answering key connects', () async {
    final clientKeys = await NoiseCrypto.generateKeyPair();
    final serverKeys = await NoiseCrypto.generateKeyPair();
    final expected = await NoiseCrypto.publicKeyOf(serverKeys);

    final accepted = server.first.then(
      (socket) => SecureChannel.respond(SocketConnection(socket), serverKeys),
    );
    final client = await SecureChannel.initiate(
      await SocketConnection.connect('127.0.0.1', server.port),
      clientKeys,
      acceptRemote: (key) => _same(key, expected),
    );
    final responder = await accepted;

    expect(client.handshakeHash, responder.handshakeHash);
    await client.close();
    await responder.close();
  });

  test('closing does not wait for a send the other side never reads', () async {
    final (client, responder) = await connectPair();
    final reading = responder.messages.listen((_) {})..pause();

    final stuck = client.send(Uint8List(48 * 1024 * 1024))..ignore();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final watch = Stopwatch()..start();
    await client.close();

    expect(watch.elapsed, lessThan(const Duration(seconds: 8)));
    final settled = await stuck
        .then((_) => true, onError: (Object _) => true)
        .timeout(const Duration(seconds: 5), onTimeout: () => false);
    expect(settled, isTrue);
    await reading.cancel();
    await responder.close();
  });

  test('messages arrive in order, both ways', () async {
    final (client, responder) = await connectPair();
    final received = responder.messages.take(3).toList();

    await client.send([1]);
    await client.send([2, 2]);
    await client.send([3, 3, 3]);

    expect(await received, [
      [1],
      [2, 2],
      [3, 3, 3],
    ]);

    final reply = client.messages.first;
    await responder.send([9]);
    expect(await reply, [9]);

    await client.close();
    await responder.done;
  });

  test('a message bigger than one Noise frame is split and joined', () async {
    final (client, responder) = await connectPair();
    final big = Uint8List(200 * 1024);
    for (var i = 0; i < big.length; i++) {
      big[i] = i % 251;
    }

    final received = responder.messages.first;
    await client.send(big);

    expect(await received, big);
    await client.close();
  });

  test('counts the bytes on the link both ways', () async {
    final (client, responder) = await connectPair();
    final big = Uint8List(200 * 1024);

    final received = responder.messages.first;
    await client.send(big);
    await received;

    expect(client.bytesSent, greaterThan(big.length));
    expect(client.bytesSent, lessThan(big.length + 1024));
    expect(responder.bytesReceived, client.bytesSent);
    expect(responder.bytesSent, 0);
    await client.close();
  });

  test('a message over the limit closes the channel with an error', () async {
    final (client, responder) = await connectPair();
    responder.messageLimit = 1024;
    final errors = <Object>[];
    final done = Completer<void>();
    responder.messages.listen(
      (_) {},
      onError: errors.add,
      onDone: done.complete,
    );

    await client.send(Uint8List(4096));

    await done.future.timeout(const Duration(seconds: 5));
    expect(errors.single, isA<FramingException>());
    expect(responder.isClosed, isTrue);
  });

  test('a paused listener holds reading back and misses nothing', () async {
    final (client, responder) = await connectPair();
    final received = <int>[];
    final subscription = responder.messages.listen(
      (message) => received.add(message.first),
    );
    subscription.pause();

    for (var i = 0; i < 50; i++) {
      await client.send([i, ...Uint8List(1000)]);
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(received, isEmpty);

    subscription.resume();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (received.length < 50 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(received, List.generate(50, (i) => i));
    await client.close();
  });

  test('an empty message is delivered', () async {
    final (client, responder) = await connectPair();
    final received = responder.messages.first;

    await client.send(const []);

    expect(await received, isEmpty);
    await client.close();
  });

  test('a tampered frame closes the channel with an error', () async {
    final serverKeys = await NoiseCrypto.generateKeyPair();
    final accepted = server.first.then(
      (socket) => SecureChannel.respond(SocketConnection(socket), serverKeys),
    );

    final socket = await Socket.connect('127.0.0.1', server.port);
    final tampering = _TamperingConnection(SocketConnection(socket));
    final client = await SecureChannel.initiate(
      tampering,
      await NoiseCrypto.generateKeyPair(),
    );
    final responder = await accepted;

    final errors = <Object>[];
    final done = Completer<void>();
    responder.messages.listen(
      (_) {},
      onError: errors.add,
      onDone: done.complete,
    );
    tampering.flipNextByte = true;
    await client.send([1, 2, 3]);

    await done.future.timeout(const Duration(seconds: 5));
    expect(errors, isNotEmpty);
    expect(responder.isClosed, isTrue);
  });

  test('a handshake with garbage fails', () async {
    final serverKeys = await NoiseCrypto.generateKeyPair();
    final accepted = server.first.then(
      (socket) => SecureChannel.respond(SocketConnection(socket), serverKeys),
    );

    final socket = await Socket.connect('127.0.0.1', server.port);
    socket.add(encodeFrame(List.filled(10, 7)));
    await socket.flush();

    await expectLater(accepted, throwsA(isA<NoiseHandshakeException>()));
    socket.destroy();
  });

  test('announces round-trip through the packet format', () {
    final announce = Announce(
      deviceId: 'abc',
      name: 'Pixel',
      port: 47640,
      platform: .PLATFORM_ANDROID,
    );

    final decoded = decodeAnnounce(encodeAnnounce(announce));

    expect(decoded, announce);
    expect(decodeAnnounce([1, 2, 3, 4, 5]), isNull);
  });
}

class _TamperingConnection implements ByteConnection {
  _TamperingConnection(this._inner);

  final ByteConnection _inner;
  bool flipNextByte = false;

  @override
  Stream<Uint8List> get input => _inner.input;

  @override
  void add(List<int> bytes) {
    if (!flipNextByte) {
      _inner.add(bytes);
      return;
    }

    flipNextByte = false;
    final copy = Uint8List.fromList(bytes);
    copy[copy.length - 1] ^= 0xff;
    _inner.add(copy);
  }

  @override
  Future<void> flush() => _inner.flush();

  @override
  Future<void> close() => _inner.close();

  @override
  String get remoteAddress => _inner.remoteAddress;
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}
