import 'dart:io';

import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScrcpyServerOptions', () {
    test('names the socket and the file after the scid, as 8 hex digits', () {
      const options = ScrcpyServerOptions(scid: 0x1234);

      expect(options.scidHex, '00001234');
      expect(options.socketName, 'scrcpy_00001234');
      expect(
        options.devicePath,
        '/data/local/tmp/ferret-scrcpy-server-00001234.jar',
      );
    });

    test('starts the pinned server, video only, over a forward tunnel', () {
      const options = ScrcpyServerOptions(scid: 0x7fffffff);

      expect(options.shellCommand, [
        'CLASSPATH=/data/local/tmp/ferret-scrcpy-server-7fffffff.jar',
        'app_process',
        '/',
        'com.genymobile.scrcpy.Server',
        '5.0.1',
        'scid=7fffffff',
        'log_level=info',
        'tunnel_forward=true',
        'video_codec=h264',
        'audio=false',
        'control=true',
        'clipboard_autosync=false',
      ]);
    });

    test('passes the size, rate and bitrate the viewer asked for', () {
      final options = ScrcpyServerOptions.from(
        const FeedOptions(
          codecs: [.h264],
          maxSize: 1920,
          maxFps: 60,
          bitrate: 4000000,
        ),
        scid: 1,
      );

      expect(
        options.shellCommand,
        containsAll(['max_size=1920', 'max_fps=60', 'video_bit_rate=4000000']),
      );
    });
  });

  group('ScrcpyRelease', () {
    test('pins the server of its own version, from scrcpy\'s releases', () {
      expect(
        ScrcpyRelease.server.url,
        'https://github.com/Genymobile/scrcpy/releases/download/'
        'v${ScrcpyRelease.version}/scrcpy-server-v${ScrcpyRelease.version}',
      );
      expect(ScrcpyRelease.server.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });

  group('VerifiedDownload', () {
    late HttpServer server;
    late Directory directory;
    late int requests;

    // SHA-256 of the 5 bytes "hello".
    const helloHash =
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';

    setUp(() async {
      requests = 0;
      directory = await Directory.systemTemp.createTemp('verified_download');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        requests++;
        if (request.uri.path != '/hello') {
          request.response.statusCode = HttpStatus.notFound;
        }
        request.response.write('hello');
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      await directory.delete(recursive: true);
    });

    PinnedFile pinned({String path = '/hello', String sha256 = helloHash}) {
      return PinnedFile(
        url: 'http://127.0.0.1:${server.port}$path',
        sha256: sha256,
        fileName: 'hello.bin',
      );
    }

    test('keeps a file whose hash is the pinned one', () async {
      final file = await VerifiedDownload().ensure(pinned(), directory);

      expect(await file.readAsString(), 'hello');
      expect(file.path, endsWith('hello.bin'));
    });

    test('does not fetch again what it already has', () async {
      await VerifiedDownload().ensure(pinned(), directory);
      await VerifiedDownload().ensure(pinned(), directory);

      expect(requests, 1);
    });

    test('fetches again when the file on disk was changed', () async {
      final file = await VerifiedDownload().ensure(pinned(), directory);
      await file.writeAsString('tampered');

      final again = await VerifiedDownload().ensure(pinned(), directory);

      expect(await again.readAsString(), 'hello');
      expect(requests, 2);
    });

    test('throws and keeps nothing when the hash is another', () async {
      final wrong = pinned(sha256: '0' * 64);

      await expectLater(
        VerifiedDownload().ensure(wrong, directory),
        throwsA(isA<DownloadException>()),
      );
      expect(await directory.list().toList(), isEmpty);
    });

    test('throws when the server says no', () async {
      await expectLater(
        VerifiedDownload().ensure(pinned(path: '/missing'), directory),
        throwsA(isA<DownloadException>()),
      );
    });
  });
}
