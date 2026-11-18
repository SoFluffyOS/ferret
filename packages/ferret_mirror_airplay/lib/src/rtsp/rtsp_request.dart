import 'dart:typed_data';

/// One request on the AirPlay control connection. iPhones mix RTSP methods
/// (`SETUP`, `RECORD`) with HTTP-style ones (`GET /info`, `POST /fp-setup`)
/// on the same connection, all framed the same way.
class RtspRequest {
  const RtspRequest({
    required this.method,
    required this.uri,
    required this.protocol,
    required this.headers,
    required this.body,
  });

  final String method;
  final String uri;

  /// `RTSP/1.0` or `HTTP/1.1`; the answer repeats it.
  final String protocol;

  /// Header names in lower case.
  final Map<String, String> headers;
  final Uint8List body;

  /// The path of [uri] without its query.
  String get path => uri.split('?').first;
}
