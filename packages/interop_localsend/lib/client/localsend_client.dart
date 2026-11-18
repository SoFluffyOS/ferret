import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:interop_localsend/client/localsend_abort.dart';
import 'package:interop_localsend/models/models.dart';
import 'package:interop_localsend/security/security.dart';

/// Calls another LocalSend member's HTTP API.
///
/// Members use self-signed certificates, so instead of a certificate
/// authority this pins each member's certificate to the fingerprint it
/// announced: a device showing another certificate is refused before any
/// file leaves this one.
class LocalSendClient {
  LocalSendClient({
    LocalSendIdentity? identity,
    Duration connectTimeout = const Duration(seconds: 5),
    this.requestTimeout = const Duration(seconds: 10),
    this.answerTimeout = const Duration(minutes: 5),
  }) : _http =
           HttpClient(
               context:
                   identity?.securityContext() ??
                   SecurityContext(withTrustedRoots: false),
             )
             ..connectionTimeout = connectTimeout
             ..autoUncompress = false {
    _http.badCertificateCallback = _checkCertificate;
  }

  static const _maxAnswerBytes = 1024 * 1024;

  /// How long short calls such as `/register` may take.
  final Duration requestTimeout;

  /// How long `/prepare-upload` waits for someone to accept on the other
  /// device.
  final Duration answerTimeout;

  final HttpClient _http;
  final Map<String, String> _pinned = {};
  final Map<String, String> _presented = {};
  final Set<String> _refused = {};

  /// Tells [peer] about this device and reads its description back
  /// (`/register`).
  Future<LocalSendInfo> register(LocalSendPeer peer, LocalSendInfo self) async {
    final answer = await _call(
      peer,
      'POST',
      'register',
      body: self.toJson(),
      timeout: requestTimeout,
    );
    final info = LocalSendInfo.fromJson(answer.json);
    if (answer.status != HttpStatus.ok || info == null) {
      throw LocalSendException(
        LocalSendFailure.fromStatus(answer.status),
        statusCode: answer.status,
      );
    }

    return info;
  }

