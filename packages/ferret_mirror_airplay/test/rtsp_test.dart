import 'dart:typed_data';

import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(String text) => Uint8List.fromList(text.codeUnits);

void main() {
  group('RtspRequestReader', () {
    const withBody =
        'POST /fp-setup RTSP/1.0\r\n'
        'X-Apple-ET: 32\r\n'
        'CSeq: 3\r\n'
        'Content-Length: 5\r\n'
        '\r\n'
        'hello';
    const withoutBody = 'GET /info?x=1 HTTP/1.1\r\nHost: ferret\r\n\r\n';

    test('reads the method, uri, headers and body', () {
      final request = RtspRequestReader().add(_bytes(withBody)).single;

      expect(request.method, 'POST');
      expect(request.uri, '/fp-setup');
      expect(request.protocol, 'RTSP/1.0');
      expect(request.headers['cseq'], '3');
      expect(request.headers['x-apple-et'], '32');
      expect(String.fromCharCodes(request.body), 'hello');
    });

    test('reads requests one after another, cut anywhere', () {
      final all = _bytes('$withBody$withoutBody$withBody');
      for (final step in const [1, 3, 50, 1000]) {
        final reader = RtspRequestReader();
        final requests = <RtspRequest>[];
        for (var offset = 0; offset < all.length; offset += step) {
          final end = (offset + step).clamp(0, all.length);
          requests.addAll(reader.add(all.sublist(offset, end)));
        }

        expect(requests.map((request) => request.method), [
          'POST',
          'GET',
          'POST',
        ]);
        expect(requests[1].path, '/info');
        expect(requests[1].body, isEmpty);
      }
    });

    test('refuses a head that never ends', () {
      final reader = RtspRequestReader();

      expect(
        () => reader.add(Uint8List(RtspRequestReader.maxHeadLength + 1)),
        throwsFormatException,
      );
    });

    test('refuses a body larger than any AirPlay request', () {
      const huge = 'POST /x RTSP/1.0\r\nContent-Length: 99999999\r\n\r\n';

      expect(
        () => RtspRequestReader().add(_bytes(huge)),
        throwsFormatException,
      );
    });

    test('refuses a first line that is not a request', () {
      expect(
        () => RtspRequestReader().add(_bytes('nonsense\r\n\r\n')),
        throwsFormatException,
      );
    });
  });

  group('RtspResponse', () {
    final request = RtspRequestReader()
        .add(_bytes('SETUP rtsp://x/1 RTSP/1.0\r\nCSeq: 9\r\n\r\n'))
        .single;

    test('repeats the protocol and sequence number of its request', () {
      final text = String.fromCharCodes(
        RtspResponse.bytes(_bytes('abc')).encodeFor(request),
      );

      expect(
        text,
        'RTSP/1.0 200 OK\r\n'
        'CSeq: 9\r\n'
        'Server: AirTunes/220.68\r\n'
        'Content-Type: application/octet-stream\r\n'
        'Content-Length: 3\r\n'
        '\r\n'
        'abc',
      );
    });

    test('carries a plist the decoder reads back', () {
      final response = RtspResponse.plist({'eventPort': 0});

      expect(BinaryPlistDecoder.decode(response.body), {'eventPort': 0});
      expect(
        response.headers['Content-Type'],
        'application/x-apple-binary-plist',
      );
    });

    test('a refusal closes the connection', () {
      final refusal = RtspResponse.unauthorized();

      expect(refusal.status, 401);
      expect(refusal.closeAfter, isTrue);
    });
  });
}
