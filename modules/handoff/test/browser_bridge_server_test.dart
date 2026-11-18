import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';

import 'support/browser_fakes.dart';

void main() {
  late BrowserBridgeServer server;
  late List<BrowserChannel> accepted;
  late int port;

  setUp(() async {
    accepted = [];
    server = BrowserBridgeServer(ports: [0]);
    final bound = await server.start(accepted.add);
    if (bound == null) {
      fail('The server did not start');
    }

    port = bound;
  });

  tearDown(() => server.stop());

  Future<int> statusFor(Map<String, String> headers) async {
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client.get('127.0.0.1', port, '/');
    request.headers
      ..set('connection', 'Upgrade')
      ..set('upgrade', 'websocket')
      ..set('sec-websocket-version', '13')
      ..set('sec-websocket-key', base64.encode(List.filled(16, 7)));
    headers.forEach(request.headers.set);
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  }

  test('an extension origin connects', () async {
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:$port',
      headers: {'Origin': chromeOrigin},
    );
    addTearDown(socket.close);
    await pumpEventQueue();

    expect(accepted.single.origin, chromeOrigin);
  });

  test('Firefox extensions connect too', () async {
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:$port',
      headers: {'Origin': firefoxOrigin},
    );
    addTearDown(socket.close);
    await pumpEventQueue();

    expect(accepted.single.origin, firefoxOrigin);
  });

  test('web pages are turned away before the upgrade', () async {
    for (final origin in [
      'https://evil.example',
      'http://127.0.0.1',
      'null',
      'chrome-extension://short',
      'chrome-extension://abcdefghijklmnopabcdefghijklmnop.evil.example',
      'moz-extension://not-a-uuid',
      'safari-web-extension://abc',
    ]) {
      expect(await statusFor({'origin': origin}), HttpStatus.forbidden);
    }

    expect(accepted, isEmpty);
  });

  test('a request without an origin is turned away', () async {
    expect(await statusFor({}), HttpStatus.forbidden);
    expect(accepted, isEmpty);
  });

  test('a host that is not this computer is turned away', () async {
    final status = await statusFor({
      'origin': chromeOrigin,
      'host': 'rebind.evil.example:$port',
    });

    expect(status, HttpStatus.forbidden);
    expect(accepted, isEmpty);
  });

  test('plain HTTP gets nothing', () async {
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client.get('127.0.0.1', port, '/');
    request.headers.set('origin', chromeOrigin);
    final response = await request.close();
    final body = await utf8.decodeStream(response);

    expect(response.statusCode, HttpStatus.upgradeRequired);
    expect(body, isEmpty);
  });

  test('the next port is used when the first is taken', () async {
    final blocker = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(blocker.close);
    final fallback = BrowserBridgeServer(ports: [blocker.port, 0]);
    addTearDown(fallback.stop);

    final bound = await fallback.start((_) {});

    expect(bound, isNot(blocker.port));
    expect(bound, isNotNull);
  });

  test('every port taken means no server', () async {
    final blocker = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(blocker.close);
    final failing = BrowserBridgeServer(ports: [blocker.port]);

    expect(await failing.start((_) {}), isNull);
  });

  test('a full bridge says so instead of upgrading', () async {
    final small = BrowserBridgeServer(ports: [0], maxConnections: 1);
    addTearDown(small.stop);
    final smallPort = await small.start((_) {});
    final first = await WebSocket.connect(
      'ws://127.0.0.1:$smallPort',
      headers: {'Origin': chromeOrigin},
    );
    addTearDown(first.close);

    await expectLater(
      WebSocket.connect(
        'ws://127.0.0.1:$smallPort',
        headers: {'Origin': chromeOrigin},
      ),
      throwsA(isA<WebSocketException>()),
    );
  });

  test('messages and replies flow through a real socket', () async {
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:$port',
      headers: {'Origin': chromeOrigin},
    );
    addTearDown(socket.close);
    final replies = socket.cast<String>().map(jsonDecode);
    await pumpEventQueue();
    final channel = accepted.single;
    final received = <String>[];
    channel.messages.listen(received.add);

    socket.add('{"type":"ping"}');
    channel.send({'type': 'pong'});

    expect(await replies.first, {'type': 'pong'});
    await pumpEventQueue();
    expect(received, ['{"type":"ping"}']);
  });

  test('the bridge binds to loopback only', () async {
    final addresses = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    final outside = [
      for (final interface in addresses)
        for (final address in interface.addresses)
          if (!address.isLoopback) address,
    ];
    if (outside.isEmpty) {
      return;
    }

    await expectLater(
      Socket.connect(
        outside.first,
        port,
        timeout: const Duration(seconds: 1),
      ),
      throwsA(isA<SocketException>()),
    );
  });
}
