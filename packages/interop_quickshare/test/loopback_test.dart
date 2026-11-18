import 'dart:async';
import 'dart:io';

import 'package:interop_quickshare/interop_quickshare.dart';
import 'package:test/test.dart';

import 'support/loopback.dart';
import 'support/raw_sender.dart';
import 'support/recording_delegate.dart';

void main() {
  late Directory directory;
  late RecordingDelegate delegate;
  late QuickShareServer server;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('quickshare_test');
    delegate = RecordingDelegate(directory);
    server = QuickShareServer(
      delegate: delegate,
      address: InternetAddress.loopbackIPv4,
      timeouts: fastTimeouts,
    );
    await server.start();
  });

  tearDown(() async {
    await server.stop();
    await directory.delete(recursive: true);
  });

  group('receiving', () {
    test(
      'several files arrive whole, with the same PIN on both sides',
      () async {
        final photo = randomBytes(300 * 1024, seed: 1);
        final notes = randomBytes(5, seed: 2);
        final video = randomBytes(70 * 1024 + 3, seed: 3);
        String? senderPin;
        var sent = 0;

        final result = await jobFor(
          server,
          files: [
            outgoing('photo.jpg', photo, mimeType: 'image/jpeg'),
            outgoing('notes.txt', notes, mimeType: 'text/plain'),
            outgoing('clip.mp4', video, mimeType: 'video/mp4'),
          ],
          onPin: (pin) => senderPin = pin,
          onProgress: (bytes) => sent = bytes,
        ).run();

        expect(result, QuickShareSendResult.sent);
        final offer = delegate.offers.single;
        expect(offer.senderName, 'Pixel');
        expect(offer.senderKind, QuickShareDeviceKind.phone);
        expect(offer.pin, matches(RegExp(r'^\d{4}$')));
        expect(offer.pin, senderPin);
        expect(offer.files.map((file) => file.name), [
          'photo.jpg',
          'notes.txt',
          'clip.mp4',
        ]);
        expect(offer.files.first.mimeType, 'image/jpeg');
        expect(offer.totalBytes, photo.length + notes.length + video.length);

        await until(() => delegate.ends.isNotEmpty);
        expect(delegate.ends, [QuickShareSessionEnd.finished]);
        expect(await delegate.saved['photo.jpg']?.readAsBytes(), photo);
        expect(await delegate.saved['notes.txt']?.readAsBytes(), notes);
        expect(await delegate.saved['clip.mp4']?.readAsBytes(), video);
        expect(delegate.receivedBytes, offer.totalBytes);
        expect(sent, offer.totalBytes);
        await until(() => !server.isBusy);
      },
    );

    test('an empty file arrives too', () async {
      final result = await jobFor(
        server,
        files: [outgoing('empty', const [])],
      ).run();

      expect(result, QuickShareSendResult.sent);
      await until(() => delegate.ends.isNotEmpty);
      expect(await delegate.saved['empty']?.length(), 0);
    });

    test('a text arrives only after the offer is accepted', () async {
      final answer = Completer<bool>();
      delegate.answer = (_) => answer.future;
      final job = jobFor(server, text: 'https://example.com/a?b=1').run();

      await until(() => delegate.offers.isNotEmpty);
      final text = delegate.offers.single.texts.single;
      expect(text.kind, QuickShareTextKind.url);
      expect(text.size, 'https://example.com/a?b=1'.length);
      expect(delegate.offers.single.files, isEmpty);
      expect(delegate.texts, isEmpty);

      answer.complete(true);
      expect(await job, QuickShareSendResult.sent);
      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.texts, ['https://example.com/a?b=1']);
      expect(delegate.ends, [QuickShareSessionEnd.finished]);
    });

    test('files and a text can come in one offer', () async {
      final bytes = randomBytes(1000);
      final result = await jobFor(
        server,
        files: [outgoing('a.bin', bytes)],
        text: 'see attached',
      ).run();

      expect(result, QuickShareSendResult.sent);
      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.texts, ['see attached']);
      expect(await delegate.saved['a.bin']?.readAsBytes(), bytes);
    });

    test('two senders at once each get their own offer and PIN', () async {
      final first = randomBytes(40 * 1024, seed: 11);
      final second = randomBytes(40 * 1024, seed: 12);

      final results = await Future.wait([
        jobFor(
          server,
          files: [outgoing('first.bin', first)],
          name: 'One',
        ).run(),
        jobFor(
          server,
          files: [outgoing('second.bin', second)],
          name: 'Two',
        ).run(),
      ]);

      expect(results, everyElement(QuickShareSendResult.sent));
      await until(() => delegate.ends.length == 2);
      expect(delegate.offers.map((offer) => offer.senderName).toSet(), {
        'One',
        'Two',
      });
      expect(
        delegate.offers.first.sessionId,
        isNot(delegate.offers.last.sessionId),
      );
      expect(await delegate.saved['first.bin']?.readAsBytes(), first);
      expect(await delegate.saved['second.bin']?.readAsBytes(), second);
    });
  });

  group('declining and cancelling', () {
    test('a declined offer sends nothing', () async {
      delegate.answer = (_) async => false;
      var sent = 0;

      final result = await jobFor(
        server,
        files: [outgoing('photo.jpg', randomBytes(1000))],
        onProgress: (bytes) => sent = bytes,
      ).run();

      expect(result, QuickShareSendResult.declined);
      expect(sent, 0);
      expect(delegate.saved, isEmpty);
      expect(delegate.ends, isEmpty);
      expect(directory.listSync(), isEmpty);
      await until(() => !server.isBusy);
    });

    test('a sender that cancels while the offer waits takes it back', () async {
      final answer = Completer<bool>();
      delegate.answer = (_) => answer.future;
      final job = jobFor(server, files: [outgoing('a.bin', randomBytes(100))]);
      final running = job.run();

      await until(() => delegate.offers.isNotEmpty);
      expect(server.isBusy, isTrue);
      await job.cancel();

      expect(await running, QuickShareSendResult.cancelled);
      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.cancelledBySender]);

      // A late answer changes nothing.
      answer.complete(true);
      await until(() => !server.isBusy);
      expect(delegate.saved, isEmpty);
    });

    test('a sender that cancels mid-file stops the transfer', () async {
      final gate = Completer<void>();
      final job = jobFor(
        server,
        files: [
          gated(
            'big.bin',
            randomBytes(32 * 1024),
            randomBytes(1024),
            gate.future,
          ),
        ],
      );
      final running = job.run();

      await until(() => delegate.receivedBytes >= 32 * 1024);
      await job.cancel();
      gate.complete();

      expect(await running, QuickShareSendResult.cancelled);
      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.cancelledBySender]);
      expect(delegate.saved, isEmpty);
    });

    test('cancelling on the receiver stops the sender', () async {
      final gate = Completer<void>();
      final running = jobFor(
        server,
        files: [
          gated(
            'big.bin',
            randomBytes(32 * 1024),
            randomBytes(1024),
            gate.future,
          ),
        ],
      ).run();

      await until(() => delegate.receivedBytes >= 32 * 1024);
      await server.cancelSession(delegate.offers.single.sessionId);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      gate.complete();

      expect(await running, QuickShareSendResult.cancelledByReceiver);
      expect(delegate.ends, isEmpty);
      expect(delegate.saved, isEmpty);
      await until(() => !server.isBusy);
    });

    test('stopping the server ends a waiting offer as declined', () async {
      final answer = Completer<bool>();
      delegate.answer = (_) => answer.future;
      final running = jobFor(
        server,
        files: [outgoing('a.bin', randomBytes(100))],
      ).run();

      await until(() => delegate.offers.isNotEmpty);
      await server.stop();

      expect(await running, QuickShareSendResult.cancelledByReceiver);
      expect(server.isRunning, isFalse);
      expect(delegate.ends, isEmpty);
      answer.complete(false);
    });

    test('a file that cannot be saved stops the transfer', () async {
      delegate.failSaving = true;

      final result = await jobFor(
        server,
        files: [
          outgoing('a.bin', randomBytes(2000)),
          outgoing('b.bin', randomBytes(2000)),
        ],
      ).run();

      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.storageFailed]);
      expect(delegate.saved, isEmpty);
      expect(result, QuickShareSendResult.cancelledByReceiver);
    });
  });

  group('senders that misbehave', () {
    test('the paired key exchange comes before the offer', () async {
      final sender = await RawSender.connect(server);
      final pin = await sender.handshake();

      final first = await sender.waitFor(.PAIRED_KEY_ENCRYPTION);
      expect(first?.pairedKeyEncryption.signedData, hasLength(72));
      expect(first?.pairedKeyEncryption.secretIdHash, hasLength(6));

      sender.link.sendSharing(
        SharingFrameV1(
          type: .PAIRED_KEY_ENCRYPTION,
          pairedKeyEncryption: PairedKeyEncryption(),
        ),
      );
      final result = await sender.waitFor(.PAIRED_KEY_RESULT);
      expect(result?.pairedKeyResult.status, PairedKeyResult_Status.UNABLE);

      sender.introduce(3);
      await until(() => delegate.offers.isNotEmpty);
      expect(delegate.offers.single.pin, pin);
      expect(delegate.offers.single.senderName, 'Raw');
      final response = await sender.waitFor(.RESPONSE);
      expect(
        response?.connectionResponse.status,
        TransferResponse_Status.ACCEPT,
      );
      await sender.close();
    });

    test('content this device cannot take is refused without asking', () async {
      final sender = await RawSender.connect(server);
      await sender.handshake();
      sender.link.sendSharing(
        SharingFrameV1(
          type: .INTRODUCTION,
          introduction: Introduction(
            wifiCredentialsMetadata: [WifiCredentialsMetadata(ssid: 'Home')],
          ),
        ),
      );

      final response = await sender.waitFor(.RESPONSE);

      expect(
        response?.connectionResponse.status,
        TransferResponse_Status.UNSUPPORTED_ATTACHMENT_TYPE,
      );
      expect(delegate.offers, isEmpty);
      await sender.close();
    });

    test('a chunk at the wrong offset ends the session', () async {
      final sender = await RawSender.connect(server);
      await sender.handshake();
      final header = sender.introduce(10);
      await sender.waitFor(.RESPONSE);

      sender.link.sendChunk(header, offset: 4, body: [1, 2, 3]);

      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.protocolError]);
      await sender.close();
    });

    test('more bytes than announced end the session', () async {
      final sender = await RawSender.connect(server);
      await sender.handshake();
      final header = sender.introduce(2);
      await sender.waitFor(.RESPONSE);

      sender.link.sendChunk(header, offset: 0, body: [1, 2, 3]);

      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.protocolError]);
      await sender.close();
    });

    test('a file sent before the answer ends the session', () async {
      final answer = Completer<bool>();
      delegate.answer = (_) => answer.future;
      final sender = await RawSender.connect(server);
      await sender.handshake();
      final header = sender.introduce(3);
      await until(() => delegate.offers.isNotEmpty);

      sender.link.sendChunk(header, offset: 0, body: [1, 2, 3], isLast: true);

      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.protocolError]);
      expect(directory.listSync(), isEmpty);
      answer.complete(true);
      await sender.close();
    });

    test('a file that ends early is not saved', () async {
      final sender = await RawSender.connect(server);
      await sender.handshake();
      final header = sender.introduce(10);
      await sender.waitFor(.RESPONSE);

      sender.link
        ..sendChunk(header, offset: 0, body: [1, 2, 3])
        ..sendChunk(header, offset: 3, isLast: true);

      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.incomplete]);
      expect(delegate.saved, isEmpty);
      expect(await sender.waitFor(.CANCEL), isNotNull);
      await sender.close();
    });

    test('a connection that drops mid-file is reported as lost', () async {
      final sender = await RawSender.connect(server);
      await sender.handshake();
      final header = sender.introduce(10);
      await sender.waitFor(.RESPONSE);

      sender.link.sendChunk(header, offset: 0, body: [1, 2, 3]);
      await sender.link.flush();
      await until(() => delegate.receivedBytes == 3);
      sender.socket.destroy();

      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.connectionLost]);
    });

    test('a frame that fails its signature ends the session', () async {
      final sender = await RawSender.connect(server);
      await sender.handshake();
      sender.introduce(10);
      await sender.waitFor(.RESPONSE);

      final forged = SecureMessageCodec(
        D2DKeys.derive(List.filled(32, 1), isServer: false),
      ).encode([1, 2, 3]);
      sender.link.writeRaw(forged);

      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.protocolError]);
      await sender.close();
    });

    test('a payload cancel from the sender is taken as a cancel', () async {
      final sender = await RawSender.connect(server);
      await sender.handshake();
      final header = sender.introduce(10);
      await sender.waitFor(.RESPONSE);

      sender.link.send(
        OfflineFrameV1(
          type: .PAYLOAD_TRANSFER,
          payloadTransfer: PayloadTransfer(
            packetType: .CONTROL,
            payloadHeader: header,
            controlMessage: PayloadTransfer_ControlMessage(
              event: .PAYLOAD_CANCELED,
            ),
          ),
        ),
      );

      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.cancelledBySender]);
      await sender.close();
    });

    test('a client that asks for another protocol gets an alert', () async {
      final sender = await RawSender.connect(server);
      sender.link
        ..send(
          OfflineFrameV1(
            type: .CONNECTION_REQUEST,
            connectionRequest: ConnectionRequest(endpointId: 'TEST'),
          ),
        )
        ..writeRaw(
          Ukey2Message(
            messageType: .CLIENT_INIT,
            messageData: Ukey2ClientInit(
              version: 1,
              random: List.filled(32, 1),
              cipherCommitments: [
                Ukey2ClientInit_CipherCommitment(
                  handshakeCipher: .P256_SHA512,
                  commitment: List.filled(64, 1),
                ),
              ],
              nextProtocol: 'PLAINTEXT',
            ).writeToBuffer(),
          ).writeToBuffer(),
        );

      final answer = await sender.link.readRaw(fastTimeouts.handshake);
      final message = Ukey2Message.fromBuffer(answer ?? const []);

      expect(message.messageType, Ukey2Message_Type.ALERT);
      expect(
        Ukey2Alert.fromBuffer(message.messageData).type,
        Ukey2Alert_AlertType.BAD_NEXT_PROTOCOL,
      );
      expect(await sender.link.readRaw(fastTimeouts.handshake), isNull);
      expect(delegate.offers, isEmpty);
    });

    test('garbage instead of a connection request is hung up on', () async {
      final sender = await RawSender.connect(server);
      sender.link.writeRaw([0xff, 0xff, 0xff, 0xff, 0xff]);

      expect(await sender.link.readRaw(fastTimeouts.handshake), isNull);
      expect(delegate.offers, isEmpty);
    });

    test('a sender that goes silent is given up on', () async {
      final quiet = QuickShareServer(
        delegate: delegate,
        address: InternetAddress.loopbackIPv4,
        timeouts: const QuickShareTimeouts(
          handshake: Duration(seconds: 5),
          idle: Duration(milliseconds: 300),
          keepAlive: Duration(seconds: 5),
          closeGrace: Duration(milliseconds: 100),
        ),
      );
      await quiet.start();
      addTearDown(quiet.stop);
      final sender = await RawSender.connect(quiet);
      await sender.handshake();
      final header = sender.introduce(10);
      await sender.waitFor(.RESPONSE);
      sender.link.sendChunk(header, offset: 0, body: [1]);

      await until(() => delegate.ends.isNotEmpty);
      expect(delegate.ends, [QuickShareSessionEnd.connectionLost]);
      await sender.close();
    });
  });

  group('server', () {
    test('picks a free port and frees it when stopped', () async {
      final port = server.boundPort;

      expect(port, isNotNull);
      expect(await server.start(), port);
      await server.stop();
      expect(server.boundPort, isNull);
      expect(
        () => jobFor(
          server,
          files: [
            outgoing('a', const [1]),
          ],
        ).run(),
        throwsA(isA<Object>()),
      );
    });

    test('turns senders away beyond its limit', () async {
      final small = QuickShareServer(
        delegate: delegate,
        address: InternetAddress.loopbackIPv4,
        maxSessions: 1,
        timeouts: fastTimeouts,
      );
      await small.start();
      addTearDown(small.stop);
      final answer = Completer<bool>();
      delegate.answer = (_) => answer.future;
      final first = jobFor(
        small,
        files: [
          outgoing('a', const [1]),
        ],
      ).run();
      await until(() => delegate.offers.isNotEmpty);

      await expectLater(
        jobFor(
          small,
          files: [
            outgoing('b', const [2]),
          ],
        ).run(),
        throwsA(isA<QuickShareException>()),
      );

      answer.complete(false);
      expect(await first, QuickShareSendResult.declined);
    });

    test('the sender says when nobody is listening', () async {
      final port = server.boundPort ?? 0;
      await server.stop();
      final job = QuickShareSendJob(
        address: InternetAddress.loopbackIPv4,
        port: port,
        sender: const QuickShareEndpointInfo(name: 'Pixel'),
        files: [
          outgoing('a', const [1]),
        ],
        timeouts: fastTimeouts,
      );

      expect(
        job.run,
        throwsA(
          isA<QuickShareException>().having(
            (error) => error.failure,
            'failure',
            QuickShareFailure.unreachable,
          ),
        ),
      );
    });
  });
}
