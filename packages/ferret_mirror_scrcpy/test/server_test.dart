import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
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

  group('ScrcpyServerOptions with sound', () {
    List<String> commandFor(List<MirrorAudioCodec> audioCodecs) =>
        ScrcpyServerOptions.from(
          FeedOptions(codecs: const [.h264], audioCodecs: audioCodecs),
          scid: 1,
        ).shellCommand;

    test('asks for the device\'s own output, as Opus', () {
      final command = commandFor(const [.opus, .pcm]);

      expect(
        command,
        containsAll(['audio=true', 'audio_codec=opus', 'audio_source=output']),
      );
      expect(command, isNot(contains('audio=false')));
    });

    test('asks for plain samples where nothing decodes Opus', () {
      expect(
        commandFor(const [.pcm]),
        containsAll(['audio=true', 'audio_codec=raw']),
      );
    });

    test('never asks for the microphone', () {
      final command = commandFor(const [.opus]).join(' ');

      expect(command, isNot(contains('mic')));
    });

    test('leaves sound off unless the viewer asked', () {
      expect(commandFor(const []), contains('audio=false'));
    });
  });

  group('ScrcpyServerBundle', () {
    final asset = File('assets/${ScrcpyRelease.serverFileName}');
    late Directory directory;

    Future<ByteData> loadAsset() async =>
        ByteData.sublistView(await asset.readAsBytes());

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('scrcpy_bundle');
    });

    tearDown(() => directory.delete(recursive: true));

    test('ships the server scrcpy released, to the byte', () async {
      final digest = sha256.convert(await asset.readAsBytes());

      expect(digest.toString(), ScrcpyRelease.serverSha256);
      expect(
        ScrcpyRelease.serverAsset,
        'packages/ferret_mirror_scrcpy/assets/scrcpy-server-v5.0.1',
      );
    });

    test('ships scrcpy\'s licence and a notice next to it', () {
      final licence = File('assets/scrcpy-LICENSE.txt').readAsStringSync();
      final notice = File('assets/scrcpy-NOTICE.txt').readAsStringSync();

      expect(licence, contains('Apache License'));
      expect(notice, contains(ScrcpyRelease.serverSha256));
      expect(notice, contains('not modified'));
    });

    test('writes the bundled server out once', () async {
      var loads = 0;
      final bundle = ScrcpyServerBundle(
        directory: () async => directory,
        load: () {
          loads++;
          return loadAsset();
        },
      );

      final file = await bundle.ensure();
      await bundle.ensure();

      expect(file.path, endsWith(ScrcpyRelease.serverFileName));
      expect(await file.length(), await asset.length());
      expect(loads, 1);
    });

    test('replaces a file on disk that was changed', () async {
      final bundle = ScrcpyServerBundle(
        directory: () async => directory,
        load: loadAsset,
      );
      final file = await bundle.ensure();
      await file.writeAsString('tampered');

      final again = await bundle.ensure();

      expect(await again.length(), await asset.length());
    });

    test('refuses bundled bytes that are not the pinned ones', () async {
      final bundle = ScrcpyServerBundle(
        directory: () async => directory,
        load: () async => ByteData(16),
      );

      await expectLater(
        bundle.ensure(),
        throwsA(isA<ScrcpyServerException>()),
      );
      expect(await directory.list().toList(), isEmpty);
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
