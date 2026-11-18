import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:interop_quickshare/interop_quickshare.dart';
import 'package:test/test.dart';

void main() {
  group('FrameReader', () {
    Uint8List framed(List<int> body) => Uint8List.fromList([
      ...(ByteData(4)..setUint32(0, body.length)).buffer.asUint8List(),
      ...body,
    ]);

    test('reads frames split and joined across packets', () async {
      final bytes = [
        ...framed([1, 2, 3]),
        ...framed([]),
        ...framed(List.filled(300, 9)),
      ];
      final reader = FrameReader(
        Stream.fromIterable([
          Uint8List.fromList(bytes.sublist(0, 2)),
          Uint8List.fromList(bytes.sublist(2, 9)),
          Uint8List.fromList(bytes.sublist(9)),
        ]),
      );

      expect(await reader.next(), [1, 2, 3]);
      expect(await reader.next(), isEmpty);
      expect(await reader.next(), List.filled(300, 9));
      expect(await reader.next(), isNull);
    });

    test('refuses frames longer than allowed', () async {
      final reader = FrameReader(
        Stream.value(Uint8List.fromList([0x7f, 0xff, 0xff, 0xff, 1])),
        maxFrameLength: 1024,
      );

      expect(
        reader.next,
        throwsA(
          isA<QuickShareException>().having(
            (error) => error.failure,
            'failure',
            QuickShareFailure.protocol,
          ),
        ),
      );
    });

    test('reports a stream that ends inside a frame', () async {
      final reader = FrameReader(
        Stream.value(Uint8List.fromList([0, 0, 0, 5, 1, 2])),
      );

      expect(reader.next, throwsA(isA<QuickShareException>()));
    });
  });

  group('BytesPayloads', () {
    PayloadTransfer chunk(int id, List<int> body, {bool last = false}) =>
        PayloadTransfer(
          packetType: .DATA,
          payloadHeader: PayloadTransfer_PayloadHeader(
            id: Int64(id),
            type: .BYTES,
          ),
          payloadChunk: PayloadTransfer_PayloadChunk(
            body: body,
            flags: switch (last) {
              true => 1,
              false => 0,
            },
          ),
        );

    test('joins the chunks of each payload', () {
      final payloads = BytesPayloads();

      expect(payloads.add(chunk(1, [1, 2])), isNull);
      expect(payloads.add(chunk(2, [7])), isNull);
      expect(payloads.add(chunk(1, [3])), isNull);
      final first = payloads.add(chunk(1, [], last: true));
      final second = payloads.add(chunk(2, [8], last: true));
      expect(first?.$1, 1);
      expect(first?.$2, [1, 2, 3]);
      expect(second?.$1, 2);
      expect(second?.$2, [7, 8]);
    });

    test('refuses payloads that grow too long or too many', () {
      final small = BytesPayloads(maxBytes: 4, maxOpen: 1);

      expect(small.add(chunk(1, [1, 2, 3])), isNull);
      expect(
        () => small.add(chunk(1, [4, 5])),
        throwsA(isA<QuickShareException>()),
      );
      expect(
        () => small.add(chunk(2, [1])),
        throwsA(isA<QuickShareException>()),
      );
    });
  });

  group('wire format', () {
    test('an introduction keeps its files and texts', () {
      final frame = SharingFrame(
        version: .V1,
        v1: SharingFrameV1(
          type: .INTRODUCTION,
          introduction: Introduction(
            fileMetadata: [
              FileMetadata(
                name: 'photo.jpg',
                type: .IMAGE,
                payloadId: Int64(-5),
                size: Int64(1 << 33),
                mimeType: 'image/jpeg',
              ),
            ],
            textMetadata: [
              TextMetadata(textTitle: 'hello', type: .URL, payloadId: Int64(9)),
            ],
          ),
        ),
      );

      final decoded = SharingFrame.fromBuffer(frame.writeToBuffer()).v1;

      expect(decoded.type, SharingFrameV1_FrameType.INTRODUCTION);
      expect(decoded.introduction.fileMetadata.single.name, 'photo.jpg');
      expect(decoded.introduction.fileMetadata.single.payloadId, Int64(-5));
      expect(decoded.introduction.fileMetadata.single.size.toInt(), 1 << 33);
      expect(
        decoded.introduction.textMetadata.single.type,
        TextMetadata_Type.URL,
      );
    });

    test('field numbers match the protocol', () {
      // Hand-encoded: OfflineFrame{version: V1, v1{type: KEEP_ALIVE,
      // keep_alive{ack: true}}}.
      final keepAlive = OfflineFrame.fromBuffer([
        0x08,
        0x01,
        0x12,
        0x06,
        0x08,
        0x05,
        0x32,
        0x02,
        0x08,
        0x01,
      ]);
      // Hand-encoded: Frame{version: V1, v1{type: RESPONSE,
      // connection_response{status: REJECT}}}.
      final response = SharingFrame.fromBuffer([
        0x08,
        0x01,
        0x12,
        0x06,
        0x08,
        0x02,
        0x1a,
        0x02,
        0x08,
        0x02,
      ]);
      // Hand-encoded: PayloadTransferFrame{packet_type: DATA,
      // payload_header{id: 7, type: FILE, total_size: 3},
      // payload_chunk{flags: 1, offset: 2, body: "A"}}.
      final payload = PayloadTransfer.fromBuffer([
        0x08,
        0x01,
        0x12,
        0x06,
        0x08,
        0x07,
        0x10,
        0x02,
        0x18,
        0x03,
        0x1a,
        0x07,
        0x08,
        0x01,
        0x10,
        0x02,
        0x1a,
        0x01,
        0x41,
      ]);

      expect(keepAlive.v1.type, OfflineFrameV1_FrameType.KEEP_ALIVE);
      expect(keepAlive.v1.keepAlive.ack, isTrue);
      expect(response.v1.type, SharingFrameV1_FrameType.RESPONSE);
      expect(
        response.v1.connectionResponse.status,
        TransferResponse_Status.REJECT,
      );
      expect(payload.payloadHeader.id, Int64(7));
      expect(
        payload.payloadHeader.type,
        PayloadTransfer_PayloadHeader_PayloadType.FILE,
      );
      expect(payload.payloadChunk.flags, 1);
      expect(payload.payloadChunk.offset, Int64(2));
      expect(payload.payloadChunk.body, [0x41]);
    });
  });
}
