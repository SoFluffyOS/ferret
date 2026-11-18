import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:interop_quickshare/interop_quickshare.dart';
import 'package:test/test.dart';

void main() {
  group('QuickShareEndpointInfo', () {
    test('round-trips the name and kind', () {
      const info = QuickShareEndpointInfo(name: 'Büro-Laptop', kind: .laptop);
      final bytes = info.encode();
      final decoded = QuickShareEndpointInfo.decode(bytes);

      expect(bytes.first, 3 << 1);
      expect(bytes[17], utf8.encode('Büro-Laptop').length);
      expect(decoded?.name, 'Büro-Laptop');
      expect(decoded?.kind, QuickShareDeviceKind.laptop);
    });

    test('travels in the TXT record as unpadded URL-safe base64', () {
      const info = QuickShareEndpointInfo(name: 'Mac', kind: .laptop);
      final txt = info.toTxt(Random(1));

      expect(txt, isNot(contains('=')));
      expect(txt, isNot(contains('+')));
      expect(QuickShareEndpointInfo.fromTxt(txt)?.name, 'Mac');
      expect(QuickShareEndpointInfo.fromTxt('%%%'), isNull);
    });

    test('reads what a phone sends', () {
      final phone = [
        1 << 1,
        ...List.filled(16, 0xab),
        5,
        ...utf8.encode('Pixel'),
        // Extra records after the name are ignored.
        2, 1, 0,
      ];

      final decoded = QuickShareEndpointInfo.decode(phone);
      expect(decoded?.name, 'Pixel');
      expect(decoded?.kind, QuickShareDeviceKind.phone);
    });

    test('gives nothing for hidden or cut-off info', () {
      expect(
        QuickShareEndpointInfo.decode([0x10, ...List.filled(17, 0)]),
        isNull,
      );
      expect(QuickShareEndpointInfo.decode(const [0, 1, 2]), isNull);
      expect(
        QuickShareEndpointInfo.decode([0, ...List.filled(16, 0), 9, 65]),
        isNull,
      );
    });

    test('cuts long names at a character boundary', () {
      final info = QuickShareEndpointInfo(name: 'é' * 200);
      final decoded = QuickShareEndpointInfo.decode(info.encode());

      expect(decoded?.name, 'é' * 48);
      expect(info.toTxt().length + 2, lessThanOrEqualTo(255));
    });
  });

  group('QuickShareService', () {
    test('makes the instance name phones look for', () {
      // 0x23, "AAAA", FC 9F 5E, 00 00.
      expect(QuickShareService.instanceName('AAAA'), 'I0FBQUH8n14AAA');
      expect(QuickShareService.endpointIdOf('I0FBQUH8n14AAA'), 'AAAA');
      expect(QuickShareService.endpointIdOf('SGVsbG8gd29ybGQ'), isNull);
      expect(QuickShareService.endpointIdOf('***'), isNull);
    });

    test('makes endpoint ids of four letters and digits', () {
      final id = QuickShareService.newEndpointId();

      expect(id, matches(RegExp(r'^[A-Za-z0-9]{4}$')));
    });
  });

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

  group('MdnsResponder', () {
    final address = InternetAddress('192.168.1.20');
    final service = QuickShareAdvertiser.serviceFor(
      'AbC1',
      50123,
      const QuickShareEndpointInfo(name: 'Laptop', kind: .laptop),
    );
    final responder = MdnsResponder(service);

    DnsMessage ask(List<String> name, int type) => DnsMessage(
      questions: [DnsQuestion(name: name, type: type)],
    );

    test('answers a browse with everything a phone needs to connect', () {
      final answer = responder.answer(
        ask(['_fc9f5ed42c8a', '_tcp', 'LOCAL'], DnsType.ptr),
        address,
      );
      final decoded = DnsMessage.decode(answer?.encode() ?? Uint8List(0));

      final pointer = decoded?.answers.single;
      expect(pointer?.type, DnsType.ptr);
      expect(pointer?.name, ['_FC9F5ED42C8A', '_tcp', 'local']);
      expect(
        DnsWire.readName(pointer?.data ?? Uint8List(0), 0)?.$1.first,
        QuickShareService.instanceName('AbC1'),
      );
      final [srv, txt, a] = decoded?.additionals ?? [];
      expect(ByteData.sublistView(srv.data).getUint16(4), 50123);
      expect(DnsWire.readName(srv.data, 6)?.$1, service.hostName);
      expect(a.name, service.hostName);
      expect(a.data, address.rawAddress);

      final value = utf8.decode(txt.data.sublist(1));
      expect(value, startsWith('n='));
      expect(
        QuickShareEndpointInfo.fromTxt(value.substring(2))?.name,
        'Laptop',
      );
    });

    test('answers questions about the instance and the host', () {
      final srv = responder.answer(
        ask(service.instanceName, DnsType.srv),
        address,
      );
      final txt = responder.answer(
        ask(service.instanceName, DnsType.txt),
        address,
      );
      final any = responder.answer(
        ask(service.instanceName, DnsType.any),
        address,
      );
      final host = responder.answer(ask(service.hostName, DnsType.a), address);

      expect(srv?.answers.single.type, DnsType.srv);
      expect(srv?.additionals.single.type, DnsType.a);
      expect(txt?.answers.single.type, DnsType.txt);
      expect(any?.answers.map((record) => record.type), [
        DnsType.srv,
        DnsType.txt,
      ]);
      expect(host?.answers.single.data, address.rawAddress);
    });

    test('lists the service type for service browsers', () {
      final answer = responder.answer(
        ask(['_services', '_dns-sd', '_udp', 'local'], DnsType.ptr),
        address,
      );

      expect(
        DnsWire.readName(answer?.answers.single.data ?? Uint8List(0), 0)?.$1,
        service.typeName,
      );
    });

    test('stays silent about other services and about answers', () {
      expect(
        responder.answer(ask(['_ipp', '_tcp', 'local'], DnsType.ptr), address),
        isNull,
      );
      expect(
        responder.answer(ask(['other', 'local'], DnsType.a), address),
        isNull,
      );
      expect(
        responder.answer(
          DnsMessage(
            isResponse: true,
            questions: [DnsQuestion(name: service.typeName, type: DnsType.ptr)],
          ),
          address,
        ),
        isNull,
      );
    });

    test('says each record once when asked twice', () {
      final answer = responder.answer(
        DnsMessage(
          questions: [
            DnsQuestion(name: service.typeName, type: DnsType.ptr),
            DnsQuestion(name: service.instanceName, type: DnsType.srv),
          ],
        ),
        address,
      );

      expect(answer?.answers.map((record) => record.type), [
        DnsType.ptr,
        DnsType.srv,
      ]);
      expect(answer?.additionals.map((record) => record.type), [
        DnsType.txt,
        DnsType.a,
      ]);
    });

    test('announces with all records, and takes them back with TTL 0', () {
      final hello = responder.announcement(address);
      final goodbye = responder.announcement(address, goodbye: true);

      expect(hello.isResponse, isTrue);
      expect(hello.answers.map((record) => record.type), [
        DnsType.ptr,
        DnsType.srv,
        DnsType.txt,
        DnsType.a,
      ]);
      expect(hello.answers.every((record) => record.ttl > 0), isTrue);
      expect(goodbye.answers.every((record) => record.ttl == 0), isTrue);
    });

    test('uses a host name that says nothing about this computer', () {
      final other = QuickShareAdvertiser.serviceFor(
        'AbC1',
        50123,
        const QuickShareEndpointInfo(name: 'Laptop'),
      );

      expect(service.host, matches(RegExp(r'^qs-[0-9a-f]{12}$')));
      expect(other.host, isNot(service.host));
    });
  });
}