  /// Asks whether a LocalSend member listens at [address], for networks
  /// where multicast doesn't get through. With HTTPS, the member's
  /// fingerprint is taken from the certificate it shows.
  Future<LocalSendPeer?> probe(
    InternetAddress address,
    LocalSendInfo self, {
    int port = LocalSendDefaults.port,
    String protocol = LocalSendDefaults.https,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final candidate = LocalSendPeer(
      info: LocalSendInfo(
        alias: address.address,
        fingerprint: '',
        port: port,
        protocol: protocol,
      ),
      address: address,
      lastSeen: DateTime.now(),
    );

    final _Answer answer;
    try {
      answer = await _call(
        candidate,
        'POST',
        'register',
        body: self.toJson(),
        timeout: timeout,
        pin: false,
      );
    } on LocalSendException {
      return null;
    }

    final info = LocalSendInfo.fromJson(answer.json);
    if (answer.status != HttpStatus.ok || info == null) {
      return null;
    }

    final presented = _presented[_key(candidate)];
    return LocalSendPeer(
      info: info.copyWith(
        fingerprint: switch (candidate.isEncrypted) {
          true => presented,
          false => null,
        },
        port: port,
        protocol: protocol,
      ),
      address: address,
      lastSeen: DateTime.now(),
    );
  }

  /// Reads [peer]'s description (`/info`).
  Future<LocalSendInfo> info(LocalSendPeer peer) async {
    final answer = await _call(peer, 'GET', 'info', timeout: requestTimeout);
    final info = LocalSendInfo.fromJson(answer.json);
    if (answer.status != HttpStatus.ok || info == null) {
      throw LocalSendException(
        LocalSendFailure.fromStatus(answer.status),
        statusCode: answer.status,
      );
    }

    return info;
  }

  /// Offers files to [peer] and waits for its answer. Returns null when
  /// the receiver is done without wanting any upload (HTTP 204), such as
  /// for a text message. Send [pin] when the receiver asked for one.
  Future<PrepareUploadResponse?> prepareUpload(
    LocalSendPeer peer,
    PrepareUploadRequest request, {
    String? pin,
    LocalSendAbort? abort,
  }) async {
    final answer = await _call(
      peer,
      'POST',
      'prepare-upload',
      query: {'pin': ?pin},
      body: request.toJson(),
      timeout: answerTimeout,
      abort: abort,
    );
    if (answer.status == HttpStatus.noContent) {
      return null;
    }

    if (answer.status != HttpStatus.ok) {
      throw LocalSendException(
        LocalSendFailure.fromStatus(answer.status),
        statusCode: answer.status,
      );
    }

    final response = PrepareUploadResponse.fromJson(answer.json);
    if (response == null) {
      throw const LocalSendException(.unexpected, statusCode: HttpStatus.ok);
    }

    return response;
  }

  /// Uploads one file's [data] of exactly [length] bytes.
  Future<void> upload(
    LocalSendPeer peer, {
    required String sessionId,
    required String fileId,
    required String token,
    required Stream<List<int>> data,
    required int length,
    LocalSendAbort? abort,
  }) async {
    final answer = await _call(
      peer,
      'POST',
      'upload',
      query: {'sessionId': sessionId, 'fileId': fileId, 'token': token},
      data: data,
      length: length,
      abort: abort,
    );
    if (answer.status != HttpStatus.ok) {
      throw LocalSendException(
        LocalSendFailure.fromStatus(answer.status),
        statusCode: answer.status,
      );
    }
  }

  /// Tells [peer] this device stopped the session. Without a [sessionId],
  /// it withdraws an offer the receiver hasn't answered yet.
  Future<void> cancel(LocalSendPeer peer, {String? sessionId}) async {
    await _call(
      peer,
      'POST',
      'cancel',
      query: {'sessionId': ?sessionId},
      timeout: requestTimeout,
    );
  }

  void close() => _http.close(force: true);

  Future<_Answer> _call(
    LocalSendPeer peer,
    String method,
    String route, {
    Map<String, String> query = const {},
    Object? body,
    Stream<List<int>>? data,
    int? length,
    Duration? timeout,
    LocalSendAbort? abort,
    bool pin = true,
  }) async {
    final key = _key(peer);
    _refused.remove(key);
    if (peer.isEncrypted && pin) {
      _pinned[key] = peer.fingerprint;
    }

    if (!pin) {
      _pinned.remove(key);
    }

    try {
      final exchange = _exchange(
        peer,
        method,
        route,
        query: query,
        body: body,
        data: data,
        length: length,
        abort: abort,
        pin: pin,
      );
      if (timeout == null) {
        return await exchange;
      }

      return await exchange.timeout(timeout);
    } on LocalSendException {
      rethrow;
    } on HandshakeException {
      if (_refused.contains(key)) {
        throw const LocalSendException(.untrusted);
      }

      throw const LocalSendException(.unreachable);
    } on TimeoutException {
      abort?.abort();
      throw const LocalSendException(.unreachable);
    } on IOException {
      throw const LocalSendException(.unreachable);
    }
  }

  Future<_Answer> _exchange(
    LocalSendPeer peer,
    String method,
    String route, {
    required Map<String, String> query,
    required Object? body,
    required Stream<List<int>>? data,
    required int? length,
    required LocalSendAbort? abort,
    required bool pin,
  }) async {
    final request = await _http.openUrl(method, peer.route(route, query));
    abort?.attach(request);

    if (body != null) {
      final encoded = utf8.encode(jsonEncode(body));
      request
        ..headers.contentType = ContentType.json
        ..contentLength = encoded.length
        ..add(encoded);
    }

    if (data != null) {
      request
        ..headers.contentType = ContentType.binary
        ..contentLength = length ?? -1;
      await request.addStream(data);
    }

    final response = await request.close();
    if (peer.isEncrypted && pin && !_showsPinned(peer, response)) {
      await response.drain<void>();
      throw const LocalSendException(.untrusted);
    }

    final bytes = await _read(response);
    return _Answer(response.statusCode, _decode(bytes));
  }

  /// Connections are reused, so the certificate is checked on each answer
  /// too, not only at the handshake.
  bool _showsPinned(LocalSendPeer peer, HttpClientResponse response) {
    final certificate = response.certificate;
    if (certificate == null) {
      return false;
    }

    return Fingerprints.same(
      Fingerprints.ofCertificate(certificate.der),
      peer.fingerprint,
    );
  }

  Future<List<int>> _read(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > _maxAnswerBytes) {
        throw const LocalSendException(.unexpected);
      }

      bytes.addAll(chunk);
    }

    return bytes;
  }

  Object? _decode(List<int> bytes) {
    if (bytes.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }

  bool _checkCertificate(X509Certificate certificate, String host, int port) {
    final key = '$host:$port';
    final presented = Fingerprints.ofCertificate(certificate.der);
    _presented[key] = presented;

    final pinned = _pinned[key];
    if (pinned == null || Fingerprints.same(pinned, presented)) {
      return true;
    }

    _refused.add(key);
    return false;
  }

  String _key(LocalSendPeer peer) => '${peer.address.address}:${peer.port}';
}

class _Answer {
  const _Answer(this.status, this.json);

  final int status;
  final Object? json;
}
