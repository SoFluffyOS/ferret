import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_mirror_airplay/src/plist/plist.dart';
import 'package:ferret_mirror_airplay/src/rtsp/rtsp_request.dart';

/// The answer to one [RtspRequest].
class RtspResponse {
  RtspResponse({
    this.status = 200,
    this.reason = 'OK',
    Map<String, String>? headers,
    Uint8List? body,
    this.closeAfter = false,
  }) : headers = headers ?? {},
       body = body ?? Uint8List(0);

  factory RtspResponse.bytes(Uint8List body) => RtspResponse(
    headers: {'Content-Type': 'application/octet-stream'},
    body: body,
  );

  factory RtspResponse.plist(Map<String, Object?> dict) => RtspResponse(
    headers: {'Content-Type': 'application/x-apple-binary-plist'},
    body: BinaryPlistEncoder.encode(dict),
  );

  factory RtspResponse.badRequest() =>
      RtspResponse(status: 400, reason: 'Bad Request');

  factory RtspResponse.unauthorized() =>
      RtspResponse(status: 401, reason: 'Unauthorized', closeAfter: true);

  static const _server = 'AirTunes/220.68';

  final int status;
  final String reason;
  final Map<String, String> headers;
  final Uint8List body;

  /// Close the connection once this is sent.
  final bool closeAfter;

  /// The bytes to send back for [request]: its protocol and sequence
  /// number are repeated.
  Uint8List encodeFor(RtspRequest request) {
    final head = StringBuffer('${request.protocol} $status $reason\r\n');
    if (request.headers['cseq'] case final sequence?) {
      head.write('CSeq: $sequence\r\n');
    }

    head.write('Server: $_server\r\n');
    for (final MapEntry(:key, :value) in headers.entries) {
      head.write('$key: $value\r\n');
    }

    head.write('Content-Length: ${body.length}\r\n\r\n');
    return Uint8List.fromList([...latin1.encode('$head'), ...body]);
  }
}
