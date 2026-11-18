import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_mirror_airplay/src/rtsp/rtsp_request.dart';

/// Cuts the control connection's bytes into requests, however they arrive.
class RtspRequestReader {
  static const maxHeadLength = 16 * 1024;
  static const maxBodyLength = 1024 * 1024;
  static const _headEnd = [13, 10, 13, 10];

  Uint8List _pending = Uint8List(0);

  /// Adds [chunk] and returns every request it completed. Throws a
  /// [FormatException] on a request that isn't RTSP or is too large.
  List<RtspRequest> add(Uint8List chunk) {
    _pending = Uint8List.fromList([..._pending, ...chunk]);
    final requests = <RtspRequest>[];
    while (true) {
      final request = _next();
      if (request == null) {
        return requests;
      }

      requests.add(request);
    }
  }

  RtspRequest? _next() {
    final headEnd = _indexOfHeadEnd();
    if (headEnd < 0) {
      if (_pending.length > maxHeadLength) {
        throw const FormatException('RTSP request head too long');
      }

      return null;
    }

    final lines = latin1.decode(_pending.sublist(0, headEnd)).split('\r\n');
    final start = lines.first.split(' ');
    if (start.length != 3) {
      throw const FormatException('Bad RTSP request line');
    }

    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final colon = line.indexOf(':');
      if (colon < 1) {
        continue;
      }

      headers[line.substring(0, colon).trim().toLowerCase()] = line
          .substring(colon + 1)
          .trim();
    }

    final bodyLength = int.tryParse(headers['content-length'] ?? '0') ?? -1;
    if (bodyLength < 0 || bodyLength > maxBodyLength) {
      throw const FormatException('Bad RTSP content length');
    }

    final bodyStart = headEnd + _headEnd.length;
    if (_pending.length < bodyStart + bodyLength) {
      return null;
    }

    final body = _pending.sublist(bodyStart, bodyStart + bodyLength);
    _pending = _pending.sublist(bodyStart + bodyLength);
    return RtspRequest(
      method: start[0],
      uri: start[1],
      protocol: start[2],
      headers: headers,
      body: body,
    );
  }

  int _indexOfHeadEnd() {
    final last = _pending.length - _headEnd.length;
    for (var index = 0; index <= last && index <= maxHeadLength; index++) {
      if (_pending[index] == 13 &&
          _pending[index + 1] == 10 &&
          _pending[index + 2] == 13 &&
          _pending[index + 3] == 10) {
        return index;
      }
    }

    return -1;
  }
}
