import 'dart:async';
import 'dart:io';

import 'package:interop_localsend/interop_localsend.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/loopback.dart';
import 'support/recording_delegate.dart';

void main() {
  late LocalSendIdentity receiverIdentity;
  late LocalSendIdentity senderIdentity;
  late Directory inbox;
  late RecordingDelegate delegate;
  late LocalSendServer server;
  late LocalSendClient client;
  late LocalSendPeer receiver;
  String? pin;
  final registered = <LocalSendInfo>[];

  setUpAll(() async {
    receiverIdentity = await LocalSendIdentity.generate();
    senderIdentity = await LocalSendIdentity.generate();
  });

  setUp(() async {
    inbox = await Directory.systemTemp.createTemp('localsend_loopback');
    delegate = RecordingDelegate(inbox);
    pin = null;
    registered.clear();
    server = LocalSendServer(
      identity: receiverIdentity,
      self: (port) => infoFor(receiverIdentity, 'Receiver', port: port),
      delegate: delegate,
      port: 0,
      fallbackPorts: 0,
      pin: () => pin,
      onRegister: (info, _) => registered.add(info),
      address: InternetAddress.loopbackIPv4,
    );
    final port = await server.start();
    receiver = peerFor(receiverIdentity, port);
    client = LocalSendClient(identity: senderIdentity);
  });

  tearDown(() async {
    client.close();
    await server.stop();
    await inbox.delete(recursive: true);
  });

  LocalSendSendJob job(List<LocalSendOutgoingFile> files, {String? pin}) =>
      LocalSendSendJob(
        client: client,
        peer: receiver,
        self: infoFor(senderIdentity, 'Sender'),
        files: files,
        pin: pin,
      );

  Future<LocalSendFailure?> failureOf(Future<Object?> work) async {
    try {
      await work;
      return null;
    } on LocalSendException catch (error) {
      return error.failure;
    }
  }

  test('several files arrive intact over HTTPS', () async {
    final photo = randomBytes(300 * 1024, seed: 1);
    final notes = randomBytes(1234, seed: 2);
    final progress = <int>[];
    var accepted = false;

    final taken = await job([
      outgoing('a', 'photo.jpg', photo, withHash: true),
      outgoing('b', 'notes.txt', notes),
      outgoing('c', 'empty.bin', const []),
    ]).run(onAccepted: () => accepted = true, onProgress: progress.add);

    expect(taken, {'a', 'b', 'c'});
    expect(accepted, isTrue);
    expect(progress.last, photo.length + notes.length);
    expect(await File(p.join(inbox.path, 'photo.jpg')).readAsBytes(), photo);
    expect(await File(p.join(inbox.path, 'notes.txt')).readAsBytes(), notes);
    expect(await File(p.join(inbox.path, 'empty.bin')).length(), 0);
    expect(delegate.partFiles, isEmpty);
    expect(delegate.ends, [LocalSendSessionEnd.finished]);
    expect(delegate.progress.last, photo.length + notes.length);
    expect(server.isBusy, isFalse);

    final offer = delegate.offers.single;
    expect(offer.sender.alias, 'Sender');
    expect(offer.sender.fingerprint, senderIdentity.fingerprint);
    expect(offer.address, InternetAddress.loopbackIPv4);
    expect(offer.totalBytes, photo.length + notes.length);
  });

  test('a declined offer is refused, and nothing is written', () async {
    delegate.decide = (_) async => null;

    final failure = await failureOf(
      job([outgoing('a', 'photo.jpg', randomBytes(64))]).run(),
    );

    expect(failure, LocalSendFailure.rejected);
    expect(inbox.listSync(), isEmpty);
    expect(delegate.ends, isEmpty);
    expect(server.isBusy, isFalse);
  });

  test('the receiver can take only some of the files', () async {
    delegate.decide = (_) async => {'b'};

    final taken = await job([
      outgoing('a', 'skip.bin', randomBytes(64)),
      outgoing('b', 'keep.bin', randomBytes(64)),
    ]).run();

    expect(taken, {'b'});
    expect(delegate.saved, ['keep.bin']);
    expect(delegate.ends, [LocalSendSessionEnd.finished]);
  });

  test('a text message needs no upload', () async {
    delegate.decide = (_) async => const {};
    const text = 'See you at 6';

    final taken = await job([
      LocalSendOutgoingFile(
        file: const LocalSendFile(
          id: 'm',
          fileName: 'm.txt',
          size: 12,
          fileType: 'text/plain',
          preview: text,
        ),
        open: () => Stream.value(text.codeUnits),
      ),
    ]).run();

    expect(taken, isEmpty);
    expect(delegate.offers.single.files.single.preview, text);
    expect(delegate.offers.single.files.single.isMessage, isTrue);
    expect(server.isBusy, isFalse);
  });

  test('the sender cancels while a file is on its way', () async {
    final big = randomBytes(4 * 1024 * 1024);
    final gate = Completer<void>();
    final sending = job([
      LocalSendOutgoingFile(
        file: LocalSendFile(id: 'a', fileName: 'big.bin', size: big.length),
        open: () async* {
          yield big.sublist(0, 64 * 1024);
          await gate.future;
          yield big.sublist(64 * 1024);
        },
      ),
    ]);

    final result = failureOf(sending.run());
    await delegate.firstProgress.future;
    await sending.cancel();
    gate.complete();

    expect(await result, LocalSendFailure.cancelled);
    await until(() => delegate.ends.isNotEmpty);
    expect(delegate.ends, [LocalSendSessionEnd.cancelledBySender]);
    await until(() => delegate.partFiles.isEmpty);
    expect(delegate.saved, isEmpty);
    expect(server.isBusy, isFalse);
  });

  test('the sender withdraws an offer nobody answered yet', () async {
    final answer = Completer<Set<String>?>();
    delegate.decide = (_) => answer.future;
    final sending = job([outgoing('a', 'photo.jpg', randomBytes(64))]);

    final result = failureOf(sending.run());
    await until(() => delegate.offers.isNotEmpty);
    await sending.cancel();

    expect(await result, LocalSendFailure.cancelled);
    await until(() => delegate.ends.isNotEmpty);
    expect(delegate.ends, [LocalSendSessionEnd.cancelledBySender]);
    answer.complete(null);
    await until(() => !server.isBusy);
  });

  test('the receiver cancels while a file is on its way', () async {
    final big = randomBytes(2 * 1024 * 1024);
    final gate = Completer<void>();
    final sending = job([
      LocalSendOutgoingFile(
        file: LocalSendFile(id: 'a', fileName: 'big.bin', size: big.length),
        open: () async* {
          yield big.sublist(0, 64 * 1024);
          await gate.future;
          yield big.sublist(64 * 1024);
        },
      ),
    ]);

    final result = failureOf(sending.run());
    await delegate.firstProgress.future;
    await server.cancelSession(delegate.offers.single.sessionId);
    gate.complete();

    expect(await result, isNotNull);
    await until(() => delegate.partFiles.isEmpty);
    expect(delegate.saved, isEmpty);
    expect(delegate.ends, isEmpty);
    expect(server.isBusy, isFalse);
  });

  test('data that does not match its SHA-256 is refused with 422', () async {
    final failure = await failureOf(
      job([
        outgoing(
          'a',
          'photo.jpg',
          randomBytes(2048),
          sha256Override: 'ab' * 32,
        ),
      ]).run(),
    );

    expect(failure, LocalSendFailure.checksum);
    expect(delegate.saved, isEmpty);
    expect(delegate.partFiles, isEmpty);
  });

  test('a file shorter than announced is refused', () async {
    final prepared = await client.prepareUpload(
      receiver,
      PrepareUploadRequest(
        info: infoFor(senderIdentity, 'Sender'),
        files: const {
          'a': LocalSendFile(id: 'a', fileName: 'short.bin', size: 100),
        },
      ),
    );
    final token = prepared?.files['a'] ?? '';

    final failure = await failureOf(
      client.upload(
        receiver,
        sessionId: prepared?.sessionId ?? '',
        fileId: 'a',
        token: token,
        data: Stream.value(List.filled(40, 1)),
        length: 40,
      ),
    );

    expect(failure, LocalSendFailure.checksum);
    expect(delegate.saved, isEmpty);
  });

  test('uploads need the right session and token', () async {
    final prepared = await client.prepareUpload(
      receiver,
      PrepareUploadRequest(
        info: infoFor(senderIdentity, 'Sender'),
        files: const {
          'a': LocalSendFile(id: 'a', fileName: 'a.bin', size: 4),
        },
      ),
    );
    final sessionId = prepared?.sessionId ?? '';

    Future<LocalSendFailure?> upload(String session, String token) => failureOf(
      client.upload(
        receiver,
        sessionId: session,
        fileId: 'a',
        token: token,
        data: Stream.value(const [1, 2, 3, 4]),
        length: 4,
      ),
    );

    expect(await upload(sessionId, 'wrong'), LocalSendFailure.rejected);
    expect(
      await upload('other', prepared?.files['a'] ?? ''),
      LocalSendFailure.busy,
    );
    expect(await upload(sessionId, prepared?.files['a'] ?? ''), isNull);
    expect(delegate.saved, ['a.bin']);
  });

  test('a second sender is told the receiver is busy', () async {
    final answer = Completer<Set<String>?>();
    delegate.decide = (_) => answer.future;
    final first = failureOf(
      job([outgoing('a', 'one.bin', randomBytes(8))]).run(),
    );
    await until(() => delegate.offers.isNotEmpty);

    final second = await failureOf(
      job([outgoing('b', 'two.bin', randomBytes(8))]).run(),
    );

    expect(second, LocalSendFailure.busy);
    answer.complete(null);
    expect(await first, LocalSendFailure.rejected);
  });

  test('a protected receiver wants the PIN, and locks after 3 tries', () async {
    pin = '123456';
    final files = [outgoing('a', 'photo.jpg', randomBytes(64))];

    expect(await failureOf(job(files).run()), LocalSendFailure.pinRequired);
    expect(
      await failureOf(job(files, pin: '000000').run()),
      LocalSendFailure.pinRequired,
    );
    expect(await job(files, pin: '123456').run(), {'a'});
    expect(delegate.offers, hasLength(1));

    for (var attempt = 0; attempt < LocalSendServer.maxPinAttempts; attempt++) {
      await failureOf(job(files, pin: 'nope').run());
    }

    expect(
      await failureOf(job(files, pin: '123456').run()),
      LocalSendFailure.tooManyRequests,
    );
  });

  test(
    'a receiver that cannot save answers 500 and ends the session',
    () async {
      delegate.failSaving = true;

      final failure = await failureOf(
        job([outgoing('a', 'photo.jpg', randomBytes(64))]).run(),
      );

      expect(failure, LocalSendFailure.receiverError);
      expect(delegate.ends, [LocalSendSessionEnd.storageFailed]);
      expect(delegate.partFiles, isEmpty);
    },
  );

  test('a device showing another certificate is never sent anything', () async {
    final impostor = LocalSendPeer(
      info: infoFor(senderIdentity, 'Receiver', port: receiver.port),
      address: InternetAddress.loopbackIPv4,
      lastSeen: DateTime.now(),
    );

    final failure = await failureOf(
      LocalSendSendJob(
        client: client,
        peer: impostor,
        self: infoFor(senderIdentity, 'Sender'),
        files: [outgoing('a', 'photo.jpg', randomBytes(64))],
      ).run(),
    );

    expect(failure, LocalSendFailure.untrusted);
    expect(delegate.offers, isEmpty);
  });

  test('a device that is gone is unreachable', () async {
    final port = receiver.port;
    await server.stop();

    final failure = await failureOf(
      LocalSendSendJob(
        client: client,
        peer: peerFor(receiverIdentity, port),
        self: infoFor(senderIdentity, 'Sender'),
        files: [outgoing('a', 'photo.jpg', randomBytes(64))],
      ).run(),
    );

    expect(failure, LocalSendFailure.unreachable);
  });

  test('register and info describe the receiver', () async {
    final self = infoFor(senderIdentity, 'Sender', port: 53317);

    final answer = await client.register(receiver, self);
    final info = await client.info(receiver);

    expect(answer.alias, 'Receiver');
    expect(answer.fingerprint, receiverIdentity.fingerprint);
    expect(info.alias, 'Receiver');
    expect(registered.single.alias, 'Sender');
    expect(registered.single.port, 53317);
  });

  test('an address scan finds the receiver and pins its certificate', () async {
    final found = <LocalSendPeer>[];
    final scanner = LegacyScanner(client: client, port: receiver.port);

    await scanner.scan(
      infoFor(senderIdentity, 'Sender'),
      [InternetAddress.loopbackIPv4],
      onFound: found.add,
    );

    expect(found.single.info.alias, 'Receiver');
    expect(found.single.fingerprint, receiverIdentity.fingerprint);
    expect(found.single.port, receiver.port);
  });

  test('unknown routes are not found', () async {
    final http = HttpClient(context: SecurityContext(withTrustedRoots: false))
      ..badCertificateCallback = (_, _, _) => true;
    addTearDown(() => http.close(force: true));

    Future<int> status(String method, String path) async {
      final request = await http.openUrl(
        method,
        Uri.parse('https://127.0.0.1:${receiver.port}$path'),
      );
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode;
    }

    expect(await status('GET', '/'), HttpStatus.notFound);
    expect(
      await status('POST', '/api/localsend/v1/send-request'),
      HttpStatus.notFound,
    );
    expect(
      await status('GET', '/api/localsend/v2/upload'),
      HttpStatus.notFound,
    );
    expect(
      await status('POST', '/api/localsend/v2/upload'),
      HttpStatus.badRequest,
    );
    expect(
      await status('POST', '/api/localsend/v2/register'),
      HttpStatus.badRequest,
    );
    expect(await status('POST', '/api/localsend/v2/cancel'), HttpStatus.ok);
  });

  test('a stalled session is given up', () async {
    await server.stop();
    server = LocalSendServer(
      identity: receiverIdentity,
      self: (port) => infoFor(receiverIdentity, 'Receiver', port: port),
      delegate: delegate,
      port: 0,
      fallbackPorts: 0,
      idleTimeout: Duration.zero,
      address: InternetAddress.loopbackIPv4,
    );
    receiver = peerFor(receiverIdentity, await server.start());

    await client.prepareUpload(
      receiver,
      PrepareUploadRequest(
        info: infoFor(senderIdentity, 'Sender'),
        files: const {
          'a': LocalSendFile(id: 'a', fileName: 'a.bin', size: 4),
        },
      ),
    );

    await until(() => delegate.ends.isNotEmpty);
    expect(delegate.ends, [LocalSendSessionEnd.stalled]);
  });
}
