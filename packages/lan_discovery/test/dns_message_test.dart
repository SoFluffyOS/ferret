import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:lan_discovery/lan_discovery.dart';
import 'package:test/test.dart';

void main() {
  group('DnsMessage', () {
    test('round-trips questions and records', () {
      final message = DnsMessage(
        id: 0x1234,
        isResponse: true,
        questions: const [
          DnsQuestion(name: ['_x', '_tcp', 'local'], type: DnsType.ptr),
        ],
        answers: [
          DnsRecord.ptr(
            ['_x', '_tcp', 'local'],
            ['one', '_x', '_tcp', 'local'],
            4500,
          ),
        ],
        additionals: [
          DnsRecord.srv(
            ['one', '_x', '_tcp', 'local'],
            ['host', 'local'],
            4321,
            120,
          ),
          DnsRecord.txt(['one', '_x', '_tcp', 'local'], {'n': 'abc'}, 4500),
          DnsRecord.a(['host', 'local'], InternetAddress('192.168.1.7'), 120),
        ],
      );

      final decoded = DnsMessage.decode(message.encode());

      expect(decoded?.id, 0x1234);
      expect(decoded?.isResponse, isTrue);
      expect(decoded?.questions.single.name, ['_x', '_tcp', 'local']);
      expect(decoded?.questions.single.type, DnsType.ptr);
      expect(decoded?.answers.single.ttl, 4500);
      expect(decoded?.answers.single.isUnique, isFalse);
      final [srv, txt, a] = decoded?.additionals ?? [];
      expect(srv.type, DnsType.srv);
      expect(srv.isUnique, isTrue);
      expect(ByteData.sublistView(srv.data).getUint16(4), 4321);
      expect(txt.data, [5, ...utf8.encode('n=abc')]);
      expect(a.data, [192, 168, 1, 7]);
    });

    test('follows compressed names in questions', () {
      final packet = Uint8List.fromList([
        0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0,
        // _x._tcp.local at offset 12.
        2, ...utf8.encode('_x'), 4, ...utf8.encode('_tcp'),
        5, ...utf8.encode('local'), 0,
        0, DnsType.ptr, 0, 1,
        // one.<pointer to offset 12>.
        3, ...utf8.encode('one'), 0xc0, 12,
        0, DnsType.srv, 0x80, 1,
      ]);

      final decoded = DnsMessage.decode(packet);

      expect(decoded?.questions[0].name, ['_x', '_tcp', 'local']);
      expect(decoded?.questions[1].name, ['one', '_x', '_tcp', 'local']);
      expect(decoded?.questions[1].type, DnsType.srv);
    });

    test('refuses malformed packets', () {
      final loop = Uint8List.fromList([
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        0,
        0xc0,
        12,
        0,
        DnsType.ptr,
        0,
        1,
      ]);

      expect(DnsMessage.decode(Uint8List(5)), isNull);
      expect(DnsMessage.decode(loop), isNull);
      expect(
        DnsMessage.decode(
          Uint8List.fromList([0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 3, 65]),
        ),
        isNull,
      );
    });
  });
}
