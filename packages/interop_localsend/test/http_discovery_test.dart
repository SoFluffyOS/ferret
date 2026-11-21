import 'dart:convert';
import 'dart:io';

import 'package:interop_localsend/interop_localsend.dart';
import 'package:test/test.dart';

import 'support/loopback.dart';
import 'support/recording_delegate.dart';

/// Without multicast (an iPhone without Apple's multicast entitlement, or
/// a network that drops it), LocalSend apps find a receiver by asking
/// every address over HTTP. The server has to answer that on its own.
void main() {
  late LocalSendIdentity identity;
  late LocalSendServer server;
  late Directory inbox;
  late HttpClient http;
  late int port;
  final registered = <(LocalSendInfo, InternetAddress)>[];

  setUpAll(() async => identity = await LocalSendIdentity.generate());

  setUp(() async {
    inbox = await Directory.systemTemp.createTemp('localsend_http');
    registered.clear();
    server = LocalSendServer(
      identity: identity,
      self: (port) => infoFor(identity, 'iPhone', port: port),
      delegate: RecordingDelegate(inbox),
      port: 0,
      fallbackPorts: 0,
      onRegister: (info, address) => registered.add((info, address)),
      address: InternetAddress.loopbackIPv4,
    );
    port = await server.start();
    http = HttpClient()..badCertificateCallback = (_, _, _) => true;
  });

  tearDown(() async {
    http.close(force: true);
    await server.stop();
    await inbox.delete(recursive: true);
  });

  Future<(int, Map<String, Object?>?)> call(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final request = await http.openUrl(
      method,
      Uri.parse('https://127.0.0.1:$port$path'),
    );
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    return (
      response.statusCode,
      switch (text.isEmpty) {
        true => null,
        false => jsonDecode(text) as Map<String, Object?>,
      },
    );
  }

  final sender = {
    'alias': 'Pixel 7',
    'version': '2.1',
    'deviceModel': 'Pixel',
    'deviceType': 'mobile',
    'fingerprint': 'abc123',
    'port': 53317,
    'protocol': 'https',
    'download': false,
  };

  test('GET /api/localsend/v2/info names this device', () async {
    final (status, json) = await call('GET', '/api/localsend/v2/info');

    expect(status, HttpStatus.ok);
    expect(json?['alias'], 'iPhone');
    expect(json?['fingerprint'], identity.fingerprint);
    expect(json?['deviceType'], 'desktop');
  });

  test(
    'POST /api/localsend/v2/register answers and lists the sender',
    () async {
      final (status, json) = await call(
        'POST',
        '/api/localsend/v2/register',
        body: sender,
      );

      expect(status, HttpStatus.ok);
      expect(json?['alias'], 'iPhone');
      expect(json?['fingerprint'], identity.fingerprint);
      expect(registered.single.$1.alias, 'Pixel 7');
      expect(registered.single.$2, InternetAddress.loopbackIPv4);
    },
  );

  test('older apps find it on the version 1 paths', () async {
    final (infoStatus, info) = await call(
      'GET',
      '/api/localsend/v1/info?fingerprint=abc123',
    );
    final (registerStatus, _) = await call(
      'POST',
      '/api/localsend/v1/register',
      body: sender,
    );

    expect(infoStatus, HttpStatus.ok);
    expect(info?['alias'], 'iPhone');
    expect(registerStatus, HttpStatus.ok);
    expect(registered, hasLength(1));
  });

  test('version 1 only finds: uploads there are not served', () async {
    final (status, _) = await call(
      'POST',
      '/api/localsend/v1/send-request',
      body: sender,
    );

    expect(status, HttpStatus.notFound);
  });

  test('a register that is not a device is refused', () async {
    final (status, _) = await call(
      'POST',
      '/api/localsend/v2/register',
      body: {'hello': 'world'},
    );

    expect(status, HttpStatus.badRequest);
    expect(registered, isEmpty);
  });

  test('stopped, nothing answers', () async {
    await server.stop();

    expect(() => call('GET', '/api/localsend/v2/info'), throwsA(anything));
  });
}
