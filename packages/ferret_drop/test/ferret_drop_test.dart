import 'dart:io';
import 'dart:typed_data';

import 'package:ferret_drop/ferret_drop.dart';
import 'package:ferret_drop/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pending shares arrive on the stream, then live ones', () async {
    final api = _FakeApi()
      ..pending = [
        SharedItems(paths: ['/cache/a.txt']),
      ];
    final drop = FerretDrop(api: api);

    final received = <SharedItems>[];
    final subscription = drop.shares.listen(received.add);
    await pumpEventQueue();
    drop.onShared(SharedItems(paths: const [], text: 'hello'));
    await pumpEventQueue();

    expect(received.map((items) => items.paths), [
      ['/cache/a.txt'],
      <String>[],
    ]);
    expect(received.last.text, 'hello');
    await subscription.cancel();
  });

  test('share targets reach the platform', () async {
    final api = _FakeApi();
    final drop = FerretDrop(api: api);

    await drop.setShareTargets([
      ShareTarget(deviceId: 'phone-id', name: 'Pixel 9', kind: 'phone'),
    ]);

    expect(api.targets.single.name, 'Pixel 9');
  });

  test('a platform without a share sheet list ignores targets', () async {
    final drop = FerretDrop(api: _FakeApi()..fails = true);

    await expectLater(drop.setShareTargets(const []), completes);
  });

  test('platform failures become false instead of throwing', () async {
    final drop = FerretDrop(api: _FakeApi()..fails = true);

    expect(await drop.open('/missing'), isFalse);
    expect(await drop.reveal('/missing'), isFalse);
    expect(await drop.canSaveToDownloads(), isFalse);
  });

  group('FilePicks', () {
    const channel = MethodChannel('io.sofluffy.ferret_drop/pick');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('hands back the picked URIs', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return ['content://docs/a.jpg', 'content://docs/b.jpg'];
      });

      expect(await FilePicks.open(), [
        'content://docs/a.jpg',
        'content://docs/b.jpg',
      ]);
      expect(calls, ['pickFiles']);
    });

    test('a picker that fails or is missing picks nothing', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'busy'),
      );
      expect(await FilePicks.open(), isEmpty);

      messenger.setMockMethodCallHandler(channel, null);
      expect(await FilePicks.open(), isEmpty);
    });
  });

  group('ContentFiles', () {
    const channel = MethodChannel('io.sofluffy.ferret_drop/content');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('describes a URI', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'describe');
        expect(call.arguments, 'content://docs/movie.mp4');
        return {
          'name': 'movie.mp4',
          'size': 1 << 30,
          'mime': 'video/mp4',
          'modified': 1700000000000,
        };
      });

      final info = await const ContentFiles().describe(
        'content://docs/movie.mp4',
      );

      expect(info?.name, 'movie.mp4');
      expect(info?.size, 1 << 30);
      expect(info?.mime, 'video/mp4');
      expect(info?.modified?.millisecondsSinceEpoch, 1700000000000);
    });

    test(
      'reads in blocks, one ahead, and slices them to the asked size',
      () async {
        final source = Uint8List.fromList([
          for (var i = 0; i < 2 * 1024 * 1024 + 10; i++) i % 251,
        ]);
        var at = 0;
        final calls = <String>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'open':
              return {'handle': 7, 'length': source.length};
            case 'read':
              final args = call.arguments as Map<Object?, Object?>;
              expect(args['handle'], 7);
              final end = (at + (args['length']! as int)).clamp(
                0,
                source.length,
              );
              final block = Uint8List.sublistView(source, at, end);
              at = end;
              return block;
            case 'close':
              return null;
          }
          return null;
        });

        final reader = await const ContentFiles().open('content://docs/a');
        expect(reader.length, source.length);
        final read = BytesBuilder(copy: false);
        while (true) {
          final bytes = await reader.read(256 * 1024);
          if (bytes.isEmpty) {
            break;
          }
          expect(bytes.length, lessThanOrEqualTo(256 * 1024));
          read.add(bytes);
        }
        await reader.close();

        expect(read.takeBytes(), source);
        expect(calls.where((call) => call == 'read').length, 4);
        expect(calls.last, 'close');
      },
    );

    test('an unreadable URI throws a FileSystemException', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'unreadable'),
      );

      await expectLater(
        const ContentFiles().open('content://gone'),
        throwsA(isA<FileSystemException>()),
      );
      expect(await const ContentFiles().describe('content://gone'), isNull);
    });
  });
}

class _FakeApi implements FerretDropHostApi {
  List<SharedItems> pending = [];
  List<ShareTarget> targets = [];
  bool fails = false;

  @override
  Future<List<SharedItems>> takePendingShares() async {
    final taken = pending;
    pending = [];
    return taken;
  }

  @override
  Future<void> setShareTargets(List<ShareTarget> targets) async {
    await _answer(true);
    this.targets = targets;
  }

  @override
  Future<bool> canSaveToDownloads() => _answer(true);

  @override
  Future<bool> open(String location, String mimeType) => _answer(true);

  @override
  Future<bool> reveal(String location) => _answer(true);

  @override
  Future<SavedFile> saveToDownloads(
    String sourcePath,
    String fileName,
    String mimeType,
    String folder,
  ) async => SavedFile(location: 'content://1', name: fileName);

  Future<T> _answer<T>(T value) async {
    if (fails) {
      throw PlatformException(code: 'unsupported');
    }

    return value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
